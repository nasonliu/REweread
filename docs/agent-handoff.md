# REweread Agent 交接手册

更新时间：2026-07-13

这份文档面向第一次接手仓库的新 AI Agent。先读 `AGENTS.md`，再从头读完本文，然后才运行命令或接触设备。本文只记录可公开的项目状态，不包含设备地址、账号、书名、Cookie、API Key、二维码 UID、用户缓存或原始日志。

## 1. 一句话现状

REweread 已完成第一个 Qt 产品里程碑 `1.0.0-rc.1`：源码已合并到 `main`，测试、官方 chiappa SDK 构建和当前测试设备上的原子升级均通过；GitHub Release 仍是 Draft prerelease，未创建公开标签，也没有公开二进制。

它还不是可面向普通用户广泛分发的正式 1.0。当前存在服务授权、上游许可证、干净设备安装/卸载和长期电池测试等阻塞项。

## 2. 接手后的第一组动作

只在一个干净 Git checkout 中工作。先执行：

```bash
git status --short
git branch --show-current
git log -5 --oneline --decorate
node scripts/check-repository.mjs
node tests/run-all.mjs
for file in scripts/*.sh apps/weread-move/*.sh; do bash -n "$file"; done
```

预期：

- 基线来自 `main`。
- `VERSION` 为 `1.0.0-rc.1`。
- 安全检查和静态验证全部通过。
- 不存在 SDK、字体、构建目录、第三方 checkout 或用户数据的待提交文件。

如果 `git status` 报 `bad tree object`、`packfile ... far too short` 或长期卡住，不要继续 commit、gc、repack 或删除 `.git/objects`。在磁盘空间正常后重新 clone，再把确实需要保留的未提交源码逐文件比较迁移。不要用一个新的 `.git` 目录直接覆盖旧工作区，因为旧工作区可能有未提交内容和忽略目录。

## 3. 当前 Git 与发布状态

关键公开提交：

| 提交 | 含义 |
| --- | --- |
| `11322fa` | PR #1 合并到 `main` |
| `a515c45` | `1.0.0-rc.1` 源码发布准备 |
| `a27145a` | 官方 systemd 深度休眠、VPDD 等待和重试 |
| `d2b9278` | 休眠前断开 Wi-Fi、唤醒后恢复 |

发布状态：

- GitHub PR #1 已合并。
- `v1.0.0-rc.1` 是 Draft prerelease 名称，不是公开标签。
- Draft 中只附源码归档和 `SHA256SUMS.txt`。
- 源码归档 SHA-256：`2eaf1c08db968606ac539edc2247e1c3aad267cdb3ca6ab9538b323fd1e571d8`。
- 不得擅自把 Draft 点成 Publish，也不得附加应用二进制或依赖包。

检查当前远端状态：

```bash
gh pr view 1 --repo nasonliu/REweread
gh release view v1.0.0-rc.1 --repo nasonliu/REweread
git ls-remote --tags origin refs/tags/v1.0.0-rc.1
```

最后一条目前应为空。若出现公开标签，先确认是谁发布以及是否完成了 release checklist。

## 4. 当前产品架构

不要把三代实现混在一起：

1. `apps/weread-qt/`：当前产品。Qt 6 / Qt Quick UI、阅读器和设备桥接。
2. `apps/weread-move/lib/` 与 `apps/weread-move/tools/`：当前 Qt 应用仍在调用的 Lua 辅助层。
3. `apps/weread-move/views/`、`native_app.lua`、`app.lua`：历史原型，不是当前 UI。

实际运行链：

```text
Main.qml
  -> C++ stores
  -> QProcess
  -> KOReader 提供的 LuaJIT
  -> apps/weread-move/tools/*.lua
  -> 用户自行安装的 weread.koplugin 模块
  -> WeRead Skill/Web 接口
  -> /home/root/.local/share/rm-weread/
```

因此“独立 APP”只表示 UI 和启动生命周期独立，不表示已经摆脱 KOReader LuaJIT 或 `weread.koplugin`。不要在文档或发布说明里写成完全独立运行时。

## 5. 源码导航

