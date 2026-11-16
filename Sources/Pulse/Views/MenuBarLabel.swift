import AppKit

// SwiftUI's MenuBarExtra renders its label as a template and drops color,
// so the label is an attributed string on an AppKit status item instead.
enum MenuBarLabel {
    static func title(for m: SystemMetrics) -> NSAttributedString {
        let segments: [(String, Severity)] = [
            ("RAM \(Int(m.memory.usageRatio * 100))%", m.memory.pressure.severity),
            ("CPU \(Int(m.cpu.usage * 100))%", m.cpu.severity),
            ("GPU \(Int(m.gpu.usage * 100))%", m.gpu.status.severity),
        ]
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let title = NSMutableAttributedString()
        for (index, (text, severity)) in segments.enumerated() {
            if index > 0 {
                title.append(NSAttributedString(string: "  ", attributes: [.font: font]))
            }
            title.append(NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: color(for: severity),
            ]))
        }
        return title
    }

    static func color(for severity: Severity) -> NSColor {
        switch severity {
        case .normal:  return .labelColor
        case .warning: return .systemOrange
        case .danger:  return .systemRed
        }
    }
}
