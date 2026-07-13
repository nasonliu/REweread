# rm-weread

面向 reMarkable Paper Pro Move 的非官方微信读书客户端实验项目。

当前阶段版本：`1.0.0-rc.1`。这是源码发布候选版，不提供公开二进制安装包。版本说明见 [CHANGELOG](CHANGELOG.md) 和 [1.0.0-rc.1 发布说明](docs/releases/v1.0.0-rc.1.md)。

本仓库的主要读者是接手开发、构建、部署和排障的 AI Agent。仓库只保存源码、测试和操作文档；SDK、XOVI、AppLoad、KOReader、字体、登录态、书架缓存、封面和电子书文件都必须从外部获取，不能提交到 Git。

> **非商用与非官方声明：** 本项目是个人研究和设备内测项目，与腾讯、微信读书或 reMarkable 无隶属、授权、认可或合作关系。项目自当前版本起采用 [PolyForm Noncommercial 1.0.0](LICENSE)，只允许许可证定义的非商用用途；不得收费销售、收费安装、捆绑设备销售、提供付费订阅或托管服务、广告变现，也不得用于企业商业运营。本项目是“源码可用”项目，不是 OSI 定义的开源软件。详见[法律与商业使用说明](docs/legal-and-commercial-use.md)。

> **服务风险：** 非商用许可证只约束本仓库自有代码，不代表腾讯允许使用微信读书接口、内容、账号数据、评论或商标。微信读书用户协议对未经授权的第三方软件、插件和接口接入有明确限制，且相关限制并不只针对商业用途。使用者必须自行阅读适用条款并承担风险。

已安装应用的基本操作、阅读手势和账号使用方法见 [微信读书 Move 快速应用指南](docs/quick-start-user-guide.md)。

## Agent 从这里开始

接手任务后按以下顺序工作：

1. 完整阅读 [AGENTS.md](AGENTS.md)。
2. 阅读 [当前 Agent 交接手册](docs/agent-handoff.md)，不要从旧会话或 Lua 原型猜当前状态。
3. 运行仓库安全检查：`node scripts/check-repository.mjs`。
4. 运行静态验证：`node tests/run-all.mjs`。
5. 根据任务阅读 [依赖清单](docs/dependencies.md) 和 [故障排查](docs/troubleshooting.md)。
6. 需要碰真机时，先执行下方“Developer Mode 与 SSH”中的用户确认流程。
7. 用户完成 Developer Mode 和 SSH 准备后，优先使用 USB 地址 `root@10.11.99.1`；只有用户明确提供新的地址时才设置 `MOVE_HOST`。
8. 真机操作前确认不会覆盖 `/home/root/.local/share/rm-weread/` 中的账号、进度、批注和缓存。
9. 完成后再次运行安全检查、静态验证和与改动风险相匹配的真机验证。

不要从旧文档猜当前实现。当前产品入口是 `apps/weread-qt/`，`apps/weread-move/` 主要提供 Lua 网络/内容辅助层和早期原型。

## 产品目标

目标是在 954 x 1696 的彩色墨水屏上提供一个接近原生阅读器的微信读书体验：

- 九宫格彩色封面书架和书籍详情页。
- 设备端扫码登录、退出和 Cookie 续期。
- 按当前进度优先下载章节，支持整本缓存和离线阅读。
- 中文重排、字体/字号/行距/段距/页边距设置及设置持久化。
- 目录、书签、进度保存与微信读书进度同步。
- 图片、图注、章节标题、注释和表格的阅读器排版。
- 热门划线评论按当前页延迟加载并缓存。
- 手写笔高亮、橡皮擦和防手触。
- Wi-Fi、前灯、电源键、磁吸保护套休眠以及返回系统。
- 墨水屏友好的高对比度、低动画和可控刷新。

## 当前实现

当前主程序是 Qt 6 / Qt Quick 应用：

```text
apps/weread-qt/
  Main.qml                 当前 UI 和交互入口
  *_store.cpp/.h           书架、阅读、下载、账号、评论、网络、灯光和电源桥接
  SocialAnchor.js          评论划线范围映射

apps/weread-move/
  lib/                     缓存、分页、下载和 WeRead 辅助代码
  tools/                   Qt 通过 QProcess 调用的 Lua 工具
  views/ + native_app.lua  早期 Lua 原型，不是当前产品入口
```

