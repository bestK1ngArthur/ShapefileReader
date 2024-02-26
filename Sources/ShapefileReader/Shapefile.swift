import Foundation

public struct Shapefile: Equatable {
    public let minBoundingBox: BoundingBox
    public let zRange: ClosedRange<Double>?
    public let mRange: ClosedRange<Double>?
    public let shapes: [Shape?]
    public let records: [InfoRecord]
}

public extension Shapefile {

    var shapesAndRecords: [(shape: Shape?, record: InfoRecord)] {
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

        public init(pathToFiles: String) {
            self.shp = .init(fileURLWithPath: "\(pathToFiles).shp")
            self.dbf = .init(fileURLWithPath: "\(pathToFiles).dbf")
            self.shx = .init(fileURLWithPath: "\(pathToFiles).shx")
        }
    }
}

// MARK: InfoRecord

extension Shapefile {

    public struct InfoProperty: Equatable {

        public enum Value: Equatable {
            case character(Character)
            case date(Date)
            case double(Double)
            case int(Int)
            case bool(Bool)
            case string(String)
        }

        let name: String
        let value: Value
    }

    public typealias InfoRecord = [InfoProperty]
}
