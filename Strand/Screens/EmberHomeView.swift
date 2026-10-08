import SwiftUI
import StrandDesign
import WhoopStore

/// The values the Ember home shows. Built by the Today screen from its already-resolved state, so this
/// view computes nothing and the numbers cannot disagree with the rest of the app.
struct EmberHomeData {
    var dayTitle: String
    var sleepPct: Double?
    var recoveryPct: Double?
    var recoveryIsPrior: Bool
    var strain: Double?
    var strainMax: Double
    var strainDecimals: Int
    var effortScale: EffortScale
    var dayStart: Date
    var dayEnd: Date
    var workouts: [WorkoutRow]
    var hrv: Double?
    var restingHr: Double?
    var sleepMinutes: Double?
    var respRate: Double?
    var steps: Int?
    var stepsSource: String?
    /// Stretches of the day each device covered, oldest first. Empty hides the strip.
    var coverage: [EmberCoverageSpan] = []

    var todaysWorkouts: [WorkoutRow] {
        let lo = Int(dayStart.timeIntervalSince1970), hi = Int(dayEnd.timeIntervalSince1970)
        return workouts.filter { $0.startTs >= lo && $0.startTs < hi }.sorted { $0.startTs < $1.startTs }
    }
}

struct EmberCoverageSpan: Equatable {
    enum Device: Equatable { case whoop, garmin }
    var device: Device
    var start: Date
    var end: Date
}

/// Short, lowercase device name for a stored source id. Garmin rows come in through Apple Health under
/// the `garmin` device; anything else from Health stays "health".
func emberSourceName(_ source: String) -> String {
    let s = source.lowercased()
    if s.contains("garmin") { return "garmin" }
    if s.contains("apple") || s.contains("health") { return "health" }
    if s.contains("manual") { return "manual" }
    return "whoop"
}

