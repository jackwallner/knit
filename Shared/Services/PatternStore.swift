import Foundation
import PDFKit
import UIKit
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
            guard let data = try? Data(contentsOf: source), let page = page(from: data) else { throw CocoaError(.fileReadCorruptFile) }
            return try save(pages: [page])
        }
        guard PDFDocument(url: source) != nil else { throw CocoaError(.fileReadCorruptFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = UUID().uuidString + ".pdf"
        try FileManager.default.copyItem(at: source, to: url(for: file))
        return file
    }

    /// A picture at reading size and the right way up, as JPEG. A camera photo is far larger than a
    /// page needs, and twenty of them at full size would run the phone out of memory.
    /// The cut is by area, not by the long side, so a tall screenshot of a chart keeps a width that reads.
    nonisolated static func page(from data: Data, pixels: CGFloat = 1650 * 2200) -> Data? {
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else { return nil }
        let scale = min(1, (pixels / (image.size.width * image.size.height)).squareRoot())
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        // Drawing bakes in the camera's orientation, which a PDF page would otherwise drop.
        return UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.8) { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Binds pictures (JPEG, from `page(from:)`) into one PDF, a page each, and returns its stored file name.
    /// Each picture goes into the file as the JPEG it already is, one at a time, so neither the file nor the
    /// memory in use grows past what the pages need.
    static func save(pages: [Data]) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = UUID().uuidString + ".pdf"
        var written = 0
        try UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)).writePDF(to: url(for: file)) { context in
            for data in pages {
                guard let provider = CGDataProvider(data: data as CFData),
                      let image = CGImage(jpegDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { continue }
                // A letter page's width in points, whatever the photo's pixels: the row band is sized in points,
                // and on a page thousands of points tall it would be a hairline.
                let bounds = CGRect(x: 0, y: 0, width: 612, height: (612 * Double(image.height) / Double(image.width)).rounded())
                context.beginPage(withBounds: bounds, pageInfo: [:])
                // Core Graphics draws images bottom up; the page is laid out top down.
                context.cgContext.translateBy(x: 0, y: bounds.height)
                context.cgContext.scaleBy(x: 1, y: -1)
                context.cgContext.draw(image, in: bounds)
                written += 1
            }
        }
        guard written > 0 else {
            delete(file)
            throw CocoaError(.fileReadCorruptFile)
        }
        return file
    }

    static func save(pages: [UIImage]) throws -> String {
        try save(pages: pages.compactMap { $0.jpegData(compressionQuality: 0.9) }.compactMap { page(from: $0) })
    }

    static func delete(_ file: String?) {
        guard let file else { return }
        try? FileManager.default.removeItem(at: url(for: file))
    }
}
