import SwiftUI
import MapKit
import FirebaseFirestore

struct LocationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = LocationsViewModel()
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
                    
                    Text("User Locations")
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
                
                Map(coordinateRegion: $viewModel.region,
                    showsUserLocation: true,
                    annotationItems: viewModel.userLocations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        VStack(spacing: 0) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.green)
                                .font(.title)
                                .background(Circle()
                                    .fill(.white)
                                    .frame(width: 32, height: 32))
                            
                            Text(location.username)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .background(isDarkMode ? darkModeColor : Color.white)
            .onAppear {
                Task {
                    await viewModel.fetchUsers()
                }
            }
        }
    }
}

class LocationsViewModel: ObservableObject {
    @Published var userLocations: [UserLocation] = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 180)
    )
    
    private let db = Firestore.firestore()
    
    func fetchUsers() async {
        do {
            let snapshot = try await db.collection("users").getDocuments()
            let locations = snapshot.documents.compactMap { document -> UserLocation? in
                guard let userData = UserData(dictionary: document.data()),
                      let latitude = userData.latitude,
                      let longitude = userData.longitude else {
                    return nil
                }
                
                return UserLocation(
                    id: userData.id,
                    username: userData.username,
                    coordinate: CLLocationCoordinate2D(
                        latitude: latitude,
                        longitude: longitude
                    )
                )
            }
            
            DispatchQueue.main.async {
                self.userLocations = locations
                if !locations.isEmpty {
                    self.updateRegion(for: locations)
                }
            }
        } catch {
            print("Error fetching users: \(error.localizedDescription)")
        }
    }
    
    private func updateRegion(for locations: [UserLocation]) {
        guard !locations.isEmpty else { return }
        
        var minLat = locations[0].coordinate.latitude
        var maxLat = locations[0].coordinate.latitude
        var minLon = locations[0].coordinate.longitude
        var maxLon = locations[0].coordinate.longitude
        
        for location in locations {
            minLat = min(minLat, location.coordinate.latitude)
            maxLat = max(maxLat, location.coordinate.latitude)
            minLon = min(minLon, location.coordinate.longitude)
            maxLon = max(maxLon, location.coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(abs(maxLat - minLat) * 1.5, 1),
            longitudeDelta: max(abs(maxLon - minLon) * 1.5, 1)
        )
        
        withAnimation {
            self.region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct UserLocation: Identifiable {
    let id: String
    let username: String
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    LocationsView()
} 