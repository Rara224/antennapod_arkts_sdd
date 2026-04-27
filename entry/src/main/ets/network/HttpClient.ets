import { http } from '@kit.NetworkKit';
import { buffer } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'HttpClient';

export class HttpResponse {
  responseCode: number = 0;
  body: string = '';
  headers: Map<string, string> = new Map();
  redirectUrl: string = '';
}

export class HttpCredentials {
  username: string = '';
  password: string = '';

  constructor(username: string, password: string) {
    this.username = username;
    this.password = password;
  }
}

export class HttpClient {
  private static readonly CONNECT_TIMEOUT: number = 10000;
  private static readonly READ_TIMEOUT: number = 30000;
  private static readonly USER_AGENT: string = 'AntennaPod/3.11.0';

  static async get(
    url: string,
    extraHeaders: Map<string, string>,
    credentials: HttpCredentials | undefined
  ): Promise<HttpResponse> {
    return await HttpClient.executeRequest(url, http.RequestMethod.GET, extraHeaders, '', credentials);
  }

  static async post(
    url: string,
    body: string,
    contentType: string,
    credentials: HttpCredentials | undefined
  ): Promise<HttpResponse> {
    const headers = new Map<string, string>();
    headers.set('Content-Type', contentType);
    return await HttpClient.executeRequest(url, http.RequestMethod.POST, headers, body, credentials);
  }

  static async getConditional(
    url: string,
    lastModified: string,
    etag: string,
    credentials: HttpCredentials | undefined
  ): Promise<HttpResponse> {
    const headers = new Map<string, string>();
    if (lastModified.length > 0) {
      headers.set('If-Modified-Since', lastModified);
    }
    if (etag.length > 0) {
      headers.set('If-None-Match', etag);
    }
    return await HttpClient.executeRequest(url, http.RequestMethod.GET, headers, '', credentials);
  }

