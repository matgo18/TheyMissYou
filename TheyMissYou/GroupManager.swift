import SwiftUI
import FirebaseFirestore

extension Notification.Name {
    static let groupMembershipChanged = Notification.Name("groupMembershipChanged")
}

class GroupManager: ObservableObject {
    static let shared = GroupManager()
    
    @Published var userGroups: [Group] = []
    @Published var usersInSharedGroups: Set<String> = []
    private let db = Firestore.firestore()
    
    private init() {}
    
    func createGroup(name: String, createdBy: String) async throws -> Group {
        let groupId = UUID().uuidString
        let group = Group(
            id: groupId,
            name: name,
            createdBy: createdBy,
            memberIds: [createdBy] // Creator is automatically a member
        )
        
        try await db.collection("groups").document(groupId).setData(group.toDictionary())
        await fetchUserGroups(userId: createdBy)
        return group
    }
    
    func joinGroup(groupId: String, userId: String) async throws {
        let groupRef = db.collection("groups").document(groupId)
        
        // First check if the group exists and if the user can access it
        let groupDoc = try await groupRef.getDocument()
        guard let groupData = groupDoc.data(),
              var group = Group(dictionary: groupData) else {
            throw NSError(
                domain: "AppErrorDomain",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Group not found or inaccessible"]
            )
        }
        
        // Check if user is already a member
        if group.memberIds.contains(userId) {
            throw NSError(
                domain: "AppErrorDomain",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "You are already a member of this group"]
            )
        }
        
        // Add user to group using a simple update instead of transaction
        group.memberIds.append(userId)
        try await groupRef.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
        
        // Refresh user's groups and notify about membership change
        await fetchUserGroups(userId: userId)
        
        // Notify about group membership change
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .groupMembershipChanged, object: nil)
        }
    }
    
    func updateUsersInSharedGroups(forUserId userId: String) async {
        do {
            // Get all groups where the user is a member
            let querySnapshot = try await db.collection("groups")
                .whereField("memberIds", arrayContains: userId)
                .getDocuments()
            
            // Collect all unique user IDs from these groups
            var userIds = Set<String>()
            for document in querySnapshot.documents {
                guard let group = Group(dictionary: document.data()) else { continue }
                userIds.formUnion(group.memberIds)
            }
            
            // Remove the current user from the set
            userIds.remove(userId)
            
            DispatchQueue.main.async {
                self.usersInSharedGroups = userIds
            }
        } catch {
            print("Error updating users in shared groups: \(error.localizedDescription)")
        }
    }
    
    func isUserInSharedGroup(userId: String, currentUserId: String) -> Bool {
        // If it's the current user, return true
        if userId == currentUserId { return true }
        
        // Check if the user is in the shared groups set
        return usersInSharedGroups.contains(userId)
    }
    
    func fetchUserGroups(userId: String) async {
        do {
            // Get groups where user is a member
            let querySnapshot = try await db.collection("groups")
                .whereField("memberIds", arrayContains: userId)
                .getDocuments()
            
            let groups = querySnapshot.documents.compactMap { document -> Group? in
                return Group(dictionary: document.data())
            }
            
            DispatchQueue.main.async {
                self.userGroups = groups.sorted(by: { $0.createdAt > $1.createdAt })
            }
            
            // Update the shared groups users whenever groups are fetched
            await updateUsersInSharedGroups(forUserId: userId)
        } catch {
            print("Error fetching user groups: \(error.localizedDescription)")
        }
    }
    
    func searchGroups(query: String) async throws -> [Group] {
        // If query is empty, return all groups
        if query.isEmpty {
            let querySnapshot = try await db.collection("groups")
                .limit(to: 50)  // Limit to prevent loading too many groups
                .getDocuments()
            
            return querySnapshot.documents.compactMap { Group(dictionary: $0.data()) }
        }
        
        // Convert query to lowercase for case-insensitive search
        let lowercaseQuery = query.lowercased()
        
        // Get all groups and filter client-side for better partial matching
        let querySnapshot = try await db.collection("groups")
            .getDocuments()
        
        let filteredGroups = querySnapshot.documents.compactMap { document -> Group? in
            guard let group = Group(dictionary: document.data()) else { return nil }
            
            // Check if the group name contains the search query (case-insensitive)
            return group.name.lowercased().contains(lowercaseQuery) ? group : nil
        }
        
        // Sort by name for better UX
        return filteredGroups.sorted { $0.name < $1.name }
    }
    
    func leaveGroup(groupId: String, userId: String) async throws {
        let groupRef = db.collection("groups").document(groupId)
        
        // First check if the group exists
        let groupDoc = try await groupRef.getDocument()
        guard let groupData = groupDoc.data(),
              let group = Group(dictionary: groupData) else {
            throw NSError(
                domain: "AppErrorDomain",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Group not found"]
            )
        }
        
        // Check if user is a member
        guard group.memberIds.contains(userId) else {
            throw NSError(
                domain: "AppErrorDomain",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "You are not a member of this group"]
            )
        }
        
        // Don't allow the creator to leave if they're the only member
        if group.createdBy == userId && group.memberIds.count == 1 {
            throw NSError(
                domain: "AppErrorDomain",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "As the creator, you cannot leave the group while being the only member. Delete the group instead."]
            )
        }
        
        // Remove user from group
        try await groupRef.updateData([
            "memberIds": FieldValue.arrayRemove([userId])
        ])
        
        // Refresh user's groups and notify about membership change
        await fetchUserGroups(userId: userId)
        
        // Notify about group membership change
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .groupMembershipChanged, object: nil)
        }
    }
} 