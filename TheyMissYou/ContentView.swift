//
//  ContentView.swift
//  TheyMissYou
//
//  Created by Xcode on 4/14/25.
//

import SwiftUI
import UserNotifications

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
    @State private var isMenuSheetPresented = false
    @State private var showingMessageView = false
    @State private var showingSettingsView = false
    @State private var showingProfileView = false
    @State private var backgroundOpacity: Double = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationFrequency") private var notificationFrequency = NotificationFrequency.immediate.rawValue
    @Environment(\.scenePhase) private var scenePhase
    
    private let darkModeColor = Color(red: 28/255, green: 28/255, blue: 30/255)
    
    // Initialize notifications when the view appears
    func initializeNotifications() {
        NotificationManager.shared.requestPermission()
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
                            showingMessageView = true
                        }) {
                            Image(systemName: "message")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    .padding()
                    .background(isDarkMode ? darkModeColor : Color.white)
                    
                    // Main content
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(0..<5) { _ in
                                VStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.green.opacity(0.3))
                                        .frame(height: 150)
                                        .cornerRadius(12)

                                    Text("Some description here...")
                                        .padding(.top, 5)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
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
                                    showingMessageView = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "message")
                                    Text("Messages")
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
            .fullScreenCover(isPresented: $showingMessageView) {
                MessageView()
            }
            .fullScreenCover(isPresented: $showingSettingsView) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingProfileView) {
                ProfileView()
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
