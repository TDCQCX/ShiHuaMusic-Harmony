# ShiHuaMusic 鸿蒙端移植计划（v2）

> **实施进度（2026-08-04 更新）**
>
> 已按本计划完成 **阶段 0、阶段 1、阶段 2**，工程已通过 `hvigor assembleHap` 构建（0 错误，告警仅剩集中于 NavUtil 的 4 条 router 弃用提示）。
>
> **联调修复（2026-08-04）**
> - 接口 timeout 根因：鸿蒙端硬编码 `192.168.66.241:8080` 不可达，后端实际监听 `127.0.0.1:8080`（与 music-client 默认一致）
> - 修复：默认 API 地址改为 `http://127.0.0.1:8080`；新增服务器设置页（用户中心入口，未登录可用），支持预览器/模拟器/局域网预设 + 自定义，保存即生效并持久化
> - 资源地址策略：后端返回的 minIO 图片/音频地址**原样使用**，不做 host 替换；`processImageUrl` 仅对相对路径兜底拼接
> - UI 对齐 music-client：首页推荐改双列网格 + 封面悬浮播放按钮 + 卡片阴影；全屏播放页模糊封面背景；歌曲行显示"歌手 · 专辑"；歌单卡片悬浮播放按钮；底部播放器封面圆角/阴影/大按钮
>
> **交互重构（2026-08-04）**
> - **导航架构**：三主 Tab 重构为 Tabs 主框架（`MainTabs`，滑动切换、bar 状态同步、不再新建页面覆盖）；`TabManager` 全局切 Tab；全局播放器常驻 Tabs 之外
> - 首页：推荐歌单改**两行三列横向滑动**；相似推荐改名**猜你喜欢**，一行一首、限 10 首、播放键右侧
> - 我的：顶部用户信息栏（未登录/已登录头像用户名邮箱 + 个人中心入口），下方功能列表（最近播放/我的歌单/我的喜欢需登录跳转）
> - 登录：修复 token 时序 bug（登录成功先注入请求头再取用户信息，消除"登录已过期"误报）；错误信息移至账户输入框上方；成功居中弹窗并跳"我的"欢迎
> - 注册：靠上布局对齐登录页；新增密码二次确认比对；错误显示在对应输入框下方；验证码倒计时红色强化；成功提示后自动跳登录
> - 播放器：图标全面换系统符号（play/pause/prev/next/heart/playlist/shuffle/repeat）；播放列表 sheet 布局修复（清空与关闭分离）
> - 播放页：纯白背景（移除封面模糊背景）；上一首/下一首换符号；移除右上角无用按钮与底部播放器
>
> **交互修复与 UI 精修（2026-08-04）**
> - **切歌 bug 修复**：AVPlayer 状态机竞态（stop/setMediaSource/prepare 未等待状态完成导致播放旧曲），新增 `waitForState` 严格等待 stopped/prepared 后再播放
> - **播放器悬浮**：全局播放器改为悬浮于底部 bar 上方（Stack 布局 + bottom 64），圆角 16 卡片 + 左右间距
> - 发现页：推荐歌单/猜你喜欢改为圆角卡片区（两侧留白），歌单取消悬浮播放按钮；收藏 icon 换系统符号 heart（修复 SVG 菱形显示问题）
> - 全部音乐：去除列表底部大空白
> - 我的：整体上移贴顶；主题切换通过 `themeVersion`（AppStorage）全局实时刷新（面板、各 Tab 即时生效）
> - **全局转场**：所有二级页面统一 `pageTransition`（淡入 + 上滑），不再右滑覆盖
> - 播放页：无标题栏（左上悬浮返回 + 顶部居中歌名）；最左循环模式切换（顺序/随机/列表/单曲四种图标）、最右爱心收藏；歌曲信息移至进度条上方
>
> **回归修复（2026-08-05）**
> - **切歌 bug 根治**：不再复用 AVPlayer 状态机，切歌时 `release()` 旧实例并创建全新 AVPlayer 再 setMediaSource/prepare/play，彻底消除状态残留导致"界面已切、声音未切"
> - **播放器悬浮修复**：主框架改用 `Stack({ alignContent: Alignment.Bottom })`，Tabs 占满全屏、播放器底部对齐（bar 上方 66vp、宽 92% 居中）
> - **首次进入空白**：EntryAbility 先 `await` 完成服务器配置/会话/播放器恢复，再 loadContent 加载首页
> - **主题设置**：改为居中弹窗卡片（白色/黑色两种），切换后所有界面（背景/卡片/组件）经 ThemeUtil 监听即时刷新；修复深色下播放页黑胶盘与背景融为一体的问题
> - **全局转场**：MainTabs 补充 pageTransition，push 时旧界面淡出、返回时淡入，不再右滑
>
> **已完成（阶段 0-2）**
> - 数据模型：`types/common.ets` 按 music-client 接口契约重建（Song/PlaylistDetail/Comment/SongDetail/Artist/PageData 等）
> - API 层：`api/ApiService.ets` 实现全部 30 个接口；`HttpUtil` 统一 Token/401/超时，PATCH 映射为 POST + 覆盖头
> - 播放引擎：`AudioManager` 迁移至新版 AVPlayer，支持 4 播放模式、音量、音质、播放列表、事件系统、**状态持久化恢复**
> - 全局状态：`GlobalDataManager`（用户会话/最近播放持久化）、`AppContext`（替代弃用的 getContext）、`StorageUtil`/`ThemeUtil` 重写
> - 导航：`NavUtil` 统一封装（router 弃用集中在单文件，后续可整体切 Navigation）
> - **后台播放**：`MediaSessionManager`（avSession 媒体会话：通知栏/锁屏控制、播放/暂停/上下曲命令回调），module.json5 配置 backgroundModes + KEEP_BACKGROUND_RUNNING
> - **播放列表**：BottomPlayer 播放列表半模态（bindSheet：高亮当前/点击播放/删除/清空）
> - **全屏播放页**：黑胶唱片旋转动画（播放旋转/暂停停止）+ 歌曲信息 + 评论
> - **头像上传**：PhotoViewPicker 选图 → PixelMap 居中裁剪 → @ohos.request 上传 → 重新拉取用户信息
> - **意见反馈**：FeedbackPage（10-200 字校验）
> - **主题设置**：用户中心主题面板（浅色/深色/自动 + 6 种主题色，即时生效并持久化）
> - 页面：15 个页面全部重写/新增并注册（首页、曲库、登录/注册/重置密码、用户中心/编辑、歌单详情、我的喜欢、最近播放、歌单列表、搜索、歌手列表/详情、全屏播放页）
> - 组件：BottomNavigation、BottomPlayer（进度拖拽/喜欢/播放模式）、SongRow、Loading/Empty 视图
> - 权限：module.json5 补充 `ohos.permission.INTERNET`、`ohos.permission.KEEP_BACKGROUND_RUNNING`、ability backgroundModes
>
> **待办（下一轮）**
> - 阶段 4：Navigation 导航迁移（消除 NavUtil 中的 router 弃用告警）、LazyForEach 长列表、三态页统一（ErrorView 接入）、安全区适配、多屏布局校验

