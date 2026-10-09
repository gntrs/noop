import SwiftUI
import StrandDesign
import StrandAnalytics

/// Corrects one pool swim: the pool it was in, then either the lengths or the distance actually swum.
/// Whichever was typed last wins, and the other follows from it, so the two can never disagree.
struct SwimFixSheet: View {
    let watchDistanceM: Double?
    let onSave: (SwimMath.Fix?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var poolM: Double
    @State private var lengthsText: String
    @State private var distanceText: String
    @FocusState private var focus: Field?
    private enum Field { case lengths, distance }

    init(watchDistanceM: Double?, fix: SwimMath.Fix?, onSave: @escaping (SwimMath.Fix?) -> Void) {
        self.watchDistanceM = watchDistanceM
        self.onSave = onSave
        let pool = fix?.poolM ?? 25
        let distance = fix.flatMap { SwimMath.distance($0) }
        _poolM = State(initialValue: pool)
        _distanceText = State(initialValue: distance.map { "\(Int($0.rounded()))" } ?? "")
        _lengthsText = State(initialValue: SwimMath.lengths(distanceM: distance, poolM: pool).map { "\($0)" } ?? "")
    }

    private var fix: SwimMath.Fix {
        SwimMath.Fix(poolM: poolM, lengths: Int(lengthsText), distanceM: Double(distanceText))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Pool", selection: $poolM) {
                        ForEach(SwimMath.poolSizes, id: \.self) { Text("\(Int($0)) m").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: poolM) { pool in
                        if let d = Double(distanceText) {
                            lengthsText = SwimMath.lengths(distanceM: d, poolM: pool).map { "\($0)" } ?? ""
                        }
                    }
                }
                Section {
                    LabeledContent("Lengths") {
                        TextField("60", text: $lengthsText)
                            .multilineTextAlignment(.trailing)
                            .focused($focus, equals: .lengths)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .onChange(of: lengthsText) { text in
                                guard focus == .lengths else { return }
                                distanceText = Int(text).flatMap { l in l > 0 ? "\(Int(Double(l) * poolM))" : nil } ?? ""
                            }
                    }
                    LabeledContent("Distance, m") {
                        TextField("1500", text: $distanceText)
                            .multilineTextAlignment(.trailing)
                            .focused($focus, equals: .distance)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .onChange(of: distanceText) { text in
                                guard focus == .distance else { return }
                                lengthsText = SwimMath.lengths(distanceM: Double(text), poolM: poolM).map { "\($0)" } ?? ""
                            }
                    }
                } footer: {
                    if let w = watchDistanceM {
                        Text("The watch said \(Int(w.rounded())) m. Pace and strokes per length follow from what you enter.")
                    }
                }
                Section {
                    Button("Use the watch's numbers", role: .destructive) {
                        onSave(nil); dismiss()
                    }
                }
            }
            .navigationTitle("Fix this swim")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(fix); dismiss() }
                        .disabled(SwimMath.distance(fix) == nil)
                }
            }
        }
    }
}
