#!/usr/bin/env node

const cookie = process.env.WEREAD_COOKIE || "";

if (!cookie.trim()) {
  console.error("Set WEREAD_COOKIE to a WeRead Cookie header string.");
  process.exit(2);
}

const names = cookie
  .split(";")
  .map((part) => part.trim().split("=")[0])
  .filter(Boolean)
  .sort();

const response = await fetch("https://weread.qq.com/web/login/renewal", {
  method: "POST",
  headers: {
    "content-type": "application/json",
    "origin": "https://weread.qq.com",
    "referer": "https://weread.qq.com/",
    "cookie": cookie,
  },
  body: JSON.stringify({ rq: "%2Fweb%2Fbook%2Fread", ql: false }),
});

const text = await response.text();
let body = null;
try {
  body = JSON.parse(text);
} catch {
  body = { rawLength: text.length };
}

const setCookie = response.headers.getSetCookie
  ? response.headers.getSetCookie()
  : response.headers.get("set-cookie");

const renewedNames = Array.isArray(setCookie)
  ? setCookie.map((line) => line.split("=")[0]).filter(Boolean).sort()
  : typeof setCookie === "string"
    ? setCookie.split(",").map((line) => line.trim().split("=")[0]).filter(Boolean).sort()
    : [];

console.log(JSON.stringify({
  ok: response.ok,
  status: response.status,
  requestCookieNames: names,
  response: body,
  renewedCookieNames: renewedNames,
}, null, 2));

