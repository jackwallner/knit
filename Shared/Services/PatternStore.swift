import Foundation

/// Imported pattern PDFs live in Application Support so they survive relaunch
/// and stay out of the user's Files app.
enum PatternStore {
    static var directory: URL {
        URL.applicationSupportDirectory.appending(path: "Patterns", directoryHint: .isDirectory)
    }

    static func url(for file: String) -> URL { directory.appending(path: file) }

    /// Copies a picked PDF in and returns its stored file name.
    static func save(from source: URL) throws -> String {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = UUID().uuidString + ".pdf"
        try FileManager.default.copyItem(at: source, to: url(for: file))
        return file
    }

    static func delete(_ file: String?) {
        guard let file else { return }
        try? FileManager.default.removeItem(at: url(for: file))
    }
}
