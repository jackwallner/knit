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
        // Leaving the app is the other way out of the reader: the place is kept then too.
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.leaving), name: UIApplication.willResignActiveNotification, object: nil)
        context.coordinator.view = view
        context.coordinator.load(url, into: view)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        context.coordinator.project = project
        if view.document?.documentURL != url { context.coordinator.load(url, into: view) }
        context.coordinator.recolor()
        context.coordinator.step()
    }

    static func dismantleUIView(_ view: PDFView, coordinator: Coordinator) {
        coordinator.keepPlace(in: view)
    }

    @MainActor
    final class Coordinator: NSObject {
        var project: Project
        /// True while the document is loading, so its first-page notification does not overwrite the saved page.
        private var restoring = false
        private var band: PDFAnnotation?
        weak var view: PDFView?

        init(project: Project) { self.project = project }

        @objc func leaving() { if let view { keepPlace(in: view) } }

        /// Writes down the zoom and the point of the page at the top of the screen, so the pattern reopens
        /// exactly where it was put down. A page still at fit-to-width is kept as that, for any screen.
        func keepPlace(in view: PDFView) {
            guard !restoring, view.document != nil, project.modelContext != nil, !project.isDeleted else { return }
            let fit = view.scaleFactorForSizeToFit
            project.readerZoom = fit > 0 && abs(view.scaleFactor - fit) / fit > 0.02 ? view.scaleFactor : 0
            if let place = view.currentDestination, let page = place.page, let index = view.document?.index(for: page) {
                project.patternPage = index
                project.readerX = place.point.x
                project.readerY = place.point.y
            }
        }

        /// Moves the band to where the count puts it, when it steps with the count.
        func step() {
            guard let band, let page = band.page, project.markPage >= 0 else { return }
            let box = page.bounds(for: .cropBox)
            let y = min(max(project.bandY, box.minY), box.maxY - project.markHeight)
            if abs(band.bounds.minY - y) > 0.5 { band.bounds = CGRect(x: box.minX, y: y, width: box.width, height: project.markHeight) }
        }

        func load(_ url: URL, into view: PDFView) {
            let document = PDFDocument(url: url)
            let start = project.patternPage
            restoring = true
            band = nil
            view.document = document
            if let document, project.markPage >= 0, project.markPage < document.pageCount, let page = document.page(at: project.markPage) {
                place(on: page, y: project.markY, height: project.markHeight)
                step()
            }
            let zoom = project.readerZoom
            let point = CGPoint(x: project.readerX, y: project.readerY)
            // Jump after layout, or PDFKit snaps back to the first page.
            DispatchQueue.main.async { [self] in
                if zoom > 0 { view.scaleFactor = min(max(zoom, view.minScaleFactor), view.maxScaleFactor) }
                if let document, start < document.pageCount, let target = document.page(at: max(start, 0)) {
                    // The same zoom and the same spot on the page, or the top of the page it was left on.
                    if point != .zero { view.go(to: PDFDestination(page: target, at: point)) } else if start > 0 { view.go(to: target) }
                }
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
            if project.markPage == index, abs(project.bandY - y) < 1 {
                clear()
                return
            }
            place(on: page, y: y, height: height)
            project.markPage = index
            project.markY = y
            project.markHeight = height
            // A band laid by hand counts its steps from this row.
            project.markRow = project.rows
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