运行时数据流：

```text
Qt Quick UI
  -> C++ Store
  -> KOReader 提供的 LuaJIT
  -> apps/weread-move/tools/*.lua
  -> weread.koplugin 的 client/content/cookie 模块
  -> 微信读书 Skill API 或 Web API
  -> /home/root/.local/share/rm-weread/
```

这意味着 UI 已经是独立 APP，但网络和内容层目前仍依赖 KOReader 的 LuaJIT 以及 `weread.koplugin`。在替换这两层之前，不要把项目描述为“完全无 KOReader 运行时依赖”。

## 支持范围

已验证基线：

完整兼容矩阵见 [docs/compatibility.md](docs/compatibility.md)。

| 项目 | 基线 |
| --- | --- |
| 设备 | reMarkable Paper Pro Move (`chiappa`) |
| 分辨率 | 954 x 1696，RGB565 彩色墨水屏 |
| 设备系统镜像 | 5.7.126，构建 `20260612085811` |
| 官方 SDK | chiappa 5.7.119 |
| Qt | 设备自带 Qt 6.8.2 |
| KOReader 运行时 | v2025.10（建议后续验证更新版） |
| XOVI | v19-23052026 |
| AppLoad | v0.5.3 |

其他设备、其他分辨率或其他系统版本都视为未验证。reMarkable 官方明确不保证 Xochitl 不同版本之间兼容，XOVI/AppLoad 也可能随系统升级失效。

## Developer Mode 与 SSH

### 没有单独的“开发者账号”

本项目不要求注册独立的 reMarkable 开发者账号。官方流程是在支持的 Paper Pro 系列设备上开启 Developer Mode。普通 reMarkable 云账号只用于同步和备份；首次开启 Developer Mode 前必须先确认重要内容已经同步。

官方入口：