> 编制时间：2026-08-04
> 开发路径：**music-client（PC Vue 完整版）→ music-miniprogram（微信小程序版）→ ShiHuaMusic（鸿蒙原生版）**
> 蓝本职责：**music-client = 功能蓝本（所有功能以它为准）；music-miniprogram = 移动端交互蓝本（Tab 导航、底部播放器、移动页面逻辑）**

## 0. 总体目标与原则

### 目标

鸿蒙端在**功能上完整覆盖 music-client（PC 版全部功能）**，在**交互上遵循小程序版（移动端）的习惯**（底部三 Tab + 底部迷你播放器 + 二级页面栈），UI 全部采用 **ArkUI 原生组件与 HarmonyOS 设计规范**实现，不引入 WebView，不做“照搬”式移植。

### 移植原则

1. **功能以 music-client 为准**：PC 版有的功能（歌手、评论、反馈、下载、重置密码、全屏播放、音质、播放列表、收藏歌单、分页搜索等）鸿蒙端必须齐全，按移动端形态重新组织。
2. **交互以 music-miniprogram 为准**：三 Tab 结构（发现/全部音乐/个人主页）、底部迷你播放器常驻、页面跳转栈、登录拦截等移动端习惯保持一致。
3. **接口以 music-client 后端契约为准**：`music-client/src/api/system.ts` 是唯一接口清单，鸿蒙端逐一实现。
4. **数据模型统一**：以 music-client 接口类型（`Song`、`PlaylistDetail`、`Comment`、`SongDetail`、`Artist`、`Result`/`ResultTable`）为准，在鸿蒙端统一建模与映射。
5. **UI 原生化**：所有页面用 ArkUI 原生组件（Navigation/Tabs/List/Grid/Swiper/Slider/Refresh/bindSheet/CustomDialog 等）实现，适配深色模式、安全区、多屏尺寸、系统字体。
6. **分阶段交付**：基础设施 → 播放引擎 → 用户体系 → 内容浏览 → UI 打磨，每阶段可构建、可验收。

---

## 1. music-client 功能全景（蓝本功能清单）

### 1.1 全局框架（PC 端）

| 区域 | 功能 |
| --- | --- |
| Header | Logo、全局搜索（回车进曲库搜索）、深色模式切换、用户下拉（个人中心/意见反馈/退出） |
| Aside 侧边栏 | 菜单：推荐 / 曲库 / 歌手 / 歌单 / 喜欢 / 个人中心；登录后展示“收藏的歌单”列表 |
| Main 内容区 | 路由页面（keep-alive 缓存） |
| Footer 播放器 | 左侧：封面+歌曲名+歌手（点击开全屏播放页）；中间：上一首/播放暂停/下一首/喜欢 + 进度条；右侧：播放模式、音量、播放列表、最近播放 |
| DrawerMusic 全屏播放 | 大封面 + 黑胶唱片旋转动画、歌曲信息、进度/控制/播放模式、歌曲详情（专辑/发行时间）、歌曲评论区 |

### 1.2 页面功能

