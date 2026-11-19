//
//  Config.swift
//  SaleTap
//
//  这里是你唯一需要改的地方。
//

import SwiftUI

enum Config {

    // MARK: - 卖货网站

    /// 点按钮后打开的网站。换成你自己的链接，必须是完整地址（带 https://）。
    static let storeURL = "https://example.com"

    // MARK: - 文案

    static let title = "好东西"
    static let subtitle = "点一下，直接进店里看"
    static let buttonTitle = "立即购买"
    static let footnote = "在 App 内打开，随时点左上角关掉"

    // MARK: - 配色

    static let backgroundTop = Color(red: 0.16, green: 0.13, blue: 0.34)
    static let backgroundBottom = Color(red: 0.05, green: 0.04, blue: 0.12)
    static let accent = Color(red: 1.00, green: 0.58, blue: 0.26)
    static let onAccent = Color(red: 0.12, green: 0.07, blue: 0.03)
}
