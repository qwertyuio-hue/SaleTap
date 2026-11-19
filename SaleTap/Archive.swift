//
//  Archive.swift
//  SaleTap
//
//  压缩包读取。支持 zip / 7z / tar / gz / xz。
//

import Foundation
import SWCompression

struct ArchiveItem: Identifiable {
    let id = UUID()
    let path: String
    let isDirectory: Bool
    let size: Int
    let data: Data?
}

enum ArchiveKind {
    case zip
    case sevenZip
    case tar
    case gzip
    case xz
    case unknown
}

enum ArchiveError: LocalizedError {
    case unsupported
    case empty
    case badEntry(String)

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "这个格式不认识，目前支持 zip、7z、tar、gz、xz"
        case .empty:
            return "包里是空的"
        case .badEntry(let name):
            return "条目路径不合法：\(name)"
        }
    }
}

struct ArchiveReader {

    static func kind(of url: URL) -> ArchiveKind {
        switch url.pathExtension.lowercased() {
        case "zip": return .zip
        case "7z": return .sevenZip
        case "tar": return .tar
        case "gz", "gzip", "tgz": return .gzip
        case "xz", "txz": return .xz
        default: return .unknown
        }
    }

    /// 读出整包内容。小文件没问题，大包会比较吃内存。
    static func entries(of url: URL) throws -> [ArchiveItem] {
        let data = try Data(contentsOf: url)
        let items: [ArchiveItem]

        switch kind(of: url) {
        case .zip:
            items = map(try ZipContainer.open(container: data))
        case .sevenZip:
            items = map(try SevenZipContainer.open(container: data))
        case .tar:
            items = map(try TarContainer.open(container: data))
        case .gzip:
            let out = try GzipArchive.unarchive(archive: data)
            items = [ArchiveItem(path: baseName(of: url), isDirectory: false, size: out.count, data: out)]
        case .xz:
            let out = try XZArchive.unarchive(archive: data)
            items = [ArchiveItem(path: baseName(of: url), isDirectory: false, size: out.count, data: out)]
        case .unknown:
            throw ArchiveError.unsupported
        }

        if items.isEmpty { throw ArchiveError.empty }
        return items
    }

    /// 解压到指定目录，返回写出的文件数。
    @discardableResult
    static func extract(_ items: [ArchiveItem], to directory: URL) throws -> Int {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)

        var count = 0
        for item in items {
            let cleaned = sanitize(item.path)
            guard !cleaned.isEmpty else { throw ArchiveError.badEntry(item.path) }
            let target = directory.appendingPathComponent(cleaned)

            if item.isDirectory {
                try fm.createDirectory(at: target, withIntermediateDirectories: true)
                continue
            }

            try fm.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            if let payload = item.data {
                try payload.write(to: target, options: .atomic)
                count += 1
            }
        }
        return count
    }

    // MARK: - 私有

    private static func baseName(of url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }

    private static func map<Entry: ContainerEntry>(_ entries: [Entry]) -> [ArchiveItem] {
        entries.map { entry in
            let name = entry.info.name
            let directory = name.hasSuffix("/") || entry.data == nil
            return ArchiveItem(
                path: name,
                isDirectory: directory,
                size: entry.info.size ?? entry.data?.count ?? 0,
                data: entry.data
            )
        }
    }

    private static func sanitize(_ path: String) -> String {
        let parts = path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
            .filter { $0 != "." && $0 != ".." }
        return parts.joined(separator: "/")
    }
}
