import Foundation

public extension Shapefile {

    enum Shape: Equatable {
        case point(Point)
        case polyLine(PolyLine)
        case polygon(Polygon)
        case multiPoint(MultiPoint)
        case pointZ(PointZ)
        case polyLineZ(PolyLineZ)
        case polygonZ(PolygonZ)
        case multiPointZ(MultiPointZ)
        case pointM(PointM)
        case polyLineM(PolyLineM)
        case polygonM(PolygonM)
        case multiPointM(MultiPointM)
        case multiPatch(MultiPatch)
    }
}

// MARK: Types of shape

extension Shapefile.Shape {

    /// A `Point` consists of a pair of double-precision coordinates in the order X,Y.
    public struct Point: Equatable {
        public let x: Double
        public let y: Double
    }

    /// A `PolyLine` is an ordered set of vertices that consists of one or more parts. A part is a connected sequence of two or more points. Parts may or may not be connected to one another. Parts may or may not intersect one another.
    public struct PolyLine: Equatable, Partable {
        public let minBoundingBox: Shapefile.BoundingBox
        public let parts: [Int]
        public let points: [Point]
    }

    /// A `Polygon` consists of one or more rings. A ring is a connected sequence of four or more points that form a closed, non-self-intersecting loop. A polygon may contain multiple outer rings. The order of vertices or orientation for a ring indicates which side of the ring is the interior of the polygon. The neighborhood to the right of an observer walking along the ring in vertex order is the neighborhood inside the polygon. Vertices of rings defining holes in polygons are in a counterclockwise direction. Vertices for a single, ringed polygon are, therefore, always in clockwise order. The rings of a polygon are referred to as its parts.
    public struct Polygon: Equatable, Partable {
        public let minBoundingBox: Shapefile.BoundingBox
        public let parts: [Int]
        public let points: [Point]
    }

    /// A `MultiPoint` represents a set of points.
    public struct MultiPoint: Equatable {
        public let minBoundingBox: Shapefile.BoundingBox
        public let points: [Point]
    }

    /// A `PointZ` consists of a triplet of double-precision coordinates in the order X, Y, Z plus a measure.
    public struct PointZ: Equatable {
        public let x: Double
        public let y: Double
        public let z: Double
        public let m: Double?
    }

    /// A `PolyLineZ` consists of one or more parts. A part is a connected sequence of two or more points. Parts may or may not be connected to one another. Parts may or may not intersect one another.
    public struct PolyLineZ: Equatable, Partable {
        public let minBoundingBox: Shapefile.BoundingBox
        public let parts: [Int]
        public let points: [Point]
        public let zRange: ClosedRange<Double>
        public let zValues: [Double]
        public let mRange: ClosedRange<Double>?
        public let mValues: [Double?]?
    }

    /// A `PolygonZ` consists of a number of rings. A ring is a closed, non-self-intersecting loop. A `PolygonZ` may contain multiple outer rings. The rings of a `PolygonZ` are referred to as its parts.
    public struct PolygonZ: Equatable, Partable {
        public let minBoundingBox: Shapefile.BoundingBox
        public let parts: [Int]
        public let points: [Point]
        public let zRange: ClosedRange<Double>
        public let zValues: [Double]
        public let mRange: ClosedRange<Double>?
        public let mValues: [Double?]?
    }

    /// A `MultiPointZ` represents a set of PointZs.
    public struct MultiPointZ: Equatable {
        public let minBoundingBox: Shapefile.BoundingBox
        public let points: [Point]
        public let zRange: ClosedRange<Double>
        public let zValues: [Double]
        public let mRange: ClosedRange<Double>?
        public let mValues: [Double?]?
    }

    /// A `PointM` consists of a pair of double-precision coordinates in the order X, Y, plus a measure M.
    public struct PointM: Equatable {
        public let x: Double
        public let y: Double
        public let m: Double
    }

    /// A shapefile `PolyLineM` consists of one or more parts. A part is a connected sequence of two or more points. Parts may or may not be connected to one another. Parts may or may not intersect one another.
    public struct PolyLineM: Equatable, Partable {
        public let minBoundingBox: Shapefile.BoundingBox
        public let parts: [Int]
        public let points: [Point]
        public let mRange: ClosedRange<Double>?
        public let mValues: [Double?]?
    }

