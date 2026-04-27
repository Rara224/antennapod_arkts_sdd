import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'FileUtils';

export class FileUtils {
  static async readText(path: string): Promise<string> {
    const content = await fileIo.readText(path);
    return content;
  }

  static async writeText(path: string, content: string): Promise<void> {
    const file = await fileIo.open(path,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    try {
      await fileIo.write(file.fd, content);
    } finally {
      await fileIo.close(file);
    }
  }

  static async copyFile(srcPath: string, dstPath: string): Promise<void> {
    await fileIo.copyFile(srcPath, dstPath);
  }

  static async deleteFile(path: string): Promise<void> {
    try {
      await fileIo.unlink(path);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'deleteFile failed for %{public}s: %{public}s', path, JSON.stringify(e));
    }
  }

  static async deleteDirectory(dirPath: string): Promise<void> {
    try {
      const files = await fileIo.listFile(dirPath);
      for (let i = 0; i < files.length; i++) {
        const childPath = dirPath + '/' + files[i];
        const stat = await fileIo.stat(childPath);
        if (stat.isDirectory()) {
          await FileUtils.deleteDirectory(childPath);
        } else {
          await fileIo.unlink(childPath);
        }
      }
      await fileIo.rmdir(dirPath);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'deleteDirectory failed for %{public}s: %{public}s', dirPath, JSON.stringify(e));
    }
  }

  static async exists(path: string): Promise<boolean> {
    try {
      await fileIo.access(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  static async fileSize(path: string): Promise<number> {
    try {
      const stat = await fileIo.stat(path);
      return stat.size;
    } catch (e) {
      return 0;
    }
  }

  static getExtension(fileName: string): string {
    const dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex === fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1);
  }

  static getFileName(path: string): string {
    const slashIndex = path.lastIndexOf('/');
    if (slashIndex < 0) {
      return path;
    }
    return path.substring(slashIndex + 1);
  }

  static buildPath(parent: string, child: string): string {
    if (parent.endsWith('/')) {
      return parent + child;
    }
    return parent + '/' + child;
  }

  static async ensureDirectory(dirPath: string): Promise<void> {
    const dirExists = await FileUtils.exists(dirPath);
    if (!dirExists) {
      await fileIo.mkdir(dirPath);
    }
  }
}
