import MapKit
import ShapefileReader
import SwiftUI

struct MapKitExampleView: View {

    struct Country: Identifiable {

        let name: String
        let code: String
        let polygons: [MKPolygon]
        let center: CLLocationCoordinate2D

        var id: String { code }
    }

    @State private var country: Country?

    private let shapefileReader = ShapefileReader()

    var body: some View {
        Map(initialPosition: .automatic) {
            if let country {
                Marker(country.name, coordinate: country.center)

                ForEach(country.polygons, id: \.self) { polygon in
                    MapPolygon(polygon)
                        .foregroundStyle(.purple)
                }
            }
        }
        .task {
            loadCountry()
        }
    }

    private func loadCountry() {
        guard
            let shp = Bundle.main.path(forResource: "countries", ofType: "shp"),
            let dbf = Bundle.main.path(forResource: "countries", ofType: "dbf"),
            let shx = Bundle.main.path(forResource: "countries", ofType: "shx")
        else {
            fatalError("Can't find shapefile files")
        }

        let result = try? shapefileReader.readShape(
            from: .init(shp: shp, dbf: dbf, shx: shx),
            at: 100
        )

        guard
            let partableShape = result?.shape?.partable,
            let name = result?.record.value(for: "NAME")?.string,
            let code = result?.record.value(for: "ISO_A2")?.string,
            let minBoundingBox = result?.shape?.minBoundingBox
        else {
            fatalError("Can't parse shape data")
        }

        let polygons = partableShape.pointsByParts.map { points in
            let coordinates = points.map { point in
                CLLocationCoordinate2D(latitude: point.y, longitude: point.x)
            }
            return MKPolygon(coordinates: coordinates, count: coordinates.count)
        }

        country = .init(
            name: name,
            code: code,
            polygons: polygons,
            center: .init(
                latitude: (minBoundingBox.yMax + minBoundingBox.yMin) / 2,
                longitude: (minBoundingBox.xMax + minBoundingBox.xMin) / 2
            )
        )
    }
}

#Preview {
    MapKitExampleView()
}