| 路由 | 功能 |
| --- | --- |
| `/` 推荐首页 | Banner 轮播（4s）、推荐歌单（网格）、相似推荐歌曲（网格+播放+刷新）；**登录后重新拉取推荐（个性化）** |
| `/library` 曲库 | 歌曲 Table（标题/歌手/专辑/喜欢/时长/下载）、分页（20/30/50）、`?query=` 全局搜索入口 |
| `/artist` 歌手 | 左侧分类：歌手类型（男/女/组合/乐队）、地区（中国/美国/韩国/日本/其他）、搜索、圆形头像网格、分页 |
| `/artist/:id` 歌手详情 | 头像、姓名、生日、地区、简介、该歌手全部歌曲 Table（可播放/喜欢） |
| `/playlist` 歌单 | 搜索、17 种风格标签筛选、Tab（精选歌单/我的收藏）、网格、分页 |
| `/playlist/:id` 歌单详情 | 封面/标题/描述/创建者/歌曲数、收藏/取消收藏、Tab（歌曲/评论）、播放全部、评论发布/点赞/删除 |
| `/like` 我的喜欢 | 封面（取第一首）、播放全部、搜索、Table 列表、分页 |
| `/user` 个人中心 | 头像（点击选图→vue-cropper 圆形裁剪→上传）、用户名/邮箱/电话/简介表单、更新信息、注销账号（二次确认） |

### 1.3 认证与用户

- 三合一对话框：登录 / 注册 / 重置密码（Tab 切换）。
- 登录：邮箱+密码；校验（邮箱格式、密码 8-18 位数字/字母/符号任两种组合）；成功后拉取用户信息。
- 注册：用户名（4-16 位字母数字下划线连字符）、邮箱、验证码（6 位，60s 倒计时）、密码。
- 重置密码：邮箱+验证码+新密码+确认密码（两次一致）。
- 退出登录：调 `/user/logout`，清理本地状态并清空所有歌曲 likeStatus。
- 路由守卫：未登录访问“喜欢/个人中心”弹出登录。
- 意见反馈：10-200 字提交。

### 1.4 播放器内核

- 全局播放列表 `trackList` + 当前索引 `currentSongIndex`；去重添加（addTracks）。
- 播放模式 4 种：顺序 order / 随机 shuffle / 列表循环 loop / 单曲循环 single，切换有提示。
- 音量（0-100，持久化）；音质 quality（默认 exhigh，经 `song/url/v1` 换取播放地址）。
- 进度 seek、播放结束自动下一首（按模式）。
- 歌曲喜欢/取消喜欢：全局同步 likeStatus（播放列表、当前页、曲库、歌手详情、歌单详情）。
- 下载歌曲（audioUrl 保存）。
- 播放列表弹窗：当前高亮、点击播放、删除单曲、清空。
- 全屏播放页：黑胶旋转动画（播放旋转/暂停停止）、歌曲信息、歌曲详情与评论。

### 1.5 接口清单（music-client `api/system.ts`）

| 模块 | 接口 |
| --- | --- |
| 用户 | `POST /user/login`、`POST /user/logout`、`GET /user/sendVerificationCode?email=`、`POST /user/register`、`PATCH /user/resetUserPassword`、`GET /user/getUserInfo`、`PUT /user/updateUserInfo`、`PATCH /user/updateUserAvatar`(multipart)、`DELETE /user/deleteAccount` |
| 内容 | `GET /banner/getBannerList`、`GET /playlist/getRecommendedPlaylists`、`GET /song/getRecommendedSongs`、`POST /song/getAllSongs`、`GET /song/getSongDetail/{id}`、`POST /artist/getAllArtists`、`GET /artist/getArtistDetail/{id}`、`POST /playlist/getAllPlaylists`、`GET /playlist/getPlaylistDetail/{id}` |
| 收藏 | `POST /favorite/getFavoriteSongs`、`POST /favorite/collectSong`、`DELETE /favorite/cancelCollectSong`、`POST /favorite/getFavoritePlaylists`、`POST /favorite/collectPlaylist`、`DELETE /favorite/cancelCollectPlaylist` |
| 评论 | `POST /comment/addSongComment`、`POST /comment/addPlaylistComment`、`PATCH /comment/likeComment/{id}`、`PATCH /comment/cancelLikeComment/{id}`、`DELETE /comment/deleteComment/{id}` |
| 反馈 | `POST /feedback/addFeedback`（params: content） |
| 播放 | `GET song/url/v1?id=&level=`（取播放地址，音质参数） |
| 歌词 | `lyric` / `lyric/new`（client 中为注释预留，歌词解析工具已写，鸿蒙端按预留实现） |

---

## 2. 鸿蒙端现状对照矩阵

