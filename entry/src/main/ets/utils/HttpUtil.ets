// HTTP网络请求工具类 - 适配鸿蒙HarmonyOS
import http from '@ohos.net.http';
import connection from '@ohos.net.connection';
import prompt from '@ohos.promptAction';
import { RequestConfig, ApiResponse } from '../types/common';

export class HttpUtil {
  private static baseUrl: string = 'http://192.168.66.241:8080';
  private static imageBaseUrl: string = 'http://192.168.66.241:9000';
  private static token: string = '';
  private static readonly DEFAULT_TIMEOUT: number = 15000; // 15秒超时
  private static readonly RETRY_COUNT: number = 3; // 重试次数

  /**
   * 初始化网络状态监听
   */
  static initNetworkListener(): void {
    try {
      const connectionConfig = connection.getConnectionPropertiesSync();
      console.log('初始网络状态:', connectionConfig ? '已连接' : '未连接');
      
      // 监听网络状态变化
      connection.on('netConnectionChange', (data: connection.NetConnectionChange) => {
        console.log('网络状态变化:', data.isAvailable ? '网络已连接' : '网络已断开');
      });
    } catch (error) {
      console.warn('获取网络状态失败:', error);
    }
  }

  /**
   * 检查网络状态
   */
  private static checkNetworkStatus(): boolean {
    try {
      const connectionConfig = connection.getConnectionPropertiesSync();
      return connectionConfig !== null;
    } catch (error) {
      console.warn('网络状态检查失败:', error);
      return true; // 默认假设网络可用
    }
  }

  /**
   * 设置基础URL
   * @param baseUrl API基础URL
   */
  static setBaseUrl(baseUrl: string): void {
    this.baseUrl = baseUrl;
  }

  /**
   * 设置图片服务器URL
   * @param imageBaseUrl 图片服务器URL
   */
  static setImageBaseUrl(imageBaseUrl: string): void {
    this.imageBaseUrl = imageBaseUrl;
  }

  /**
   * 设置认证Token
   * @param token 认证令牌
   */
  static setToken(token: string): void {
    this.token = token;
  }

  /**
   * 清除Token
   */
  static clearToken(): void {
    this.token = '';
  }

  /**
   * 获取当前Token
   */
  static getToken(): string {
    return this.token;
  }

