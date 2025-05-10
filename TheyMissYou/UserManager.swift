import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userData: UserData?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {
        // Listen for auth state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            print("Auth state changed. User: \(user?.uid ?? "nil")")
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
                if let user = user {
                    // Start fetching user data
                    Task {
                        await self?.fetchUserData(userId: user.uid)
                    }
                } else {
                    self?.userData = nil
                }
            }
        }
    }
    
    func login(email: String, password: String) async throws {
        print("Attempting login with email: \(email)")
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            print("Login successful for user: \(result.user.uid)")
            await fetchUserData(userId: result.user.uid)
        } catch {
            print("Login failed: \(error.localizedDescription)")
            throw AuthError.loginFailed(error.localizedDescription)
        }
    }
    
    func register(email: String, password: String, username: String, latitude: Double? = nil, longitude: Double? = nil) async throws {
        print("Attempting registration with email: \(email), username: \(username)")
        do {
            // Check if username is already taken
            let querySnapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments()
            
            if !querySnapshot.documents.isEmpty {
                print("Username already taken: \(username)")
                throw AuthError.registrationFailed("Username is already taken")
            }
            
            // Create auth user
            let result = try await auth.createUser(withEmail: email, password: password)
            print("Auth user created successfully: \(result.user.uid)")
            
            // Create user document in Firestore
            let userData = UserData(
                id: result.user.uid,
                email: email,
                username: username,
                createdAt: Date(),
                latitude: latitude,
                longitude: longitude
            )
            
            let userDict = userData.toDictionary()
            print("Creating Firestore document for user: \(result.user.uid)")
            try await db.collection("users").document(result.user.uid).setData(userDict)
            print("Firestore document created successfully")
            
            await fetchUserData(userId: result.user.uid)
        } catch let error as AuthError {
            print("Registration failed with AuthError: \(error.localizedDescription)")
            throw error
        } catch {
            print("Registration failed with error: \(error.localizedDescription)")
            throw AuthError.registrationFailed(error.localizedDescription)
        }
    }
    
    func signOut() throws {
        print("Attempting sign out")
        do {
            try auth.signOut()
            DispatchQueue.main.async {
                self.userData = nil
                self.isAuthenticated = false
            }
            print("Sign out successful")
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }
    
    private func fetchUserData(userId: String) async {
        print("Fetching user data for userId: \(userId)")
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data() {
                print("User data fetched successfully")
                DispatchQueue.main.async {
                    self.userData = UserData(dictionary: data)
                }
            } else {
                print("No user data found for userId: \(userId)")
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }
    
    func getUser(userId: String) async throws -> UserData? {
        print("Fetching user data for userId: \(userId)")
        let document = try await db.collection("users").document(userId).getDocument()
        if let data = document.data() {
            print("User data fetched successfully")
            return UserData(dictionary: data)
        } else {
            print("No user data found for userId: \(userId)")
            return nil
        }
    }
    
    func updateLocation(latitude: Double, longitude: Double) async throws {
        guard let userId = currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        print("Updating location for user: \(userId)")
        let data = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        do {
            try await db.collection("users").document(userId).updateData(data)
            print("Location updated successfully")
            
            // Update local user data
            if var updatedUserData = self.userData {
                updatedUserData.latitude = latitude
                updatedUserData.longitude = longitude
                DispatchQueue.main.async {
                    self.userData = updatedUserData
                }
            }
        } catch {
            print("Error updating location: \(error.localizedDescription)")
            throw error
        }
    }
}

// User data model
struct UserData: Codable {
    let id: String
    let email: String
    let username: String
    let createdAt: Date
    var profileImageUrl: String?
    var bio: String?
    var latitude: Double?
    var longitude: Double?
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "email": email,
            "username": username,
            "createdAt": createdAt,
            "profileImageUrl": profileImageUrl as Any,
            "bio": bio as Any,
            "latitude": latitude as Any,
            "longitude": longitude as Any
        ]
    }
    
    init(id: String, email: String, username: String, createdAt: Date, profileImageUrl: String? = nil, bio: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.createdAt = createdAt
        self.profileImageUrl = profileImageUrl
        self.bio = bio
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let email = dictionary["email"] as? String,
              let username = dictionary["username"] as? String,
              let createdAt = dictionary["createdAt"] as? Timestamp else {
            print("Failed to parse user data: missing required fields")
            return nil
        }
        
        self.id = id
        self.email = email
        self.username = username
        self.createdAt = createdAt.dateValue()
        self.profileImageUrl = dictionary["profileImageUrl"] as? String
        self.bio = dictionary["bio"] as? String
        self.latitude = dictionary["latitude"] as? Double
        self.longitude = dictionary["longitude"] as? Double
    }
}

// Custom error enum for better error handling
enum AuthError: LocalizedError {
    case loginFailed(String)
    case registrationFailed(String)
    case signOutFailed(String)
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .loginFailed(let message),
             .registrationFailed(let message),
             .signOutFailed(let message):
            return message
        case .notAuthenticated:
            return "User is not authenticated"
        }
    }
} 