| 功能域 | music-client | 小程序 | 鸿蒙端现状 | 行动 |
| --- | --- | --- | --- | --- |
| 底部三 Tab 导航 | 侧边栏菜单 | tabBar（发现/全部音乐/个人主页） | BottomNavigation 已有，仅首页挂载 | 统一挂载三个主 Tab 页 |
| 发现首页 | Banner+推荐歌单+推荐歌曲+登录重拉 | 同左（无登录重拉） | 页面已有，接口路径不符、跳转 TODO、无下拉刷新 | 修正接口、接通跳转、加 Refresh |
| 全部音乐/曲库 | 分页+搜索+下载+喜欢 | 20 条触底追加 | 列表+触底逻辑已写；回顶/分享/提示 TODO | 改分页接口、接通回顶、加下载/喜欢 |
| 歌手列表/详情 | 分类筛选+搜索+分页+详情 | 无 | **缺失** | 新增两个页面 |
| 歌单列表 | 搜索+风格筛选+精选/收藏 Tab+分页 | 我的歌单（推荐接口模拟） | MyPlaylists 已有（模拟数据） | 按 client 改造：风格筛选、收藏 Tab、真实接口 |
| 歌单详情 | 收藏+歌曲/评论 Tab+播放全部+评论互动 | 歌曲/评论（评论模拟） | 已有页面；无评论 Tab；播放未接；详情为模拟 | 接真实接口、补评论 Tab、接通播放 |
| 我的喜欢 | 分页+搜索+播放全部+取消收藏 | 模拟列表 | MyFavorites 已有（模拟） | 接 `/favorite/getFavoriteSongs`，分页+搜索 |
| 最近播放 | 播放列表（非独立页） | 独立页（模拟） | RecentPlay 已有（模拟+清空） | 接本地播放历史持久化 |
| 登录 | 邮箱+密码+守卫 | 邮箱+密码 | 页面已有；API 为模拟 | 接真实接口、校验对齐 |
| 注册 | 用户名+邮箱+验证码+密码 | 同左 | 页面已有；API 为模拟、校验不同 | 接真实接口、校验对齐 |
| 重置密码 | 邮箱+验证码+新密码+确认 | 入口存在但页面缺失 | **缺失** | 新增页面（独立页或对话框） |
| 个人中心 | 头像裁剪上传+资料+注销 | 头像直接上传+资料+注销 | 已有页面；头像/保存/删除为模拟 | 接 PhotoViewPicker+裁剪+真实接口 |
| 意见反馈 | 反馈对话框 | 无 | **缺失** | 新增 |
| 迷你播放器 | Footer 播放器 | player 组件 | BottomPlayer 已有；进度拖拽/列表/详情 TODO | 补齐进度/列表/全屏播放页 |
| 全屏播放页 | DrawerMusic（黑胶+歌曲信息+评论） | 无 | **缺失** | 新增（鸿蒙特色：bindSheet 或独立页） |
| 播放列表管理 | 弹窗（高亮/播放/删除/清空） | 无 | **缺失** | 新增 bindSheet 半模态 |
| 播放模式 | 顺序/随机/循环/单曲（4 种） | 列表循环/单曲/随机 | AudioManager 支持 4 模式 | 与 UI 联动 |
| 音质选择 | quality + `song/url/v1` | 无 | **缺失** | 新增（默认 exhigh） |
| 下载 | audioUrl 下载 | 无 | HttpUtil.download TODO | 用 @ohos.request.downloadFile 实现 |
| 歌曲/歌单评论 | 发布/点赞/删除（真实接口） | 本地模拟 | 无评论模块 | 新增评论组件与页面 |
| 收藏歌单 | 侧边栏+歌单页收藏 Tab | 无 | 仅详情页本地收藏切换 | 接收藏接口+收藏列表 |
| 搜索 | 全局搜索→曲库；歌单/歌手搜索 | 占位 | SearchPage UI 完整（模拟数据） | 接真实搜索（曲库/歌手/歌单） |
| 后台播放 | Web 无此概念 | requiredBackgroundModes audio | 无 | avSession+后台任务 |
| 主题 | 深色+主题色 primary（#7E22CE） | 无深色 | ThemeUtil 浅/深/自动已有 | 支持主题色自定义 |

---

## 3. 鸿蒙原生 UI 组件选型与设计原则

### 3.1 组件映射（PC/小程序能力 → ArkUI 原生组件）

| 能力 | 原实现 | ArkUI 原生实现 |
| --- | --- | --- |
| 页面导航 | vue-router / wx.navigateTo | `Navigation` + `NavPathStack`（推荐，鸿蒙特色）+ 页面注册；或统一 `router.pushUrl`。首页三 Tab 用 `Tabs`+`TabContent`（barPosition End）或现有 BottomNavigation |
| 列表 | el-table / wx scroll-view | `List` + `ListItem` + **`LazyForEach`**（长列表） |
| 网格 | Tailwind grid | `Grid` + `GridItem`（推荐歌单、歌手头像、歌单卡片） |
| 轮播 | el-carousel / swiper | `Swiper`（autoplay、circular、indicator、interval 4000） |
| 进度条/音量 | el-slider | `Slider`（onChange 拖动预览 / onChangeEnd 提交 seek） |
| 下拉刷新 | 无 / onPullDownRefresh | `Refresh` 组件（onRefreshing） |
| 触底分页 | 分页器 / onReachBottom | `List.onReachEnd` + 加载更多 |
| 半模态弹层 | el-drawer / el-popover | `bindSheet`（播放列表、全屏播放、最近播放） |
| 对话框 | el-dialog / wx.showModal | `CustomDialogController`（确认、反馈、登录、裁剪） |
| 操作菜单 | el-dropdown / wx.showActionSheet | 自封装 ActionSheet（基于 bindSheet） |
| 提示 | ElMessage / wx.showToast | `promptAction.showToast` / 自封装 Toast |
| 表单 | el-form | `TextInput`（Normal/Email/Password/PhoneNumber）+ 校验工具 |
| 头像选择 | input[type=file] / wx.chooseMedia | `@ohos.file.picker`（PhotoViewPicker） |
| 头像裁剪 | vue-cropper | 选择后经 `PixelMap`/`@ohos.multimedia.image` 裁剪 + 圆形遮罩 UI |
| 文件上传 | axios FormData / wx.uploadFile | `@ohos.request`（uploadFile，multipart，字段名 avatar） |
| 文件下载 | a[download] | `@ohos.request.downloadFile` + `@ohos.file.fs` 保存 |
| 音频播放 | HTMLAudio / InnerAudioContext | `@ohos.multimedia.media` AudioPlayer（已有） |
| 后台播放 | — / requiredBackgroundModes | `@ohos.multimedia.avsession`（媒体会话+通知控制+音频焦点）+ 后台任务 |
| 本地存储 | localStorage / wx.setStorageSync | `@ohos.data.preferences`（已有 StorageUtil/PreferencesUtil） |
| 深色模式 | useDark（class） | `@ohos.display` + ThemeUtil（已有），支持跟随系统 |
| 分享 | — / wx.onShareAppMessage | 鸿蒙系统分享（ShareKit）或暂缓 |
| 状态管理 | Pinia | 单例 GlobalDataManager + AppStorage/@StorageLink（页面间共享播放状态） |