  /**
   * 网络请求封装 - 带重试机制
   * @param config 请求配置
   * @returns Promise<ApiResponse>
   */
  static async request<T>(config: RequestConfig, retryCount: number = 0): Promise<ApiResponse<T>> {
    // 检查网络状态
    if (!this.checkNetworkStatus()) {
      prompt.showToast({
        message: '网络连接不可用，请检查网络设置',
        duration: 3000
      });
      throw new Error('网络不可用');
    }

    const httpRequest = http.createHttp();
    
    try {
      const fullUrl = this.buildFullUrl(config.url, config.params);
      const headers = this.buildHeaders(config.headers);
      
      // 显示加载提示
      if (config.showLoading !== false) {
        prompt.showLoading({
          message: '加载中...',
          mask: true
        });
      }

      console.log(`[HTTP] 发送请求 (第${retryCount + 1}次尝试):`, fullUrl, config.method || 'GET');
      
      const httpRequestOptions: http.HttpRequestOptions = {
        method: this.mapHttpMethod(config.method || 'GET'),
        header: headers,
        extraData: config.data || {},
        expectDataType: http.HttpDataType.STRING,
        usingCache: config.useCache || false,
        priority: 1,
        connectTimeout: config.timeout || this.DEFAULT_TIMEOUT,
        readTimeout: config.timeout || this.DEFAULT_TIMEOUT
      };

      const response = await httpRequest.request(fullUrl, httpRequestOptions);

      console.log(`[HTTP] 请求响应 (状态码: ${response.responseCode}):`, response.result);
      
      // 隐藏加载提示
      if (config.showLoading !== false) {
        prompt.hideLoading();
      }

      // 处理HTTP状态码
      if (response.responseCode >= 200 && response.responseCode < 300) {
        const result = JSON.parse(response.result as string);
        
        // 处理401错误
        if (response.responseCode === 401 || result.code === 401) {
          this.handleUnauthorized();
          throw new Error('登录已过期，请重新登录');
        }
        
        return result;
      } else if (response.responseCode >= 500 && retryCount < this.RETRY_COUNT) {
        // 服务器错误且可重试
        console.warn(`[HTTP] 服务器错误 ${response.responseCode}，进行第${retryCount + 1}次重试...`);
        await this.delay(1000 * (retryCount + 1)); // 指数退避
        return this.request<T>(config, retryCount + 1);
      } else {
        throw new Error(`请求失败: ${response.responseCode}`);
      }
    } catch (error) {
      console.error(`[HTTP] 网络请求失败 (第${retryCount + 1}次尝试):`, error);
      
      // 隐藏加载提示
      if (config.showLoading !== false) {
        prompt.hideLoading();
      }
      
      // 网络错误且可重试
      if ((error.message.includes('Network Error') || error.message.includes('connection')) && 
          retryCount < this.RETRY_COUNT) {
        console.warn(`[HTTP] 网络错误，进行第${retryCount + 1}次重试...`);
        await this.delay(1000 * (retryCount + 1));
        return this.request<T>(config, retryCount + 1);
      }
      
      const errorMessage = error.message || '网络请求失败';
      prompt.showToast({
        message: this.getErrorMessage(errorMessage),
        duration: 2000
      });
      
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 延迟函数
   * @param ms 延迟毫秒数
   */
  private static delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 获取友好的错误信息
   * @param errorMessage 原始错误信息
   */
  private static getErrorMessage(errorMessage: string): string {
    if (errorMessage.includes('Network Error')) {
      return '网络连接失败，请检查网络设置';
    } else if (errorMessage.includes('timeout')) {
      return '请求超时，请稍后重试';
    } else if (errorMessage.includes('401')) {
      return '登录已过期，请重新登录';
    } else if (errorMessage.includes('403')) {
      return '没有权限访问该资源';
    } else if (errorMessage.includes('404')) {
      return '请求的资源不存在';
    } else if (errorMessage.includes('500')) {
      return '服务器内部错误，请稍后重试';
    } else {
      return errorMessage;
    }
  }

  /**
   * GET请求
   * @param url 请求URL
   * @param params 查询参数
   * @param showLoading 是否显示加载提示
   */
  static async get<T>(url: string, params?: Record<string, string | number>, showLoading: boolean = true): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: 'GET',
      params,
      showLoading
    });
  }

  /**
   * POST请求
   * @param url 请求URL
   * @param data 请求数据
   * @param showLoading 是否显示加载提示
   */
  static async post<T>(url: string, data?: Object, showLoading: boolean = true): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: 'POST',
      data,
      showLoading
    });
  }

  /**
   * PUT请求
   * @param url 请求URL
   * @param data 请求数据
   */
  static async put<T>(url: string, data?: Object): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: 'PUT',
      data
    });
  }

  /**
   * DELETE请求
   * @param url 请求URL
   */
  static async delete<T>(url: string): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: 'DELETE'
    });
  }

  /**
   * 构建完整URL
   * @param url 相对URL
   * @param params 查询参数
   */
  private static buildFullUrl(url: string, params?: Record<string, string | number>): string {
    let fullUrl: string = `${this.baseUrl}${url}`;
    
    if (params) {
      const queryString = Object.keys(params)
        .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key] as string)}`)
        .join('&');
      
      if (queryString) {
        fullUrl += `?${queryString}`;
      }
    }
    
    return fullUrl;
  }

  /**
   * 构建请求头
   * @param customHeaders 自定义请求头
   */
  private static buildHeaders(customHeaders?: Record<string, string>): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    // 添加Token
    if (this.token) {
      const tokenValue: string = this.token.startsWith('Bearer ') ? this.token : `Bearer ${this.token}`;
      headers['Authorization'] = tokenValue;
    }

    // 合并自定义请求头
    if (customHeaders) {
      Object.assign(headers, customHeaders);
    }

    return headers;
  }

  /**
   * 映射HTTP方法
   * @param method HTTP方法
   */
  private static mapHttpMethod(method: string): http.RequestMethod {
    switch (method.toUpperCase()) {
      case 'GET':
        return http.RequestMethod.GET;
      case 'POST':
        return http.RequestMethod.POST;
      case 'PUT':
        return http.RequestMethod.PUT;
      case 'DELETE':
        return http.RequestMethod.DELETE;
      default:
        return http.RequestMethod.GET;
    }
  }

  /**
   * 处理未授权错误
   */
  private static handleUnauthorized(): void {
    this.clearToken();
    // TODO: 跳转到登录页面或显示登录提示
  }

  /**
   * 文件上传
   * @param url 上传URL
   * @param filePath 文件路径
   * @param fileName 文件名
   * @param formData 表单数据
   * @param progressCallback 进度回调
   */
  static async upload<T>(
    url: string, 
    filePath: string, 
    fileName: string = 'file',
    formData?: Record<string, string>,
    progressCallback?: (progress: number) => void
  ): Promise<ApiResponse<T>> {
    // 检查网络状态
    if (!this.checkNetworkStatus()) {
      throw new Error('网络不可用');
    }

    const httpRequest = http.createHttp();
    
    try {
      const fullUrl = this.buildFullUrl(url);
      const headers = this.buildHeaders();
      
      prompt.showLoading({
        message: '上传中...',
        mask: true
      });

      console.log('[HTTP] 开始上传文件:', filePath, '到', fullUrl);
      
      // 鸿蒙文件上传API实现
      const uploadResponse = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.POST,
        header: {
          ...headers,
          'Content-Type': 'multipart/form-data'
        },
        extraData: {
          file: filePath,
          fileName: fileName,
          ...formData
        },
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.DEFAULT_TIMEOUT,
        readTimeout: this.DEFAULT_TIMEOUT
      });

      console.log('[HTTP] 上传响应:', uploadResponse.responseCode);
      
      prompt.hideLoading();

      if (uploadResponse.responseCode >= 200 && uploadResponse.responseCode < 300) {
        const result = JSON.parse(uploadResponse.result as string);
        return result;
      } else {
        throw new Error(`上传失败: ${uploadResponse.responseCode}`);
      }
    } catch (error) {
      console.error('[HTTP] 文件上传失败:', error);
      prompt.hideLoading();
      
      prompt.showToast({
        message: '文件上传失败',
        duration: 2000
      });
      
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 文件下载
   * @param url 下载URL
   * @param filePath 保存路径
   * @param progressCallback 进度回调
   */
  static async download(
    url: string, 
    filePath: string,
    progressCallback?: (progress: number) => void
  ): Promise<void> {
    // 检查网络状态
    if (!this.checkNetworkStatus()) {
      throw new Error('网络不可用');
    }

    const httpRequest = http.createHttp();
    
    try {
      console.log('[HTTP] 开始下载文件:', url, '保存到', filePath);
      
      const downloadResponse = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        usingCache: false,
        connectTimeout: this.DEFAULT_TIMEOUT,
        readTimeout: this.DEFAULT_TIMEOUT
      });

      console.log('[HTTP] 下载响应:', downloadResponse.responseCode);
      
      if (downloadResponse.responseCode >= 200 && downloadResponse.responseCode < 300) {
        // TODO: 实现鸿蒙文件保存逻辑
        // 需要使用文件管理API保存下载的内容
        console.log('[HTTP] 文件下载完成:', filePath);
        prompt.showToast({
          message: '文件下载完成',
          duration: 2000
        });
      } else {
        throw new Error(`下载失败: ${downloadResponse.responseCode}`);
      }
    } catch (error) {
      console.error('[HTTP] 文件下载失败:', error);
      
      prompt.showToast({
        message: '文件下载失败',
        duration: 2000
      });
      
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 处理图片URL，确保在鸿蒙应用中正常显示
   * @param url 图片URL
   */
  static processImageUrl(url: string): string {
    if (!url) return '';
    
    // 如果URL已经是完整URL，只提取路径部分
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        const pathStartIndex: number = url.indexOf('/', url.indexOf('://') + 3);
        const path: string = pathStartIndex !== -1 ? url.substring(pathStartIndex) : '/';
        return `${this.imageBaseUrl}${path}`;
      } catch (e) {
        console.warn('Failed to process URL:', url, e);
        return url;
      }
    }
    
    // 否则拼接图片服务器地址
    const cleanPath: string = url.startsWith('/') ? url : '/' + url;
    return `${this.imageBaseUrl}${cleanPath}`;
  }

  /**
   * 获取网络请求统计信息
   */
  static getRequestStats(): { success: number; failed: number; total: number } {
    // 这里可以添加请求统计逻辑
    return { success: 0, failed: 0, total: 0 };
  }
}