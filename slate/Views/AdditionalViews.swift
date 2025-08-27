import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var apiManager: APIManager
    let onNewChat: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon/Logo
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(.blue)
                
                Text("AI Chat")
                    .font(.system(.largeTitle, design: .default, weight: .bold))
                    .foregroundStyle(.primary)
            }
            
            VStack(spacing: 12) {
                Text("Welcome to AI Chat")
                    .font(.system(.title2, design: .default, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                Text("Start a conversation with AI models from OpenAI and OpenRouter. Your conversations are saved locally and privately.")
                    .font(.system(.body, design: .default))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: onNewChat) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(.body, weight: .medium))
                    Text("Start New Chat")
                        .font(.system(.body, design: .default, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(apiManager.openAIKey.isEmpty && apiManager.openRouterKey.isEmpty)
            
            if apiManager.openAIKey.isEmpty && apiManager.openRouterKey.isEmpty {
                Text("Please configure your API keys in Settings")
                    .font(.system(.caption, design: .default))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Model Picker
struct ModelPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var apiManager: APIManager
    let conversation: Conversation
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("API Provider", selection: Binding(
                        get: { apiManager.selectedProvider },
                        set: {
                            apiManager.selectedProvider = $0
                            apiManager.saveKeys()
                            Task {
                                await apiManager.fetchModels()
                            }
                        }
                    )) {
                        ForEach(APIManager.APIProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue)
                                .tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("API Provider")
                } footer: {
                    Text("Switch between OpenAI and OpenRouter to access different models")
                }
                
                Section {
                    if apiManager.isLoadingModels {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading models...")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(apiManager.availableModels) { model in
                            Button(action: {
                                conversation.selectedModel = model.id
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.displayName)
                                            .font(.system(.body, design: .default, weight: .medium))
                                            .foregroundStyle(.primary)
                                        
                                        if model.supportsThinking {
                                            Text("Supports reasoning")
                                                .font(.system(.caption, design: .default))
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if conversation.selectedModel == model.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Available Models")
                } footer: {
                    if apiManager.availableModels.isEmpty && !apiManager.isLoadingModels {
                        Text("No models available. Please check your API key in Settings.")
                    }
                }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if apiManager.availableModels.isEmpty {
                Task {
                    await apiManager.fetchModels()
                }
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var apiManager: APIManager
    @State private var showingAPIKeyInfo = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("OpenAI API Key", text: $apiManager.openAIKey)
                            .textContentType(.password)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: { showingAPIKeyInfo = true }) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    TextField("OpenRouter API Key", text: $apiManager.openRouterKey)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                    
                } header: {
                    Text("API Keys")
                } footer: {
                    Text("Your API keys are stored securely on your device and never shared.")
                }
                
                Section {
                    Button("Refresh Models") {
                        Task {
                            await apiManager.fetchModels()
                        }
                    }
                    .disabled(apiManager.isLoadingModels)
                    
                    if apiManager.isLoadingModels {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading...")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Models")
                } footer: {
                    Text("Available models: \(apiManager.availableModels.count)")
                }
                
                Section {
                    Link("OpenAI API Keys", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    Link("OpenRouter API Keys", destination: URL(string: "https://openrouter.ai/keys")!)
                } header: {
                    Text("Get API Keys")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        apiManager.saveKeys()
                        dismiss()
                    }
                }
            }
        }
        .alert("API Keys", isPresented: $showingAPIKeyInfo) {
            Button("OK") { }
        } message: {
            Text("API keys allow the app to communicate with AI services. You can get free keys from OpenAI and OpenRouter. Your keys are stored locally and securely.")
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [URL]
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .text,
            .pdf,
            .data
        ], asCopy: true)
        
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedFiles.append(contentsOf: urls)
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 10
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self?.parent.selectedImages.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}
