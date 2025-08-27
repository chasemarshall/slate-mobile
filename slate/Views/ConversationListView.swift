//
//  ConversationListView.swift
//  slate
//
//  Created by Chase Frazier on 8/27/25.
//


import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    let conversations: [Conversation]
    @Binding var selectedConversation: Conversation?
    @Binding var showingSettings: Bool
    @State private var searchText = ""
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations.sorted { $0.lastMessageAt > $1.lastMessageAt }
        } else {
            return conversations.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText) ||
                conversation.messages.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
            }.sorted { $0.lastMessageAt > $1.lastMessageAt }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedConversation) {
                ForEach(filteredConversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .tag(conversation)
                }
                .onDelete(perform: deleteConversations)
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search conversations")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: createNewConversation) {
                        Image(systemName: "square.and.pencil")
                            .fontWeight(.medium)
                    }
                    .accessibilityLabel("New Chat")
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .fontWeight(.medium)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
    }
    
    private func createNewConversation() {
        let newConversation = Conversation(title: "New Chat")
        modelContext.insert(newConversation)
        selectedConversation = newConversation
    }
    
    private func deleteConversations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let conversation = filteredConversations[index]
                if selectedConversation?.id == conversation.id {
                    selectedConversation = nil
                }
                modelContext.delete(conversation)
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.system(.body, design: .default, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            if let lastMessage = conversation.messages.last {
                Text(lastMessage.content)
                    .font(.system(.subheadline, design: .default))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Text(conversation.lastMessageAt, style: .relative)
                .font(.system(.caption, design: .default))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}