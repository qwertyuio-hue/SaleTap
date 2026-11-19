//
//  ArchiveDetailView.swift
//  SaleTap
//
//  压缩包内容浏览与解压。
//

import SwiftUI

struct ArchiveDetailView: View {

    let url: URL

    @State private var items: [ArchiveItem] = []
    @State private var loading = true
    @State private var errorMessage: String?
    @State private var extractMessage: String?
    @State private var preview: ArchiveItem?

    var body: some View {
        Group {
            if loading {
                ProgressView("正在读取…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                Text(errorMessage ?? "没有内容")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(32)
            } else {
                content
            }
        }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    extractAll()
                } label: {
                    Label("解压", systemImage: "square.and.arrow.down")
                }
            }
        }
        .task { await load() }
        .alert("解压完成", isPresented: Binding(
            get: { extractMessage != nil },
            set: { if !$0 { extractMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(extractMessage ?? "")
        }
        .sheet(item: $preview) { item in
            TextPreview(path: item.path, text: decode(item.data))
        }
    }

    private var content: some View {
        List {
            Section {
                LabeledContent("条目", value: "\(items.count)")
                LabeledContent("解压后", value: ByteCountFormatter.string(
                    fromByteCount: Int64(items.reduce(0) { $0 + $1.size }), countStyle: .file))
            }

            Section("内容") {
                ForEach(items) { item in
                    Button {
                        if !item.isDirectory, presentable(item) {
                            preview = item
                        }
                    } label: {
                        row(for: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func row(for item: ArchiveItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isDirectory ? "folder" : "doc")
                .foregroundStyle(item.isDirectory ? Config.accent : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.path)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !item.isDirectory {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(item.size), countStyle: .file))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !item.isDirectory, presentable(item) {
                Image(systemName: "eye")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - 逻辑

    private func load() async {
        loading = true
        let target = url
        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try ArchiveReader.entries(of: target)
            }.value
            items = result
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }

    private func extractAll() {
        let target = url
        let snapshot = items
        do {
            let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("解压结果")
                .appendingPathComponent(target.deletingPathExtension().lastPathComponent)

            let count = try ArchiveReader.extract(snapshot, to: folder)
            extractMessage = "写入了 \(count) 个文件，位于「文件」App 的 SaleTap/解压结果/\(target.deletingPathExtension().lastPathComponent)"
        } catch {
            extractMessage = "解压失败：\(error.localizedDescription)"
        }
    }

    private func presentable(_ item: ArchiveItem) -> Bool {
        guard let data = item.data, data.count <= 200_000 else { return false }
        return decode(data) != nil
    }

    private func decode(_ data: Data?) -> String? {
        guard let data else { return nil }
        if let text = String(data: data, encoding: .utf8) { return text }
        return String(data: data, encoding: .isoLatin1)
    }
}

struct TextPreview: View {
    let path: String
    let text: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text ?? "这个文件不是文本")
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .textSelection(.enabled)
            }
            .navigationTitle(path)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
