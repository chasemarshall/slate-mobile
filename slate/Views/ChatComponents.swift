import SwiftUI
import MarkdownUI

// MARK: - Chat Header
struct ChatHeaderView: View {
    @EnvironmentObject var apiManager: APIManager
    let conversation: Conversation
    let selectedModel: AIModel?
    @Binding var isSearching: Bool
    @Binding var searchText: String
    @Binding var showingModelPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Main header with Liquid Glass styling
            HStack {
                Button(action: { showingModelPicker = true }) {
                    HStack(spacing: 6) {
                        Text(selectedModel?.displayName ?? "Select Model")
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .imageScale(.small)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: .rect(cornerRadius: 20))
                }
                .accessibilityLabel("Change AI Model")
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Think Harder Toggle with Liquid Glass effect
                    Button(action: {
                        conversation.thinkHarderEnabled.toggle()
                    }) {
                        Image(systemName: conversation.thinkHarderEnabled ? "brain.filled.head.profile" : "brain.head.profile")
                            .font(.system(.title3, weight: .medium))
                            .foregroundStyle(conversation.thinkHarderEnabled ? .blue : .secondary)
                            .frame(width: 36, height: 36)
                            .background(
                                .regularMaterial,
                                in: .circle
                            )
                            .overlay {
                                if conversation.thinkHarderEnabled {
                                    Circle()
                                        .strokeBorder(.blue.opacity(0.3), lineWidth: 1)
                                }
                            }
                    }
                    .accessibilityLabel("Think Harder: \(conversation.thinkHarderEnabled ? "On" : "Off")")
                    
                    // Search Toggle with Liquid Glass effect
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSearching.toggle()
                        }
                        if !isSearching {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(.title3, weight: .medium))
                            .foregroundStyle(isSearching ? .blue : .secondary)
                            .frame(width: 36, height: 36)
                            .background(
                                .regularMaterial,
                                in: .circle
                            )
                            .overlay {
                                if isSearching {
                                    Circle()
                                        .strokeBorder(.blue.opacity(0.3), lineWidth: 1)
                                }
                            }
                    }
                    .accessibilityLabel("Search Messages")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Search bar with Liquid Glass background
            if isSearching {
                HStack {
                    TextField("Search messages...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Cancel") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSearching = false
                        }
                        searchText = ""
                    }
                    .font(.system(.body))
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(.thickMaterial) // Enhanced Liquid Glass material
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.separator.opacity(0.5))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Message Bubble with Liquid Glass Design
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 6) {
                    messageContent
                        .background(.blue, in: .rect(cornerRadius: 20))
                        .foregroundStyle(.white)
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(.caption2, design: .default))
                        .foregroundStyle(.tertiary)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    messageContent
                        .background(.thickMaterial, in: .rect(cornerRadius: 20)) // Enhanced Liquid Glass
                        .overlay {
                            // Subtle glass border effect
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(.separator.opacity(0.3), lineWidth: 0.5)
                        }
                    
                    HStack {
                        Text(message.timestamp, style: .time)
                            .font(.system(.caption2, design: .default))
                            .foregroundStyle(.tertiary)
                        
                        if let thinkingTime = message.thinkingTime {
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(.caption2))
                                    .foregroundStyle(.blue)
                                Text("\(String(format: "%.1f", thinkingTime))s")
                                    .font(.system(.caption2, design: .default))
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var messageContent: some View {
        if message.isThinking {
            HStack(spacing: 8) {
                ThinkingIndicator()
                Text("Thinking...")
                    .font(.system(.body, design: .default))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else if message.isFromUser {
            Text(message.content)
                .font(.system(.body, design: .default))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        } else {
            Markdown(message.content)
                .markdownTextStyle {
                    FontFamilyVariant(.normal)
                    FontSize(.em(1))
                }
                .markdownBlockStyle(\.codeBlock) { configuration in
                    configuration.label
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }
}

// MARK: - Enhanced Thinking Indicator with Liquid Glass
struct ThinkingIndicator: View {
    @State private var animationProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 8, height: 8)
                    .opacity(opacityForDot(at: index))
                    .scaleEffect(scaleForDot(at: index))
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationProgress
                    )
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: .capsule)
        .scaleEffect(pulseScale)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever()) {
                animationProgress = 1
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                pulseScale = 1.05
            }
        }
    }
    
    private func opacityForDot(at index: Int) -> Double {
        let delay = Double(index) * 0.2
        let progress = (animationProgress - delay).clamped(to: 0...1)
        return 0.4 + 0.6 * sin(progress * .pi)
    }
    
    private func scaleForDot(at index: Int) -> Double {
        let delay = Double(index) * 0.2
        let progress = (animationProgress - delay).clamped(to: 0...1)
        return 0.8 + 0.4 * sin(progress * .pi)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - Chat Input
struct ChatInputView: View {
    @Binding var messageText: String
    @Binding var selectedFiles: [URL]
    @Binding var selectedImages: [UIImage]
    @Binding var showingFilePicker: Bool
    @Binding var showingImagePicker: Bool
    let isSending: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // File attachments preview
            if !selectedFiles.isEmpty || !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedFiles, id: \.self) { file in
                            FileAttachmentPreview(url: file) {
                                selectedFiles.removeAll { $0 == file }
                            }
                        }
                        
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ImageAttachmentPreview(image: image) {
                                selectedImages.remove(at: index)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
            }
            
            // Input area
            HStack(spacing: 12) {
                // Attachment buttons
                HStack(spacing: 8) {
                    Button(action: { showingFilePicker = true }) {
                        Image(systemName: "paperclip")
                            .foregroundColor(.secondary)
                    }
                    .disabled(isSending)
                    
                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    }
                    .disabled(isSending)
                }
                
                // Text input
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isSending)
                
                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
}

// MARK: - File Attachment Preview
struct FileAttachmentPreview: View {
    let url: URL
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(formatFileSize(url))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatFileSize(_ url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB, .useGB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: size)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return "Unknown size"
    }
}

// MARK: - Image Attachment Preview
struct ImageAttachmentPreview: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(.white)
                    .clipShape(Circle())
            }
            .offset(x: 5, y: -5)
        }
    }
}