| 要改什么 | 先看哪里 |
| --- | --- |
| 页面/UI/手势/弹窗 | `apps/weread-qt/Main.qml` |
| 评论范围纯映射 | `apps/weread-qt/SocialAnchor.js` |
| 正文、分页、位置 | `reader_store.*` 和 `Main.qml` reader helpers |
| 下载和章节打开 | `download_store.*`、`apps/weread-move/lib/download_manager.lua` |
| 评论与缓存 | `notes_store.*`、`fetch-notes.lua` |
| 登录和退出 | `account_store.*`、`login-qr.lua`、`logout.lua` |
| 云端进度 | `progress_sync_store.*`、`fetch-progress.lua`、`sync-progress.lua` |
| 手写笔 | `stylus_store.*` 和 QML pen palette/hit layers |
| 电源/磁吸套 | `power_store.*` |
| Wi-Fi | `network_store.*` |
| 前灯 | `frontlight_store.*` |
| AppLoad 安装 | `scripts/install-weread-qt-appload.sh` |
| XOVI 持久化 | `scripts/install-xovi-autostart.sh` |
| 会话和系统恢复 | `scripts/weread-qt-session.sh` |
| 发布元数据 | `VERSION`、`CHANGELOG.md`、`release-manifest.json` |

`Main.qml` 超过八千行。可以规划组件化，但不要把一次行为修复和大规模拆文件绑在同一个提交里。静态测试大量依赖源码契约，重构前先找到对应 validator。

## 6. 设备端目录边界

```text
/home/root/weread-qt/                              当前应用
/home/root/weread-qt.previous/                     最近一次原子升级回退
/home/root/xovi/exthome/appload/weread-move/        AppLoad 入口
/home/root/xovi/exthome/appload/weread-move.previous/ AppLoad 回退
/home/root/.local/share/rm-weread/                  用户账号、书籍和缓存
/home/root/xovi/exthome/appload/koreader/           用户安装的运行时
/usr/lib/systemd/system/xochitl.service.d/99-xovi-appload.conf
```

前三类程序文件可以在明确任务中替换。用户数据目录不得删除、打包、打印或上传。卸载脚本默认保留数据；只有用户明确要求，并提供脚本要求的完整确认短语时才允许删除。

不要假定 Wi-Fi 地址固定。默认 USB SSH 是 `root@10.11.99.1`；WLAN SSH 必须由用户先明确开启，再通过 `MOVE_HOST` 传入当前地址。

## 7. 标准开发与部署

本地：

```bash
./scripts/bootstrap-remarkable-sdk.sh
./scripts/download-reader-fonts.sh
./scripts/build-weread-qt.sh
```

部署前再次运行安全检查和测试。正式安装/升级：

```bash
MOVE_HOST=root@DEVICE_ADDRESS ./scripts/install-weread-qt-appload.sh
```

安装器会：

1. 检查架构、XOVI、AppLoad、KOReader 和插件模块。
2. 上传到 `/home/root/weread-qt.installing`。
3. 停止旧应用。
4. 原子切换应用和 AppLoad 目录。
5. 保留 `.previous` 回退目录。
6. 后续失败时自动恢复旧目录和 Xochitl。
7. 重写持久化 XOVI drop-in；这一步会短暂把根分区重挂载为可写，必须提前告知用户。

卸载预演：

```bash
MOVE_HOST=root@DEVICE_ADDRESS DRY_RUN=1 ./scripts/uninstall-weread-qt-appload.sh
```

不要在用户的唯一设备上为了“测试卸载”执行真实卸载。当前候选版只完成了 dry-run，真实卸载应留给干净或备用设备验证。

## 8. 真机验证标准

本地测试只能证明源码契约。以下项目必须在真实 `954 x 1696` 设备上验证：

- 第一次点击 AppLoad 图标能否进入。
- 书架是否是九宫格彩色封面，左右滑动是否换页。
- 详情页是否按当前进度快速进入章节，而不是阻塞下载整本。
- 正文页而非版权页的中文缩进、分页、图片和图注。
- 修改字号/间距后是否保持 `textOffset`。
- 评论虚线是否与正文对齐，点击后是否弹窗且不翻页。
- 笔和手触是否正确分流，最终高亮是否吸附到文本。
- 退出是否恢复 Xochitl。
- 电源键和磁吸套是否真正进入深度休眠。

