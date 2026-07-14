# Agent 升级到 REweread 1.5.0

本文面向负责升级现有 Paper Pro Move 安装的 AI Agent。普通用户不要把 SSH
密码、私钥、百度凭据或设备日志交给 Agent；Agent 应引导用户在交互式终端和
浏览器配置页中亲自输入敏感信息。

## 1. 先确认升级边界

升级前必须完整阅读 `AGENTS.md`、`docs/agent-handoff.md` 和本文。1.5.0
仍是非官方、非商用、仅源码里程碑，不代表已经获得腾讯、微信读书或
reMarkable 授权，也不允许发布二进制依赖包。

如果设备尚未开启 Developer Mode，Agent 必须先告诉用户并等待明确确认：

- 首次开启会恢复出厂并删除尚未同步的本地数据。
- 它会削弱 Secure Boot 信任链并显示开机警告。
- 自行修改造成的损坏可能不在官方保修或 Protection Plan 范围内。
- 用户必须先完成云同步或其他备份，并亲自在设备上开启。
- Agent 不索取、显示、保存或提交设备密码和任何 SSH 私钥。

已经在正常运行旧版 REweread 的设备通常无需重新开启 Developer Mode。

## 2. 更新一个干净的源码检出

不要在带有未提交改动的工作区直接拉取和覆盖。先检查：

```bash
git status --short
git branch --show-current
git remote -v
```

干净检出可按以下方式更新。远端名称不是 `origin` 时替换为实际名称：

```bash
git fetch origin --prune
git switch main
git pull --ff-only origin main
test "$(tr -d '[:space:]' < VERSION)" = "1.5.0"
```

若工作区不干净，保留原目录并新建 clone 或 Git worktree；不要使用
`git reset --hard`、覆盖 `.git` 或删除用户的未提交文件来制造“干净”状态。

## 3. 运行升级前检查

```bash
node scripts/check-repository.mjs
node tests/run-all.mjs
for file in scripts/*.sh apps/weread-move/*.sh; do
  bash -n "$file"
done
```

任何一项失败都应先定位，不能因为设备上“看起来能打开”就跳过。尤其要确认
仓库中没有 SDK、字体、KOReader、XOVI、AppLoad、`weread.koplugin`、`.env`、
API Key、Cookie、书籍、封面、批注、用户截图或设备日志。

## 4. 准备依赖并构建

```bash
./scripts/bootstrap-remarkable-sdk.sh
./scripts/download-reader-fonts.sh
./scripts/build-weread-qt.sh
```

构建产物应位于：

```text
apps/weread-qt/build/rm_weread_qt
```

Apple Silicon 使用脚本配置的 `linux/arm64` Docker 环境。QML AOT 和最终链接
可能需要一段时间；先检查 Docker 进程是否仍在运行，不要并发启动第二次构建。

## 5. 连接设备

优先使用 USB：

```bash
ssh root@10.11.99.1
```

首次连接时，用户应在交互式终端亲自输入设备显示的随机密码。后续无人值守工作
只使用用户自行安装的主机公钥。不要使用 `sshpass`、密码环境变量、
`StrictHostKeyChecking=no` 或包含密码的命令行。

Wi-Fi SSH 默认关闭。只有用户已经明确启用并提供当前地址时，才设置：

```bash
MOVE_HOST=root@DEVICE_IP
```

不要把某次设备地址写死到仓库或文档。

## 6. 安装 1.5.0

安装器会停止当前应用、短暂替换应用目录和 AppLoad 入口，并通过 XOVI drop-in
恢复持久启动。它会短暂把根分区重新挂载为可写；这是高影响操作，Agent 必须在
执行前向用户说明并取得同意。

USB 安装：

```bash
MOVE_HOST=root@10.11.99.1 ./scripts/install-weread-qt-appload.sh
```

经用户批准的 Wi-Fi 安装：

```bash
MOVE_HOST=root@DEVICE_IP ./scripts/install-weread-qt-appload.sh
```

安装器先上传到 `/home/root/weread-qt.installing`，再原子切换；上一版程序保存在
`/home/root/weread-qt.previous`，上一版 AppLoad 入口保存在相邻 `.previous`
目录。后续步骤失败时脚本会恢复上一版和 Xochitl。

严禁删除：

```text
/home/root/.local/share/rm-weread/
```

该目录中的账号、书籍缓存、阅读进度、批注、自由笔迹和
`baidu-ocr.json` 都应在升级后保留。升级 1.5.0 不要求重新绑定百度 OCR。

## 7. 真机验证

先验证不包含用户内容的状态：

```bash
MOVE_HOST=root@10.11.99.1 ./scripts/verify-weread-qt-device.sh
```

然后在真实正文页由用户验证：

1. AppLoad 只出现一个“微信读书”入口，能够一次打开。
2. 原账号、书架、阅读位置和原有笔迹仍在。
3. 拼音候选可以点“上页/下页”。
4. 手写输入法能完整书写，点“识别”后才请求百度 OCR。
5. 阅读页可分别选择颜色、荧光笔和自由写；连续书写不会中途刷新或断笔。
6. 点一块相邻笔迹后可直接 OCR，不出现旧的全屏识别窗口。
7. 手掌接触页面时不会翻页，页脚不会被正文覆盖。
8. 退出应用后 Xochitl 正常恢复。

不要用封面、版权页或章节标题页判断正文分页，也不要把静态测试通过当成笔延迟
和电子纸刷新已经通过。

## 8. 百度 OCR 配置

已有配置应自动保留。尚未配置时，Agent 只负责指导用户阅读
`docs/baidu-ocr-configuration-flow.md`，在百度控制台自行创建应用，并通过设备
“我的 → 百度 OCR → 开启浏览器配置”亲自填写 API Key 和 Secret Key。

Agent 不得让用户把凭据发进聊天，不得把凭据写入 `.env` 后上传设备，也不得通过
SSH、命令行参数或调试日志验证真实密钥。

## 9. 回滚与恢复

安装器失败会自动回滚。如果应用进程退出但系统界面没有恢复，可执行：

```bash
ssh "$MOVE_HOST" '/home/root/xovi/start || systemctl start xochitl'
```

手动回滚程序目录会影响正在运行的应用，只能在用户授权后按
`docs/troubleshooting.md` 操作。不要通过删除用户数据、退出账号或恢复出厂来处理
输入法、OCR 或笔迹问题。

## 10. Agent 完成升级后的报告

必须分别说明：

- 拉取的 Git 提交和 `VERSION`。
- 本地安全检查、静态测试、shell 检查和 SDK 构建结果。
- 真机上实际验证的项目，尤其是正文页连续手写、候选翻页和退出恢复。
- 没有执行的项目与仍存在的发布阻塞。
- 用户数据目录未被删除，百度凭据未被读取或输出。
