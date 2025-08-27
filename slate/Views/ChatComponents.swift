import SwiftUI
import MarkdownUI

// MARK: - Premium Liquid Glass Chat Header
struct ChatHeaderView: View {
    @EnvironmentObject var apiManager: APIManager
    let conversation: Conversation
    let selectedModel: AIModel?
    @Binding var isSearching: Bool
    @Binding var searchText: String
    @Binding var showingModelPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium floating header with enhanced Liquid Glass
            HStack(spacing: 20) {
                Button(action: { 
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showingModelPicker = true 
                    }
                }) {
                    HStack(spacing: 10) {
                        Text(selectedModel?.displayName ?? "Select Model")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(showingModelPicker ? 180 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingModelPicker)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(showingModelPicker ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingModelPicker)
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Enhanced Think Harder Toggle with premium effects
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            conversation.thinkHarderEnabled.toggle()
                        }
                    }) {
                        Image(systemName: conversation.thinkHarderEnabled ? "brain.filled.head.profile" : "brain.head.profile")
                            .font(.system(.title3, weight: .semibold))
                            .foregroundStyle(conversation.thinkHarderEnabled ? .white : .primary)
                            .frame(width: 44, height: 44)
                            .background(
                                conversation.thinkHarderEnabled ?
                                    .blue.gradient :
                                    .ultraThinMaterial,
                                in: .rect(cornerRadius: 22)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(
                                        conversation.thinkHarderEnabled ?
                                            .clear : .white.opacity(0.3),
                                        lineWidth: 1
                                    )
                            }
                            .shadow(
                                color: conversation.thinkHarderEnabled ?
                                    .blue.opacity(0.4) : .black.opacity(0.15),
                                radius: conversation.thinkHarderEnabled ? 8 : 6,
                                x: 0, y: 4
                            )
                    }
                    .scaleEffect(conversation.thinkHarderEnabled ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: conversation.thinkHarderEnabled)
                    
                    // Enhanced Search Toggle with premium effects
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isSearching.toggle()
                        }
                        if !isSearching { searchText = "" }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(.title3, weight: .semibold))
                            .foregroundStyle(isSearching ? .white : .primary)
                            .frame(width: 44, height: 44)
                            .background(
                                isSearching ?
                                    .blue.gradient :
                                    .ultraThinMaterial,
                                in: .rect(cornerRadius: 22)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(
                                        isSearching ?
                                            .clear : .white.opacity(0.3),
                                        lineWidth: 1
                                    )
                            }
                            .shadow(
                                color: isSearching ?
                                    .blue.opacity(0.4) : .black.opacity(0.15),
                                radius: isSearching ? 8 : 6,
                                x: 0, y: 4
                            )
                    }
                    .scaleEffect(isSearching ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSearching)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            // Premium floating search bar with enhanced animations
            if isSearching {
                HStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        TextField("Search messages...", text: $searchText)
                            .font(.system(.body, design: .default))
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                    
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isSearching = false
                        }
                        searchText = ""
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                    removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9))
                ))
            }
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 1)
        }
    }
}