不要只看截图第一屏，不要用版权页判断分段，不要用静态 validator 宣称手写笔、休眠或评论交互已经在设备上通过。

## 9. 深度休眠：最容易踩坑的部分

### 正确路线

必须调用官方 `systemctl suspend`。不要直接写 `/sys/power/state`，因为那会绕过官方 sleep hooks：

- 配置电源键和 Folio wake source。
- 关闭并卸载 Wi-Fi/BT 驱动。
- 调整 regulator。
- 唤醒后恢复驱动和运行时 wake source。

应用自己的 `rm-weread-qt` wake lock 只负责阻止阅读期间 autosleep，不等于完整系统休眠流程。

### VPDD 保护窗口

彩色电子纸刷新后，G2194 的 VPDD 有最长约 30 秒保护窗口。设备公开 `vpdd_timeout_ms` 和 `vpdd_length`，但 regulator 编号可能变化，所以代码按 `name == VPDD` 动态查找，不能硬编码 `regulator.13`。

典型失败：

```text
Can't suspend, vpdd timer running
Resource temporarily unavailable
```

处理规则：

1. 先显示休眠封面。
2. 保持应用 wake lock。
3. 等实时 `vpdd_timeout_ms` 归零。
4. 再释放 wake lock 并调用 `systemctl suspend`。
5. `systemctl` 返回 0 只表示任务被 systemd 接受，不表示内核成功休眠。
6. 延迟检查 `systemd-suspend.service`；失败时有界重试。

即使 VPDD 显示为 0，第一次 suspend 仍可能因瞬时 busy 失败；当前代码允许最多三次尝试。

### 测试方法

- 断开充电线，避免 `udev.charger` 干扰判断。
- 触发休眠后至少等 45 到 60 秒再唤醒。
- 用 kernel journal 确认 `PM: suspend entry (deep)` 和最终 wake IRQ。
- 合套后很快重新打开，只会取消 pending sleep；这不算深度休眠测试。
- Folio 唤醒时可能同时出现 power-key IRQ，应用层原因文本偶尔先显示“电源键”，以内核 SPLD 最终 wake reason 为准。

已经验证过一次电源键深睡保持数分钟，最终只由 power button 唤醒。磁吸套的快速开合与 Folio wake routing 已验证；长期合套电池测试仍应补做。

## 10. AppLoad/XOVI 的坑

- AppLoad 文件存在不代表图标会显示。先确认 Xochitl 进程环境中真的有 `LD_PRELOAD=/home/root/xovi/xovi.so`。
- `/etc` 下临时创建的自启动 service 可能在重启或系统更新后消失。
- 当前持久化入口是 `/usr/lib/systemd/system/xochitl.service.d/99-xovi-appload.conf`。
- 系统更新可能替换 `/usr/lib`，因此更新后必须重新检查兼容性和 drop-in。
- 不要同时保留“微信读书”和“微信读书·系统”两个入口；安装器会清理旧入口。
- 图标要点两次通常是旧进程、旧 transient unit 或 launcher 提前返回，不要用让用户多点一次来掩盖。

## 11. 登录和账号的坑

当前 QR 流程：

```text
GET /api/auth/getLoginUid
-> 展示 /web/confirm?uid=...
-> 轮询 /api/auth/getLoginInfo?uid=...&otp=
-> 合并 Set-Cookie 和 token
-> 0600 保存 session
```

- 不要恢复旧 `/web/login/getuid`、`getinfo` 或 `session/init` 路线。
- 手机显示登录成功但设备无反应时，先查 `Set-Cookie`；`wr_vid` 不一定在 JSON 中。
- 任何状态输出都不能包含 token、Cookie 或真实二维码 UID。
- 退出账号只删除活动凭据，缓存按文档保留。
- 当前缓存还没有完成严格的按账号隔离。切换账号时不要把旧账号私有书架、进度或评论当作新账号数据展示，这是 1.0 稳定版前的重要缺口。

## 12. 阅读、分页和进度的坑