### 3.2 设计原则（鸿蒙化）

- **单位**：全部使用 vp；间距/圆角/字号走 ThemeUtil token；rpx 不做换算硬编码。
- **布局**：Column/Row/Stack/RelativeContainer；长页面 Scroll/List；卡片用 surface + 圆角 + 阴影。
- **安全区**：顶部状态栏沉浸、底部手势条避让（expandSafeArea）；列表底部预留播放器高度。
- **主题**：浅色/深色/自动 + 可配置主题色（对齐 client 的 primary，默认可取 `#7E22CE`）。
- **动效**：页面转场、按钮按压态、Swiper 切换、黑胶唱片旋转（组动画+播放/暂停联动）。
- **触控**：点按热区 ≥44vp；列表行 56-72vp；支持返回手势。
- **状态页**：加载中/加载失败重试/空数据三态统一组件。
- **字体**：系统字体（HarmonyOS Sans），适配字体缩放不截断。

---

## 4. 分阶段实施计划

### 阶段 0：基础设施（约 1 周）

**目的**：统一工程骨架，让后续所有页面按同一套模式开发。

1. **路由与页面注册**
   - `main_pages.json` 补全全部页面：歌手列表、歌手详情、歌单列表、歌单详情、搜索、我的喜欢、最近播放、重置密码、全屏播放页等。
   - 所有页面组件补 `@Entry`；统一导航方案（推荐 `Navigation` + `NavPathStack`，与三 Tab 共存）。
2. **API 层（以 music-client `api/system.ts` 为唯一契约）**
   - 新增 `ets/api/ApiService.ets`，逐一实现 20+ 接口（get/post/put/patch/delete/upload/download）。
   - 统一 baseUrl（开发 `192.168.66.241:8080`、图片 `:9000`，可配置）；统一 Token 注入、401 处理、超时重试。
3. **数据模型与映射**
   - `common.ets` 按 client 接口类型重建：`Song`、`PlaylistSong`、`PlaylistDetail`、`Comment`、`SongDetail`、`Artist`、`ArtistDetail`、`UserInfo`、`Result`、`ResultTable`、`trackModel`。
   - 新增 `DataMapper.ets`：client 字段（`songId/songName/artistName/coverUrl/audioUrl/duration(秒)`）→ trackModel 转换，与客户端播放器解耦。
4. **全局状态（GlobalDataManager 补齐，对齐 Pinia stores）**
   - 播放：`trackList`、`currentSongIndex`、`volume`、`quality`、`currentPageSongs`。
   - 用户：`userInfo`、`token`、`isLoggedIn`（已有）；登录后拉取收藏歌单列表。
   - 播放历史：`recentPlayHistory`（上限 100，Preferences 持久化）。
5. **通用组件**
   - `LoadingView`、`EmptyView`、`ErrorView`（重试）、`ConfirmDialog`、`ActionSheet`、`Toast`、`FeedbackDialog`、`CommentSection`、`SongRow`（歌曲行：封面/歌名/歌手/喜欢/时长/更多，供曲库/歌单/歌手/喜欢复用）。
6. **主题**：ThemeUtil 增加主题色配置（primary 可换），深色 token 全面走查。

### 阶段 1：播放引擎与播放体验（约 1.5 周）

**目的**：建立“点歌 → 播放 → 全局联动 → 后台播放”完整闭环，这是音乐 App 主干。

1. **AudioManager 升级（对齐 useAudioPlayer + AudioStore）**
   - 播放列表：`setTrackList/addTracks(去重)/deleteTrack/clear`、当前索引。
   - 播放模式 4 种：顺序/随机/列表循环/单曲循环；切歌/结束行为按模式（含单曲循环从头播）。
   - 音量 0-100 持久化；音质 quality（默认 exhigh），URL 为空时经 `song/url/v1?id=&level=` 换取。
   - 进度事件、状态事件、歌曲切换事件（已有，保持）。
2. **底部迷你播放器（BottomPlayer 完善）**
   - 封面+歌名+歌手；播放/暂停、上一首、下一首；喜欢按钮（全局 likeStatus 联动）；播放模式切换（4 种图标）；进度条拖拽（Slider onChange/onChangeEnd）；点击打开全屏播放页；播放列表入口。
   - 三个主 Tab 页 + 二级页面统一挂载。
3. **播放列表（新）**
   - `bindSheet` 半模态：当前高亮、点击切换播放、删除单曲、清空列表；对应 client 的 recently/popover。
