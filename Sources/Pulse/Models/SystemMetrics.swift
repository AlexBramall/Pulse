import Foundation

struct SystemMetrics {
    var cpu: CPUMetrics
    var memory: MemoryMetrics
    var gpu: GPUMetrics
    var disk: DiskMetrics
}

extension SystemMetrics {
    static let placeholder = SystemMetrics(
        cpu: CPUMetrics(
            usage: 0.34,
            topProcesses: [
                ProcessStat(name: "Xcode", value: 28.0),
                ProcessStat(name: "Slack", value: 6.0),
                ProcessStat(name: "Chrome", value: 4.0)
            ],
            sustained: false
        ),
        memory: MemoryMetrics(
            used: 11.2,
            total: 16.0,
            pressure: .normal,
            topProcesses: [
                ProcessStat(name: "Chrome", value: 3800),
                ProcessStat(name: "Xcode", value: 2100),
                ProcessStat(name: "Slack", value: 800)
            ],
            swapUsed: 0
        ),
        gpu: GPUMetrics(usage: 0.22, memoryUsed: 1.4, thermalState: .nominal, sustained: false),
        disk: DiskMetrics(used: 241, total: 512)
    )
}

struct CPUMetrics {
    var usage: Double               // 0.0–1.0
    var topProcesses: [ProcessStat]
    var sustained: Bool
}

struct MemoryMetrics {
    var used: Double                // GB
    var total: Double               // GB
    var pressure: MemoryPressure
    var topProcesses: [ProcessStat]
    var swapUsed: Double            // GB

    var usageRatio: Double { total > 0 ? used / total : 0 }
    var free: Double { total - used }
}

enum Severity {
    case normal, warning, danger
}

enum MemoryPressure: String {
    case normal   = "Normal"
    case elevated = "Elevated"
    case critical = "Critical"

    var severity: Severity {
        switch self {
        case .normal:   return .normal
        case .elevated: return .warning
        case .critical: return .danger
        }
    }
}

extension CPUMetrics {
    var severity: Severity {
        if sustained { return .danger }
        return usage > SustainedLoadTracker.threshold ? .warning : .normal
    }
}

struct GPUMetrics {
    var usage: Double               // 0.0–1.0, Device Utilization
    var memoryUsed: Double          // GB
    var thermalState: ProcessInfo.ThermalState
    var sustained: Bool

    var isThrottling: Bool { thermalState == .serious || thermalState == .critical }

    var status: GPUStatus {
        if sustained || isThrottling { return .overworked }
        if usage > SustainedLoadTracker.threshold { return .busy }
        return .normal
    }
}

enum GPUStatus: String {
    case normal     = "Normal"
    case busy       = "Busy"
    case overworked = "Overworked"

    var severity: Severity {
        switch self {
        case .normal:     return .normal
        case .busy:       return .warning
        case .overworked: return .danger
        }
    }
}

struct DiskMetrics {
    var used: Double                // GB
    var total: Double               // GB

    var free: Double { total - used }
    var usageRatio: Double { total > 0 ? used / total : 0 }
}

struct ProcessStat: Identifiable {
    let id = UUID()
    var name: String
    var value: Double               // CPU % or Memory MB depending on context
}