- [Developer Mode 官方说明](https://developer.remarkable.com/documentation/developer-mode)
- [reMarkable Developer Portal](https://developer.remarkable.com/)
- [创建和配对普通 reMarkable 云账号](https://support.remarkable.com/articles/Knowledge/Pair-your-reMarkable-with-the-cloud)

### Agent 必须先提示用户

在引导开启 Developer Mode 或执行任何 SSH 命令前，Agent 必须明确告诉用户：

1. 首次开启 Developer Mode 会执行恢复出厂，设备上尚未同步的本地数据会丢失。
2. Developer Mode 会削弱 Secure Boot 的信任链和设备安全性，并在每次开机时显示警告。
3. 因自行修改导致的问题可能不属于官方保修或 Protection Plan 支持范围。
4. 用户需要先完成云同步或独立备份，并亲自在设备上开启 Developer Mode。
5. Agent 不会索取、显示、记录或提交 SSH 密码和私钥。

Agent 必须等待用户明确确认“备份完成并同意开启”，不能静默开启，也不能把恢复出厂当作普通安装步骤。

### 用户开启 Developer Mode

在设备上依次打开：

```text
Settings
  -> General
  -> Paper Tablet
  -> Software
  -> Advanced
  -> Developer Mode
```

按照屏幕提示完成恢复出厂和重新设置。Developer Mode 开启后会一直保持，关闭它需要使用官方 Recovery 流程。

### 去哪里找 SSH 登录信息

Developer Mode 开启后，在设备上依次打开：

```text
Settings
  -> General
  -> Help
  -> About
  -> Copyrights and Licenses
  -> General Information
```

这里会显示 SSH 用户名和随机生成的密码。官方文档当前给出的用户名是 `root`。通过 USB-C 把设备连接到电脑后，默认地址是：

```bash
ssh root@10.11.99.1
```

首次连接时由用户在终端提示符中亲自输入设备显示的密码。不要把密码粘贴到 README、聊天记录、issue、日志、脚本、环境变量或 Git 提交中；Agent 也不得要求用户发送包含密码的截图。

### SSH 密码与 SSH 密钥不是一回事

reMarkable 显示的是 SSH 密码，不会提供可下载的 SSH 私钥。若希望 Agent 后续免密码连接，应在用户自己的电脑上生成密钥对，只把公钥安装到设备：

```bash
test -f ~/.ssh/id_ed25519.pub || ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub | ssh root@10.11.99.1 \
  'umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys'
```

运行第二条命令时，用户仍需亲自输入一次设备显示的随机密码。私钥 `~/.ssh/id_ed25519` 必须始终留在用户电脑上；仓库、Agent 输出和设备安装包中都不能包含它。

如果 SSH 提示主机指纹发生变化，Agent 必须停下来让用户确认设备是否刚恢复出厂，不能用 `StrictHostKeyChecking=no` 绕过检查。

### 可选：启用 Wi-Fi SSH

官方默认关闭 Wi-Fi SSH。先通过 USB 登录，再由用户明确同意后运行：

```bash
ssh root@10.11.99.1 'rm-ssh-over-wlan on'
```

之后才使用设备当前 WLAN 地址：

```bash
MOVE_HOST=root@DEVICE_IP ./scripts/install-weread-qt-appload.sh
```

Agent 不得假设 WLAN 地址固定，也不得在未告知用户的情况下开放 Wi-Fi SSH。

## 外部依赖

所有依赖必须下载到 Git 忽略的 `downloads/`、Docker volume 或设备目录中。完整版本、地址、许可证和更新规则见 [docs/dependencies.md](docs/dependencies.md)。关键入口：

- [reMarkable Developer Portal](https://developer.remarkable.com/)
- [reMarkable SDK 下载列表](https://developer.remarkable.com/links)
- [reMarkable 官方示例](https://github.com/reMarkable/remarkable-developer-examples)
- [XOVI](https://github.com/asivery/xovi)
- [AppLoad](https://github.com/asivery/rm-appload)
- [KOReader](https://github.com/koreader/koreader)
- [weread.koplugin](https://github.com/QiuYukang/weread.koplugin)
- [LXGW WenKai](https://github.com/lxgw/LxgwWenKai)
- [WenQuanYi](https://sourceforge.net/projects/wqy/)

仓库不使用 Git submodule。外部源码不得复制到 `third_party/` 后提交。

## 本地准备

需要：

- macOS 或 Linux 主机。
- Docker；Apple Silicon 使用 `linux/arm64` 容器。
- Node.js 18 或更新版本，用于验证脚本。
- `ssh`、`scp`、`rsync`、`curl`。
- 已按上方流程进入 Developer Mode 并配置好 USB SSH 的 Paper Pro Move。

### 1. 准备 SDK

```bash
./scripts/bootstrap-remarkable-sdk.sh
```

脚本会把官方 chiappa SDK 下载到被忽略的 `downloads/official-sdk/`，校验 SHA-256，然后安装到 Docker volume `rm_chiappa_sdk`。SDK 不进入仓库。

### 2. 准备字体

```bash
./scripts/download-reader-fonts.sh
```

字体会进入被忽略的 `downloads/fonts/`。脚本校验固定版本的文件摘要。

### 3. 构建

```bash
./scripts/build-weread-qt.sh
```

输出为：

```text
apps/weread-qt/build/rm_weread_qt
```

构建脚本会先把固定版本的 QR Code Generator 下载并校验到被忽略的 `downloads/sources/`，再把该外部路径传给 CMake，不会写入源码树。

从干净提交生成源码候选包和 SHA-256：

```bash
./scripts/package-source-release.sh
```

输出进入被忽略的 `packages/`。该脚本只归档 Git 已跟踪源码，不会打包本地二进制、字体、SDK、设备依赖或用户数据。

## 设备依赖

当前安装器假设设备已经具备：

```text
/home/root/xovi/
/home/root/xovi/exthome/appload/
/home/root/xovi/exthome/appload/koreader/luajit
/home/root/xovi/exthome/appload/koreader/plugins/weread.koplugin/
```

推荐通过社区包管理器安装 XOVI/AppLoad；具体来源见依赖文档。`weread.koplugin` 需要用户自行从上游仓库安装。不要把插件源码、用户 `config.lua` 或 API Key 打进本项目安装包。

## 安装与开发部署

默认通过 USB SSH：

```bash
MOVE_HOST=root@10.11.99.1 ./scripts/install-weread-qt-appload.sh
```

通过 Wi-Fi 调试时，用户需要先在设备上明确启用 WLAN SSH，然后传入地址：

```bash
MOVE_HOST=root@DEVICE_IP ./scripts/install-weread-qt-appload.sh
```

安装器会复制主程序、字体和 Lua 辅助文件，创建 AppLoad 图标，并安装 XOVI 的 Xochitl drop-in。它不会删除：

```text
/home/root/.local/share/rm-weread/
```

升级时安装器先上传到 staging 目录，再原子替换应用和 AppLoad 入口；旧版本保留在相邻的 `.previous` 目录，后续步骤失败会自动回滚。

卸载应用但默认保留账号、书籍和阅读数据：

```bash
MOVE_HOST=root@10.11.99.1 ./scripts/uninstall-weread-qt-appload.sh
```

删除用户数据是独立危险操作，只有用户明确要求后才可使用 `REMOVE_DATA=1` 和脚本要求的完整确认短语。可先设置 `DRY_RUN=1` 查看将执行的动作。

开发中快速覆盖并启动：

```bash
MOVE_HOST=root@10.11.99.1 RUN_SECONDS=0 ./scripts/run-weread-qt-on-move.sh
```

当前官方 Qt 路线运行时会停止 Xochitl，退出后由 `weread-qt-session.sh` 恢复。Wi-Fi 连接通常仍在，但 reMarkable 系统 UI 和 `rm-sync` 在阅读期间不可用。不要在应用运行时执行系统升级或恢复出厂设置。

## 登录和本地数据

扫码登录由设备端生成二维码，登录 Cookie 保存到：

```text
/home/root/.local/share/rm-weread/session.json
```

书架、封面、书籍、阅读进度、评论缓存和本地批注也都在：

```text
/home/root/.local/share/rm-weread/
```

这些文件只能留在设备或用户明确指定的私有备份中。禁止放入 issue、日志、截图附件或 Git 提交。切换账号时缓存会保留；当前缓存还没有按账号隔离，因此 Agent 不得把一个用户的缓存用于另一个用户的调试样本。

## 验证

本地基础验证：

```bash
node scripts/check-repository.mjs
node tests/run-all.mjs
for file in scripts/*.sh apps/weread-move/*.sh; do bash -n "$file"; done
```

注意：`tests/run-all.mjs` 主要是源码契约和静态回归，不等于真机端到端测试。

真机验证会启动/停止 APP 和 Xochitl，只能在用户允许时执行：

```bash
MOVE_HOST=root@10.11.99.1 ./scripts/verify-weread-qt-device.sh
```

发布前还要按 [docs/release-checklist.md](docs/release-checklist.md) 做冷启动、重启、休眠、登录、翻页、评论、下载和卸载验证。

## 常见故障入口

| 现象 | Agent 第一检查点 |
| --- | --- |
| AppLoad 图标消失 | Xochitl 是否带 `LD_PRELOAD=/home/root/xovi/xovi.so`，drop-in 是否还在 |
| 点击图标第一次无反应 | AppLoad launcher 是否提前退出，旧进程/临时 systemd unit 是否残留 |
| 白屏或闪退 | `/tmp/rm-weread-qt.err`、`/tmp/rm-weread-qt-session.log`，Qt/SDK 版本是否匹配 |
| 扫码后一直等待 | `login-qr.lua` 是否使用当前 `/api/auth/getLoginUid` 和 `/api/auth/getLoginInfo` 流程 |
| 书架为空 | API Key、Cookie 状态、`refresh-shelf.lua` 和 `shelf.json`，不要打印真实值 |
| 评论有数据但无虚线 | `pageStart/pageEnd`、`TextEdit.positionAt()` 和 `readerSocialTouchLayer` |
| 点击评论后卡死 | 只加载当前页、3 秒停留延迟、取消上一页请求、等待浮窗完成后再发下一请求 |
| 字号变化后进度跳动 | 保存并恢复 `textOffset`，不要只保存 `pageIndex` |
| 底部大面积空白 | 用真实正文页测试分页，章节末尾例外；不要用版权页判断 |
| 电源键/保护套无效 | 区分 `KEY_POWER`、`SW_LID`、`SW_MACHINE_COVER` 与应用层手势 |
| 系统升级后 APP 消失 | `/usr/lib` 会被系统镜像替换，重新验证并安装兼容的 XOVI/AppLoad 和 drop-in |

完整命令和判断树见 [docs/troubleshooting.md](docs/troubleshooting.md)。

## 仓库安全规则

以下内容永远不能提交：

- `wrk-...` API Key、Cookie、Access Token、二维码 UID、设备密码或私钥。
- `config.lua`、`session.json`、`.env` 和任何凭据导出。
- `shelf.json`、阅读进度、评论缓存、批注、设备日志或用户截图。
- EPUB、PDF、MOBI、AZW、书籍图片、封面缓存和解包章节。
- reMarkable SDK、XOVI/AppLoad 压缩包、KOReader、字体二进制和其他第三方源码。
- `build/`、`downloads/`、`packages/`、`tmp/`、`third_party/`。

提交前必须运行：

```bash
node scripts/check-repository.mjs
```

如果安全检查命中，不要简单删除规则。先确认文件来源，移出仓库，再轮换任何可能已经暴露的凭据。

## 发布边界

项目使用微信读书的 Skill API 和未公开 Web 接口。接口可能随时变化，[微信读书用户协议](https://cdn.weread.qq.com/app/weread_user_agreement_android_s.html)也限制未经授权的第三方软件、插件和接口接入。非商用不等于已经获得腾讯授权。

任何源码或构建产物的分发都必须：

1. 保留 PolyForm Noncommercial 许可证、`Required Notice` 和版权声明。
2. 只用于许可证允许的非商用目的，不得通过软件、安装、支持、捆绑硬件、订阅、广告或数据服务获得商业利益。
3. 完成所有第三方代码、运行时和字体的许可证审查；本项目许可证不会覆盖它们。
4. 避免使用会让用户误以为是腾讯或 reMarkable 官方产品的名称、图标和文案。
5. 评估微信读书接口、账号、内容缓存、评论数据、个人信息和著作权风险。
6. 提供安装、升级、卸载、数据清理、系统恢复和免责声明。

`weread.koplugin` 当前上游仓库未提供明确 LICENSE，因此其再分发和衍生使用是独立阻塞项。最稳妥的公开方式是仅发布不含微信协议实现、用户内容和上游源码的 UI/渲染代码；在腾讯和上游许可未解决前，不应发布面向普通用户的二进制安装包。

### 如果未来考虑商业化

本项目当前不提供商业许可。仅取得本仓库作者同意也不足以合法商业化；商业项目至少需要同时完成：

1. 从腾讯取得对微信读书服务接入、登录、接口、内容、评论、进度数据和商标使用的书面授权。
2. 从 `weread.koplugin` 等无明确许可或受独立许可约束的上游取得书面授权，或用经过审查的独立实现替换。
3. 解决 XOVI、AppLoad、KOReader、字体、二维码库及其他依赖的许可证和再分发义务。
4. 建立不分发书籍内容、不绕过技术保护、尊重用户购买与访问范围的内容方案。
5. 完成隐私、个人信息、网络安全、著作权、消费者保护和设备保修方面的专业法律审查。
6. 最后再向本仓库权利人申请单独书面商业许可；当前没有自动授权、付费即授权或默认商业许可渠道。

在上述授权全部书面落实以前，任何商业部署、收费安装、预装销售、企业内部运营或公开应用商店分发都应视为禁止。

许可证变更只对当前及后续发布生效。已经在旧 MIT 许可证下合法取得的历史副本，其既有授权通常不能通过本次修改追溯撤销；删除历史或改写 Git 记录也不能可靠消除已经授出的权利。

这个长期开发工作区的旧分支和本地 Git 对象可能包含早期设备标识或测试样本。公开 GitHub 时必须从当前已清洗文件创建单一根提交；不要对本地开发仓库执行 `git push --all` 或 `git push --mirror`。
