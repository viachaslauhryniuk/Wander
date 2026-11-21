import SwiftUI

extension View {
    func skeleton(_ isPlaceholder: Bool) -> some View {
        TimelineView(.animation(paused: !isPlaceholder)) { context in
            self
                .redacted(reason: isPlaceholder ? .placeholder : [])
                .opacity(isPlaceholder ? 0.7 + 0.3 * cos(context.date.timeIntervalSinceReferenceDate * .pi) : 1)
        }
    }
}
