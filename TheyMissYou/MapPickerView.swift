import SwiftUI
import MapKit
import UIKit

struct MapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var coordinate: CLLocationCoordinate2D
    @State private var region: MKCoordinateRegion
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private let darkModeColor = Color(red: 28/255, green: 28/255, blue: 30/255)
    
    init(coordinate: Binding<CLLocationCoordinate2D>) {
        self._coordinate = coordinate
        // Center on the continental United States
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Geographic center of the continental US
            span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60) // Zoom level to show most of the US
        )
        _region = State(initialValue: initialRegion)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                MapViewWithTap(region: $region, coordinate: $coordinate)
                    .gesture(
                        DragGesture()
                            .onEnded { _ in
                                coordinate = region.center
                            }
                    )
                
                VStack {
                    Text("Press and hold to place pin, double tap to zoom")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Confirm Location")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .background(isDarkMode ? darkModeColor : Color.white)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    dismiss()
                }
            )
        }
    }
}

struct MapViewWithTap: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        
        // Replace tap gesture with long press
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5 // Half second press
        mapView.addGestureRecognizer(longPressGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Only update annotations, not the region
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Update the binding to reflect the current map region
        DispatchQueue.main.async {
            region = mapView.region
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithTap
        
        init(_ parent: MapViewWithTap) {
            self.parent = parent
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                let mapView = gesture.view as! MKMapView
                let point = gesture.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                parent.coordinate = coordinate
            }
        }
    }
}

struct LocationPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    MapPickerView(coordinate: .constant(CLLocationCoordinate2D(latitude: 0, longitude: 0)))
} 