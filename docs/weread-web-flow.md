# 微信读书 Web Reader 接口路线

这个文档记录当前可用的技术路径，目标是支撑 Move 上的直接阅读，不做公开批量导出工具。

## 两类接口

### 官方 Skill/Gateway

OpenCLI 的 `weread-official` adapter 走的是官方 API key：

```text
WEREAD_API_KEY=wrk-...
```

适合：

- 搜索
- 书架
- 书籍元数据
- 笔记和划线
- 阅读数据
- 推荐/发现

不适合：

- 完整章节正文
- Web Reader XHTML/CSS 分片

### Web Reader Cookie 接口

完整正文来自 `weread.qq.com` Web Reader，需要当前账号的 Web 登录态。

已观察到的关键接口：

```text
POST /web/login/renewal
POST /web/book/chapterInfos
POST /web/book/outline
POST /web/book/chapter/e_0
POST /web/book/chapter/e_1
POST /web/book/chapter/e_2
POST /web/book/chapter/e_3
GET  /web/book/readInfo
GET  /web/book/bookmarklist
GET  /web/book/underlines
GET  /web/review/list
```

## 正文获取流程

1. 打开 Reader URL：

```text
https://weread.qq.com/web/reader/{bookHash}
```

2. 从页面初始状态或接口里取：

```text
bookId
chapterUid
reader.psvts
```

3. 用微信读书的 `_e()` 算法生成：

```text
b = _e(bookId)
c = _e(chapterUid)
pc = _e(currentUnixTimestamp)
```

4. 构造请求体：

```json
{
  "b": "_e(bookId)",
  "c": "_e(chapterUid)",
  "r": "randomSquare",
  "st": 0,
  "ct": "currentUnixTimestamp",
  "ps": "reader.psvts",
  "pc": "_e(currentUnixTimestamp)",
  "sc": 1,
  "prevChapter": false,
  "s": "signature"
}
```

5. 请求分片：

```text
e_0, e_1, e_3 -> XHTML 内容分片
e_2           -> CSS，st=1
```

6. 校验并解码：

- 返回体前 32 字符是 MD5 校验。
- `e_0/e_1/e_3` 拼接后解码为 XHTML。
- `e_2` 单独解码为 CSS。
- TXT 格式书籍可能需要回退到 `t_0/t_1`。

## 关键注意点

- `sc=1` 是完整正文的关键；`sc=0` 可能只返回预览。
- `pc` 不能和 `ps` 相同，否则可能返回 `{}`。
- `e_2` CSS 请求需要 `st=1`。
- 请求要带 `Origin`、`Referer`、`Cookie`。
- 续期接口是：

```text
POST https://weread.qq.com/web/login/renewal
```

请求体：

```json
{"rq":"%2Fweb%2Fbook%2Fread","ql":false}
```

成功时返回类似：

```json
{"succ":1}
```

## 现有上游实现位置

```text
third_party/weread.koplugin/lib/weread.lua
  _e()、sign()、reader_url()、content params

third_party/weread.koplugin/lib/content.lua
  chapterInfos、e_0/e_1/e_2/e_3、解码、EPUB/HTML 生成、资源打包

third_party/weread.koplugin/lib/client.lua
  HTTP 客户端、cookie 续期、官方 API key 请求

third_party/weread.koplugin/lib/cookie.lua
  cURL/cookie 解析
```

## 扫码登录待办

已在 Web 前端里看到二维码登录相关路径痕迹：

```text
/web/login/getuid
/web/login/getinfo
/web/login/wxCode
/web/login/session/init
```

待验证：

- `getuid` 的准确请求方法和参数。
- `getinfo` 的轮询间隔、状态码和字段。
- `wxCode` 和 `session/init` 哪个是当前 Web 实际使用的最终建连接口。
- Move 端二维码显示方案：KOReader 内显示 PNG/SVG，或临时 HTML/图片。

