import Foundation
import Observation
import UIKit

/// Sample photos served from the Ravel site, for designs added after the app shipped: fetched once, kept in
/// the caches folder, and drawn from memory after that. The app never carries them, and a design whose photo
/// has not arrived (offline, or not yet published) draws its garment instead.
@MainActor
@Observable
final class PhotoStore {
    static let shared = PhotoStore()

    /// Photos only ever come from Ravel's own site, at a path the record or design names under `photos/`.
    static let site = URL(string: "https://jackwallner.github.io/knit/")!

    private(set) var images: [String: UIImage] = [:]
    @ObservationIgnored private var loading = Set<String>()
    @ObservationIgnored private let folder: URL

    init(folder: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "Photos")) {
        self.folder = folder
    }

    /// A path a photo may have: `photos/` and a file name of lowercase letters, digits and hyphens.
    static func isAllowed(_ path: String) -> Bool {
        path.range(of: "^photos/[a-z0-9]+(-[a-z0-9]+)*\\.jpg$", options: .regularExpression) != nil
    }

    func image(_ path: String) -> UIImage? { images[path] }

    /// Loads the photo from the cache, or from the site the first time. Failures leave the drawing showing.
    func load(_ path: String) async {
        guard Self.isAllowed(path), images[path] == nil, loading.insert(path).inserted else { return }
        defer { loading.remove(path) }
        let file = folder.appending(path: path.replacingOccurrences(of: "/", with: "_"))
        if let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            images[path] = image
            return
        }
        #if DEBUG
        // `-PhotoRoot docs`: photos from the repository's site folder, before they are published.
        if let root = UserDefaults.standard.string(forKey: "PhotoRoot") {
            let local = (root.hasPrefix("/") ? URL(fileURLWithPath: root) : Self.repository.appending(path: root)).appending(path: path)
            if let data = try? Data(contentsOf: local), let image = UIImage(data: data) { images[path] = image }
            return
        }
        #endif
        var request = URLRequest(url: Self.site.appending(path: path), timeoutInterval: 20)
        request.httpShouldHandleCookies = false
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200, let image = UIImage(data: data) else { return }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
        images[path] = image
    }

    #if DEBUG
    private static let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    #endif
}