/// WHOOP style home: three dials, today's activities, a handful of plain rows. One orange for recovery
/// and live heart rate, greys for the rest, SF Symbols for icons.
struct EmberHomeView: View {
    let data: EmberHomeData
    @EnvironmentObject private var live: LiveState

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            header
            dials
            if !data.coverage.isEmpty { EmberCoverageStrip(spans: data.coverage, dayStart: data.dayStart, dayEnd: data.dayEnd) }
            activities
            stats
        }
        .padding(.top, 8)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(data.dayTitle)
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.6)
                .foregroundStyle(StrandPalette.textPrimary)
            Spacer()
            if let hr = live.heartRate, hr > 0, live.connected {
                HStack(spacing: 5) {
                    Image(systemName: "heart.fill").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(StrandPalette.accent)
                    Text("\(hr)").font(.system(size: 17, weight: .semibold).monospacedDigit())
                        .foregroundStyle(StrandPalette.textPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("Heart rate \(hr) beats per minute"))
            }
        }
    }

    private var dials: some View {
        HStack(alignment: .top, spacing: 0) {
            dial(label: "Sleep", value: data.sleepPct, maxValue: 100, unit: "%", decimals: 0,
                 tint: StrandPalette.restBright, route: .metric(HeroRingMetric.rest))
            dial(label: data.recoveryIsPrior ? "Recovery, last" : "Recovery", value: data.recoveryPct,
                 maxValue: 100, unit: "%", decimals: 0, tint: StrandPalette.chargeColor,
                 route: .metric(HeroRingMetric.charge))
            dial(label: "Strain", value: data.strain, maxValue: data.strainMax, unit: "",
                 decimals: data.strainDecimals, tint: StrandPalette.effortColor,
                 route: .metric(HeroRingMetric.effort))
        }
    }

    private func dial(label: String, value: Double?, maxValue: Double, unit: String, decimals: Int,
                      tint: Color, route: TabRoute) -> some View {
        NavigationLink(value: route) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().stroke(StrandPalette.hairline, lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: min(1, max(0, (value ?? 0) / maxValue)))
                        .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(value.map { String(format: "%.\(decimals)f", $0) } ?? "–")
                            .font(.system(size: 26, weight: .semibold).monospacedDigit())
                            .tracking(-0.8)
                        if value != nil, !unit.isEmpty {
                            Text(unit).font(.system(size: 13, weight: .medium))
                                .foregroundStyle(StrandPalette.textTertiary)
                        }
                    }
                    .foregroundStyle(StrandPalette.textPrimary)
                }
                .frame(width: 92, height: 92)
                Text(label).font(.system(size: 13, weight: .medium))
                    .foregroundStyle(StrandPalette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(label) \(value.map { String(format: "%.\(decimals)f", $0) } ?? "no data")"))
    }

    private var activities: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Activities").font(.system(size: 17, weight: .semibold))
                .foregroundStyle(StrandPalette.textPrimary)
                .padding(.bottom, 8)
            let rows = data.todaysWorkouts
            if rows.isEmpty {
                Text("Nothing recorded yet today.")
                    .font(.system(size: 15))
                    .foregroundStyle(StrandPalette.textTertiary)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, w in
                    NavigationLink(value: TabRoute.workouts) { activityRow(w) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func activityRow(_ w: WorkoutRow) -> some View {
        HStack(spacing: 14) {
            Image(systemName: sportSymbol(w.sport))
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(StrandPalette.textSecondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(WorkoutSource.displaySport(w.sport))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(StrandPalette.textPrimary)
                Text("\(Self.time(w.startTs)) to \(Self.time(w.endTs)), \(emberSourceName(w.source))")
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            Spacer()
            Text(w.strain.map { String(format: "%.\(data.strainDecimals)f", UnitFormatter.effortValue($0, scale: data.effortScale)) } ?? "–")
                .font(.system(size: 17, weight: .semibold).monospacedDigit())
                .foregroundStyle(StrandPalette.textPrimary)
        }
        .frame(minHeight: 52)
        .overlay(alignment: .top) { Rectangle().fill(StrandPalette.hairline).frame(height: 0.5) }
        .contentShape(Rectangle())
    }

    private var stats: some View {
        VStack(spacing: 0) {
            statRow("Sleep", data.sleepMinutes.map { Self.hm($0) }, nil, route: .metric("sleep_hours"))
            statRow("HRV", data.hrv.map { String(format: "%.0f", $0) }, "ms", route: .metric("hrv"))
            statRow("Resting heart rate", data.restingHr.map { String(format: "%.0f", $0) }, "bpm", route: .metric("rhr"))
            statRow("Respiratory rate", data.respRate.map { String(format: "%.1f", $0) }, "rpm", route: .metric("resp_rate"))
            statRow(data.stepsSource.map { "Steps, \($0)" } ?? "Steps", data.steps.map { $0.formatted() }, nil, route: .metric("steps"))
        }
        .overlay(alignment: .bottom) { Rectangle().fill(StrandPalette.hairline).frame(height: 0.5) }
    }

    private func statRow(_ label: String, _ value: String?, _ unit: String?, route: TabRoute) -> some View {
        NavigationLink(value: route) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(.system(size: 15)).foregroundStyle(StrandPalette.textSecondary)
                Spacer()
                Text(value ?? "–").font(.system(size: 17, weight: .semibold).monospacedDigit())
                    .foregroundStyle(StrandPalette.textPrimary)
                if let unit, value != nil {
                    Text(unit).font(.system(size: 13)).foregroundStyle(StrandPalette.textTertiary)
                }
            }
            .frame(minHeight: 48)
            .overlay(alignment: .top) { Rectangle().fill(StrandPalette.hairline).frame(height: 0.5) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    static func hm(_ minutes: Double) -> String {
        let m = Int(minutes.rounded())
        return "\(m / 60):" + String(format: "%02d", m % 60)
    }

    private static let timeFormat: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
    static func time(_ ts: Int) -> String { timeFormat.string(from: Date(timeIntervalSince1970: TimeInterval(ts))) }
}

/// A 24 hour bar: orange where the WHOOP covered the day, hatched grey where Garmin filled in.
struct EmberCoverageStrip: View {
    let spans: [EmberCoverageSpan]
    let dayStart: Date
    let dayEnd: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { g in
                let total = dayEnd.timeIntervalSince(dayStart)
                ZStack(alignment: .leading) {
                    Capsule().fill(StrandPalette.hairline)
                    ForEach(Array(spans.enumerated()), id: \.offset) { _, s in
                        let x = g.size.width * CGFloat(max(0, s.start.timeIntervalSince(dayStart)) / total)
                        let w = g.size.width * CGFloat(max(0, min(s.end, dayEnd).timeIntervalSince(max(s.start, dayStart))) / total)
                        Rectangle()
                            .fill(s.device == .whoop ? StrandPalette.chargeColor : StrandPalette.textTertiary)
                            .frame(width: w)
                            .offset(x: x)
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: 8)
            HStack(spacing: 16) {
                legend(StrandPalette.chargeColor, "whoop")
                legend(StrandPalette.textTertiary, "garmin")
                Spacer()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Which device covered which part of the day"))
    }

    private func legend(_ c: Color, _ name: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 12, height: 6)
            Text(name).font(.system(size: 12)).foregroundStyle(StrandPalette.textSecondary)
        }
    }
}
