import SwiftUI

struct ChatView: View {
    @Bindable var chat: GuideChat
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(chat.messages) { message in
                        if message.isGuide {
                            answer(message.text)
                        } else {
                            Text(verbatim: message.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.tint.opacity(0.12), in: .rect(cornerRadius: 22))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.leading, 60)
                        }
                    }
                }
                .padding(22)
            }
            .defaultScrollAnchor(.bottom, for: .sizeChanges)
            input
        }
        .presentationBackground(Color.paper)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .foregroundStyle(.tint)
                Text("Ask the guide")
                    .font(.headline)
                Spacer()
                Label("Claude", systemImage: "cloud")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(Color.primary.opacity(0.06), in: .capsule)
                Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
                    .labelStyle(.iconOnly)
                    .fontWeight(.semibold)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
            }
            Label("About \(chat.stopName)", systemImage: "mappin")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.accentText)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(.tint.opacity(0.1), in: .capsule)
        }
        .padding(EdgeInsets(top: 20, leading: 22, bottom: 0, trailing: 16))
    }

    private func answer(_ text: String) -> some View {
        Text(verbatim: text.isEmpty ? "The guide is thinking about your question" : text)
            .lineSpacing(5)
            .skeleton(text.isEmpty)
    }

    private var input: some View {
        HStack(spacing: 8) {
            TextField("Ask anything about this place", text: $chat.question)
                .submitLabel(.send)
                .onSubmit(chat.send)
            Button("Send", systemImage: "arrow.up", action: chat.send)
                .labelStyle(.iconOnly)
                .fontWeight(.semibold)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .disabled(!chat.canSend)
        }
        .padding(.leading, 18)
        .padding(.trailing, 7)
        .frame(height: 54)
        .glassEffect(in: .capsule)
        .padding(12)
    }
}
