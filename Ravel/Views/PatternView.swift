import PDFKit
import SwiftUI

/// The pattern PDF. Reopens on the page the knitter left off at.
struct PatternView: UIViewRepresentable {
    let url: URL
    @Binding var page: Int

    func makeCoordinator() -> Coordinator { Coordinator(page: $page) }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .systemGroupedBackground
        load(url, into: view, coordinator: context.coordinator)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.pageChanged(_:)), name: .PDFViewPageChanged, object: view)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        context.coordinator.page = $page
        if view.document?.documentURL != url { load(url, into: view, coordinator: context.coordinator) }
    }

    private func load(_ url: URL, into view: PDFView, coordinator: Coordinator) {
        let document = PDFDocument(url: url)
        let start = page
        coordinator.restoring = true
        view.document = document
        // Jump after layout, or PDFKit snaps back to the first page.
        DispatchQueue.main.async {
            if let document, start > 0, start < document.pageCount, let target = document.page(at: start) { view.go(to: target) }
            coordinator.restoring = false
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var page: Binding<Int>
        /// True while the document is loading, so its first-page notification does not overwrite the saved page.
        var restoring = false

        init(page: Binding<Int>) { self.page = page }

        @objc func pageChanged(_ note: Notification) {
            guard !restoring, let view = note.object as? PDFView, let current = view.currentPage, let index = view.document?.index(for: current) else { return }
            if page.wrappedValue != index { page.wrappedValue = index }
        }
    }
}
