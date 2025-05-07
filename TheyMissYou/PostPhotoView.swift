import SwiftUI
import PhotosUI

struct PostPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var postManager = PostManager.shared
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var caption = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    private let darkModeColor = Color(red: 28/255, green: 28/255, blue: 30/255)
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Top Navigation Bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text("New Post")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await handleShare()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        } else {
                            Text("Share")
                                .foregroundColor(.green)
                                .font(.title3)
                                .bold()
                        }
                    }
                    .disabled(selectedImage == nil || isLoading)
                }
                .padding()
                .background(isDarkMode ? darkModeColor : Color.white)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Image Selection Area
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .onTapGesture {
                                    isImagePickerPresented = true
                                }
                        } else {
                            Button(action: {
                                isImagePickerPresented = true
                            }) {
                                VStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 40))
                                        .foregroundColor(.green)
                                    Text("Add Photo")
                                        .foregroundColor(.green)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Caption TextField
                        TextField("Write a caption...", text: $caption, axis: .vertical)
                            .padding()
                            .background(isDarkMode ? darkModeColor.opacity(0.5) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(isDarkMode ? .white : .primary)
                            .disabled(isLoading)
                    }
                    .padding()
                }
            }
            .background(isDarkMode ? darkModeColor : Color.white)
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Message"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationBarHidden(true)
        }
    }
    
    private func handleShare() async {
        guard let image = selectedImage else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await postManager.createPost(image: image, caption: caption)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

// Image Picker using PhotosUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
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
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    PostPhotoView()
} 