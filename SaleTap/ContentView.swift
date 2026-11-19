//
//  ContentView.swift
//  SaleTap
//
//  一个按钮，点一下进入卖货网站。
//

import SwiftUI
import SafariServices

struct ContentView: View {

    @State private var showSafari = false
    @State private var buttonPressed = false
    @State private var showInvalidURL = false

    private var storeURL: URL? {
        guard let url = URL(string: Config.storeURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else { return nil }
        return url
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer()

                header

                Spacer()

                buyButton

                Text(Config.footnote)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 22)

                Spacer().frame(height: 44)
            }
            .padding(.horizontal, 28)
        }
        .sheet(isPresented: $showSafari) {
            if let storeURL {
                SafariView(url: storeURL)
                    .ignoresSafeArea()
            }
        }
        .alert("链接有问题", isPresented: $showInvalidURL) {
            Button("好", role: .cancel) {}
        } message: {
            Text("Config.swift 里的 storeURL 不是有效的 http/https 地址。")
        }
    }

    // MARK: - 背景

    private var background: some View {
        LinearGradient(
            colors: [Config.backgroundTop, Config.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Config.accent.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 110, y: -140)
        }
        .ignoresSafeArea()
    }

    // MARK: - 标题

    private var header: some View {
        VStack(spacing: 12) {
            Text(Config.title)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(Config.subtitle)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - 按钮

    private var buyButton: some View {
        Button(action: openStore) {
            Text(Config.buttonTitle)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Config.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 68)
                .background(
                    Capsule().fill(Config.accent)
                )
                .overlay(
                    Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Config.accent.opacity(0.45), radius: 22, y: 10)
                .scaleEffect(buttonPressed ? 0.96 : 1)
                .opacity(buttonPressed ? 0.85 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !buttonPressed else { return }
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                        buttonPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        buttonPressed = false
                    }
                }
        )
    }

    // MARK: - 动作

    private func openStore() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        guard storeURL != nil else {
            showInvalidURL = true
            return
        }
        showSafari = true
    }
}

// MARK: - 内置浏览器

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.preferredControlTintColor = UIColor(Config.accent)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - 预览

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
