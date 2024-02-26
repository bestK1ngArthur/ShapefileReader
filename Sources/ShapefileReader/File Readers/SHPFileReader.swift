import Foundation

final class SHPFileReader {

    typealias BoundingBox = Shapefile.BoundingBox
    typealias Shape = Shapefile.Shape

    var minBoundingBox: BoundingBox { header.minBoundingBox }
    var zRange: ClosedRange<Double>? { header.zRange }
    var mRange: ClosedRange<Double>? { header.mRange }

    private let fileHandle: FileHandle
    private var header: Header!

    init(url: URL) throws {
        fileHandle = try .init(forReadingFrom: url)
        header = try readHeader()
    }

    deinit {
        try? fileHandle.close()
    }

    func readShapes() throws -> [Shape?] {
        var offset: UInt64 = 100
        var shapes: [Shapefile.Shape?] = []

        while let result = try readShape(at: offset) {
            shapes.append(result.shape)
            offset = result.nextOffset
        }

        return shapes
    }

    private func readHeader() throws -> Header {
        try fileHandle.seek(toOffset: 24)

        let lengthValues = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 4),
            with: ">i"
        )
        var fileLength = UInt64((lengthValues[0].int!) * 2)

        let rawShapeType = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 8),
            with: "<ii"
        )[1].int!
        guard let shapeType = ShapeType(rawValue: rawShapeType) else {
            fatalError("Unknown shapetype \(rawShapeType)")
        }

        let minBoundingBox = try readBoundingBox()

        let rangesValues = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 32),
            with: "<4d"
        ).map { $0.double! }
        let zRange = rangesValues[0]...rangesValues[1]
        let mRange = rangesValues[2]...rangesValues[3]

        // Can't trust length declared in shp header
        fileHandle.seekToEndOfFile()
        let length = fileHandle.offsetInFile
        if length != fileLength {
            fileLength = length
        }

        return .init(
            fileLength: fileLength,
            shapeType: shapeType,
            minBoundingBox: minBoundingBox,
            zRange: zRange.isEmpty ? nil : zRange,
            mRange: mRange.isEmpty ? nil : mRange
        )
    }

    private func readShape(at offset: UInt64) throws -> (shape: Shape?, nextOffset: UInt64)? {
        if offset == header.fileLength {
            return nil
        }

        try fileHandle.seek(toOffset: offset)

        let length = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 8),
            with: ">2i"
        )[1].int!
        let nextOffset = fileHandle.offsetInFile + UInt64((2 * length))

        let rawShapeType = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 4),
            with: "<i"
        )[0].int!
        guard let shapeType = ShapeType(rawValue: rawShapeType) else {
            fatalError("Unknown shapetype \(rawShapeType)")
        }

        if !Set([header.shapeType, .nullShape]).contains(shapeType) {
            fatalError("Invalid shapetype \(rawShapeType)")
        }

        let shape: Shape?
        switch shapeType {
            case .nullShape:
                shape = nil

            case .point:
                let point = try readPoint()
                shape = .point(point)

            case .polyLine:
                let polyLine = try readPolyLine()
                shape = .polyLine(polyLine)

            case .polygon:
                let polygon = try readPolygon()
                shape = .polygon(polygon)

            case .multiPoint:
                let multiPoint = try readMultiPoint()
                shape = .multiPoint(multiPoint)

            case .pointZ:
                let pointZ = try readPointZ()
                shape = .pointZ(pointZ)

            case .polyLineZ:
                let polyLineZ = try readPolyLineZ()
                shape = .polyLineZ(polyLineZ)

            case .polygonZ:
                let polygonZ = try readPolygonZ()
                shape = .polygonZ(polygonZ)

            case .multiPointZ:
                let multiPointZ = try readMultiPointZ()
                shape = .multiPointZ(multiPointZ)

            case .pointM:
                let pointM = try readPointM()
                shape = .pointM(pointM)

            case .polyLineM:
                let polyLineM = try readPolyLineM()
                shape = .polyLineM(polyLineM)

            case .polygonM:
                let polygonM = try readPolygonM()
                shape = .polygonM(polygonM)

            case .multiPointM:
                let multiPointM = try readMultiPointM()
                shape = .multiPointM(multiPointM)

            case .multiPatch:
                let multiPatch = try readMultiPatch()
                shape = .multiPatch(multiPatch)
        }

        return (shape, nextOffset)
    }

    private func readPoint() throws -> Shape.Point {
        let point = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 2 * Constants.doubleSize),
            with: "<2d"
        ).map { $0.double! }
        return .init(x: point[0], y: point[1])
    }

    private func readPolyLine() throws -> Shape.PolyLine {
        let minBoundingBox = try readBoundingBox()

        let partsCount = try readInt()
        let pointsCount = try readInt()

        let parts = try readIntArray(with: partsCount)
        let points = try readPointArray(with: pointsCount)

        return .init(
            minBoundingBox: minBoundingBox,
            parts: parts,
            points: points
        )
    }

    private func readPolygon() throws -> Shape.Polygon {
        let minBoundingBox = try readBoundingBox()

        let partsCount = try readInt()
        let pointsCount = try readInt()

        let parts = try readIntArray(with: partsCount)
        let points = try readPointArray(with: pointsCount)

        return .init(
            minBoundingBox: minBoundingBox,
            parts: parts,
            points: points
        )
    }

    private func readMultiPoint() throws -> Shape.MultiPoint {
        let minBoundingBox = try readBoundingBox()
    
        let pointsCount = try readInt()
        let points = try readPointArray(with: pointsCount)

        return .init(
            minBoundingBox: minBoundingBox,
            points: points
        )
    }

    private func readPointZ() throws -> Shape.PointZ {
        let point = try readPoint()
        let z = try readDouble()
        let m = try readDouble()

        return .init(
            x: point.x,
            y: point.y,
            z: z,
            m: m < Constants.minM ? nil : m
        )
    }

    private func readPolyLineZ() throws -> Shape.PolyLineZ {
        let minBoundingBox = try readBoundingBox()

        let partsCount = try readInt()
        let pointsCount = try readInt()

        let parts = try readIntArray(with: partsCount)
        let points = try readPointArray(with: pointsCount)

        let z = try readDoubleArray(with: pointsCount)

        let m: (range: ClosedRange<Double>, array: [Double])?
        if let mRange = header.mRange, !mRange.isEmpty {
            m = try readDoubleArray(with: pointsCount)
        } else {
            m = nil
        }

        return .init(
            minBoundingBox: minBoundingBox,
            parts: parts,
            points: points,
            zRange: z.range,
            zValues: z.array,
            mRange: m?.range,
            mValues: m?.array.map { $0 < Constants.minM ? nil : $0 }
        )
    }

    private func readPolygonZ() throws -> Shape.PolygonZ {
        let minBoundingBox = try readBoundingBox()

        let partsCount = try readInt()
        let pointsCount = try readInt()

        let parts = try readIntArray(with: partsCount)
        let points = try readPointArray(with: pointsCount)

        let z = try readDoubleArray(with: pointsCount)

        let m: (range: ClosedRange<Double>, array: [Double])?
        if let mRange = header.mRange, !mRange.isEmpty {
            m = try readDoubleArray(with: pointsCount)
        } else {
            m = nil
        }

        return .init(
            minBoundingBox: minBoundingBox,
            parts: parts,
            points: points,
            zRange: z.range,
            zValues: z.array,
            mRange: m?.range,
            mValues: m?.array.map { $0 < Constants.minM ? nil : $0 }
        )
    }

    private func readMultiPointZ() throws -> Shape.MultiPointZ {
        let minBoundingBox = try readBoundingBox()

        let pointsCount = try readInt()
        let points = try readPointArray(with: pointsCount)

        let z = try readDoubleArray(with: pointsCount)

        let m: (range: ClosedRange<Double>, array: [Double])?
        if let mRange = header.mRange, !mRange.isEmpty {
            m = try readDoubleArray(with: pointsCount)
        } else {
            m = nil
        }

        return .init(
            minBoundingBox: minBoundingBox,
            points: points,
            zRange: z.range,
            zValues: z.array,
            mRange: m?.range,
            mValues: m?.array.map { $0 < Constants.minM ? nil : $0 }
        )
    }

    private func readPointM() throws -> Shape.PointM {
        let point = try readPoint()
        let m = try readDouble()
        return .init(
            x: point.x,
            y: point.y,
            m: m
        )
    }

    private func readPolyLineM() throws -> Shape.PolyLineM {
        let minBoundingBox = try readBoundingBox()

        let partsCount = try readInt()
        let pointsCount = try readInt()

        let parts = try readIntArray(with: partsCount)
        let points = try readPointArray(with: pointsCount)

        let m: (range: ClosedRange<Double>, array: [Double])?
        if let mRange = header.mRange, !mRange.isEmpty {
            m = try readDoubleArray(with: pointsCount)
        } else {
            m = nil
        }

        return .init(
            minBoundingBox: minBoundingBox,
            parts: parts,
            points: points,
            mRange: m?.range,
            mValues: m?.array.map { $0 < Constants.minM ? nil : $0 }
        )
    }

    private func readPolygonM() throws -> Shape.PolygonM {
        let minBoundingBox = try readBoundingBox()

        let partsCount = try readInt()
        let pointsCount = try readInt()

        let parts = try readIntArray(with: partsCount)
        let points = try readPointArray(with: pointsCount)

        let m: (range: ClosedRange<Double>, array: [Double])?
        if let mRange = header.mRange, !mRange.isEmpty {
            m = try readDoubleArray(with: pointsCount)
        } else {
            m = nil
        }

        return .init(
            minBoundingBox: minBoundingBox,
            parts: parts,
            points: points,
            mRange: m?.range,
            mValues: m?.array.map { $0 < Constants.minM ? nil : $0 }
        )
    }

    private func readMultiPointM() throws -> Shape.MultiPointM {
        let minBoundingBox = try readBoundingBox()

        let pointsCount = try readInt()
        let points = try readPointArray(with: pointsCount)

        let m: (range: ClosedRange<Double>, array: [Double])?
        if let mRange = header.mRange, !mRange.isEmpty {
            m = try readDoubleArray(with: pointsCount)
        } else {
            m = nil
        }

        return .init(
            minBoundingBox: minBoundingBox,
            points: points,
            mRange: m?.range,
            mValues: m?.array.map { $0 < Constants.minM ? nil : $0 }
        )
    }

    private func readMultiPatch() throws -> Shape.MultiPatch {
        let minBoundingBox = try readBoundingBox()

        let partsCount = try readInt()
        let pointsCount = try readInt()

        let parts = try readIntArray(with: partsCount)
        let partTypes = try readIntArray(with: partsCount)
            .map { Shape.MultiPatch.PartType(rawValue: $0)! }

        let points = try readPointArray(with: pointsCount)

        let z = try readDoubleArray(with: pointsCount)

        let m: (range: ClosedRange<Double>, array: [Double])?
        if let mRange = header.mRange, !mRange.isEmpty {
            m = try readDoubleArray(with: pointsCount)
        } else {
            m = nil
        }

        return .init(
            minBoundingBox: minBoundingBox,
            parts: parts,
            partTypes: partTypes,
            points: points,
            zRange: z.range,
            zValues: z.array,
            mRange: m?.range,
            mValues: m?.array.map { $0 < Constants.minM ? nil : $0 }
        )
    }

    // MARK: Help readers

    private func readBoundingBox() throws -> BoundingBox {
        let boxValues = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 4 * Constants.doubleSize),
            with: "<4d"
        ).map { $0.double! }
        return .init(
            xMin: boxValues[0],
            yMin: boxValues[1],
            xMax: boxValues[2],
            yMax: boxValues[3]
        )
    }

    private func readInt() throws -> Int {
        try DataUnpacker.unpack(
            fileHandle.readData(ofLength: Constants.intSize),
            with: "<i"
        )[0].int!
    }

    private func readDouble() throws -> Double {
        try DataUnpacker.unpack(
            fileHandle.readData(ofLength: Constants.doubleSize),
            with: "<d"
        )[0].double!
    }

    private func readIntArray(with count: Int) throws -> [Int] {
        guard count > 0 else {
            return []
        }

        return try DataUnpacker.unpack(
            fileHandle.readData(ofLength: count * Constants.intSize),
            with: "<\(count)i"
        ).map { $0.int! }
    }

    private func readPointArray(with count: Int) throws -> [Shape.Point] {
        guard count > 0 else {
            return []
        }

        var points: [Shape.Point] = []
        for _ in 0..<count {
            let point = try readPoint()
            points.append(point)
        }
        return points
    }

    private func readDoubleArray(with count: Int) throws -> (range: ClosedRange<Double>, array: [Double]) {
        guard count > 0 else {
            return (0...0, [])
        }

        let rangeValues = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 2 * Constants.doubleSize),
            with: "<2d"
        ).map { $0.double! }
        let range = rangeValues[0]...rangeValues[1]

        let array = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: count * Constants.doubleSize),
            with: "<\(count)i"
        ).map { $0.double! }

        return (range, array)
    }
}

private extension SHPFileReader {

    struct Header: Equatable {
        let fileLength: UInt64
        let shapeType: ShapeType
        let minBoundingBox: BoundingBox
        let zRange: ClosedRange<Double>?
        let mRange: ClosedRange<Double>?
    }

    enum ShapeType: Int {
        case nullShape = 0
        case point = 1
        case polyLine = 3
        case polygon = 5
        case multiPoint = 8
        case pointZ = 11
        case polyLineZ = 13
        case polygonZ = 15
        case multiPointZ = 18
        case pointM = 21
        case polyLineM = 23
        case polygonM = 25
        case multiPointM = 28
        case multiPatch = 31
    }

    enum Constants {
        static let minM: Double = -10e38
        static let intSize = 4
        static let doubleSize = 8
    }
}
