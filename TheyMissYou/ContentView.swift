//
//  ContentView.swift
//  TheyMissYou
//
//  Created by Xcode on 4/14/25.
//

import SwiftUI
import UserNotifications
import FirebaseFirestore

struct SlideFromRight: GeometryEffect {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translationX = offset * size.width
        return ProjectionTransform(CGAffineTransform(translationX: translationX, y: 0))
    }
}

struct ContentView: View {
    @StateObject private var postManager = PostManager.shared
    @StateObject private var userManager = UserManager.shared
    @State private var isMenuSheetPresented = false
    @State private var showingAuthView = false
    @State private var showingSettingsView = false
    @State private var showingProfileView = false
    @State private var showingPostPhotoView = false
    @State private var backgroundOpacity: Double = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationFrequency") private var notificationFrequency = NotificationFrequency.immediate.rawValue
    @Environment(\.scenePhase) private var scenePhase
    
    private let darkModeColor = Color(red: 28/255, green: 28/255, blue: 30/255)
    
    // Initialize notifications when the view appears
    func initializeNotifications() {
        NotificationManager.shared.requestPermission()
        
        // Listen for notification taps
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowPostPhotoView"),
            object: nil,
            queue: .main
        ) { _ in
            showingPostPhotoView = true
        }
    }
    
    // Function to send a reminder notification
    func sendReminderNotification() {
        NotificationManager.shared.scheduleNotification(
            title: "We Miss You!",
            body: "Come back and check what's new in the app!",
            timeInterval: notificationFrequency
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Top Navigation Bar
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                isMenuSheetPresented.toggle()
                                backgroundOpacity = isMenuSheetPresented ? 0.3 : 0
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .foregroundColor(.green)
                                .font(.title2)
                        }

                        Spacer()

                        Text("They Miss You")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.green)

                        Spacer()

                        Button(action: {
                            showingAuthView = true
                        }) {
                            Image(systemName: "person.badge.key.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    .padding()
                    .background(isDarkMode ? darkModeColor : Color.white)
                    
                    // Main content
                    ZStack {
                        if postManager.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                        } else if let error = postManager.error {
                            VStack(spacing: 16) {
                                Text("Error loading posts")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.gray)
                                Button(action: {
                                    Task {
                                        await postManager.fetchPosts()
                                    }
                                }) {
                                    Text("Try Again")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                        } else if postManager.posts.isEmpty {
                            VStack(spacing: 16) {
                                Text("No posts yet")
                                    .font(.title3)
                                if UserManager.shared.isAuthenticated {
                                    Button(action: {
                                        showingPostPhotoView = true
                                    }) {
                                        Text("Create your first post")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(postManager.posts) { post in
                                        PostView(post: post)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical)
                            }
                            .refreshable {
                                await postManager.fetchPosts()
                            }
                        }
                    }
                    .background(isDarkMode ? darkModeColor : Color.white)
                }
                .background(isDarkMode ? darkModeColor : Color.white)
                
                // Side Menu
                GeometryReader { geometry in
                    HStack {
                        VStack(spacing: 20) {
                            HStack {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        isMenuSheetPresented = false
                                        showingProfileView = true
                                    }
                                }) {
                                    Circle()
                                        .fill(Color.green.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.green)
                                                .font(.title2)
                                        )
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 50)
                            
                            Text("Menu")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.green)
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    isMenuSheetPresented = false
                                    showingAuthView = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "person.badge.key.fill")
                                    Text("Login / Register")
                                }
                                .foregroundColor(.green)
                                .font(.title3)
                            }
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    isMenuSheetPresented = false
                                    showingPostPhotoView = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("New Post")
                                }
                                .foregroundColor(.green)
                                .font(.title3)
                            }
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    isMenuSheetPresented = false
                                    showingSettingsView = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "gear")
                                    Text("Settings")
                                }
                                .foregroundColor(.green)
                                .font(.title3)
                            }
                            
                            Spacer()
                        }
                        .frame(width: geometry.size.width * 0.6)
                        .background(isDarkMode ? darkModeColor : Color.white)
                        .shadow(radius: 5)
                        
                        Spacer()
                    }
                    .offset(x: isMenuSheetPresented ? 0 : -geometry.size.width * 0.6)
                }
                .zIndex(1)
                
                // Dim background when menu is shown
                if isMenuSheetPresented {
                    Color.black.opacity(backgroundOpacity)
                        .animation(.easeInOut(duration: 0.3), value: backgroundOpacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isMenuSheetPresented = false
                                backgroundOpacity = 0
                            }
                        }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingAuthView) {
                AuthView()
            }
            .fullScreenCover(isPresented: $showingSettingsView) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingProfileView) {
                ProfileView()
            }
            .fullScreenCover(isPresented: $showingPostPhotoView) {
                PostPhotoView()
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onAppear {
            initializeNotifications()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                sendReminderNotification()
            }
        }
    }
}

#Preview {
    ContentView()
}