- 缓存目录必须使用真实 WeRead `bookId`，否则会打开错书。
- 阅读位置必须持久化 `textOffset`。`pageIndex` 在改字号、字体、间距后不稳定。
- 正常正文页应尽量填满可用行，目标约 95%；章节末尾和图片边界可以留白。
- 中文段落分页使用“两边至少各留两行”的拆分规则，不要为了保持整段而制造大空白。
- 首行缩进只影响第一行，不能把每一行容量都按缩进扣减。
- 章节标题另起页、加大加黑；章节尾分隔、图片与图注都属于页面流。
- 图片不能固定在屏幕上只让文字翻页。
- 自检必须采样真实 `readerBodyText`，不要用封面、标题页或版权页。
- 自检不得覆盖用户真实设置或阅读进度。

## 13. 评论和注释的坑

社交评论范围是章节相对偏移，不是当前页像素坐标。正确链路：

```text
远端 plainStart/plainEnd
-> 与 pageStart/pageEnd 相交
-> markText/XHTML 文本锚定
-> 当前页本地文本位置
-> TextEdit.positionAt()/positionToRectangle()
-> 虚线几何和同一组 hit rect
```

- `count > 0, visible = 0`：数据已取回，页范围映射错了。
- `visible > 0` 但点不到：渲染层或事件层错了。
- 虚线和点击区域必须共享几何，不能一个用富文本下划线、另一个用估算坐标。
- `readerSocialTouchLayer` 必须位于翻页区域之上，并消费事件。
- 评论只在当前页停留约 3 秒后加载；翻走就取消或降级上一页请求。
- 优先读缓存，不要每次重复请求整本书评论。
- 等一个评论弹窗加载完成后再允许下一次请求，避免 QML model 重建和 helper 堆积导致假死。
- 注释链接和评论链接都不能同时触发翻页。

评论接口是未公开 Web surface，随时可能变化。遇到“手机有评论、设备没有”时，先确认数据获取、页范围、文本锚定、绘制、点击五层中的哪一层失败，不要一上来重写 API。

## 14. 手写笔和触摸的坑

至少分清三套坐标：原始笔设备坐标、窗口/QML 坐标、TextEdit 文档坐标。

- 文本吸附使用可见 `TextEdit.positionAt()` 和 `positionToRectangle()`。
- 不要用字体大小和行高粗略反推最终高亮位置。
- 笔专用标注控制拒绝手触；普通按钮按需求接受笔和手。
- 颜色胶囊、橡皮擦和评论/注释点击必须消费事件，不能顺带翻页。
- 社交评论虚线偏移和手写高亮偏移是两类问题，不能共用一个“坐标补偿值”。

## 15. Docker、磁盘和构建的坑

- Apple Silicon 使用 `linux/arm64` Docker 容器和 `rm_chiappa_sdk` volume。
- `build-weread-qt.sh` 会删除旧 build 目录后全量构建；QML AOT 最后几步可能长时间停在 94%，要确认 Docker 容器是否仍在运行，不要立即启动第二个构建。
- Codex 工具可能先返回输出，但底层 Docker/SSH/SCP 进程仍在运行。检查进程或继续 poll，不能因为暂时没有新输出就当作完成。
- 磁盘写满曾导致 Docker ext4 只读、构建中断和 Git pack 损坏。优先删除生成的 `apps/weread-qt/build/`，完整退出并重开 Docker；未经用户同意不要 prune volumes、镜像或其他项目数据。
- SourceForge 字体下载可能很慢。不要绕过固定 SHA-256；可以复用本机已校验的忽略目录缓存，但不能提交字体。
- 设备 BusyBox 不接受某些 GNU 缩写参数，例如 `head -20`。使用 `head -n 20` 或 `sed -n '1,20p'`。
- 编译输出存在 Qt locale 警告时，先确认脚本已经导出 `LANG=C.UTF-8 LC_ALL=C.UTF-8`；不要把无关警告误判成链接失败。

## 16. 设备卡死时

不要连续点评论、翻页、注释和笔胶囊，这会让事件与 helper 请求继续排队。

先抓脱敏状态：

```bash
ssh "$MOVE_HOST" '
  pidof rm_weread_qt
  tail -80 /tmp/rm-weread-qt.err
  tail -80 /tmp/rm-weread-qt-session.log
  ps | grep -E "luajit|rm_weread_qt" | grep -v grep
'
```

设备是 BusyBox，命令选项要保守。原始 helper 输出可能包含书名、评论或账号信息，不能贴进公开 issue。

