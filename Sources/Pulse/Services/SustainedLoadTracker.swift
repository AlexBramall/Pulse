import Foundation

struct SustainedLoadTracker {
    private let threshold = 0.85
    private let window: TimeInterval = 60
    private var highSince: Date?

    mutating func update(_ usage: Double, now: Date = Date()) -> Bool {
        guard usage > threshold else {
            highSince = nil
            return false
        }
        if highSince == nil { highSince = now }
        return now.timeIntervalSince(highSince!) > window
    }
}
