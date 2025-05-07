import SwiftUI
import FirebaseFirestore

struct PostView: View {
    // MARK: - Properties
    let post: Post
    
    // MARK: - Environment
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - State Objects
    @StateObject private var postManager = PostManager.shared
    @StateObject private var userManager = UserManager.shared
    @StateObject private var imageManager = ImageManager.shared
    
    // MARK: - State
    @State private var username: String = "Unknown User"
    @State private var showingDeleteAlert = false
    @State private var isLiking = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoadingUsername = true
    
    // MARK: - Computed Properties
    private var isCurrentUserPost: Bool {
        post.userId == userManager.currentUser?.uid
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            postHeader
            
            // Image
            postImage
            
            // Caption
            Text(post.caption)
                .font(.body)
                .padding(.vertical, 4)
            
            // Footer
            postFooter
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(radius: 5)
        .alert("Delete Post", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePost()
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await fetchUsername()
        }
    }
    
    // MARK: - View Components
    private var postHeader: some View {
        HStack {
            if isLoadingUsername {
                ProgressView()
                    .frame(height: 20)
            } else {
                Text(username)
                    .font(.headline)
            }
            Spacer()
            Text(post.createdAt.timeAgo())
                .font(.caption)
                .foregroundColor(.gray)
            
            if isCurrentUserPost {
                Menu {
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
        }
    }
    
    private var postImage: some View {
        Group {
            if let image = imageManager.loadImage(filename: post.imageFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.largeTitle)
                    )
            }
        }
    }
    
    private var postFooter: some View {
        HStack {
            Button(action: {
                if !isLiking {
                    likePost()
                }
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .opacity(isLiking ? 0.5 : 1.0)
                    Text("\(post.likes)")
                        .font(.subheadline)
                }
            }
            .disabled(isLiking)
            
            Spacer()
        }
    }
    
    // MARK: - Methods
    private func fetchUsername() async {
        isLoadingUsername = true
        do {
            if let userData = try await userManager.getUser(userId: post.userId) {
                username = userData.username
            } else {
                username = "Unknown User"
                errorMessage = "Could not find user information"
                showError = true
            }
        } catch {
            username = "Unknown User"
            errorMessage = "Error loading username: \(error.localizedDescription)"
            showError = true
        }
        isLoadingUsername = false
    }
    
    private func likePost() {
        isLiking = true
        Task {
            do {
                try await postManager.likePost(post)
                isLiking = false
            } catch {
                errorMessage = "Failed to like post: \(error.localizedDescription)"
                showError = true
                isLiking = false
            }
        }
    }
    
    private func deletePost() {
        Task {
            do {
                try await postManager.deletePost(post)
            } catch {
                errorMessage = "Failed to delete post: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

// MARK: - Date Extension
extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
} 