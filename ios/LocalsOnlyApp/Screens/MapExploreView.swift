import CoreLocation
import MapKit
import SwiftUI

struct PlaceAnnotation: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let coordinate: CLLocationCoordinate2D
    let averageScore: Double?
    let ratingsCount: Int
    let coverPhotoURL: String?

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

struct MapExploreView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var annotations: [PlaceAnnotation] = []
    @State private var selectedID: UUID?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.1611),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )
    @State private var isLoading = true
    @State private var showNearMe = false
    @StateObject private var locationManager = LocationManager()

    private var selectedAnnotation: PlaceAnnotation? {
        annotations.first { $0.id == selectedID }
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition, selection: $selectedID) {
                if showNearMe, let loc = locationManager.location?.coordinate {
                    Annotation("You", coordinate: loc) {
                        Circle()
                            .fill(Color.coastalAqua)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: Color.coastalAqua.opacity(0.5), radius: 4)
                    }
                }

                ForEach(annotations) { pin in
                    Annotation(pin.name, coordinate: pin.coordinate) {
                        mapPin(for: pin)
                    }
                    .tag(pin.id)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .ignoresSafeArea(edges: .bottom)

            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading places...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                }
            }

            if annotations.isEmpty && !isLoading {
                VStack {
                    Spacer()
                    GlassCard {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "map")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.coastalAqua)
                            Text("No places on the map yet")
                                .font(.cardTitle)
                                .foregroundStyle(Color.coastalTextPrimary)
                            Text("Places with coordinates will appear here as they're added.")
                                .font(.captionCopy)
                                .foregroundStyle(Color.coastalTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(Spacing.md)
                    Spacer()
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showNearMe.toggle()
                if showNearMe {
                    locationManager.requestPermission()
                    if let loc = locationManager.location?.coordinate {
                        withAnimation {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: loc,
                                    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                                )
                            )
                        }
                    }
                }
            } label: {
                Image(systemName: showNearMe ? "location.fill" : "location")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(showNearMe ? .white : Color.coastalAqua)
                    .frame(width: 40, height: 40)
                    .background(showNearMe ? Color.coastalAqua : Color.coastalCard)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            }
            .padding(Spacing.md)
            .padding(.top, Spacing.xl)
        }
        .overlay(alignment: .bottom) {
            if let selected = selectedAnnotation {
                selectedPlaceCard(selected)
                    .padding(Spacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: selectedID)
        .task { await loadPlaces() }
        .onChange(of: locationManager.location) { _, newLoc in
            if showNearMe, let loc = newLoc?.coordinate {
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: loc,
                            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                        )
                    )
                }
            }
        }
    }

    private func mapPin(for pin: PlaceAnnotation) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(pinColor(for: pin))
                    .frame(width: 32, height: 32)
                    .shadow(color: pinColor(for: pin).opacity(0.4), radius: 4, y: 2)
                Image(systemName: pin.category == "drink" ? "cup.and.saucer.fill" : "fork.knife")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }
            Triangle()
                .fill(pinColor(for: pin))
                .frame(width: 10, height: 6)
        }
    }

    private func pinColor(for pin: PlaceAnnotation) -> Color {
        if let score = pin.averageScore {
            return .scoreColor(for: score)
        }
        return .coastalAqua
    }

    private func selectedPlaceCard(_ pin: PlaceAnnotation) -> some View {
        NavigationLink(value: pin.id) {
            GlassCard {
                HStack {
                    if let coverURL = pin.coverPhotoURL, let url = URL(string: coverURL) {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image.resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            } else {
                                placeCardPlaceholder
                            }
                        }
                    } else {
                        placeCardPlaceholder
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(pin.name)
                            .font(.cardTitle)
                            .foregroundStyle(Color.coastalTextPrimary)
                        Text("\(pin.category.capitalized) · \(pin.ratingsCount) ratings")
                            .font(.captionCopy)
                            .foregroundStyle(Color.coastalTextSecondary)
                    }
                    Spacer()
                    if let score = pin.averageScore {
                        Text(String(format: "%.1f", score))
                            .font(.sectionTitle)
                            .foregroundStyle(Color.scoreColor(for: score))
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.scoreColor(for: score).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var placeCardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.coastalSand.opacity(0.12))
            .frame(width: 48, height: 48)
    }

    private func loadPlaces() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let places = try await session.api.placesNearby()
            annotations = places.map {
                PlaceAnnotation(
                    id: $0.id, name: $0.name, category: $0.category,
                    coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                    averageScore: $0.averageScore, ratingsCount: $0.ratingsCount,
                    coverPhotoURL: $0.coverPhotoURL
                )
            }
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: EquatableCoordinate?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        location = EquatableCoordinate(coordinate: loc.coordinate)
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

struct EquatableCoordinate: Equatable {
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: EquatableCoordinate, rhs: EquatableCoordinate) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}
