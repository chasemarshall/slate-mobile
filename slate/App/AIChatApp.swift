//
//  AIChatApp.swift
//  slate
//
//  Created by Chase Frazier on 8/27/25.
//


import SwiftUI
import SwiftData
import Combine

@main
struct AIChatApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Conversation.self,
            Message.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var conversations: [Conversation]
    @StateObject private var apiManager = APIManager()
    @State private var showingSidebar = false
    @State private var selectedConversation: Conversation?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            ConversationListView(
                conversations: conversations,
                selectedConversation: $selectedConversation,
                showingSettings: $showingSettings
            )
        } detail: {
            // Main Chat View
            if let conversation = selectedConversation {
                ChatView(conversation: conversation)
                    .environmentObject(apiManager)
            } else {
                WelcomeView(onNewChat: createNewConversation)
                    .environmentObject(apiManager)
            }
        }
        .onAppear {
            if selectedConversation == nil && !conversations.isEmpty {
                selectedConversation = conversations.first
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(apiManager)
        }
    }
    
    private func createNewConversation() {
        let newConversation = Conversation(title: "New Chat")
        modelContext.insert(newConversation)
        selectedConversation = newConversation
    }
}

// MARK: - Models
@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var lastMessageAt: Date
    @Relationship(deleteRule: .cascade) var messages: [Message]
    var selectedModel: String
    var thinkHarderEnabled: Bool
    
    init(title: String, selectedModel: String = "gpt-4") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.lastMessageAt = Date()
        self.messages = []
        self.selectedModel = selectedModel
        self.thinkHarderEnabled = false
    }
}

@Model
final class Message {
    var id: UUID
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    var conversation: Conversation?
    var thinkingTime: TimeInterval?
    var isThinking: Bool
    
    init(content: String, isFromUser: Bool, conversation: Conversation?) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.conversation = conversation
        self.thinkingTime = nil
        self.isThinking = false
    }
}

// MARK: - API Manager
class APIManager: ObservableObject {
    @Published var openAIKey = ""
    @Published var openRouterKey = ""
    @Published var selectedProvider: APIProvider = .openAI
    @Published var availableModels: [AIModel] = []
    @Published var isLoadingModels = false
    
    enum APIProvider: String, CaseIterable {
        case openAI = "OpenAI"
        case openRouter = "OpenRouter"
    }
    
    init() {
        loadKeys()
        loadModels()
    }
    
    func loadKeys() {
        if let openAI = UserDefaults.standard.string(forKey: "openai_key") {
            openAIKey = openAI
        }
        if let openRouter = UserDefaults.standard.string(forKey: "openrouter_key") {
            openRouterKey = openRouter
        }
        if let provider = UserDefaults.standard.string(forKey: "selected_provider") {
            selectedProvider = APIProvider(rawValue: provider) ?? .openAI
        }
    }
    
    func saveKeys() {
        UserDefaults.standard.set(openAIKey, forKey: "openai_key")
        UserDefaults.standard.set(openRouterKey, forKey: "openrouter_key")
        UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selected_provider")
    }
    
    func loadModels() {
        Task {
            await fetchModels()
        }
    }
    
    @MainActor
    func fetchModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        
        let key = selectedProvider == .openAI ? openAIKey : openRouterKey
        guard !key.isEmpty else {
            availableModels = getDefaultModels()
            return
        }
        
        do {
            let models = try await fetchModelsFromAPI()
            availableModels = models
        } catch {
            print("Error fetching models: \(error)")
            availableModels = getDefaultModels()
        }
    }
    
    private func fetchModelsFromAPI() async throws -> [AIModel] {
        let key = selectedProvider == .openAI ? openAIKey : openRouterKey
        let baseURL = selectedProvider == .openAI ? 
            "https://api.openai.com/v1/models" : 
            "https://openrouter.ai/api/v1/models"
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        if selectedProvider == .openRouter {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
        
        return response.data.compactMap { modelData in
            // Filter for chat models and add display names
            guard modelData.id.contains("gpt") || 
                  modelData.id.contains("claude") || 
                  modelData.id.contains("llama") else { return nil }
            
            return AIModel(
                id: modelData.id,
                displayName: formatModelName(modelData.id),
                supportsThinking: modelData.id.contains("o1") || modelData.id.contains("reasoning")
            )
        }
    }
    
    private func formatModelName(_ id: String) -> String {
        // Convert API model IDs to user-friendly names
        switch id {
        case let name where name.contains("gpt-4o"):
            return "GPT-4o"
        case let name where name.contains("gpt-4-turbo"):
            return "GPT-4 Turbo"
        case let name where name.contains("gpt-4"):
            return "GPT-4"
        case let name where name.contains("gpt-3.5"):
            return "GPT-3.5 Turbo"
        case let name where name.contains("claude-3.5-sonnet"):
            return "Claude 3.5 Sonnet"
        case let name where name.contains("claude-3-opus"):
            return "Claude 3 Opus"
        default:
            return id.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }
    
    private func getDefaultModels() -> [AIModel] {
        if selectedProvider == .openAI {
            return [
                AIModel(id: "gpt-4", displayName: "GPT-4", supportsThinking: false),
                AIModel(id: "gpt-4-turbo", displayName: "GPT-4 Turbo", supportsThinking: false),
                AIModel(id: "gpt-3.5-turbo", displayName: "GPT-3.5 Turbo", supportsThinking: false)
            ]
        } else {
            return [
                AIModel(id: "anthropic/claude-3.5-sonnet", displayName: "Claude 3.5 Sonnet", supportsThinking: false),
                AIModel(id: "openai/gpt-4", displayName: "GPT-4", supportsThinking: false),
                AIModel(id: "meta-llama/llama-3.1-8b-instruct", displayName: "Llama 3.1 8B", supportsThinking: false)
            ]
        }
    }
}

// MARK: - Supporting Types
struct AIModel: Identifiable, Codable {
    let id: String
    let displayName: String
    let supportsThinking: Bool
}

struct ModelsResponse: Codable {
    let data: [ModelData]
}

struct ModelData: Codable {
    let id: String
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
}