import SwiftUI

/// Calm ornamental empty / loading / error surface used across tabs.
struct MihrabEmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var retryTitle: String = L10n.tryAgain
    var retry: (() -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 40))
                .foregroundStyle(MihrabColor.brass)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.pulse, options: .repeating.speed(0.4), isActive: !reduceMotion && retry == nil)

            Text(title)
                .font(.headline)
                .foregroundStyle(MihrabColor.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(MihrabColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            if let retry {
                Button(action: retry) {
                    Text(retryTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(minHeight: MihrabSpace.hit)
                        .background(Capsule().fill(MihrabColor.emerald))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .mihrabSolidCard(cornerRadius: 28)
        .accessibilityElement(children: .combine)
    }
}
