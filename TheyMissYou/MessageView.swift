import SwiftUI

struct ChatPreview: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
}

struct MessageView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private let darkModeColor = Color(red: 28/255, green: 28/255, blue: 30/255)
    
    // Sample data
    let chats = [
        ChatPreview(name: "John Doe", lastMessage: "Hey, how are you?", time: "12:30 PM", unreadCount: 2),
        ChatPreview(name: "Jane Smith", lastMessage: "See you tomorrow!", time: "11:45 AM", unreadCount: 0),
        ChatPreview(name: "Mike Johnson", lastMessage: "Thanks for your help", time: "Yesterday", unreadCount: 1),
        ChatPreview(name: "Sarah Wilson", lastMessage: "That sounds great!", time: "Yesterday", unreadCount: 0),
        ChatPreview(name: "David Brown", lastMessage: "Can we meet next week?", time: "Tuesday", unreadCount: 3)
    ]
    
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
                    
                    Text("Messages")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button(action: {
                        // New message action
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
                .padding()
                .background(isDarkMode ? darkModeColor : Color.white)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: .constant(""))
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Chat List
                List(chats) { chat in
                    HStack {
                        // Profile Picture
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(chat.name.prefix(1)))
                                    .foregroundColor(.green)
                                    .font(.title3)
                            )
                        
                        // Chat Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chat.name)
                                .font(.headline)
                                .foregroundColor(isDarkMode ? .white : .primary)
                            Text(chat.lastMessage)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Time and Unread Count
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(chat.time)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            if chat.unreadCount > 0 {
                                Text("\(chat.unreadCount)")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(isDarkMode ? darkModeColor : Color.white)
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)
            .background(isDarkMode ? darkModeColor : Color.white)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    MessageView()
} 