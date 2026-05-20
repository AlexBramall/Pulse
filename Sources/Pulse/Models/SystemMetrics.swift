import Foundation

struct SystemMetrics {
    var cpu: CPUMetrics
    var memory: MemoryMetrics
    var battery: BatteryMetrics
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
        battery: BatteryMetrics(
            percentage: 84,
            isCharging: true,
            health: 91,
            cycleCount: 312,
            cpuTemp: nil,
            gpuTemp: nil,
            fanRPM: nil,
            isOnACPower: true
        ),
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

enum MemoryPressure: String {
    case normal   = "Normal"
    case elevated = "Elevated"
    case critical = "Critical"
}

struct BatteryMetrics {
    var percentage: Int
    var isCharging: Bool
    var health: Int                 // 0–100
    var cycleCount: Int
    var cpuTemp: Double?            // °C, nil until M3
    var gpuTemp: Double?            // °C, nil until M3
    var fanRPM: Int?                // nil on fanless Macs
    var isOnACPower: Bool
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
