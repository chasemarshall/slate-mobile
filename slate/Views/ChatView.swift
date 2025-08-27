//
//  ChatView.swift
//  slate
//
//  Created by Chase Frazier on 8/27/25.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var apiManager: APIManager
    let conversation: Conversation
    
    @State private var messageText = ""
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var showingModelPicker = false
    @State private var showingFilePicker = false
    @State private var selectedFiles: [URL] = []
    @State private var showingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var isSending = false
    
    var filteredMessages: [Message] {
        if !isSearching || searchText.isEmpty {
            return conversation.messages.sorted { $0.timestamp < $1.timestamp }
        } else {
            return conversation.messages.filter {
                $0.content.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.timestamp < $1.timestamp }
        }
    }
    
    var selectedModel: AIModel? {
        apiManager.availableModels.first { $0.id == conversation.selectedModel }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with model picker and controls
            ChatHeaderView(
                conversation: conversation,
                selectedModel: selectedModel,
                isSearching: $isSearching,
                searchText: $searchText,
                showingModelPicker: $showingModelPicker
            )
            .environmentObject(apiManager)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: conversation.messages.count) { _, _ in
                    if let lastMessage = conversation.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            ChatInputView(
                messageText: $messageText,
                selectedFiles: $selectedFiles,
                selectedImages: $selectedImages,
                showingFilePicker: $showingFilePicker,
                showingImagePicker: $showingImagePicker,
                isSending: isSending,
                onSend: sendMessage
            )
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingModelPicker) {
            ModelPickerView(conversation: conversation)
                .environmentObject(apiManager)
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(selectedFiles: $selectedFiles)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImages: $selectedImages)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: messageText, isFromUser: true, conversation: conversation)
        conversation.messages.append(userMessage)
        conversation.lastMessageAt = Date()
        
        // Update conversation title if it's the first message
        if conversation.messages.count == 1 {
            conversation.title = String(messageText.prefix(50))
        }
        
        let messageToSend = messageText
        messageText = ""
        selectedFiles.removeAll()
        selectedImages.removeAll()
        
        Task {
            await sendToAPI(message: messageToSend)
        }
    }
    
    @MainActor
    private func sendToAPI(message: String) async {
        isSending = true
        
        // Create thinking message if model supports it
        let aiMessage = Message(content: "", isFromUser: false, conversation: conversation)
        let supportsThinking = selectedModel?.supportsThinking == true && conversation.thinkHarderEnabled
        
        if supportsThinking {
            aiMessage.isThinking = true
            aiMessage.content = "Thinking..."
        }
        
        conversation.messages.append(aiMessage)
        
        let startTime = Date()
        
        do {
            let response = try await callAPI(message: message, thinkHarder: conversation.thinkHarderEnabled)
            
            if supportsThinking {
                aiMessage.thinkingTime = Date().timeIntervalSince(startTime)
                aiMessage.isThinking = false
            }
            
            aiMessage.content = response
            conversation.lastMessageAt = Date()
        } catch {
            aiMessage.content = "Sorry, I encountered an error: \(error.localizedDescription)"
            aiMessage.isThinking = false
        }
        
        isSending = false
    }
    
    private func callAPI(message: String, thinkHarder: Bool) async throws -> String {
        let key = apiManager.selectedProvider == .openAI ? apiManager.openAIKey : apiManager.openRouterKey
        let baseURL = apiManager.selectedProvider == .openAI ? 
            "https://api.openai.com/v1/chat/completions" : 
            "https://openrouter.ai/api/v1/chat/completions"
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var messages: [[String: Any]] = []
        
        // Add system message if think harder is enabled
        if thinkHarder {
            messages.append([
                "role": "system",
                "content": "Please think step by step and provide detailed reasoning for your response. Take your time to consider all aspects of the question."
            ])
        }
        
        // Add conversation history
        for msg in conversation.messages.dropLast() { // Exclude the AI message we just added
            messages.append([
                "role": msg.isFromUser ? "user" : "assistant",
                "content": msg.content
            ])
        }
        
        let requestBody: [String: Any] = [
            "model": conversation.selectedModel,
            "messages": messages,
            "max_tokens": 4096,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if apiManager.selectedProvider == .openRouter {
            request.setValue("AI-Chat-iOS", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("AI Chat iOS App", forHTTPHeaderField: "X-Title")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        
        guard let choice = response.choices.first,
              let content = choice.message.content else {
            throw APIError.noData
        }
        
        return content
    }
}

struct ChatResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: MessageContent
    }
    
    struct MessageContent: Codable {
        let content: String?
    }
}