import MapKit
import SwiftUI

struct StoryView: View {
    @Bindable var viewModel: WalkViewModel
    let stop: TourSession.Stop
    @Environment(\.dismiss) private var dismiss

    private var story: Story? {
        viewModel.writer.stories[stop.placeID]
    }

    private var draft: Story.PartiallyGenerated? {
        viewModel.writer.drafts[stop.placeID]
    }

    private var headline: String? {
        story?.headline ?? draft?.headline
    }

    private var paragraphs: [String] {
        story?.paragraphs ?? draft?.paragraphs ?? []
    }

    private var lookFor: String? {
        story?.lookFor ?? draft?.lookFor
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                lookAround
                VStack(alignment: .leading, spacing: 16) {
                    Text("Stop \(stop.number) of \(viewModel.stops.count) · \(stop.name)")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.7)
                        .foregroundStyle(Color.accentText)
                    Text(headline ?? "A story about this place")
                        .font(.title.bold())
                        .tracking(-0.56)
                        .skeleton(headline == nil)
                    if let failure = viewModel.writer.failures[stop.placeID] {
                        Text(failure.message)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(paragraphs.indices, id: \.self) { index in
                        Text(paragraphs[index])
                            .lineSpacing(5)
                    }
                    if let lookFor {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Look for")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.accentText)
                                Text(lookFor)
                            }
                        } icon: {
                            Image(systemName: "eye")
                                .foregroundStyle(Color.accentText)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.primary.opacity(0.05), in: .rect(cornerRadius: 18))
                    }
                }
                .padding(EdgeInsets(top: 26, leading: 24, bottom: 32, trailing: 24))
            }
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaBar(edge: .bottom) {
            Button {
                viewModel.ask(about: stop)
            } label: {
                Label("Ask about this place", systemImage: "sparkle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.extraLarge)
            .disabled(story == nil)
            .padding(.horizontal, 16)
        }
        .sheet(item: $viewModel.chat) { chat in
            ChatView(chat: chat)
        }
        .overlay(alignment: .topLeading) {
            Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
                .labelStyle(.iconOnly)
                .fontWeight(.semibold)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .padding(16)
        }
        .presentationBackground(Color.paper)
    }

    private var lookAround: some View {
        Group {
            if let scene = viewModel.scene {
                LookAroundPreview(initialScene: scene, allowsNavigation: false, badgePosition: .bottomTrailing)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "binoculars")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(height: 300)
    }
}
