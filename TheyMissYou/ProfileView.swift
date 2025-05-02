import SwiftUI

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    
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
                    
                    Button(action: {
                        // Edit profile action
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
                .padding()
                .background(isDarkMode ? darkModeColor : Color.white)
                
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
                            Text("John Doe")
                                .font(.title)
                                .bold()
                                .foregroundColor(isDarkMode ? .white : .primary)
                            
                            Text("@johndoe")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("Living life one day at a time")
                                .font(.body)
                                .foregroundColor(isDarkMode ? .white : .primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Stats
                        HStack(spacing: 40) {
                            VStack {
                                Text("256")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.green)
                                Text("Following")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("1.2K")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.green)
                                Text("Followers")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("48")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.green)
                                Text("Posts")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                // Edit Profile action
                            }) {
                                Text("Edit Profile")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                // Share Profile action
                            }) {
                                Text("Share Profile")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(isDarkMode ? darkModeColor : Color.white)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    ProfileView()
} 