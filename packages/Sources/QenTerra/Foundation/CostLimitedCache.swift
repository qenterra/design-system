/// A deterministic least-recently-used cache bounded by entry count and caller-supplied cost.
/// Values and identity remain caller-owned; this value type provides no synchronization.
public struct CostLimitedCache<Key: Hashable, Value> {
    private struct Entry {
        let value: Value
        let cost: Int
    }

    public let countLimit: Int
    public let totalCostLimit: Int
    public private(set) var totalCost = 0
    private var entries: [Key: Entry] = [:]
    private var recency: [Key] = []

    public init(countLimit: Int, totalCostLimit: Int) {
        self.countLimit = max(countLimit, 1)
        self.totalCostLimit = max(totalCostLimit, 1)
    }

    public var count: Int {
        entries.count
    }

    public var isEmpty: Bool {
        entries.isEmpty
    }

    public mutating func value(forKey key: Key) -> Value? {
        guard let entry = entries[key] else { return nil }
        recency.removeAll { $0 == key }
        recency.append(key)
        return entry.value
    }

    /// Replaces the old value. Oversized values are not retained; negative costs are treated as zero.
    public mutating func insert(_ value: Value, forKey key: Key, cost: Int) {
        removeValue(forKey: key)
        let cost = max(cost, 0)
        guard cost <= totalCostLimit else { return }
        // Evict before addition so even Int.max budgets cannot overflow the accounting.
        while entries.count >= countLimit || totalCost > totalCostLimit - cost {
            guard let oldest = recency.first else { break }
            removeValue(forKey: oldest)
        }
        entries[key] = Entry(value: value, cost: cost)
        recency.append(key)
        totalCost += cost
    }

    public mutating func removeValue(forKey key: Key) {
        guard let entry = entries.removeValue(forKey: key) else { return }
        recency.removeAll { $0 == key }
        totalCost -= entry.cost
    }

    public mutating func removeAll(where predicate: (Key) -> Bool) {
        for key in entries.keys.filter(predicate) {
            removeValue(forKey: key)
        }
    }

    public mutating func removeAll() {
        entries.removeAll(keepingCapacity: true)
        recency.removeAll(keepingCapacity: true)
        totalCost = 0
    }
}
