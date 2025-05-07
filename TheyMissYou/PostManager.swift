import SwiftUI
import FirebaseFirestore

class PostManager: ObservableObject {
    static let shared = PostManager()
    
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let imageManager = ImageManager.shared
    
    private init() {
        Task {
            await fetchPosts()
        }
    }
    
    func createPost(image: UIImage, caption: String) async throws {
        guard let userId = UserManager.shared.currentUser?.uid else {
            throw NSError(domain: "PostManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Save image locally
        let filename = try imageManager.saveImage(image)
        
        // Create post document
        let post = Post(
            id: UUID().uuidString,
            userId: userId,
            imageFilename: filename,
            caption: caption,
            createdAt: Date(),
            likes: 0
        )
        
        try await db.collection("posts").document(post.id).setData(post.toDictionary())
        await fetchPosts()
    }
    
    @MainActor
    func fetchPosts() async {
        isLoading = true
        error = nil
        
        do {
            let snapshot = try await db.collection("posts")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            posts = snapshot.documents.compactMap { document in
                Post(dictionary: document.data())
            }
            
            // Set up real-time updates
            db.collection("posts")
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("Error fetching posts: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    self?.posts = documents.compactMap { document in
                        Post(dictionary: document.data())
                    }
                }
        } catch {
            self.error = error.localizedDescription
            print("Error fetching posts: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func likePost(_ post: Post) async throws {
        try await db.collection("posts").document(post.id).updateData([
            "likes": FieldValue.increment(Int64(1))
        ])
    }
    
    func deletePost(_ post: Post) async throws {
        // Delete image file
        imageManager.deleteImage(filename: post.imageFilename)
        
        // Delete post document
        try await db.collection("posts").document(post.id).delete()
    }
}

// Post data model
struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let imageFilename: String
    let caption: String
    let createdAt: Date
    var likes: Int
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "imageFilename": imageFilename,
            "caption": caption,
            "createdAt": createdAt,
            "likes": likes
        ]
    }
    
    init(id: String, userId: String, imageFilename: String, caption: String, createdAt: Date, likes: Int) {
        self.id = id
        self.userId = userId
        self.imageFilename = imageFilename
        self.caption = caption
        self.createdAt = createdAt
        self.likes = likes
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let userId = dictionary["userId"] as? String,
              let imageFilename = dictionary["imageFilename"] as? String,
              let caption = dictionary["caption"] as? String,
              let createdAt = dictionary["createdAt"] as? Timestamp,
              let likes = dictionary["likes"] as? Int else {
            print("Failed to parse post data: missing required fields")
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.imageFilename = imageFilename
        self.caption = caption
        self.createdAt = createdAt.dateValue()
        self.likes = likes
    }
} 