//
//  FilesView.swift
//  SaleTap
//
//  本机文件列表：导入压缩包，点进去看内容。
//

import SwiftUI
import UniformTypeIdentifiers

struct FilesView: View {

    @State private var files: [URL] = []
    @State private var showImporter = false
    @State private var errorMessage: String?

    private var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var body: some View {
        NavigationStack {
            Group {
                if files.isEmpty {
                    placeholder
                } else {
                    list
                }
            }
            .navigationTitle("解压")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showImporter = true
                    } label: {
                        Label("导入", systemImage: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                do {
                    let url = try result.get()
                    try copyIn(url)
                    reload()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            .alert("出错了", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear(perform: reload)
    }

    private var placeholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "archivebox")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.secondary)
            Text("还没有文件")
                .font(.headline)
            Text("点右上角 + 从「文件」里导入 zip、7z、tar、gz 或 xz")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List {
            ForEach(files, id: \.self) { url in
                NavigationLink {
                    ArchiveDetailView(url: url)
                } label: {
                    row(for: url)
                }
            }
            .onDelete(perform: delete)
        }
    }

    private func row(for url: URL) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: url))
                .font(.system(size: 18))
                .foregroundStyle(Config.accent)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(url.lastPathComponent)
                    .font(.body)
                    .lineLimit(1)
                Text(byteText(for: url))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - 动作

    private func reload() {
        let fm = FileManager.default
        let items = (try? fm.contentsOfDirectory(
            at: documents,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        files = items
            .filter { !$0.hasDirectoryPath }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    private func copyIn(_ url: URL) throws {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let target = documents.appendingPathComponent(url.lastPathComponent)
        let fm = FileManager.default
        if fm.fileExists(atPath: target.path) {
            try fm.removeItem(at: target)
        }
        try fm.copyItem(at: url, to: target)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let url = files[index]
            try? FileManager.default.removeItem(at: url)
        }
        reload()
    }

    private func byteText(for url: URL) -> String {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private func icon(for url: URL) -> String {
        switch ArchiveReader.kind(of: url) {
        case .zip: return "doc.zipper"
        case .sevenZip: return "square.stack.3d.up"
        case .tar: return "shippingbox"
        case .gzip, .xz: return "arrow.down.doc"
        case .unknown: return "doc"
        }
    }
}