4. **全屏播放页（新，鸿蒙特色页）**
   - 大封面 + 黑胶唱片旋转动画（播放时旋转、暂停停止，rotate 动画）。
   - 歌曲信息、进度条、控制按钮、播放模式、播放列表入口。
   - 歌曲详情区：专辑、发行时间（`/song/getSongDetail/{id}`）。
   - 歌曲评论区：发布/点赞/删除（真实接口，登录校验）。
5. **喜欢联动**
   - 收藏/取消收藏歌曲（`/favorite/collectSong`、`/favorite/cancelCollectSong`），成功后同步所有页面的 likeStatus（播放列表、当前页面歌曲、曲库、歌手详情、歌单详情）。
6. **后台播放**
   - `@ohos.multimedia.avsession` 创建媒体会话：通知栏显示封面/标题/控制按钮；音频焦点处理；后台任务保活；来电暂停等系统事件。
7. **最近播放**
   - 每次播放写入本地历史（去重、上限 100），提供最近播放页与清空。

### 阶段 2：用户体系与个人中心（约 1.5 周）

**目的**：认证三合一 + 个人中心全链路真实可用。

1. **登录 / 注册 / 重置密码（三合一，对齐 AuthTabs）**
   - 登录：`/user/login` → 保存 token → `/user/getUserInfo`；校验规则与 client 一致；已登录自动跳转；登录/注册页暂停播放（小程序习惯）。
   - 注册：`/user/register` + `/user/sendVerificationCode`（60s 倒计时）；用户名 4-16、验证码 6 位、密码 8-18 两种组合。
   - 重置密码：`/user/resetUserPassword`（PATCH），邮箱+验证码+新密码+确认密码。
   - 形态：移动端建议独立页面或全屏对话框（小程序习惯是独立页）。
2. **登录守卫**
   - 未登录访问“我的喜欢/个人中心/收藏的歌单”时弹登录（对齐 client 的 AuthGuard + 小程序弹窗习惯）。
3. **个人中心**
   - 资料展示：头像/用户名/邮箱/电话/简介。
   - 头像更新：PhotoViewPicker 选图 → 圆形裁剪（PixelMap 处理）→ `/user/updateUserAvatar`（multipart，字段 avatar）→ 重新拉取用户信息。
   - 资料更新：`/user/updateUserInfo`（PUT）。
   - 注销账号：`/user/deleteAccount`（DELETE），二次确认（自定义 Dialog），注销后清理本地并回首页。
4. **意见反馈（新）**
   - 反馈对话框：内容 10-200 字，`/feedback/addFeedback`（params）。
5. **退出登录**
   - `/user/logout` → 清理本地用户/Token → 清空所有歌曲 likeStatus → 刷新页面状态。

### 阶段 3：内容浏览与互动（约 2 周）

**目的**：所有内容页面功能齐全、数据真实。

1. **发现首页**
   - `/banner/getBannerList`（Swiper autoplay 4s + circular）；`/playlist/getRecommendedPlaylists`（Grid 网格）；`/song/getRecommendedSongs`（列表）；登录后重新拉取（个性化推荐行为对齐 client）。
   - 下拉刷新（Refresh）；“更多”进歌单/曲库；卡片点击跳歌单详情；歌曲点击播放。
2. **全部音乐（曲库）**
   - `/song/getAllSongs`（POST 分页 pageNum/pageSize/songName/artistName/album）；分页触底加载或加载更多；搜索（对齐 header 全局搜索：输入关键词进曲库）。
   - 歌曲行复用 SongRow：播放/喜欢/下载。
3. **歌手列表（新）**
   - 分类筛选：歌手类型（男/女/组合/乐队）、地区（中国/美国/韩国/日本/其他）+ 搜索 + 重置；`/artist/getAllArtists`（POST 分页+gender+area+name）。
   - Grid 圆形头像网格 + 分页（触底加载）。
4. **歌手详情（新）**
   - `/artist/getArtistDetail/{id}`：头像、姓名、生日、地区、简介；该歌手歌曲列表（SongRow 播放/喜欢/下载）。
5. **歌单列表（改造 MyPlaylists）**
   - 搜索 + 风格标签筛选（17 种风格）+ Tab（精选歌单/我的收藏）+ 分页；`/playlist/getAllPlaylists`、`/favorite/getFavoritePlaylists`。
6. **歌单详情**
   - `/playlist/getPlaylistDetail/{id}`：封面/标题/描述/创建者/歌曲数；收藏/取消收藏（`/favorite/collectPlaylist`、`cancelCollectPlaylist`，isCollected 同步）。
   - Tab：歌曲（SongRow+播放全部）/ 评论（发布/点赞/删除，`/comment/*`，登录校验）。
7. **我的喜欢**
   - `/favorite/getFavoriteSongs`（POST 分页+搜索）；播放全部；取消收藏实时移除。
8. **最近播放**
   - 本地历史列表：播放、删除单条、清空。
9. **全局搜索页（改造 SearchPage）**
   - 热搜词/搜索历史（Preferences 持久化）；结果分类：歌曲（`/song/getAllSongs` songName）/歌手（`/artist/getAllArtists` name）/歌单（`/playlist/getAllPlaylists` title）；结果行点击播放/跳详情。
10. **下载歌曲**
    - `@ohos.request.downloadFile` 保存音频到应用文件/媒体库，带进度提示。
11. **收藏歌单入口**
    - 个人中心或歌单页提供“收藏的歌单”列表（登录后展示，对齐 client 侧边栏）。