// MARK: - Premium Liquid Glass Message Bubbles
struct MessageBubble: View {
    let message: Message
    @State private var isAppearing = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.isFromUser {
                Spacer(minLength: 100)
                
                VStack(alignment: .trailing, spacing: 12) {
                    messageContent
                        .background(.blue.gradient, in: .rect(cornerRadius: 24))
                        .foregroundStyle(.white)
                        .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                        .scaleEffect(isAppearing ? 1.0 : 0.8)
                        .opacity(isAppearing ? 1.0 : 0.0)
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .opacity(isAppearing ? 1.0 : 0.0)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    messageContent
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                        .scaleEffect(isAppearing ? 1.0 : 0.8)
                        .opacity(isAppearing ? 1.0 : 0.0)
                    
                    HStack(spacing: 12) {
                        Text(message.timestamp, style: .time)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .opacity(isAppearing ? 1.0 : 0.0)
                        
                        if let thinkingTime = message.thinkingTime {
                            HStack(spacing: 6) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(.caption, weight: .medium))
                                Text("\(String(format: "%.1f", thinkingTime))s")
                                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                            }
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.15), in: .rect(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.blue.opacity(0.3), lineWidth: 1)
                            }
                            .opacity(isAppearing ? 1.0 : 0.0)
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isAppearing = true
            }
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        if message.isThinking {
            HStack(spacing: 16) {
                PremiumLiquidThinkingIndicator()
                Text("Thinking...")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        } else if message.isFromUser {
            Text(message.content)
                .font(.system(.body, design: .default))
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
        } else {
            Markdown(message.content)
                .markdownTextStyle {
                    FontFamilyVariant(.normal)
                    FontSize(.em(1))
                    ForegroundColor(.primary)
                }
                .markdownBlockStyle(\.codeBlock) { configuration in
                    configuration.label
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.black.opacity(0.08), in: .rect(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Premium Liquid Glass Thinking Indicator
struct PremiumLiquidThinkingIndicator: View {
    @State private var animationProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 10, height: 10)
                    .opacity(opacityForDot(at: index))
                    .scaleEffect(scaleForDot(at: index))
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationProgress
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.blue.opacity(0.15), in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.blue.opacity(0.3), lineWidth: 1)
        }
        .scaleEffect(pulseScale)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
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
        return 0.4 + 0.6 * sin(progress * .pi * 2)
    }
    
    private func scaleForDot(at index: Int) -> Double {
        let delay = Double(index) * 0.2
        let progress = (animationProgress - delay).clamped(to: 0...1)
        return 0.8 + 0.4 * sin(progress * .pi * 2)
    }
}

// MARK: - Premium Floating Liquid Glass Chat Input
struct ChatInputView: View {
    @Binding var messageText: String
    @Binding var selectedFiles: [URL]
    @Binding var selectedImages: [UIImage]
    @Binding var showingFilePicker: Bool
    @Binding var showingImagePicker: Bool
    let isSending: Bool
    let onSend: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var inputScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium floating attachments preview
            if !selectedFiles.isEmpty || !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(selectedFiles, id: \.self) { file in
                            PremiumLiquidFilePreview(url: file) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedFiles.removeAll { $0 == file }
                                }
                            }
                        }
                        
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            PremiumLiquidImagePreview(image: image) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedImages.remove(at: index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 20)
                .background(.ultraThinMaterial)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(height: 1)
                }
            }
            
            // Premium floating input area with enhanced Liquid Glass
            HStack(alignment: .bottom, spacing: 20) {
                // Premium attachment button with enhanced effects
                Menu {
                    Button(action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showingImagePicker = true 
                        }
                    }) {
                        Label("Photos", systemImage: "photo.fill")
                    }
                    Button(action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showingFilePicker = true 
                        }
                    }) {
                        Label("Files", systemImage: "doc.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(.blue)
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .scaleEffect(isTextFieldFocused ? 0.95 : 1.0)
                }
                .disabled(isSending)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTextFieldFocused)
                
                // Premium floating text input with enhanced Liquid Glass
                HStack(alignment: .bottom, spacing: 20) {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .font(.system(.body, design: .default))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .lineLimit(1...6)
                        .disabled(isSending)
                    
                    // Premium send button with enhanced effects
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            onSend()
                        }
                    }) {
                        Group {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(.body, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .background(.blue.gradient, in: .rect(cornerRadius: 20))
                        .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                        .scaleEffect(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.8 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                .scaleEffect(inputScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isTextFieldFocused)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 1)
            }
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                inputScale = focused ? 1.02 : 1.0
            }
        }
    }
}

// MARK: - Premium Liquid Glass Attachment Previews
struct PremiumLiquidFilePreview: View {
    let url: URL
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "doc.fill")
                .font(.system(.title3, weight: .semibold))
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(url.lastPathComponent)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .lineLimit(1)
                
                Text("Document")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(.title3))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct PremiumLiquidImagePreview: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 90, height: 90)
                .clipShape(.rect(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(.title3))
                    .foregroundStyle(.white)
                    .background(Circle().fill(.black.opacity(0.7)))
            }
            .offset(x: 8, y: -8)
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
