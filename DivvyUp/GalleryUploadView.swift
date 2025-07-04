import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Gallery Upload View
struct GalleryUploadView: View {
    @ObservedObject var ocrService: OCRService
    @State private var selectedItem: PhotosPickerItem?
    @State private var isDragOver = false
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag and Drop Area
            RoundedRectangle(cornerRadius: 12)
                .fill(isDragOver ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(isDragOver ? .blue : .gray)
                        
                        Text("Drop receipt images here")
                            .font(.headline)
                            .foregroundColor(isDragOver ? .blue : .gray)
                        
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button("Browse Photos") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                )
                .onDrop(of: [.image], isTargeted: $isDragOver) { providers in
                    handleDrop(providers: providers)
                }
            
            // Photo Picker
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Choose from Photos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await loadSelectedPhoto(from: newItem)
                }
            }
            
            // Processing Indicator
            if ocrService.isProcessing {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Processing image...")
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            // Recent uploads or preview
            if !ocrService.recognizedText.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recognized Text:")
                        .font(.headline)
                    
                    ScrollView {
                        Text(ocrService.recognizedText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 150)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
            }
        }
        .padding()
        .navigationTitle("Upload Receipt")
        .sheet(isPresented: $showingImagePicker) {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Select Photo")
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        ocrService.processImage(image)
                    }
                }
            }
            return true
        }
        
        return false
    }
    
    private func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                ocrService.processImage(image)
            }
        }
    }
}

// MARK: - Multiple Image Upload View
struct MultipleImageUploadView: View {
    @ObservedObject var ocrService: OCRService
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var currentImageIndex = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Multiple Photo Picker
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 10,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo.stack")
                    Text("Select Multiple Photos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    await loadSelectedPhotos(from: newItems)
                }
            }
            
            // Image Preview Carousel
            if !images.isEmpty {
                VStack(spacing: 12) {
                    Text("Processing \(currentImageIndex + 1) of \(images.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TabView(selection: $currentImageIndex) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Image(uiImage: images[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 220)
                    
                    HStack(spacing: 16) {
                        Button("Process Current") {
                            if currentImageIndex < images.count {
                                ocrService.processImage(images[currentImageIndex])
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Process All") {
                            processAllImages()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
            }
        }
        .padding()
    }
    
    private func loadSelectedPhotos(from items: [PhotosPickerItem]) async {
        var loadedImages: [UIImage] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loadedImages.append(image)
            }
        }
        
        await MainActor.run {
            images = loadedImages
            currentImageIndex = 0
        }
    }
    
    private func processAllImages() {
        for image in images {
            ocrService.processImage(image)
        }
    }
}

// MARK: - Drag and Drop Modifier
struct DropImageModifier: ViewModifier {
    @ObservedObject var ocrService: OCRService
    @State private var isDragOver = false
    
    func body(content: Content) -> some View {
        content
            .onDrop(of: [.image], isTargeted: $isDragOver) { providers in
                handleDrop(providers: providers)
            }
            .overlay(
                isDragOver ? 
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
                    .background(Color.blue.opacity(0.1))
                : nil
            )
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        ocrService.processImage(image)
                    }
                }
            }
            return true
        }
        
        return false
    }
}

extension View {
    func dropImage(ocrService: OCRService) -> some View {
        self.modifier(DropImageModifier(ocrService: ocrService))
    }
} 