若应用进程已死而系统没有恢复：

```bash
ssh "$MOVE_HOST" '/home/root/xovi/start || systemctl start xochitl'
```

这是恢复手段，不是正常退出方案。正常路径必须由 `weread-qt-session.sh` 恢复 Xochitl。

## 17. 发布与法律边界

当前许可证是 PolyForm Noncommercial 1.0.0：源码可用、禁止商用，不是 OSI 开源。

当前不能发布普通用户二进制，原因至少包括：

- 没有腾讯对微信读书接口、内容、评论和商标的书面许可。
- `weread.koplugin` 上游没有明确 LICENSE。
- 字体、QR 库、XOVI/AppLoad/KOReader 的再分发义务还要逐项审查。
- 干净设备安装/卸载和长期电池测试未完成。

已经删除了旧的 `package-weread-plugin.sh`，不要恢复，也不要把用户自行安装的插件打进发布包。

当前允许做的是：维护公开源码、生成 source-only 候选归档、保持 GitHub Draft。把 Draft 发布、创建公开标签或附加二进制前，必须重新逐项核对 `docs/release-checklist.md`。

## 18. 当前未完成事项

按优先级：

### P0：可靠性验收

- 在断开充电线的情况下做 24 到 48 小时深睡电量记录。
- 做一次磁吸套保持关闭超过 60 秒的受控深睡测试，确认只由 Folio 打开唤醒。
- 记录阅读中、pending VPDD、deep suspend 三种状态的电耗差异。
- 修正 Folio 与 power-key IRQ 同时到达时应用层“唤醒原因”偶尔误标的问题。

### P0：安装生命周期

- 在干净兼容设备上测试首次安装。
- 在备用或干净设备上真实执行默认保留数据的卸载，再验证 Xochitl 和 drop-in 恢复。
- 验证系统更新后恢复流程。

### P1：账号与内容层

- 完成缓存按账号隔离，避免切换账号时暴露旧账号私有数据。
- 降低对 KOReader LuaJIT 和无许可证 `weread.koplugin` 的依赖；替代实现必须先做权利链和接口风险审查。
- 继续确认阅读时长、评论、本地批注和云端进度哪些有稳定且允许使用的同步渠道。

### P1：阅读器回归

- 用多本含图片、图注、表格、注释和长正文的书做正文页矩阵测试，但测试数据不能进仓库。
- 重复评论打开/关闭压力测试。
- 检查每种受支持字体、字号、行距和段距组合下的 95% 页面填充。

### P2：代码结构

- 逐步把 `Main.qml` 拆成稳定组件，每次只迁移一个行为域并保留对应测试。
- 把更多静态源码契约升级为纯逻辑单元测试，减少只靠字符串断言的覆盖。
- 不要在行为修复中顺手重写整个 UI。

## 19. 不要重复走的弯路

- 不要把 Lua 原型当当前产品部署。
- 不要用 `pageIndex` 代替 `textOffset`。
- 不要直接套用远端评论 offset 画线。
- 不要把评论 hit layer 放在翻页层下面。
- 不要把图片固定在页面上。
- 不要在休眠时只释放 wake lock，而绕过官方 systemd hooks。
- 不要硬编码 regulator 编号。
- 不要因为 `systemctl suspend` 返回 0 就宣布休眠成功。
- 不要用版权页做中文段落验收。
- 不要让用户反复手测可以脚本化的点击压力问题。
- 不要删除用户数据来解决缓存或登录问题。
- 不要把 SDK、字体、插件、书籍或日志放进 GitHub Release。
- 不要把 source-only Draft 说成正式公开 1.0。

## 20. 新会话建议的开场回复

新 Agent 可以这样向用户确认：

> 我已经阅读 AGENTS.md 和 docs/agent-handoff.md。当前基线是 main 上的 1.0.0-rc.1 source-only 候选版；公开 Release 仍是 Draft。接下来我会先检查本地 Git 是否健康并运行仓库安全检查和全套验证，不读取或输出账号、书架和设备日志原文。涉及设备部署、根分区、重启、账号或数据删除前，我会先说明影响并等你确认。

完成这些后，再根据用户的新目标进入实现，不要重新从旧 KOReader UI 或早期设计稿开始。