### 阶段 4：UI/UX 打磨与发布（约 1 周）

1. **主题**：深色/浅色/自动全页面生效；主题色自定义；硬编码颜色清零。
2. **安全区与多屏**：状态栏沉浸、底部手势避让、列表预留播放器高度；手机/折叠屏/平板布局校验（Grid 断点）。
3. **动效**：页面转场、列表按压反馈、Swiper、黑胶旋转、进度条动画。
4. **性能**：长列表 LazyForEach；图片占位/缓存；搜索防抖；页面 keep-alive 等价缓存（Navigation 页面栈保留）。
5. **三态页**：加载/失败重试/空数据覆盖所有列表页。
6. **无障碍与细节**：热区 ≥44vp、语义标签、键盘弹起避让。
7. **构建与回归**：`hvigor assembleHap` 通过；真机全流程回归。

---

## 5. 页面/组件级移植任务清单

| # | 功能 | client 蓝本 | 小程序形态 | 鸿蒙落地 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 1 | 底部 Tab | Aside 菜单 | tabBar | Tabs/BottomNavigation 三 Tab（发现/全部音乐/个人主页）统一挂载 | 部分已有 |
| 2 | 发现首页 | `/` | index | IndexPage：Swiper+Grid+List+Refresh+登录重拉 | 改造 |
| 3 | 全部音乐 | `/library` | library | LibraryPage：分页 List+搜索+喜欢+下载 | 改造 |
| 4 | 歌手列表 | `/artist` | 无 | 新增 ArtistListPage：分类筛选+Grid+分页 | 新增 |
| 5 | 歌手详情 | `/artist/:id` | 无 | 新增 ArtistDetailPage：信息+歌曲列表 | 新增 |
| 6 | 歌单列表 | `/playlist` | my-playlists | PlaylistListPage：搜索+风格筛选+精选/收藏 Tab | 改造 |
| 7 | 歌单详情 | `/playlist/:id` | playlistDetail | PlaylistDetailPage：详情+收藏+歌曲/评论 Tab | 改造 |
| 8 | 我的喜欢 | `/like` | my-favorites/like | MyFavoritesPage：分页+搜索+取消收藏 | 改造 |
| 9 | 最近播放 | Footer 播放列表 | recent-play | RecentPlayPage：本地历史 | 改造 |
| 10 | 搜索 | Header 全局搜索 | search(占位) | SearchPage：热搜/历史/分类结果接真实接口 | 改造 |
| 11 | 登录/注册 | AuthTabs | login/register | LoginPage/RegisterPage 接真实接口+校验 | 改造 |
| 12 | 重置密码 | ResetPasswordForm | 入口无页面 | 新增 ResetPasswordPage | 新增 |
| 13 | 个人中心 | `/user` | user/user-edit | UserPage+UserEditPage：头像裁剪上传+资料+注销 | 改造 |
| 14 | 意见反馈 | FeedbackDialog | 无 | 新增 FeedbackDialog | 新增 |
| 15 | 迷你播放器 | Footer | player | BottomPlayer：进度/喜欢/模式/列表/全屏入口 | 改造 |
| 16 | 全屏播放页 | DrawerMusic | 无 | 新增 PlayDetailPage：黑胶动画+歌曲信息+评论 | 新增 |
| 17 | 播放列表 | popover | 无 | bindSheet 半模态组件 PlaylistSheet | 新增 |
| 18 | 评论组件 | DrawerMusic right / playlist | 本地模拟 | 新增 CommentSection（歌曲/歌单复用） | 新增 |
| 19 | 下载 | Table 下载 | 无 | HttpUtil/request downloadFile | 新增 |
| 20 | 后台播放 | — | requiredBackgroundModes | avSession 媒体会话 | 新增 |

---

## 6. API 接口统一清单（鸿蒙端全部实现）

