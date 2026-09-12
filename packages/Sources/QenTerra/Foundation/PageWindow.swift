public enum PagePrefetchDirection {
    case before
    case after
    case none
}

public struct PageWindow<Element> {
    private let pageCapacity: Int
    private var pages: [Int: [Element]] = [:]
    private var recency: [Int] = []

    public init(pageCapacity: Int) {
        self.pageCapacity = max(pageCapacity, 1)
    }

    public var cachedPageCount: Int {
        pages.count
    }

    public var cachedPageIndexes: [Int] {
        recency
    }

    public mutating func item(
        at index: Int,
        pageSize: Int
    ) -> Element? {
        guard index >= 0, pageSize > 0 else {
            return nil
        }
        let page = index / pageSize
        let offset = index % pageSize
        guard let items = pages[page], items.indices.contains(offset) else {
            return nil
        }
        touch(page)
        return items[offset]
    }

    @discardableResult
    public mutating func insert(
        _ items: [Element],
        page: Int
    ) -> Int? {
        guard page >= 0 else {
            return nil
        }
        pages[page] = items
        touch(page)
        var evictedPage: Int?
        while pages.count > pageCapacity, let leastRecent = recency.first {
            pages[leastRecent] = nil
            recency.removeFirst()
            evictedPage = leastRecent
        }
        return evictedPage
    }

    public mutating func removeAll() {
        pages.removeAll(keepingCapacity: true)
        recency.removeAll(keepingCapacity: true)
    }

    public mutating func index(
        where predicate: (Element) -> Bool,
        pageSize: Int
    ) -> Int? {
        guard pageSize > 0 else {
            return nil
        }
        for page in Array(recency.reversed()) {
            guard
                let offset = pages[page]?.firstIndex(where: predicate)
            else {
                continue
            }
            let (start, multiplicationOverflow) = page.multipliedReportingOverflow(by: pageSize)
            let (index, additionOverflow) = start.addingReportingOverflow(offset)
            guard !multiplicationOverflow, !additionOverflow else {
                return nil
            }
            touch(page)
            return index
        }
        return nil
    }

    public mutating func replace(
        where predicate: (Element) -> Bool,
        with replacement: Element
    ) -> Bool {
        for page in pages.keys {
            guard let offset = pages[page]?.firstIndex(where: predicate) else {
                continue
            }
            pages[page]?[offset] = replacement
            touch(page)
            return true
        }
        return false
    }

    private mutating func touch(_ page: Int) {
        recency.removeAll { $0 == page }
        recency.append(page)
    }
}

public struct PageRequestTracker {
    private let pageSize: Int
    private var loadingPages: Set<Int> = []
    private var completedPages: Set<Int> = []

    public init(pageSize: Int) {
        self.pageSize = max(pageSize, 1)
    }

    public func needsRequest(containing row: Int) -> Bool {
        guard row >= 0 else {
            return false
        }
        let page = row / pageSize
        return !loadingPages.contains(page) && !completedPages.contains(page)
    }

    public mutating func beginRequest(
        containing row: Int
    ) -> Int? {
        guard needsRequest(containing: row) else {
            return nil
        }
        let page = row / pageSize
        loadingPages.insert(page)
        return page
    }

    public mutating func finishRequest(page: Int) {
        loadingPages.remove(page)
        completedPages.insert(page)
    }

    public mutating func forgetRequest(page: Int) {
        loadingPages.remove(page)
        completedPages.remove(page)
    }

    public mutating func failRequest(page: Int) {
        loadingPages.remove(page)
    }

    public mutating func invalidate() {
        loadingPages.removeAll(keepingCapacity: true)
        completedPages.removeAll(keepingCapacity: true)
    }
}

public enum PagePrefetchPolicy {
    public static func pages(
        around page: Int,
        pageCount: Int,
        prefetchPages: Int,
        direction: PagePrefetchDirection
    ) -> [Int] {
        guard
            pageCount > 0,
            prefetchPages > 0,
            page >= 0,
            page < pageCount
        else {
            return []
        }
        switch direction {
        case .before:
            let lowerBound = max(page - prefetchPages, 0)
            guard lowerBound < page else {
                return []
            }
            return Array((lowerBound ..< page).reversed())
        case .after:
            let upperBound = page + min(prefetchPages, pageCount - 1 - page)
            guard page < upperBound else {
                return []
            }
            return Array((page + 1) ... upperBound)
        case .none:
            return []
        }
    }

    public static func range(
        visibleRows: ClosedRange<Int>,
        totalCount: Int,
        pageSize: Int,
        prefetchPages: Int
    ) -> ClosedRange<Int>? {
        guard totalCount > 0, pageSize > 0 else {
            return nil
        }
        let lastIndex = totalCount - 1
        let lastPage = lastIndex / pageSize
        let lowerPage = max(visibleRows.lowerBound, 0) / pageSize
        let visibleUpperPage = min(max(visibleRows.upperBound, 0) / pageSize, lastPage)
        let upperPage = visibleUpperPage + min(max(prefetchPages, 0), lastPage - visibleUpperPage)
        let lowerBound = min(lowerPage * pageSize, lastIndex)
        let upperBound = upperPage == lastPage ? lastIndex : (upperPage + 1) * pageSize - 1
        return lowerBound ... upperBound
    }
}
