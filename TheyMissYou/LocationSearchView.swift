import SwiftUI

struct LocationSearchView: View {
    @Binding var selectedLocation: String
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private let darkModeColor = Color(red: 28/255, green: 28/255, blue: 30/255)
    
    // Sample list of major cities
    private let cities = [
        "New York, USA",
        "London, UK",
        "Paris, France",
        "Tokyo, Japan",
        "Sydney, Australia",
        "Dubai, UAE",
        "Singapore",
        "Hong Kong",
        "Berlin, Germany",
        "Toronto, Canada",
        "Mumbai, India",
        "São Paulo, Brazil",
        "Moscow, Russia",
        "Seoul, South Korea",
        "Mexico City, Mexico",
        "Amsterdam, Netherlands",
        "Rome, Italy",
        "Madrid, Spain",
        "Cairo, Egypt",
        "Bangkok, Thailand"
    ]
    
    var filteredCities: [String] {
        if searchText.isEmpty {
            return cities
        }
        return cities.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search location", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                List(filteredCities, id: \.self) { city in
                    Button(action: {
                        selectedLocation = city
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.green)
                            Text(city)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Search Location")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .background(isDarkMode ? darkModeColor : Color.white)
        }
    }
}

#Preview {
    LocationSearchView(selectedLocation: .constant(""))
} 