/**
 * 网络请求工具（ArkTS 规范）
 * 统一 baseUrl、Token 注入、401 处理、超时控制
 */
import http from '@ohos.net.http';
import { StorageUtil } from './StorageUtil';
import { ApiResult, RequestConfig } from '../types/common';

export class HttpUtil {
  private static baseUrl: string = 'http://127.0.0.1:8080';
  private static imageBaseUrl: string = 'http://127.0.0.1:9000';
  private static token: string = '';
  private static readonly DEFAULT_TIMEOUT: number = 15000;

  /**
   * 启动时读取保存的服务器配置
   */
  static async loadServerConfig(): Promise<void> {
    const savedBaseUrl = await StorageUtil.getString('server_base_url', '');
    if (savedBaseUrl) {
      HttpUtil.baseUrl = savedBaseUrl;
    }
    const savedImageBaseUrl = await StorageUtil.getString('server_image_base_url', '');
    if (savedImageBaseUrl) {
      HttpUtil.imageBaseUrl = savedImageBaseUrl;
    }
  }

  /**
   * 保存服务器配置并立即生效
   */
  static async saveServerConfig(baseUrl: string, imageBaseUrl: string): Promise<void> {
    HttpUtil.baseUrl = baseUrl;
    HttpUtil.imageBaseUrl = imageBaseUrl;
    await StorageUtil.putString('server_base_url', baseUrl);
    await StorageUtil.putString('server_image_base_url', imageBaseUrl);
  }

  static setBaseUrl(url: string): void {
    HttpUtil.baseUrl = url;
  }

  static getBaseUrl(): string {
    return HttpUtil.baseUrl;
  }

  static setImageBaseUrl(url: string): void {
    HttpUtil.imageBaseUrl = url;
  }

  static getImageBaseUrl(): string {
    return HttpUtil.imageBaseUrl;
  }

  static setToken(token: string): void {
    HttpUtil.token = token;
  }

  static getToken(): string {
    return HttpUtil.token;
  }

  static clearToken(): void {
    HttpUtil.token = '';
  }

  /**
   * 统一请求入口
   */
  static async request<T>(config: RequestConfig): Promise<ApiResult<T>> {
    const httpRequest = http.createHttp();
    try {
      const fullUrl = HttpUtil.buildFullUrl(config.url, config.params);
      const headers = HttpUtil.buildHeaders(config.headers);
      if (config.method.toUpperCase() === 'PATCH') {
        headers['X-HTTP-Method-Override'] = 'PATCH';
      }
      const options: http.HttpRequestOptions = {
        method: HttpUtil.mapMethod(config.method),
        header: headers,
        extraData: config.data,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: config.timeout ?? HttpUtil.DEFAULT_TIMEOUT,
        readTimeout: config.timeout ?? HttpUtil.DEFAULT_TIMEOUT
      };
      const response = await httpRequest.request(fullUrl, options);
      if (response.responseCode === 401) {
        HttpUtil.handleUnauthorized();
        throw new Error('登录已过期，请重新登录');
      }
      const resultStr = response.result as string;
      const result = JSON.parse(resultStr) as ApiResult<T>;
      if (result.code === 401) {
        HttpUtil.handleUnauthorized();
        throw new Error('登录已过期，请重新登录');
      }
      return result;
    } catch (error) {
      const err = error as Error;
      throw new Error(HttpUtil.getErrorMessage(err.message));
    } finally {
      httpRequest.destroy();
    }
  }

  static async get<T>(url: string, params?: Record<string, string>): Promise<ApiResult<T>> {
    const config: RequestConfig = {
      url: url,
      method: 'GET',
      params: params
    };
    return HttpUtil.request<T>(config);
  }

  static async post<T>(url: string, data?: object, params?: Record<string, string>): Promise<ApiResult<T>> {
    const config: RequestConfig = {
      url: url,
      method: 'POST',
      data: data,
      params: params
    };
    return HttpUtil.request<T>(config);
  }

  static async put<T>(url: string, data?: object): Promise<ApiResult<T>> {
    const config: RequestConfig = {
      url: url,
      method: 'PUT',
      data: data
    };
    return HttpUtil.request<T>(config);
  }

  static async patch<T>(url: string, data?: object): Promise<ApiResult<T>> {
    const config: RequestConfig = {
      url: url,
      method: 'PATCH',
      data: data
    };
    return HttpUtil.request<T>(config);
  }

  static async delete<T>(url: string, params?: Record<string, string>): Promise<ApiResult<T>> {
    const config: RequestConfig = {
      url: url,
      method: 'DELETE',
      params: params
    };
    return HttpUtil.request<T>(config);
  }

  /**
   * 处理资源 URL（图片/音频）
   * 后端返回完整地址（如 minIO）时原样使用；仅当接口返回相对路径时才拼接图片服务器地址
   */
  static processImageUrl(url: string): string {
    if (!url) {
      return '';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    const cleanPath = url.startsWith('/') ? url : '/' + url;
    return HttpUtil.imageBaseUrl + cleanPath;
  }

  private static buildFullUrl(url: string, params?: Record<string, string>): string {
    let fullUrl: string = HttpUtil.baseUrl + url;
    if (params) {
      const keys = Object.keys(params);
      if (keys.length > 0) {
        const parts: string[] = [];
        keys.forEach((key: string) => {
          const value = params[key];
          parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(value.toString()));
        });
        fullUrl = fullUrl + '?' + parts.join('&');
      }
    }
    return fullUrl;
  }

  private static buildHeaders(customHeaders?: Record<string, string>): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (customHeaders) {
      const keys = Object.keys(customHeaders);
      keys.forEach((key: string) => {
        headers[key] = customHeaders[key];
      });
    }
    if (HttpUtil.token) {
      const tokenValue = HttpUtil.token.startsWith('Bearer ') ? HttpUtil.token : 'Bearer ' + HttpUtil.token;
      headers['Authorization'] = tokenValue;
    }
    return headers;
  }

  private static mapMethod(method: string): http.RequestMethod {
    switch (method.toUpperCase()) {
      case 'GET':
        return http.RequestMethod.GET;
      case 'POST':
        return http.RequestMethod.POST;
      case 'PUT':
        return http.RequestMethod.PUT;
      case 'PATCH':
        // HarmonyOS http 不支持 PATCH，映射为 POST + 方法覆盖头
        return http.RequestMethod.POST;
      case 'DELETE':
        return http.RequestMethod.DELETE;
      default:
        return http.RequestMethod.GET;
    }
  }

  private static handleUnauthorized(): void {
    HttpUtil.clearToken();
  }

  private static getErrorMessage(message: string): string {
    if (message.includes('401') || message.includes('登录已过期')) {
      return '登录已过期，请重新登录';
    }
    if (message.includes('timeout')) {
      return '请求超时，请稍后重试';
    }
    if (message.includes('网络不可用') || message.includes('Network')) {
      return '网络连接失败，请检查网络设置';
    }
    return message;
  }
}