  static async getBinary(url: string): Promise<ArrayBuffer> {
    const httpRequest = http.createHttp();
    try {
      const headerObj = HttpClient.buildHeaderObject(new Map<string, string>());
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: headerObj,
        connectTimeout: HttpClient.CONNECT_TIMEOUT,
        readTimeout: HttpClient.READ_TIMEOUT,
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      });
      if (resp.result instanceof ArrayBuffer) {
        return resp.result;
      }
      return new ArrayBuffer(0);
    } finally {
      httpRequest.destroy();
    }
  }

  static async head(url: string): Promise<HttpResponse> {
    const headerObj = HttpClient.buildHeaderObject(new Map<string, string>());
    const httpRequest = http.createHttp();
    try {
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.HEAD,
        header: headerObj,
        connectTimeout: HttpClient.CONNECT_TIMEOUT,
        readTimeout: HttpClient.READ_TIMEOUT
      });
      return HttpClient.buildResponse(resp);
    } finally {
      httpRequest.destroy();
    }
  }

  private static async executeRequest(
    url: string,
    method: http.RequestMethod,
    extraHeaders: Map<string, string>,
    body: string,
    credentials: HttpCredentials | undefined
  ): Promise<HttpResponse> {
    const httpRequest = http.createHttp();
    try {
      const headerObj = HttpClient.buildHeaderObject(extraHeaders);
      const options: http.HttpRequestOptions = {
        method: method,
        header: headerObj,
        connectTimeout: HttpClient.CONNECT_TIMEOUT,
        readTimeout: HttpClient.READ_TIMEOUT,
        expectDataType: http.HttpDataType.STRING
      };
      if (body.length > 0) {
        options.extraData = body;
      }

      let resp = await httpRequest.request(url, options);

      // 401 且有凭据时，添加 Authorization header 重试一次
      if (resp.responseCode === 401 && credentials !== undefined) {
        hilog.info(DOMAIN, TAG, 'Got 401, retrying with credentials for %{public}s', url);
        httpRequest.destroy();
        const retryRequest = http.createHttp();
        try {
          const authHeaderObj = HttpClient.buildAuthHeaderObject(extraHeaders, credentials);
          const retryOptions: http.HttpRequestOptions = {
            method: method,
            header: authHeaderObj,
            connectTimeout: HttpClient.CONNECT_TIMEOUT,
            readTimeout: HttpClient.READ_TIMEOUT,
            expectDataType: http.HttpDataType.STRING
          };
          if (body.length > 0) {
            retryOptions.extraData = body;
          }
          resp = await retryRequest.request(url, retryOptions);
          return HttpClient.buildResponse(resp);
        } finally {
          retryRequest.destroy();
        }
      }

      return HttpClient.buildResponse(resp);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Request failed for %{public}s: %{public}s', url, JSON.stringify(e));
      if (e instanceof Error) {
        throw e;
      }
      throw new Error('Request failed for ' + url);
    } finally {
      httpRequest.destroy();
    }
  }

  private static buildResponse(resp: http.HttpResponse): HttpResponse {
    const result = new HttpResponse();
    result.responseCode = resp.responseCode;

    if (typeof resp.result === 'string') {
      result.body = resp.result;
    }

    // 解析响应头（避免 Object.entries 引入 any 类型）
    if (resp.header !== undefined && resp.header !== null) {
      HttpClient.extractHeaders(resp.header, result.headers);
    }

    // 检测永久重定向
    if (resp.responseCode === 301 || resp.responseCode === 308) {
      const location = result.headers.get('location');
      if (location !== undefined) {
        result.redirectUrl = location;
      }
    }

    return result;
  }

  private static buildHeaderObject(extraHeaders: Map<string, string>): Object {
    const obj: Record<string, string> = {
      'User-Agent': HttpClient.USER_AGENT,
      'Accept-Encoding': 'gzip'
    };
    extraHeaders.forEach((value: string, key: string) => {
      obj[key] = value;
    });
    return obj;
  }

  private static buildAuthHeaderObject(
    extraHeaders: Map<string, string>,
    credentials: HttpCredentials
  ): Object {
    const authValue = 'Basic ' + buffer.from(
      credentials.username + ':' + credentials.password
    ).toString('base64');
    const authHeaders = new Map<string, string>();
    extraHeaders.forEach((value: string, key: string) => {
      authHeaders.set(key, value);
    });
    authHeaders.set('Authorization', authValue);
    return HttpClient.buildHeaderObject(authHeaders);
  }

  /**
   * 从 Object 类型的响应头中提取键值对到 Map，避免 Object.entries 引入 any。
   * 通过 JSON.stringify 序列化后用字符串解析提取。
   */
  private static extractHeaders(headerObj: Object, target: Map<string, string>): void {
    const json = JSON.stringify(headerObj);
    const len = json.length;
    if (len <= 2) {
      return;
    }
    let pos = 1;
    while (pos < len - 1) {
      // 定位 key 开始引号
      while (pos < len && json.charAt(pos) !== '"') {
        pos++;
      }
      if (pos >= len - 1) {
        break;
      }
      pos++;
      let key = '';
      while (pos < len && json.charAt(pos) !== '"') {
        key += json.charAt(pos);
        pos++;
      }
      pos++;
      // 跳过冒号和空白
      while (pos < len && (json.charAt(pos) === ':' || json.charAt(pos) === ' ')) {
        pos++;
      }
      // 读取 value
      let value = '';
      if (pos < len && json.charAt(pos) === '"') {
        pos++;
        while (pos < len && json.charAt(pos) !== '"') {
          if (json.charAt(pos) === '\\' && pos + 1 < len) {
            pos++;
            value += json.charAt(pos);
          } else {
            value += json.charAt(pos);
          }
          pos++;
        }
        pos++;
      } else {
        while (pos < len && json.charAt(pos) !== ',' && json.charAt(pos) !== '}') {
          value += json.charAt(pos);
          pos++;
        }
      }
      if (key.length > 0) {
        target.set(key.toLowerCase(), value);
      }
      // 跳过逗号
      while (pos < len && (json.charAt(pos) === ',' || json.charAt(pos) === ' ')) {
        pos++;
      }
    }
  }
}
