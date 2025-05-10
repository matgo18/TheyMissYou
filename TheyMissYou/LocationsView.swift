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
            VStack(spacing: 0) {
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
                
                // Main Content
                ZStack(alignment: .top) {
                    if viewModel.isLoading {
                        VStack {
                            ProgressView("Loading locations...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.top, 40)
                            Spacer()
                        }
                    } else if let error = viewModel.error {
                        VStack {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.yellow)
                                Text(error)
                                    .multilineTextAlignment(.center)
                                Button(action: {
                                    Task {
                                        await viewModel.fetchUserLocations()
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
                            .padding(.top, 40)
                            Spacer()
                        }
                    } else if viewModel.userLocations.isEmpty {
                        VStack {
                            VStack(spacing: 16) {
                                Image(systemName: "mappin.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No user locations found")
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 40)
                            Spacer()
                        }
                    } else {
                        Map(coordinateRegion: .constant(viewModel.region),
                            interactionModes: .all,
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
                        .edgesIgnoringSafeArea(.bottom)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(isDarkMode ? darkModeColor : Color.white)
            .task {
                await viewModel.fetchUserLocations()
            }
        }
    }
}

class LocationsViewModel: ObservableObject {
    @Published var userLocations: [UserLocation] = []
    @Published var region = MKCoordinateRegion(
        // Default to San Francisco with a reasonable zoom level
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
    )
    @Published var error: String?
    @Published var isLoading = false
    
    private let userManager = UserManager.shared
    private let groupManager = GroupManager.shared
    private let db = Firestore.firestore()
    
    func fetchUserLocations() async {
        guard let currentUserId = userManager.currentUser?.uid else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let snapshot = try await Firestore.firestore().collection("users").getDocuments()
            var locations: [UserLocation] = []
            
            for document in snapshot.documents {
                // Only process users in shared groups
                if !groupManager.isUserInSharedGroup(userId: document.documentID, currentUserId: currentUserId) {
                    continue
                }
                
                guard let data = document.data() as? [String: Any],
                      let latitude = (data["latitude"] as? NSNumber)?.doubleValue,
                      let longitude = (data["longitude"] as? NSNumber)?.doubleValue,
                      let username = data["username"] as? String else {
                    continue
                }
                
                // Validate coordinates
                guard (-90...90).contains(latitude) && (-180...180).contains(longitude) &&
                      !(latitude == 0 && longitude == 0) else {
                    continue
                }
                
                let location = UserLocation(
                    id: document.documentID,
                    username: username,
                    coordinate: CLLocationCoordinate2D(
                        latitude: latitude,
                        longitude: longitude
                    )
                )
                locations.append(location)
            }
            
            DispatchQueue.main.async {
                self.userLocations = locations
                if !locations.isEmpty {
                    self.updateRegion(for: locations)
                }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Error fetching user locations: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func updateRegion(for locations: [UserLocation]) {
        guard !locations.isEmpty else { return }
        
        // Calculate the center and span
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
        
        // Ensure we have valid coordinates
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Calculate span with minimum values to prevent zero spans
        let latDelta = max(0.1, abs(maxLat - minLat) * 1.5)
        let lonDelta = max(0.1, abs(maxLon - minLon) * 1.5)
        
        // Create and validate the region
        let center = CLLocationCoordinate2D(
            latitude: max(-90, min(90, centerLat)),
            longitude: max(-180, min(180, centerLon))
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: min(170, latDelta),  // Prevent spanning more than most of the globe
            longitudeDelta: min(170, lonDelta)
        )
        
        DispatchQueue.main.async {
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