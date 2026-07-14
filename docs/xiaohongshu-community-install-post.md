# 小红书分享稿｜REweread 社区须知、安装和使用

## 标题参考

我把微信读书搬到 reMarkable Paper Pro Move 了｜免费非商用内测

## 正文

最近一直在折腾一件事：让 reMarkable Paper Pro Move 可以直接看微信读书。

现在已经有彩色封面书架、书籍详情、中文重排、目录、字号和行距设置、灯光调节、阅读进度、划线评论、注释、荧光笔与页内自由手写、块级百度 OCR、拼音与手写输入法、离线下载，以及电源键和磁吸保护套休眠。

项目地址：

https://github.com/nasonliu/REweread

先把最重要的事情说在前面：

**项目只能个人研究、学习和非商用使用。不能收费，不能商用。**

不要卖 App、卖安装包、卖下载链接，也不要收费安装、代刷机、远程配置、做付费群、付费教程、预装设备加价、广告引流或者企业商用。换个名字、换个图标继续卖也不行。

不管叫安装费、辛苦费、技术服务费、赞赏还是捐赠，只要拿这个项目变相赚钱，都不符合社区规则和项目许可证。

这个项目也不是腾讯、微信读书或 reMarkable 官方产品，没有得到这些公司的授权。项目会使用微信读书接口，接口可能变化，也存在账号、内容、服务条款和第三方依赖方面的风险。免费和非商用不代表完全没有风险，安装前请自己判断。

## 安装前先看

目前只验证了：

- reMarkable Paper Pro Move。
- 项目 README 中列出的系统、SDK、XOVI、AppLoad 和 KOReader 版本组合。
- macOS 或 Linux 电脑。
- 电脑已经安装 Docker，并能使用 Git、SSH 和 USB。

其他 reMarkable 型号不要直接照搬安装。

安装需要开启 Developer Mode。第一次开启 Developer Mode 会恢复出厂，设备里还没有同步的资料会丢失，也会降低设备安全性。请先确认重要笔记已经同步或备份，再决定要不要继续。

这不是手机点一下就能装的普通 App。目前更适合愿意自己折腾，或者愿意让本地 AI Coding Agent 帮忙安装的人。

## Developer Mode 和 SSH

这里不需要申请单独的“开发者账号”，而是在设备上开启 Developer Mode。

设备路径：

```text
Settings
  -> General
  -> Paper Tablet
  -> Software
  -> Advanced
  -> Developer Mode
```

开启并重新设置设备后，SSH 登录信息在：

```text
Settings
  -> General
  -> Help
  -> About
  -> Copyrights and Licenses
  -> General Information
```

这里显示的是 `root` 用户和随机 SSH 密码，不是 SSH 私钥。

请不要把密码发到评论区、群聊、GitHub issue 或 Agent 对话里。最稳妥的方式是在本机终端出现密码提示时自己输入，或者自己把电脑的 SSH 公钥安装到设备。

## 用 Codex 或 Hermes 安装

Codex、Hermes 或其他 Coding Agent 必须运行在连接设备的那台电脑上，并且能够操作本地文件、Docker、Git 和 SSH。只有网页聊天、没有终端权限的 Agent 无法直接完成安装。

推荐先用 USB-C 连接设备。USB SSH 默认地址是：

```text
root@10.11.99.1
```

打开 Codex 或 Hermes，把下面整段提示词发给它。不要在提示词后面追加设备密码、微信读书 API Key、Cookie 或其他登录信息。

## 可直接复制的 Agent 安装提示词

