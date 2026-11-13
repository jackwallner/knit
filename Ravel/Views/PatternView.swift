import PDFKit
import SwiftUI

/// The pattern PDF. Reopens on the page the knitter left off at, and a tap lays
/// a band across the row being worked, like the ruler on a chart keeper.
struct PatternView: UIViewRepresentable {
    let url: URL
    @Bindable var project: Project

    func makeCoordinator() -> Coordinator { Coordinator(project: project) }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor(Theme.paper)
        view.pageShadowsEnabled = false
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.pageChanged(_:)), name: .PDFViewPageChanged, object: view)
        context.coordinator.load(url, into: view)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        context.coordinator.project = project
        if view.document?.documentURL != url { context.coordinator.load(url, into: view) }
        context.coordinator.recolor()
    }

    @MainActor
    final class Coordinator: NSObject {
        var project: Project
        /// True while the document is loading, so its first-page notification does not overwrite the saved page.
        private var restoring = false
        private var band: PDFAnnotation?

        init(project: Project) { self.project = project }

        func load(_ url: URL, into view: PDFView) {
            let document = PDFDocument(url: url)
            let start = project.patternPage
            restoring = true
            band = nil
            view.document = document
            if let document, project.markPage >= 0, project.markPage < document.pageCount, let page = document.page(at: project.markPage) {
                place(on: page, y: project.markY, height: project.markHeight)
            }
            // Jump after layout, or PDFKit snaps back to the first page.
            DispatchQueue.main.async { [self] in
                if let document, start > 0, start < document.pageCount, let target = document.page(at: start) { view.go(to: target) }
                restoring = false
            }
        }

        @objc func pageChanged(_ note: Notification) {
            guard !restoring, let view = note.object as? PDFView, let current = view.currentPage, let index = view.document?.index(for: current) else { return }
            if project.patternPage != index { project.patternPage = index }
        }

        @objc func tapped(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? PDFView, let page = view.page(for: gesture.location(in: view), nearest: false), let index = view.document?.index(for: page) else { return }
            let point = view.convert(gesture.location(in: view), to: page)
            // Snap to the line of text under the finger; on a chart, mark where the finger landed.
            let selection = page.selectionForLine(at: point)
            var line = selection?.bounds(for: page)
            // With tight leading PDFKit merges neighbouring lines into one block. Then mark the line under the finger.
            if let block = line, let text = selection?.attributedString, text.length > 0,
               let size = (text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)?.pointSize, block.height > size * 1.8 {
                line = CGRect(x: block.minX, y: point.y - size * 0.6, width: block.width, height: size * 1.2)
            }
            let height = max((line?.height ?? 12) + 4, 14)
            let y = (line?.midY ?? point.y) - height / 2
            if project.markPage == index, abs(project.markY - y) < 1 {
                clear()
                return
            }
            place(on: page, y: y, height: height)
            project.markPage = index
            project.markY = y
            project.markHeight = height
        }

        private func place(on page: PDFPage, y: Double, height: Double) {
            band?.page?.removeAnnotation(band!)
            let box = page.bounds(for: .cropBox)
            let annotation = PDFAnnotation(bounds: CGRect(x: box.minX, y: y, width: box.width, height: height), forType: .highlight, withProperties: nil)
            annotation.color = project.color.uiColor.withAlphaComponent(0.3)
            page.addAnnotation(annotation)
            band = annotation
        }

        private func clear() {
            if let band { band.page?.removeAnnotation(band) }
            band = nil
            project.markPage = -1
        }

        func recolor() {
            band?.color = project.color.uiColor.withAlphaComponent(0.3)
        }
    }
}
