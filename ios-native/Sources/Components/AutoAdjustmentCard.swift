import SwiftUI

/// Shared placement and styling for both independent automatic adjustments.
struct AutoAdjustmentCard: View {
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $isOn) {
                Label(L("Ajuste automático", "Auto adjust"), systemImage: "wand.and.stars")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .tint(Theme.red)
            Text(description)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.red.opacity(0.35), lineWidth: 1))
    }
}
