# SaleTap

一个按钮的 iOS App：点一下，在 App 内打开你的卖货网站（SFSafariViewController，不用跳出 App）。

**没有 Mac 也能编译出 IPA** —— 见下面「云端编译」。

## 改链接

打开 `SaleTap/Config.swift`，改这一行：

```swift
static let storeURL = "https://你的网址"
```

同一个文件里还能改标题、副标题、按钮文字和配色。

## 云端编译（不需要 Mac）

仓库里已经放好 `.github/workflows/build.yml`。把整个 `switapp` 文件夹推到 GitHub，它就会在 GitHub 的 macOS 机器上自动编译。

1. 在 GitHub 新建一个仓库（Private 也可以）。
2. 把本文件夹的所有内容推上去。
   - 有电脑：`git init && git add . && git commit -m init && git remote add origin <仓库地址> && git push -u origin main`
   - 只有手机：在 GitHub 网页里用 **Add file → Upload files**，一次把文件拖/传上去。注意 `.github/workflows/` 是隐藏目录，网页上传要先手动建这个路径，或者干脆用 GitHub App 传。
3. 推送后自动开始跑。仓库 → **Actions** → 左边选 **Build IPA** → 点最新那次运行。
4. 页面底部 **Artifacts** 里下载 `SaleTap-unsigned-ipa`。手机上下载会得到一个 zip，解压就是 `SaleTap-unsigned.ipa`。

> 这是**未签名**的 IPA。iOS 不认未签名的包，要装必须再签一次名 —— 见下一节。

## 签名与安装（这一步绕不开）

| 你手上有什么 | 怎么装 |
| --- | --- |
| 一台电脑（Win/Mac 都行） | 用 [Sideloadly](https://sideloadly.io) 或 AltStore，拿你的 Apple ID 免费签，拖进 iPhone 就行。缺点：7 天过期要重签 |
| 一张签名证书（.p12 + 描述文件） | 手机上用轻松签 / Esign 之类直接签，签完点安装 |
| 苹果开发者账号（$99/年） | 用 `build-signed.yml`，配好 Secrets 直接出签名好的 IPA，还能走 TestFlight 装上，不用管 7 天过期 |

### 想用 build-signed.yml

在仓库 **Settings → Secrets and variables → Actions** 里加这几个：

| Secret | 内容 |
| --- | --- |
| `BUILD_CERTIFICATE_BASE64` | 证书 .p12 转 base64：`base64 -i cert.p12 \| pbcopy` |
| `P12_PASSWORD` | 导出 .p12 时设的密码 |
| `PROVISIONING_PROFILE_BASE64` | 描述文件 .mobileprovision 转 base64 |
| `TEAM_ID` | 开发者账号的 Team ID（10 位） |
| `EXPORT_METHOD` | `development` / `ad-hoc` / `app-store`，可不填，默认 development |

配好后 Actions → **Build signed IPA** → Run workflow。

> `ad-hoc` 和 `app-store` 方式的描述文件里必须包含你的设备 UDID（ad-hoc）或者能上架（app-store）。

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `SaleTap/SaleTapApp.swift` | App 入口 |
| `SaleTap/Config.swift` | 网址、文案、配色，只改这里 |
| `SaleTap/ContentView.swift` | 界面 + 按钮 + 内置浏览器 |
| `SaleTap.xcodeproj` | Xcode 工程，已带共享 scheme（CI 要用） |
| `.github/workflows/build.yml` | 云端编译出未签名 IPA |
| `.github/workflows/build-signed.yml` | 云端编译 + 签名（需要证书） |
