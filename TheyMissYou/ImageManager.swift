import SwiftUI

class ImageManager: ObservableObject {
    static let shared = ImageManager()
    
    @Published private var imageCache: [String: UIImage] = [:]
    
    private init() {}
    
    func saveImage(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.compressionFailed
        }
        
        let filename = UUID().uuidString + ".jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        imageCache[filename] = image
        return filename
    }
    
    func loadImage(filename: String) -> UIImage? {
        // Check cache first
        if let cachedImage = imageCache[filename] {
            return cachedImage
        }
        
        // If not in cache, load from disk
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return nil }
        
        // Store in cache
        imageCache[filename] = image
        return image
    }
    
    func deleteImage(filename: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
        imageCache.removeValue(forKey: filename)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

enum ImageError: LocalizedError {
    case compressionFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        }
    }
} 