import SwiftUI

struct Chip: View {
    let title: String
    var symbol: String? = nil
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isOn ? Color.accentText : .primary)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isOn ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.06), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

extension Chip { //copied from List
    init(_ topic: String, selection: Binding<Set<String>>) {
        self.init(title: topic, isOn: selection.wrappedValue.contains(topic)) {
            selection.wrappedValue.formSymmetricDifference([topic])
        }
    }
}