```text
我要在我自己的 reMarkable Paper Pro Move 上安装 REweread。

项目地址：
https://github.com/nasonliu/REweread

用途仅限我个人研究和非商用使用。禁止收费安装、转售、预装销售、付费服务、广告变现或企业商业部署。

你是负责安装和验证的 Coding Agent。请完整执行，但必须遵守以下规则：

一、开始前先停下来确认
1. 先完整阅读仓库的 README.md、AGENTS.md、docs/dependencies.md、docs/troubleshooting.md、docs/legal-and-commercial-use.md 和 docs/release-checklist.md。
2. 先询问并确认我的设备确实是 reMarkable Paper Pro Move，不要把未验证的步骤用于其他型号。
3. 先提醒我：第一次开启 Developer Mode 会恢复出厂并清除未同步的本地数据，也会降低设备安全性。
4. 必须等我明确回复“备份完成、Developer Mode 已开启、设备已用 USB 连接”后，才能执行设备修改。
5. 不要替我静默开启 Developer Mode，不要执行恢复出厂。

二、密码和用户数据安全
1. 不要要求我把 SSH 密码、SSH 私钥、微信读书 API Key、Cookie、Access Token 或二维码登录信息发到聊天里。
2. SSH 密码需要时，让我在本机交互式终端中亲自输入；优先帮助我配置本机公钥登录。
3. 不要使用 sshpass、密码环境变量、带密码的命令行或 StrictHostKeyChecking=no。
4. 不要读取、打印、上传或提交我的书架、书籍、封面、阅读进度、评论、批注和设备日志原文。
5. 不得删除或覆盖 /home/root/.local/share/rm-weread/，除非我明确要求删除数据。

三、本地准备和源码验证
1. 在合适的本地工作目录克隆项目，不要在仓库里放第三方源码、SDK、字体、登录配置或构建缓存：
   git clone https://github.com/nasonliu/REweread.git
   cd REweread
2. 检查 Docker、Node.js 18+、Git、SSH、SCP、rsync 和 curl 是否可用。
3. 运行：
   node scripts/check-repository.mjs
   node tests/run-all.mjs
   bash -n scripts/*.sh
4. 任一检查失败时，先定位并说明问题，不要带着失败状态继续改设备。

四、依赖和兼容性
1. 按 docs/dependencies.md 使用官方或上游原始地址准备依赖，不要把依赖提交到项目仓库。
2. 核对设备系统版本和项目测试过的兼容矩阵。
3. 检查设备上是否已有兼容的 XOVI、AppLoad、KOReader 和 weread.koplugin。
4. 不要盲目安装“最新版本”；先核对当前系统兼容性，并在安装或修改 XOVI/AppLoad 前向我说明风险。
5. weread.koplugin 上游目前没有明确 LICENSE，只能按个人非商用研究处理，不要重新打包或公开分发它。

五、构建
1. 按项目脚本准备官方 chiappa SDK：
   ./scripts/bootstrap-remarkable-sdk.sh
2. 下载项目使用的字体：
   ./scripts/download-reader-fonts.sh
3. 构建 Qt 应用：
   ./scripts/build-weread-qt.sh
4. 确认生成 apps/weread-qt/build/rm_weread_qt，并报告构建结果和 SHA-256。

六、安装到设备
1. 优先通过 USB SSH 使用 root@10.11.99.1，不要先开放 Wi-Fi SSH。
2. 先做只读检查：设备型号、系统版本、磁盘空间、现有 XOVI/AppLoad/KOReader 状态和当前 AppLoad 入口。
3. 在任何 remount、systemd、Xochitl、XOVI 或 AppLoad 修改前，先告诉我将修改什么以及如何恢复。
4. 得到确认后运行仓库提供的安装脚本：
   MOVE_HOST=root@10.11.99.1 ./scripts/install-weread-qt-appload.sh
5. 安装必须保留已有账号、书架、进度、评论、批注和缓存。
6. 不要把我的凭据、字体、SDK、第三方依赖或用户数据提交到 Git。

七、安装后验证
1. 确认 AppLoad 中只出现一个正确的“微信读书”入口。
2. 确认第一次点击图标就能启动应用。
3. 确认彩色九宫格书架、书籍详情、继续阅读、目录、左右翻页和阅读设置可以打开。
4. 确认书架可以在封面区域左右滑动换页。
5. 确认应用可以退出到系统，退出后 Xochitl 正常恢复。
6. 在我允许时，再验证电源键休眠、磁吸保护套休眠、灯光关闭和 Wi-Fi。
7. 重启设备后再次确认 AppLoad 入口仍然存在。
8. 检查日志时必须脱敏，只汇报错误类型，不要输出账号、书名、Cookie、API Key 或用户内容。

八、微信读书登录
1. 应用内登录优先让我在设备上显示二维码，再用手机微信扫码确认。
2. 如果书架提示缺少 WeRead Skill API Key，请告诉我去微信读书 App 对应的 Skill 设置中获取我自己的 Key，并指导我只在设备本地私密配置。
3. 不要替我生成、猜测或收集 API Key，也不要把 Key 写进源码或安装包。

九、完成标准
完成后请给我一份简短报告，包含：
- 本地检查和构建是否通过。
- 使用的设备系统和依赖版本。
- 安装了哪些文件和启动入口。
- 真机实际验证了哪些功能。
- 哪些功能仍需要我手动操作验证。
- 明确确认没有删除 /home/root/.local/share/rm-weread/，没有保存或提交任何密码、Cookie、API Key、书籍或用户数据。

如果遇到不确定、需要恢复出厂、系统版本不兼容、依赖来源不清楚或可能损坏系统的情况，请停止并向我解释，不要自行冒险继续。
```

