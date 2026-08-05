# ShiHuaMusic-Harmony（拾华音乐 · 鸿蒙版）

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS%20NEXT-6.0.0(20)-blue.svg)](https://developer.huawei.com/consumer/cn/)
[![Language](https://img.shields.io/badge/Language-ArkTS-purple.svg)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-overview)
[![UI](https://img.shields.io/badge/UI-ArkUI-purple.svg)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

拾华音乐是一款基于 **HarmonyOS NEXT（API 20）** 原生开发的在线音乐播放应用。项目沿袭 `music-client（Vue）→ music-miniprogram（微信小程序）→ ShiHuaMusic-Harmony` 的移植路径，对接自建后端服务与 MinIO 对象存储，覆盖发现、搜索、歌单、播放、用户与系统播控的完整音乐体验。

## 功能特性

### 发现与内容
- 品牌启动页：深紫渐变 + 应用图标卡 + 动态频谱，淡出进入主界面
- 发现页：Banner、推荐歌单（两行三列，左右滑动查看更多）、猜你喜欢
- 全部音乐：热门榜单 / 新歌榜单、歌手类型与地区筛选、顶部搜索
- 歌单列表 / 歌单详情（评论、收藏）、歌手列表 / 歌手详情
- 全局搜索：歌曲、歌手、歌单模糊与精确搜索，无结果时推荐其他歌曲

### 播放体验
- 全局悬浮迷你播放器：上滑平滑收起为圆形封面 + 播放进度环，下滑恢复，同一卡片容器连续动画
- 播放页：旋转黑胶唱片、动态频谱、进度拖动、收藏、循环模式（顺序 / 随机 / 列表 / 单曲）、上一首 / 下一首、查看评论
- 播放列表管理：切换歌曲、移除单曲、一键清空
- 多播放模式、播放进度与音量设置持久化

### 系统播控（鸿蒙特色）
- 通知栏 / 播控中心常驻媒体控制：播放、暂停、上一首、下一首、**拖动进度条**、循环模式切换、收藏
- 播控状态与 App 内播放器实时双向同步
- 后台播放（`audioPlayback` 长时任务，配合 `KEEP_BACKGROUND_RUNNING` 权限）

### 用户系统
- 注册、登录、找回密码（邮箱验证码）
- 个人中心：头像选择上传（相册 + 居中裁剪）、用户名 / 邮箱 / 手机 / 个人简介编辑
- 我的喜欢、最近播放、我的歌单、歌单收藏
- 意见反馈、主题设置（白色 / 黑色全局切换，深色模式组件配色独立适配）

## 技术栈

| 分类 | 技术 |
| --- | --- |
| 语言 / UI | ArkTS（严格模式）、ArkUI 声明式 UI |
| 运行环境 | HarmonyOS NEXT，API 20（6.0.0(20)），Stage 模型 |
| 音频播放 | AVPlayer（@kit.MediaKit） |
| 系统播控 | AVSession（@kit.AVSessionKit）：通知栏、锁屏、播控中心、蓝牙控制 |
| 网络请求 | @ohos.net.http（HttpUtil 统一封装：Token 注入、401 处理、超时控制） |
| 本地存储 | @ohos.data.preferences（主题、播放状态、播放历史、Token 持久化） |
| 系统深色模式 | @ohos.display |
| 相册 / 图片 | @kit.MediaLibraryKit、@kit.ImageKit（头像选择与裁剪） |
| 文件系统 | @kit.CoreFileKit（fileIo） |
| 文件上传 | @kit.BasicServicesKit（request.uploadFile） |
| 应用框架 | @kit.AbilityKit（UIAbility）、@kit.ArkUI（router / window / prompt）、@kit.PerformanceAnalysisKit（hilog） |
| 构建工具 | hvigor（hvigorw） |

## 项目结构

```
ShiHuaMusic/
├── AppScope/                       # 应用级配置与资源（图标、应用名）
├── entry/src/main/ets/
│   ├── entryability/               # UIAbility 入口（加载启动页）
│   ├── pages/
│   │   ├── Splash/                 # 启动页
│   │   ├── MainTabs/               # 主框架：发现 / 全部音乐 / 我的
│   │   ├── Index/                  # 发现页
│   │   ├── Library/                # 全部音乐页
│   │   ├── User/                   # 我的、个人中心、找回密码、意见反馈
│   │   ├── Login/ · Register/      # 登录 / 注册
│   │   ├── Search/                 # 全局搜索
│   │   ├── MyFavorites/ · RecentPlay/ · MyPlaylists/
│   │   ├── Playlist/ · PlaylistDetail/
│   │   ├── Artist/ · ArtistDetail/
│   │   ├── PlayDetail/             # 播放页、歌曲评论
│   │   └── Rank/                   # 榜单
│   ├── components/                 # BottomPlayer 全局播放器、SongRow、Loading/Empty/Error 视图
│   ├── utils/                      # AudioManager、MediaSessionManager、HttpUtil、ThemeUtil、StorageUtil 等
│   ├── api/                        # ApiService 接口封装
│   └── types/                      # 全局类型定义
├── build-profile.json5             # SDK 版本与构建配置
├── oh-package.json5
└── hvigorfile.ts
```

## 环境要求

- DevEco Studio 6.0+
- HarmonyOS SDK 6.0.0(20)（API 20，HarmonyOS NEXT）
- Node.js 18+（hvigor 构建所需，DevEco Studio 可自动配置）
- Windows 10/11 或 macOS（开发机与真机需同一局域网）

## 快速开始

1. 使用 DevEco Studio 打开项目根目录，等待自动同步工程（运行期无第三方依赖，无需手动 `npm install`）。
2. 连接 HarmonyOS NEXT 真机或启动模拟器。
3. 点击 Run 构建并部署；后台播放能力需在真机上授权「应用在后台继续运行」。

命令行构建：

```bash
hvigorw assembleHap --mode module -p product=default --no-daemon
```

## 后端配置

- API 服务地址：`http://192.168.31.89:8080`
- 对象存储（MinIO）：`http://192.168.31.89:9000`
- 后端返回的封面 / 音频地址为完整 MinIO 地址，客户端直接使用，无需二次拼接
- 修改位置：`entry/src/main/ets/utils/HttpUtil.ets` 中的 `baseUrl` / `imageBaseUrl`

## 版本记录

- v1.0.0
  - 新增品牌启动页（动态频谱 + 淡出转场）
  - 全局迷你播放器卡片式收放动画
  - 通知栏 / 播控中心：播放控制、进度拖动、循环模式与收藏双向同步
  - 发现页、全部音乐（榜单 + 筛选）、搜索、歌单、歌手等完整内容链路
  - 用户系统（注册 / 登录 / 头像 / 资料 / 收藏 / 历史）
  - 白色 / 黑色全局主题切换
  - 应用图标更新为 cover.png

## 许可证

本项目基于 [MIT License](LICENSE) 开源。

<div align="center">

Made with ♥ by TDCQCX

</div>
