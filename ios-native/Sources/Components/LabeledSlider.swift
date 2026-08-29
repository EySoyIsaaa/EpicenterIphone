import SwiftUI

/// Slider con etiqueta y valor, reutilizado en DSP y Efectos.
struct LabeledSlider: View {
    let title: String
    let value: Double
    let range: ClosedRange<Double>
    var unit: String = ""
    var disabled: Bool = false
    let onChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(Int(value.rounded()))\(unit)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
            Slider(value: Binding(get: { value }, set: { onChange($0) }), in: range)
                .tint(Theme.red)
                .disabled(disabled)
        }
        .opacity(disabled ? 0.45 : 1)
    }
}
