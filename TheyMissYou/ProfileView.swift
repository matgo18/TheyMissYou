import SwiftUI
import MapKit

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var userManager = UserManager.shared
    @State private var showingSignOutAlert = false
    @State private var showingAuthView = false
    @State private var showingMapPicker = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State private var isUpdatingLocation = false
    
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
                    
                    Text("Profile")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if userManager.isAuthenticated {
                        Button(action: {
                            showingSignOutAlert = true
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                    }
                }
                .padding()
                .background(isDarkMode ? darkModeColor : Color.white)
                
                if userManager.isAuthenticated {
                    authenticatedContent
                } else {
                    unauthenticatedContent
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .background(isDarkMode ? darkModeColor : Color.white)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .fullScreenCover(isPresented: $showingAuthView) {
                AuthView()
            }
            .fullScreenCover(isPresented: $showingMapPicker) {
                MapPickerView(coordinate: $coordinate)
                    .onDisappear {
                        if coordinate.latitude != 0 || coordinate.longitude != 0 {
                            Task {
                                await updateLocation()
                            }
                        }
                    }
            }
        }
    }
    
    private var authenticatedContent: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile Picture
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 50))
                    )
                    .padding(.top, 20)
                
                // User Info
                VStack(spacing: 15) {
                    if let userData = userManager.userData {
                        Text(userData.username)
                            .font(.title)
                            .bold()
                            .foregroundColor(isDarkMode ? .white : .primary)
                        
                        Text(userData.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if let bio = userData.bio {
                            Text(bio)
                                .font(.body)
                                .foregroundColor(isDarkMode ? .white : .primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Text("Member since: \(userData.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                            
                        // Location Update Button
                        Button(action: {
                            showingMapPicker = true
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.green)
                                Text(isUpdatingLocation ? "Updating..." : "Update Location")
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .disabled(isUpdatingLocation)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var unauthenticatedContent: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Not Signed In")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Sign in to view your profile")
                .font(.body)
                .foregroundColor(.gray)
            
            Button(action: {
                showingAuthView = true
            }) {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func signOut() {
        do {
            try userManager.signOut()
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func updateLocation() async {
        guard coordinate.latitude != 0 || coordinate.longitude != 0 else { return }
        
        isUpdatingLocation = true
        defer { isUpdatingLocation = false }
        
        do {
            try await userManager.updateLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    ProfileView()
} 