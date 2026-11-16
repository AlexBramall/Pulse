import Foundation

struct SustainedLoadTracker {
    static let threshold = 0.85
    private let window: TimeInterval = 60
    private var highSince: Date?

    mutating func update(_ usage: Double, now: Date = Date()) -> Bool {
        guard usage > Self.threshold else {
            highSince = nil
            return false
        }
        let start = highSince ?? now
        highSince = start
        return now.timeIntervalSince(start) > window
    }
}
