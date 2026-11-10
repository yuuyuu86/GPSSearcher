import SwiftUI
import CoreLocation
import Charts

struct ContentView: View {
    @State private var lm = LocationManager()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    accuracyHeader
                        .listRowBackground(Color.clear)
                }

                if !lm.isPreciseEnabled {
                    Section {
                        Label("「正確な位置情報」がオフです。設定アプリでオンにしてください。", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                if let loc = lm.location {
                    Section("精度") {
                        row("水平精度", meters(loc.horizontalAccuracy))
                        row("垂直精度", meters(loc.verticalAccuracy))
                        row("速度精度", loc.speedAccuracy >= 0 ? String(format: "±%.1f m/s", loc.speedAccuracy) : "—")
                        row("方位精度", loc.courseAccuracy >= 0 ? String(format: "±%.0f°", loc.courseAccuracy) : "—")
                    }
                    Section("位置") {
                        row("緯度", String(format: "%.6f", loc.coordinate.latitude))
                        row("経度", String(format: "%.6f", loc.coordinate.longitude))
                        row("高度", String(format: "%.1f m", loc.altitude))
                        row("速度", loc.speed >= 0 ? String(format: "%.1f m/s", loc.speed) : "—")
                        row("更新時刻", loc.timestamp.formatted(date: .omitted, time: .standard))
                    }
                    if lm.history.count > 1 {
                        Section("水平精度の推移（直近60件）") {
                            Chart(Array(lm.history.enumerated()), id: \.offset) { i, v in
                                LineMark(x: .value("#", i), y: .value("m", v))
                                    .interpolationMethod(.monotone)
                            }
                            .chartYAxisLabel("m")
                            .frame(height: 160)
                        }
                    }
                }
            }
            .navigationTitle("GPSSearcher")
        }
        .onAppear { lm.start() }
    }

    private var accuracyHeader: some View {
        let acc = lm.location?.horizontalAccuracy ?? -1
        let level = AccuracyLevel(acc)
        return VStack(spacing: 8) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(level.color)
                .symbolEffect(.pulse, isActive: lm.location == nil)
            Text(statusText(acc))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(level.label)
                .font(.headline)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(level.color.opacity(0.2), in: Capsule())
                .foregroundStyle(level.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .animation(.default, value: acc)
    }

    private func statusText(_ acc: Double) -> String {
        switch lm.authorization {
        case .denied, .restricted: return "許可なし"
        default: return acc >= 0 ? String(format: "±%.1f m", acc) : "測位中…"
        }
    }

    private func meters(_ v: Double) -> String { v >= 0 ? String(format: "±%.1f m", v) : "—" }

    private func row(_ title: String, _ value: String) -> some View {
        LabeledContent(title) { Text(value).monospacedDigit() }
    }
}

enum AccuracyLevel {
    case excellent, good, fair, poor, none
    init(_ acc: Double) {
        switch acc {
        case ..<0: self = .none
        case ..<5: self = .excellent
        case ..<15: self = .good
        case ..<50: self = .fair
        default: self = .poor
        }
    }
    var label: String {
        switch self {
        case .excellent: "非常に良い"
        case .good: "良い"
        case .fair: "普通"
        case .poor: "悪い"
        case .none: "取得待ち"
        }
    }
    var color: Color {
        switch self {
        case .excellent: .green
        case .good: .mint
        case .fair: .orange
        case .poor: .red
        case .none: .gray
        }
    }
}

#Preview { ContentView() }
