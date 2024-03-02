import Foundation

public struct Shapefile: Equatable {

    public let minBoundingBox: BoundingBox
    public let zRange: ClosedRange<Double>?
    public let mRange: ClosedRange<Double>?
    public let shapes: [Shape?]
    public let records: [InfoRecord]

    public var shapesAndRecords: [(shape: Shape?, record: InfoRecord)] {
        Array(zip(shapes, records))
    }
}

// MARK: Bounding Box

extension Shapefile {

    public struct BoundingBox: Equatable {

        public let xMin: Double
        public let yMin: Double
        public let xMax: Double
        public let yMax: Double

        public static let zero = Self(xMin: 0, yMin: 0, xMax: 0, yMax: 0)
    }
}

// MARK: Path

extension Shapefile {

    public struct Path {

        let shp: URL
        let dbf: URL
        let shx: URL

        public init(shp: URL, dbf: URL, shx: URL) {
            self.shp = shp
            self.dbf = dbf
            self.shx = shx
        }

        public init(shp: String, dbf: String, shx: String) {
            self.shp = .init(fileURLWithPath: shp)
            self.dbf = .init(fileURLWithPath: dbf)
            self.shx = .init(fileURLWithPath: shx)
        }

        public init(pathToFilesWithEqualName filePath: String) {
            self.shp = .init(fileURLWithPath: "\(filePath).shp")
            self.dbf = .init(fileURLWithPath: "\(filePath).dbf")
            self.shx = .init(fileURLWithPath: "\(filePath).shx")
        }
    }
}

