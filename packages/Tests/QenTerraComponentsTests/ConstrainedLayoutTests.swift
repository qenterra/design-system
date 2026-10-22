#if os(macOS)
import AppKit
import SwiftUI
import Testing
import QenTerraComponents

@MainActor
@Suite("Constrained shared layouts", .serialized)
struct ConstrainedLayoutTests {
    @Test(arguments: [CGFloat(0), 40, 100])
    func flowMeasuresAndPlacesWrappingChildrenWithinTheProposal(width: CGFloat) {
        let observation = FlowObservation()
        let host = NSHostingView(rootView:
            DesignFlowLayout(horizontalSpacing: 8, verticalSpacing: 6) {
                WrappingProbe(idealWidth: 240, observation: observation) { Color.clear }
                Color.clear.frame(width: 20, height: 10)
            }
            .frame(width: width, alignment: .leading)
        )
        host.frame = CGRect(x: 0, y: 0, width: width, height: 300)
        host.layoutSubtreeIfNeeded()

        #expect(observation.placedSize?.width == width)
        #expect(observation.placementProposal?.width == width)
        if width > 0 {
            #expect(observation.placedSize?.height == ceil(240 / width) * 20)
        }
        #expect(host.fittingSize.height == (width > 0 ? ceil(240 / width) * 20 + 16 : 36))
    }

    @Test func flowWrapsLongLocalizedTextVertically() {
        let host = NSHostingView(rootView:
            DesignFlowLayout {
                Text("A much longer localized destination that must wrap across several lines")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 80)
        )
        host.frame = CGRect(x: 0, y: 0, width: 80, height: 300)
        host.layoutSubtreeIfNeeded()
        #expect(host.fittingSize.height > 60)
    }

    @Test func flowReportsTheActualWidthOfAChildThatRefusesCompression() {
        let arrangement = DesignFlowLayout.arrangement(
            sizes: [CGSize(width: 240, height: 20), CGSize(width: 20, height: 10)],
            proposalWidth: 80,
            horizontalSpacing: 8,
            verticalSpacing: 6
        )
        #expect(arrangement.size == CGSize(width: 240, height: 36))
        #expect(arrangement.origins == [.zero, CGPoint(x: 0, y: 26)])
    }

    @Test(arguments: [false, true])
    func shortRailCanScrollEveryDestinationAndFooterIntoTheViewport(expanded: Bool) throws {
        let observation = RailObservation()
        let host = NSHostingView(rootView:
            rail(expanded: expanded)
                .overlayPreferenceValue(NavigationRailItemBoundsKey<Int>.self) { anchors in
                    GeometryReader { geometry in
                        let _ = { observation.frames = anchors.mapValues { geometry[$0] } }()
                        Color.clear.allowsHitTesting(false)
                    }
                }
        )
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: expanded ? 216 : 64, height: 200),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.contentView = host
        host.frame = CGRect(x: 0, y: 0, width: expanded ? 216 : 64, height: 200)
        host.layoutSubtreeIfNeeded()
        defer { window.contentView = nil }

        let scroll = try #require(descendants(of: host).compactMap { $0 as? NSScrollView }.first)
        let document = try #require(scroll.documentView)
        #expect(document.bounds.height >= 648)
        #expect(scroll.contentView.bounds.height <= 200)
        let initialDestination = try #require(observation.frames[0])
        let initialFooter = try #require(observation.frames[10])
        #expect(initialDestination.height == 48)
        #expect(initialDestination.minY >= 0 && initialDestination.maxY <= 200)
        #expect(initialFooter.minY > 200)
        document.scroll(CGPoint(x: 0, y: document.bounds.height))
        scroll.reflectScrolledClipView(scroll.contentView)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
        host.layoutSubtreeIfNeeded()
        #expect(scroll.contentView.bounds.maxY >= document.bounds.maxY - 1)
        let visibleFooter = try #require(observation.frames[10])
        #expect(visibleFooter.minY >= 0 && visibleFooter.maxY <= 200)
        #expect(try #require(observation.frames[0]).maxY < 0)
        document.scroll(.zero)
        scroll.reflectScrolledClipView(scroll.contentView)
        #expect(scroll.contentView.bounds.minY == 0)
    }

    @Test(arguments: [false, true])
    func tallRailKeepsFooterAtTheBottomWithoutOverflow(expanded: Bool) throws {
        let host = NSHostingView(rootView: rail(expanded: expanded))
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: expanded ? 216 : 64, height: 900),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.contentView = host
        host.frame = CGRect(x: 0, y: 0, width: expanded ? 216 : 64, height: 900)
        host.layoutSubtreeIfNeeded()
        defer { window.contentView = nil }
        let scroll = try #require(descendants(of: host).compactMap { $0 as? NSScrollView }.first)
        let document = try #require(scroll.documentView)
        #expect(abs(document.bounds.height - scroll.contentView.bounds.height) <= 1)
    }

    private func rail(expanded: Bool) -> some View {
        NavigationRail(
            items: (0..<10).map { NavigationRailItem(id: $0, title: "Destination \($0)", symbol: "music.note") },
            selection: .constant(0),
            footerItems: [NavigationRailItem(id: 10, title: "Settings", symbol: "gearshape")],
            expansion: .constant(expanded),
            expansionConfiguration: .init(
                expandedTitle: "Collapse", collapsedTitle: "Expand",
                expandedSymbol: "sidebar.left", collapsedSymbol: "sidebar.right",
                expandedHint: "Collapse navigation", collapsedHint: "Expand navigation"
            ),
            presentation: .cadence
        )
    }

    private func descendants(of view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }
}

@MainActor
private final class FlowObservation {
    var placedSize: CGSize?
    var placementProposal: ProposedViewSize?
}

@MainActor
private final class RailObservation {
    var frames: [Int: CGRect] = [:]
}

private struct WrappingProbe: Layout {
    let idealWidth: CGFloat
    let observation: FlowObservation

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = min(idealWidth, max(0, proposal.width ?? idealWidth))
        return CGSize(width: width, height: width > 0 ? ceil(idealWidth / width) * 20 : 20)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        MainActor.assumeIsolated {
            observation.placedSize = bounds.size
            observation.placementProposal = proposal
        }
        for subview in subviews {
            subview.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
        }
    }
}
#endif
