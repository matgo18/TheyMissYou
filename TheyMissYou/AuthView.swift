import SwiftUI

struct AuthView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                            }
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if !isLogin {
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Button
                        Button(action: {
                            handleAuth()
                        }) {
                            Text(isLogin ? "Login" : "Register")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
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
    
    private func handleAuth() {
        if !isLogin {
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
        }
        
        guard !email.isEmpty else {
            alertMessage = "Please enter an email"
            showingAlert = true
            return
        }
        
        guard !password.isEmpty else {
            alertMessage = "Please enter a password"
            showingAlert = true
            return
        }
        
        // TODO: Implement actual authentication
        alertMessage = isLogin ? "Login successful!" : "Registration successful!"
        showingAlert = true
        
        // Dismiss the view after successful auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    AuthView()
} 