# ShiHuaMusic-Harmony

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-4.0-green.svg)](https://www.harmonyos.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

ShiHuaMusic是一个优雅的多平台音乐播放器应用，支持HarmonyOS原生应用版本，提供流畅的音乐播放体验。

## ✨ 项目亮点

- 🎵 **跨平台支持** - 同时提供HarmonyOS原生应用=
- 🎨 **精美UI设计** - 支持浅色/深色/自动主题切换
- 🔊 **完整音频功能** - 播放、暂停、切换、进度控制、音量调节
- 👤 **用户系统** - 完整的登录注册功能，支持游客模式
- 📱 **响应式设计** - 适配各种屏幕尺寸和设备
- ⚡ **高性能** - 优化的音频播放和本地存储管理

## 📱 功能特性

### 核心播放功能
- 本地音乐文件播放
- 播放控制（播放、暂停、上一首、下一首）
- 多种播放模式（顺序、循环、单曲、随机）
- 进度条拖拽控制
- 音量调节
- 播放列表管理

### 用户体验
- 优雅的界面设计
- 主题切换（浅色/深色/AUTO）
- 流畅的动画效果
- 智能加载提示
- 错误处理和用户友好提示

### 数据管理
- 用户信息本地存储
- 播放历史记录
- 收藏列表管理
- 播放进度恢复
- 设置配置保存

## 🏗️ 项目结构

```
ShiHuaMusic/
├── 📁 entry/                     # HarmonyOS原生应用
│   ├── src/main/ets/
│   │   ├── pages/               # 页面文件
│   │   │   ├── Index/           # 首页
│   │   │   ├── User/            # 用户页面
│   │   │   ├── Login/           # 登录页面
│   │   │   ├── Register/        # 注册页面
│   │   │   └── ...
│   │   ├── utils/               # 工具类
│   │   │   ├── AudioManager.ets # 音频管理器
│   │   │   ├── ThemeUtil.ets    # 主题工具
│   │   │   ├── HttpUtil.ets     # 网络请求
│   │   │   ├── GlobalDataManager.ets # 全局数据管理
│   │   │   └── ...
│   │   └── types/               # 类型定义
│   └── oh-package.json5         # 依赖配置
├── AppScope/                    # 应用作用域配置
├── hvigor/                      # 构建配置
└── README.md                    # 项目说明
```

## 🚀 快速开始

### 开发环境要求

#### HarmonyOS版本
- DevEco Studio 6.0.0.868+
- HarmonyOS SDK 4.0+
- Node.js 18.0+
- Windows 11 (推荐)



### HarmonyOS应用开发

1. 使用DevEco Studio打开 `entry/` 文件夹
2. 连接HarmonyOS设备或启动模拟器
3. 点击运行按钮构建和部署

```bash
# 安装依赖（如果需要）
cd entry
npm install

# 构建项目
hvigor assembleHap
```


## 📖 使用指南

### HarmonyOS版本
1. 应用启动后会自动初始化主题和用户状态
2. 首页显示音乐列表，点击即可播放
3. 用户页面提供登录注册和个人设置功能
4. 支持主题切换和播放设置

## 🛠️ 技术栈

### HarmonyOS技术
- **开发语言**: ArkTS
- **UI框架**: ArkUI
- **网络请求**: @ohos.net.http
- **本地存储**: @ohos.data.preferences
- **媒体播放**: @ohos.media
- **网络状态**: @ohos.net.connection


### 共同特性
- 模块化架构设计
- TypeScript类型安全
- 响应式状态管理
- 主题系统统一
- 本地数据持久化

## 🔧 配置说明

### API配置
在工具类中修改默认服务器地址：
- 开发环境：`http://192.168.66.241:8080`
- 生产环境：需要配置实际的API地址

### 主题配置
主题配置文件位置：
- HarmonyOS: `src/main/ets/utils/ThemeUtil.ets`
- 支持自定义颜色、字体、间距等主题参数

## 📝 开发日志

- [v1.0.0] 初始版本发布
- 支持HarmonyOS原生应用和小程序双平台
- 实现完整音频播放功能
- 添加用户认证系统
- 支持主题切换
- 优化用户体验和性能


## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源协议，详情请查看许可证文件。


<div align="center">

**如果这个项目对你有帮助，请给我们一个 ⭐ Star！**

Made with ❤️ by TDCQCX

</div>