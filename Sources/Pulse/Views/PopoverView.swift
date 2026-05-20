import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var metrics: MetricsService

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    memorySection
                    Divider().padding(.horizontal, 14)
                    cpuSection
                    Divider().padding(.horizontal, 14)
                    batterySection
                    Divider().padding(.horizontal, 14)
                    diskSection
                }
            }
            Divider()
            footer
        }
        .frame(width: 300)
        .background(.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .font(.system(size: 12))
            Text("Pulse")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text("System Health")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Full Detail") { }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.blue)
            Spacer()
            Button("Settings") { }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Memory

    private var memorySection: some View {
        MetricSectionView(title: "Memory", icon: "memorychip") {
            let m = metrics.current.memory
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    ProgressBarView(value: m.usageRatio, tint: pressureColor(m.pressure))
                    Text(String(format: "%.1f / %.0f GB", m.used, m.total))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(pressureColor(m.pressure))
                        .frame(width: 5, height: 5)
                    Text("Pressure: \(m.pressure.rawValue)")
                        .font(.system(size: 11))
                    if m.swapUsed > 0.01 {
                        Spacer()
                        Text(String(format: "Swap %.1f GB", m.swapUsed))
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                    }
                }
                processLine(processes: m.topProcesses, formatValue: { formatMemory($0) })
            }
        }
    }

    // MARK: - CPU

    private var cpuSection: some View {
        MetricSectionView(title: "CPU", icon: "cpu") {
            let c = metrics.current.cpu
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    ProgressBarView(value: c.usage, tint: cpuColor(c.usage))
                    Text("\(Int(c.usage * 100))%")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                if c.sustained {
                    Label("Sustained high load", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Battery

    private var batterySection: some View {
        MetricSectionView(title: "Battery & Thermals", icon: "battery.100percent") {
            let b = metrics.current.battery
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    ProgressBarView(value: Double(b.percentage) / 100, tint: batteryColor(b.percentage))
                    HStack(spacing: 4) {
                        Text("\(b.percentage)%")
                            .font(.system(size: 11, design: .monospaced))
                        if b.isCharging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.green)
                        }
                    }
                    .fixedSize()
                }
                HStack(spacing: 12) {
                    Label("\(b.health)% health", systemImage: "heart")
                        .font(.system(size: 11))
                        .foregroundStyle(b.health < 80 ? .orange : .secondary)
                    Text("\(b.cycleCount) cycles")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                if let cpuTemp = b.cpuTemp {
                    HStack(spacing: 12) {
                        Label(String(format: "CPU %.0f°C", cpuTemp), systemImage: "thermometer.medium")
                            .font(.system(size: 11))
                            .foregroundStyle(tempColor(cpuTemp))
                        if let gpuTemp = b.gpuTemp {
                            Label(String(format: "GPU %.0f°C", gpuTemp), systemImage: "thermometer.medium")
                                .font(.system(size: 11))
                                .foregroundStyle(tempColor(gpuTemp))
                        }
                        if let fan = b.fanRPM {
                            Spacer()
                            Label("\(fan) RPM", systemImage: "fan")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Thermals available in a future update")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                        .italic()
                }
            }
        }
    }

    // MARK: - Disk

    private var diskSection: some View {
        MetricSectionView(title: "Storage", icon: "internaldrive") {
            let d = metrics.current.disk
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    ProgressBarView(value: d.usageRatio, tint: diskColor(d.free))
                    Text(String(format: "%.0f / %.0f GB", d.used, d.total))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                if d.free < 20 {
                    Label(
                        String(format: "%.1f GB free — running low", d.free),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(d.free < 5 ? .red : .orange)
                }
            }
        }
    }

    // MARK: - Shared helpers

    @ViewBuilder
    private func processLine(processes: [ProcessStat], formatValue: @escaping (Double) -> String) -> some View {
        let top = Array(processes.prefix(3))
        if !top.isEmpty {
            HStack(spacing: 0) {
                ForEach(Array(top.enumerated()), id: \.offset) { index, proc in
                    Text(proc.name)
                        .font(.system(size: 10, weight: .medium))
                    Text(" \(formatValue(proc.value))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    if index < top.count - 1 {
                        Text("  ·  ")
                            .font(.system(size: 10))
                            .foregroundStyle(.quaternary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func formatMemory(_ mb: Double) -> String {
        mb >= 1024
            ? String(format: "%.1fGB", mb / 1024)
            : String(format: "%.0fMB", mb)
    }

    // MARK: - Color logic

    private func pressureColor(_ p: MemoryPressure) -> Color {
        switch p {
        case .normal:   return .blue
        case .elevated: return .orange
        case .critical: return .red
        }
    }

    private func cpuColor(_ usage: Double) -> Color {
        if usage > 0.85 { return .red }
        if usage > 0.60 { return .orange }
        return .blue
    }

    private func batteryColor(_ pct: Int) -> Color {
        if pct <= 15 { return .red }
        if pct <= 30 { return .orange }
        return .green
    }

    private func diskColor(_ freeGB: Double) -> Color {
        if freeGB < 5  { return .red }
        if freeGB < 20 { return .orange }
        return .blue
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp > 90 { return .red }
        if temp > 70 { return .orange }
        return .secondary
    }
}
