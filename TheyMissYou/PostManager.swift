import SwiftUI
import FirebaseFirestore

class PostManager: ObservableObject {
    static let shared = PostManager()
    
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let imageManager = ImageManager.shared
    private let userManager = UserManager.shared
    private let groupManager = GroupManager.shared
    private var listener: ListenerRegistration?
    
    private init() {
        // Listen for auth state changes
        NotificationCenter.default.addObserver(self, selector: #selector(handleAuthStateChange), name: .authStateDidChange, object: nil)
        
        // Listen for group membership changes
        NotificationCenter.default.addObserver(self, selector: #selector(handleGroupMembershipChange), name: .groupMembershipChanged, object: nil)
    }
    
    deinit {
        removeListener()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleAuthStateChange() {
        if userManager.currentUser == nil {
            // User logged out, clear posts
            DispatchQueue.main.async {
                self.posts = []
                self.removeListener()
            }
        } else {
            // User logged in, fetch posts
            Task {
                await fetchPosts()
            }
        }
    }
    
    @objc private func handleGroupMembershipChange() {
        print("Group membership changed, refreshing posts...")
        Task {
            await fetchPosts()
        }
    }
    
    private func removeListener() {
        listener?.remove()
        listener = nil
    }
    
    func createPost(image: UIImage, caption: String) async throws {
        guard let userId = userManager.currentUser?.uid else {
            throw NSError(domain: "PostManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Save image locally
        let filename = try imageManager.saveImage(image)
        
        // Create post document
        let postId = UUID().uuidString
        let post = Post(
            id: postId,
            userId: userId,
            imageFilename: filename,
            caption: caption,
            createdAt: Date(),
            likes: 0
        )
        
        // Save post to Firestore
        try await db.collection("posts").document(postId).setData(post.toDictionary())
        
        // Add post ID to user's data
        try await userManager.addPostToUser(userId: userId, postId: postId)
    }
    
    @MainActor
    func fetchPosts() async {
        guard let currentUserId = userManager.currentUser?.uid else {
            posts = []
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // First, ensure we have the latest shared group users
            await groupManager.updateUsersInSharedGroups(forUserId: currentUserId)
            
            // Get all users in shared groups
            let sharedUsers = groupManager.usersInSharedGroups
            var allRelevantUserIds = sharedUsers
            allRelevantUserIds.insert(currentUserId) // Include current user
            
            var fetchedPosts: [Post] = []
            
            // Fetch posts directly from Firestore using user IDs
            let snapshot = try await db.collection("posts")
                .whereField("userId", in: Array(allRelevantUserIds))
                .getDocuments()
            
            for document in snapshot.documents {
                guard var post = Post(dictionary: document.data()) else { continue }
                
                // Fetch user data for the post
                if let userData = try? await userManager.getUser(userId: post.userId) {
                    post.username = userData.username
                    fetchedPosts.append(post)
                }
            }
            
            // Sort posts by creation date
            self.posts = fetchedPosts.sorted(by: { $0.createdAt > $1.createdAt })
            
            // Set up real-time updates
            setupPostsListener(userIds: allRelevantUserIds)
            
        } catch {
            self.error = error.localizedDescription
            print("Error fetching posts: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func setupPostsListener(userIds: Set<String>) {
        // Remove existing listener if any
        removeListener()
        
        // Only set up listener if we have user IDs to monitor
        guard !userIds.isEmpty else { return }
        
        listener = db.collection("posts")
            .whereField("userId", in: Array(userIds))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents else {
                    print("Error listening for post updates: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                Task {
                    var updatedPosts: [Post] = []
                    
                    for document in documents {
                        guard var post = Post(dictionary: document.data()) else { continue }
                        
                        // Fetch user data for the post
                        if let userData = try? await self.userManager.getUser(userId: post.userId) {
                            post.username = userData.username
                            updatedPosts.append(post)
                        }
                    }
                    
                    // Sort posts by creation date
                    updatedPosts.sort(by: { $0.createdAt > $1.createdAt })
                    
                    DispatchQueue.main.async {
                        self.posts = updatedPosts
                    }
                }
            }
    }
    
    func deletePost(_ post: Post) async throws {
        // Delete image file
        imageManager.deleteImage(filename: post.imageFilename)
        
        // Remove post ID from user's data
        try await userManager.removePostFromUser(userId: post.userId, postId: post.id)
        
        // Delete post document
        try await db.collection("posts").document(post.id).delete()
    }
    
    func likePost(_ post: Post) async throws {
        try await db.collection("posts").document(post.id).updateData([
            "likes": FieldValue.increment(Int64(1))
        ])
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
    var username: String?  // Added to store the username
    
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
    
    init(id: String, userId: String, imageFilename: String, caption: String, createdAt: Date, likes: Int, username: String? = nil) {
        self.id = id
        self.userId = userId
        self.imageFilename = imageFilename
        self.caption = caption
        self.createdAt = createdAt
        self.likes = likes
        self.username = username
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
        self.username = nil  // Will be set after fetching user data
    }
} 