| 功能 | 接口 | 鸿蒙落地 |
| --- | --- | --- |
| 登录 | `POST /user/login` | LoginPage |
| 登出 | `POST /user/logout` | UserPage |
| 验证码 | `GET /user/sendVerificationCode?email=` | Register/ResetPassword |
| 注册 | `POST /user/register` | RegisterPage |
| 重置密码 | `PATCH /user/resetUserPassword` | ResetPasswordPage |
| 用户信息 | `GET /user/getUserInfo` | UserPage/GlobalDataManager |
| 更新资料 | `PUT /user/updateUserInfo` | UserEditPage |
| 更新头像 | `PATCH /user/updateUserAvatar`（multipart avatar） | UserEditPage |
| 注销 | `DELETE /user/deleteAccount` | UserEditPage |
| 轮播图 | `GET /banner/getBannerList` | IndexPage |
| 推荐歌单 | `GET /playlist/getRecommendedPlaylists` | IndexPage |
| 推荐歌曲 | `GET /song/getRecommendedSongs` | IndexPage |
| 全部歌曲 | `POST /song/getAllSongs`（分页+搜索） | LibraryPage/SearchPage |
| 歌曲详情 | `GET /song/getSongDetail/{id}` | PlayDetailPage |
| 全部歌手 | `POST /artist/getAllArtists`（分页+gender/area/name） | ArtistListPage |
| 歌手详情 | `GET /artist/getArtistDetail/{id}` | ArtistDetailPage |
| 全部歌单 | `POST /playlist/getAllPlaylists`（分页+title/style） | PlaylistListPage |
| 歌单详情 | `GET /playlist/getPlaylistDetail/{id}` | PlaylistDetailPage |
| 收藏歌曲列表 | `POST /favorite/getFavoriteSongs`（分页+搜索） | MyFavoritesPage |
| 收藏歌曲 | `POST /favorite/collectSong?songId=` | 播放器/各列表 |
| 取消收藏歌曲 | `DELETE /favorite/cancelCollectSong?songId=` | 播放器/各列表 |
| 收藏歌单列表 | `POST /favorite/getFavoritePlaylists` | PlaylistListPage/收藏歌单入口 |
| 收藏歌单 | `POST /favorite/collectPlaylist?playlistId=` | PlaylistDetailPage |
| 取消收藏歌单 | `DELETE /favorite/cancelCollectPlaylist?playlistId=` | PlaylistDetailPage |
| 歌曲评论 | `POST /comment/addSongComment` | PlayDetailPage |
| 歌单评论 | `POST /comment/addPlaylistComment` | PlaylistDetailPage |
| 点赞评论 | `PATCH /comment/likeComment/{id}` | 评论组件 |
| 取消点赞评论 | `PATCH /comment/cancelLikeComment/{id}` | 评论组件 |
| 删除评论 | `DELETE /comment/deleteComment/{id}` | 评论组件 |
| 意见反馈 | `POST /feedback/addFeedback` | FeedbackDialog |
| 播放地址 | `GET song/url/v1?id=&level=` | AudioManager |
| 歌词 | `lyric` / `lyric/new`（预留） | 歌词模块（二期） |

---

## 7. 数据模型映射（client 类型 → ArkTS）

```ts
// client 接口类型 → 鸿蒙 common.ets
Song { songId, songName, artistName, album, duration(秒·字符串), coverUrl, audioUrl, likeStatus, releaseTime }
PlaylistSong extends Song
PlaylistDetail { playlistId, title, coverUrl, introduction, songs[], likeStatus, comments[], isCollected }
Comment { commentId, username, userAvatar, content, createTime, likeCount }
SongDetail { songId, songName, artistName, album, lyric?, duration, coverUrl, audioUrl, releaseTime, likeStatus, comments[] }
Artist { artistId, artistName, avatar, birth, area, introduction, songs[] }
UserInfo { userId, username, phone, email, avatarUrl(userAvatar), introduction, token? }
Result { code, message, data? } / ResultTable { code, message, data{ items, total, pageSize, currentPage } }
trackModel { id, title, artist, album, cover, url, duration(ms), likeStatus }   // 播放器内部
```

播放器内部使用 `trackModel`，页面层通过 `DataMapper` 将 `Song` 转为 `trackModel`，保证与 client 的 `convertToTrackModel` 行为一致（含默认封面、时长单位换算）。

---

## 8. 验收标准

### 功能验收（对照 music-client 全功能 + 小程序交互）

- music-client 每个页面/功能在鸿蒙端有对应实现：8 个路由页 + 播放器 + 认证三合一 + 评论 + 收藏 + 反馈 + 下载 + 重置密码。
- 移动端交互符合小程序习惯：三 Tab、底部迷你播放器、二级页面栈、未登录拦截弹窗。
- 同一账号两端数据一致（登录、收藏、评论、歌单、喜欢状态）。
- 播放链路：任意页点歌 → 迷你播放器同步 → 全屏播放页 → 后台/锁屏续播 → 恢复。

### UI 验收

- 浅色/深色/自动主题全页面无硬编码色差；主题色可切换。
- 手机/折叠屏/平板布局无溢出、无遮挡；状态栏/安全区/键盘弹起正确。
- 动效自然（转场、黑胶旋转、Swiper）；列表 60fps。

### 质量验收

- `hvigor assembleHap` 构建通过；真机核心链路回归（播放、登录、注册、重置密码、头像、评论、收藏、下载、反馈）。

### 里程碑

| 里程碑 | 内容 | 预估 |
| --- | --- | --- |
| M1 可用 MVP | 基础设施 + 播放闭环 + 登录注册 | 4 周 |
| M2 功能齐全 | 全部内容页面 + 评论/收藏/歌手/下载/反馈 | 6 周 |
| M3 发布准备 | UI 打磨 + 性能 + 验收修复 | 7-8 周 |

---

## 9. 风险与注意事项

1. **后端契约确认**：以 music-client `api/system.ts` 为准，但鸿蒙端 baseUrl 需与小程序一致（`192.168.66.241:8080`/`:9000`），如有不一致以实际后端为准，映射层兜底字段差异（`userAvatar/avatarUrl`、`userId/id/user_id`）。
2. **歌词为 client 预留功能**：解析工具已写好但接口注释未启用，鸿蒙端先建歌词数据结构与解析模块，播放页预留歌词面板，二期接入。
3. **后台播放依赖系统能力**：avSession、后台任务权限需在 module.json5 配置，并处理音频焦点与来电暂停。
4. **头像裁剪**：鸿蒙无现成 vue-cropper，需要基于 PhotoViewPicker + PixelMap 裁剪实现圆形头像，注意真机图片方向/EXIF。
5. **下载存储**：需要申请文件存储相关权限或写入应用沙箱，真机验证。
6. **小程序未纳入 Git**：以工作区当前文件为蓝本，避免版本漂移。