    /// A `PolygonM` consists of a number of rings. A ring is a closed, non-self-intersecting loop. Note that intersections are calculated in X,Y space, not in X,Y,M space. A `PolygonM` may contain multiple outer rings. The rings of a `PolygonM` are referred to as its parts.
    public struct PolygonM: Equatable, Partable {
        public let minBoundingBox: Shapefile.BoundingBox
        public let parts: [Int]
        public let points: [Point]
        public let mRange: ClosedRange<Double>?
        public let mValues: [Double?]?
    }

    /// A `MultiPointM` represents a set of PointMs.
    public struct MultiPointM: Equatable {
        public let minBoundingBox: Shapefile.BoundingBox
        public let points: [Point]
        public let mRange: ClosedRange<Double>?
        public let mValues: [Double?]?
    }

    /// A `MultiPatch` consists of a number of surface patches. Each surface patch describes a surface. The surface patches of a `MultiPatch` are referred to as its parts, and the type of part controls how the order of vertices of an `MultiPatch` part is interpreted.
    public struct MultiPatch: Equatable, Partable {
        public enum PartType: Int {
            case triangleStrip = 0
            case triangleFan = 1
            case outerRing = 2
            case innerRing = 3
            case firstRing = 4
            case ring = 5
        }

        public let minBoundingBox: Shapefile.BoundingBox
        public let parts: [Int]
        public let partTypes: [PartType]
        public let points: [Point]
        public let zRange: ClosedRange<Double>
        public let zValues: [Double]
        public let mRange: ClosedRange<Double>?
        public let mValues: [Double?]?
    }
}

public extension Shapefile.Shape {

    var minBoundingBox: Shapefile.BoundingBox? {
        switch self {
            case .point:
                return nil
            case .polyLine(let polyLine):
                return polyLine.minBoundingBox
            case .polygon(let polygon):
                return polygon.minBoundingBox
            case .multiPoint(let multiPoint):
                return multiPoint.minBoundingBox
            case .pointZ:
                return nil
            case .polyLineZ(let polyLineZ):
                return polyLineZ.minBoundingBox
            case .polygonZ(let polygonZ):
                return polygonZ.minBoundingBox
            case .multiPointZ(let multiPointZ):
                return multiPointZ.minBoundingBox
            case .pointM:
                return nil
            case .polyLineM(let polyLineM):
                return polyLineM.minBoundingBox
            case .polygonM(let polygonM):
                return polygonM.minBoundingBox
            case .multiPointM(let multiPointM):
                return multiPointM.minBoundingBox
            case .multiPatch(let multiPatch):
                return multiPatch.minBoundingBox
        }
    }
}

// MARK: Partable

public protocol Partable {

    var points: [Shapefile.Shape.Point] { get }
    var parts: [Int] { get }

    var pointsByParts: [[Shapefile.Shape.Point]] { get }
}

public extension Partable {

    var pointsByParts: [[Shapefile.Shape.Point]] {
        guard parts.count > 1 else {
            return [points]
        }

        var pointsByParts: [[Shapefile.Shape.Point]] = []
        var startIndex = 0

        for endIndex in parts.suffix(from: 1) {
            let partPoints = Array(points[startIndex..<endIndex])
            pointsByParts.append(partPoints)
            startIndex = endIndex
        }

        return pointsByParts
    }
}

public extension Shapefile.Shape {

    var partable: Partable? {
        switch self {
            case .point:
                return nil
            case .polyLine(let polyLine):
                return polyLine
            case .polygon(let polygon):
                return polygon
            case .multiPoint:
                return nil
            case .pointZ:
                return nil
            case .polyLineZ(let polyLineZ):
                return polyLineZ
            case .polygonZ(let polygonZ):
                return polygonZ
            case .multiPointZ:
                return nil
            case .pointM:
                return nil
            case .polyLineM(let polyLineM):
                return polyLineM
            case .polygonM(let polygonM):
                return polygonM
            case .multiPointM:
                return nil
            case .multiPatch(let multiPatch):
                return multiPatch
        }
    }
}
