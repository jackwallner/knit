import Foundation
import PDFKit
import UniformTypeIdentifiers

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
        // A picture of a pattern is kept as a one-page PDF so the reader and the row band work the same way.
        if UTType(filenameExtension: source.pathExtension)?.conforms(to: .image) == true {
            guard let image = UIImage(contentsOfFile: source.path) else { throw CocoaError(.fileReadCorruptFile) }
            return try save(pages: [image])
        }
        guard PDFDocument(url: source) != nil else { throw CocoaError(.fileReadCorruptFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = UUID().uuidString + ".pdf"
        try FileManager.default.copyItem(at: source, to: url(for: file))
        return file
    }

    /// Binds pictures into one PDF, a page each, and returns its stored file name.
    static func save(pages: [UIImage]) throws -> String {
        let document = PDFDocument()
        for image in pages {
            if let page = PDFPage(image: image) { document.insert(page, at: document.pageCount) }
        }
        guard document.pageCount > 0 else { throw CocoaError(.fileReadCorruptFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = UUID().uuidString + ".pdf"
        guard document.write(to: url(for: file)) else { throw CocoaError(.fileWriteUnknown) }
        return file
    }

    static func delete(_ file: String?) {
        guard let file else { return }
        try? FileManager.default.removeItem(at: url(for: file))
    }
}
