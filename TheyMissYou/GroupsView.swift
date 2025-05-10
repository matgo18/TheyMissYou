import SwiftUI

struct GroupsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var groupManager = GroupManager.shared
    @StateObject private var userManager = UserManager.shared
    
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var newGroupName = ""
    @State private var searchQuery = ""
    @State private var searchResults: [Group] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    private let darkModeColor = Color(red: 28/255, green: 28/255, blue: 30/255)
    
    var body: some View {
        NavigationView {
            VStack {
                // Top Navigation Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text("Groups")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button(action: {
                        showingCreateGroup = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
                .padding()
                .background(isDarkMode ? darkModeColor : Color.white)
                
                // My Groups Section
                VStack(alignment: .leading) {
                    Text("My Groups")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if groupManager.userGroups.isEmpty {
                        VStack {
                            Text("You haven't joined any groups yet")
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                            Spacer()
                        }
                    } else {
                        List(groupManager.userGroups) { group in
                            GroupRow(group: group)
                        }
                    }
                }
                
                // Join Group Button
                Button(action: {
                    showingJoinGroup = true
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Join a Group")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .padding()
            }
            .background(isDarkMode ? darkModeColor : Color.white)
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupSheet(isPresented: $showingCreateGroup)
            }
            .sheet(isPresented: $showingJoinGroup) {
                JoinGroupSheet(isPresented: $showingJoinGroup)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let userId = userManager.currentUser?.uid {
                    Task {
                        await groupManager.fetchUserGroups(userId: userId)
                    }
                }
            }
        }
    }
}

struct CreateGroupSheet: View {
    @Binding var isPresented: Bool
    @StateObject private var groupManager = GroupManager.shared
    @StateObject private var userManager = UserManager.shared
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Group Name", text: $groupName)
                        .disabled(isLoading)
                }
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                }
            }
            .navigationTitle("Create Group")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
                .disabled(isLoading),
                trailing: Button(action: {
                    Task {
                        await createGroup()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Create")
                    }
                }
                .disabled(groupName.isEmpty || isLoading)
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .interactiveDismissDisabled(isLoading)
    }
    
    private func createGroup() async {
        guard let userId = userManager.currentUser?.uid else {
            errorMessage = "You must be logged in to create a group"
            showError = true
            return
        }
        
        isLoading = true
        
        do {
            _ = try await groupManager.createGroup(name: groupName, createdBy: userId)
            isLoading = false
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}

struct JoinGroupSheet: View {
    @Binding var isPresented: Bool
    @StateObject private var groupManager = GroupManager.shared
    @StateObject private var userManager = UserManager.shared
    @State private var searchQuery = ""
    @State private var searchResults: [Group] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var searchTask: DispatchWorkItem?
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchQuery, placeholder: "Search groups by name")
                    .padding()
                
                if isLoading {
                    ProgressView("Searching...")
                        .padding(.top, 40)
                } else if searchResults.isEmpty {
                    VStack {
                        if searchQuery.isEmpty {
                            Text("Enter a group name to search")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else {
                            Text("No groups found")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        }
                        Spacer()
                    }
                } else {
                    List(searchResults) { group in
                        Button(action: {
                            joinGroup(group)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(group.name)
                                        .font(.headline)
                                    Text("\(group.memberIds.count) members")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Join Group")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            })
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: searchQuery) { newValue in
            // Cancel any previous search task
            searchTask?.cancel()
            
            // Create a new search task
            let task = DispatchWorkItem {
                Task {
                    await performSearch()
                }
            }
            searchTask = task
            
            // Schedule the task with a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
        }
        .onAppear {
            // Load all groups initially
            Task {
                await performSearch()
            }
        }
    }
    
    private func performSearch() async {
        isLoading = true
        do {
            let results = try await groupManager.searchGroups(query: searchQuery)
            DispatchQueue.main.async {
                self.searchResults = results
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    private func joinGroup(_ group: Group) {
        guard let userId = userManager.currentUser?.uid else {
            errorMessage = "You must be logged in to join a group"
            showError = true
            return
        }
        
        Task {
            do {
                try await groupManager.joinGroup(groupId: group.id, userId: userId)
                DispatchQueue.main.async {
                    isPresented = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct GroupRow: View {
    let group: Group
    @StateObject private var userManager = UserManager.shared
    @StateObject private var groupManager = GroupManager.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLeaving = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(group.name)
                .font(.headline)
            Text("\(group.memberIds.count) members")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                leaveGroup()
            } label: {
                Label("Leave", systemImage: "person.fill.xmark")
            }
            .disabled(isLeaving)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func leaveGroup() {
        guard let userId = userManager.currentUser?.uid else {
            errorMessage = "You must be logged in to leave a group"
            showError = true
            return
        }
        
        isLeaving = true
        
        Task {
            do {
                try await groupManager.leaveGroup(groupId: group.id, userId: userId)
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            DispatchQueue.main.async {
                isLeaving = false
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

#Preview {
    GroupsView()
} 