## 装好以后怎么用

### 打开和登录

1. 在 reMarkable 系统中打开 AppLoad。
2. 点“微信读书”图标。
3. 第一次登录时，用手机微信扫描设备上的二维码并确认。
4. 登录成功后等待书架同步完成。

### 书架

- 点彩色封面进入书籍详情。
- 在九宫格封面区域左右滑动切换下一批或上一批书。
- “继续阅读”打开最近阅读的书。
- “下载本页”下载当前显示的 9 本书。
- “同步”刷新书架和封面。
- 右上角“退出”回到 reMarkable 系统。

### 阅读

- 手指点正文右半边或向左滑：下一页。
- 手指点正文左半边或向右滑：上一页。
- 从左边缘向右滑：打开目录。
- 从底部向上滑：打开阅读设置。
- 阅读设置里可以改字体、字号、行距、段距、页边距、字重、灯光和进度。
- 右上角可以查看电量并快速调节灯光。
- 阅读设置中的“退出到书架”可以保存进度并返回书架。

### 评论、注释和手写笔

- 在当前页停留约 3 秒，应用会尝试加载本页划线评论。
- 点正文下方的黑色虚线打开评论。
- 用笔点红色上标数字查看注释。
- 用笔点右侧小圆点展开工具，颜色和模式分开选择；“划”吸附正文，“写”可直接在页内空白处写字、圈画或做符号。
- 用手点一块相邻笔迹可就地“识别”或“删除”；OCR 只识别所选块，不扫描整页，原始笔迹仍保留。
- 搜索框可切换拼音、手写和英文，拼音与 OCR 候选可点“上页/下页”。
- 百度 OCR 要在“我的”中主动开启 HTTPS 浏览器配置，由用户亲自填写 API Key 与 Secret Key，不要把密钥发给安装 Agent。
- 笔靠近时会防手掌误触；正常状态下手指仍用于翻页和点笔迹操作。

### 休眠

- 短按电源键休眠，再短按一次唤醒。
- 合上磁吸保护套休眠，打开后恢复阅读。
- 休眠画面会显示当前书籍封面。

完整操作指南：

https://github.com/nasonliu/REweread/blob/main/docs/quick-start-user-guide.md

## 常见问题

### 为什么不是一键安装？

因为这是 reMarkable Developer Mode 下的社区项目，需要匹配设备系统、SDK、XOVI、AppLoad 和运行时版本。让 Agent 先检查再安装，比直接复制一串命令更稳妥。

### 为什么不能直接把 SSH 密码发给 Agent？

设备密码相当于 root 权限。密码、私钥、微信读书 Cookie 和 API Key 都不应该进入聊天记录、日志或 GitHub。

### 系统升级以后图标没了怎么办？

系统升级可能替换 XOVI/AppLoad 相关文件。不要反复乱装，把同一项目地址和上面的排障要求交给本地 Agent，让它先检查版本和日志。

### 可以帮别人安装吗？

可以在完全免费、非商业、把风险说清楚的前提下互相交流。但不能收安装费、服务费、辛苦费，也不要保存别人的设备密码和微信读书登录信息。

### 可以拿去卖吗？

不可以。不能卖软件、卖安装、卖教程、卖预装设备，也不能用于公司或工作室的商业项目。

## 最后再强调一次

这个项目公开出来，是希望喜欢墨水屏和阅读器的朋友一起研究、一起改进。

可以自己玩，可以学习，可以免费交流，也可以提交非商业改进。

**但不要收费，不要商用，不要拿别人的账号和内容冒险。**

如果发现有人倒卖、收费安装、预装加价或者冒充官方，请不要购买，也欢迎提醒社区避坑。

## 置顶评论短版

项目地址：https://github.com/nasonliu/REweread

仅限个人研究和非商用使用。禁止售卖 App、收费安装、代刷机、付费群分发、预装设备加价、广告引流及企业商用。安装需要 Paper Pro Move、Developer Mode、Docker 和本地 Coding Agent。开启 Developer Mode 前务必备份；不要把 SSH 密码、微信读书 API Key 或 Cookie 发给任何人。完整安装提示词和使用说明见正文及项目 README。
