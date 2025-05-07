import SwiftUI

struct AuthView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var userManager = UserManager.shared
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
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
                    
                    Text(isLogin ? "Login" : "Register")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    // Empty view for symmetry
                    Color.clear
                        .frame(width: 30, height: 30)
                }
                .padding()
                .background(isDarkMode ? darkModeColor : Color.white)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // App Logo
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 40))
                            )
                            .padding(.top, 20)
                        
                        // Form Fields
                        VStack(spacing: 15) {
                            if !isLogin {
                                TextField("Username", text: $username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disabled(isLoading)
                            }
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(isLoading)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(isLoading)
                            
                            if !isLogin {
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(isLoading)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Button
                        Button(action: {
                            Task {
                                await handleAuth()
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isLogin ? "Login" : "Register")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(isLoading)
                        
                        // Toggle between Login and Register
                        Button(action: {
                            isLogin.toggle()
                            // Clear fields when switching
                            email = ""
                            password = ""
                            confirmPassword = ""
                            username = ""
                        }) {
                            Text(isLogin ? "Don't have an account? Register" : "Already have an account? Login")
                                .foregroundColor(.green)
                        }
                        .padding(.top)
                        .disabled(isLoading)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(isDarkMode ? darkModeColor : Color.white)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Message"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func handleAuth() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if isLogin {
                try await userManager.login(email: email, password: password)
                presentationMode.wrappedValue.dismiss()
            } else {
                // Registration validation
                guard !username.isEmpty else {
                    alertMessage = "Please enter a username"
                    showingAlert = true
                    return
                }
                
                guard password == confirmPassword else {
                    alertMessage = "Passwords do not match"
                    showingAlert = true
                    return
                }
                
                try await userManager.register(email: email, password: password, username: username)
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

#Preview {
    AuthView()
} 