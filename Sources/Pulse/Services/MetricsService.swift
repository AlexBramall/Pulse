import Foundation
import SwiftUI

@MainActor
final class MetricsService: ObservableObject {
    @Published private(set) var current: SystemMetrics = .placeholder

    private let cpu        = CPUMonitor()
    private let memory     = MemoryMonitor()
    private let processes  = ProcessMonitor()
    private let battery    = BatteryMonitor()
    private let disk       = DiskMonitor()

    private var pollingTask: Task<Void, Never>?
    private var sustainedHighStart: Date?
    let pollInterval: TimeInterval = 3.0

    init() {
        // Warm up the CPU delta baseline before the first real sample.
        _ = cpu.sample()
        startPolling()
    }

    func startPolling() {
        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: .seconds(self?.pollInterval ?? 3))
            }
        }
    }

    private func refresh() {
        let cpuUsage = cpu.sample()

        // Track sustained high CPU load
        if cpuUsage > 0.85 {
            if sustainedHighStart == nil { sustainedHighStart = Date() }
        } else {
            sustainedHighStart = nil
        }
        let sustained = sustainedHighStart.map { Date().timeIntervalSince($0) > 60 } ?? false

        let (memUsed, memTotal, pressure, swapUsed) = memory.sample()
        let topMemProcs = processes.topByMemory(limit: 3)
        let bat = battery.sample()
        let dsk = disk.sample()

        current = SystemMetrics(
            cpu: CPUMetrics(
                usage: cpuUsage,
                topProcesses: topMemProcs, // reuse memory top for now; CPU per-process in M4
                sustained: sustained
            ),
            memory: MemoryMetrics(
                used: memUsed,
                total: memTotal,
                pressure: pressure,
                topProcesses: topMemProcs,
                swapUsed: swapUsed
            ),
            battery: bat,
            disk: dsk
        )
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Menu bar helpers

    var menuBarText: String {
        let ram = Int(current.memory.usageRatio * 100)
        let cpu = Int(current.cpu.usage * 100)
        let bat = current.battery.percentage
        return "RAM \(ram)%  CPU \(cpu)%  \(bat)%"
    }

    var healthTint: Color {
        switch current.memory.pressure {
        case .critical: return .red
        case .elevated: return .orange
        case .normal:
            return current.cpu.usage > 0.85 ? .orange : .primary
        }
    }
}
