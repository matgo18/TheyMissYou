import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationFrequency") private var notificationFrequency = NotificationFrequency.immediate.rawValue
    
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
                    
                    Text("Settings")
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
                
                List {
                    Section(header: Text("Appearance")) {
                        Toggle(isOn: $isDarkMode) {
                            HStack {
                                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                    .foregroundColor(.green)
                                Text("Dark Mode")
                                    .foregroundColor(isDarkMode ? .white : .primary)
                            }
                        }
                        .tint(.green)
                    }
                    .listRowBackground(isDarkMode ? darkModeColor : Color.white)
                    
                    Section(
                        header: Text("Notifications"),
                        footer: Text("Notifications will be scheduled when you leave the app")
                            .foregroundColor(.gray)
                    ) {
                        Picker("Reminder Frequency", selection: $notificationFrequency) {
                            ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.description)
                                    .tag(frequency.rawValue)
                                    .foregroundColor(.green)
                            }
                        }
                        .tint(.green)
                        .accentColor(.green)
                    }
                    .listRowBackground(isDarkMode ? darkModeColor : Color.white)
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(Visibility.hidden)
            }
            .navigationBarHidden(true)
            .background(isDarkMode ? darkModeColor : Color.white)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    SettingsView()
} 