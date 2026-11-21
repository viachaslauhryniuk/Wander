import SwiftUI

extension View {
    func errorAlert(_ error: Binding<(any Error)?>) -> some View {
        alert(error.wrappedValue?.message ?? "", item: error) { _ in
            Button("OK") {}
        }
    }

    func skeleton(_ isPlaceholder: Bool) -> some View {
        TimelineView(.animation(paused: !isPlaceholder)) { context in
            self
                .redacted(reason: isPlaceholder ? .placeholder : [])
                .opacity(isPlaceholder ? 0.7 + 0.3 * cos(context.date.timeIntervalSinceReferenceDate * .pi) : 1)
        }
    }
}
