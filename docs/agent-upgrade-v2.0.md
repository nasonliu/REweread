# Agent 升级到 REweread 2.0.0

2.0.0 是非官方、非商用的 source-only 里程碑。开始前完整阅读
`AGENTS.md`、`docs/agent-handoff.md`、本文；不得索取、打印、保存或提交
设备密码、SSH 私钥、百度 OCR/DeepSeek API Key、Cookie 或用户数据。

## 升级步骤

1. 在干净检出中执行 `git pull --ff-only` 拉取目标分支，确认 `VERSION` 为 `2.0.0`。
2. 运行 `node scripts/check-repository.mjs`、`node tests/run-all.mjs` 和 shell
   语法检查；失败时停止，不用跳过验证。
3. 运行 `./scripts/download-reader-fonts.sh` 与
   `./scripts/build-weread-qt.sh`。
4. 仅在用户已授权连接设备时运行
   `MOVE_HOST=root@DEVICE ./scripts/install-weread-qt-appload.sh`；它必须严禁删除
   `/home/root/.local/share/rm-weread/`，并留下 `.previous` 回退目录。安装器会使根分区重新挂载为可写以更新 XOVI drop-in；必须在执行前取得同意。
5. 在真机验证：提问笔迹完全淡出后才出现 AI 回信；回复笔画逐步显现、局部淡出；
   选择人物后询问姓名、时代、背景时回答一致。

## API Key 与配置

API Key 不进 `.env`、终端参数、Git 或聊天记录。用户自行在设备 **我的 →
百度 OCR → 开启浏览器配置** 取得短时配对码后，在手机/电脑 HTTPS 页面中只提交
一个服务：百度 OCR 填 API Key 和 Secret Key；DeepSeek 填 API Key（地址和模型
可保留默认）。每次只改动所提交的服务，另一份已有凭据必须保留。

完整申请、权限、网络、隐私和故障处理见
[百度 OCR 与 DeepSeek 配置指南](baidu-ocr-configuration-flow.md)。
