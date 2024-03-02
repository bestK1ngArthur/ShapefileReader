import Foundation

/// Shapefile format files reader, supports `.shp`, `.dbf` and `.shx` formats.
/// [Link to Wikipedia](https://en.wikipedia.org/wiki/Shapefile)
public class ShapefileReader {

    public enum ReadError: Error {
        case invalidRecordsCount
    }

    public init() {}

    /// Reads alll shapes and support data from files
    /// - parameter path: Path to shapefile files
    /// - returns: Shapefile struct
    public func read(
        from path: Shapefile.Path
    ) throws -> Shapefile {
        let shpFile = try SHPFileReader(url: path.shp)
        let dbfFile = try DBFFileReader(url: path.dbf)

        let shapes = try shpFile.readShapes()
        let records = try dbfFile.readRecords()

        guard shapes.count == records.count else {
            throw ReadError.invalidRecordsCount
        }

        return .init(
            minBoundingBox: shpFile.minBoundingBox,
            zRange: shpFile.zRange,
            mRange: shpFile.mRange,
            shapes: try shpFile.readShapes(),
            records: try dbfFile.readRecords()
        )
    }

    /// Reads specific shape and record from files
    /// - parameter path: Path to shapefile files
    /// - parameter index: Index of shape
    /// - returns: Shape with record as tuple
    public func readShape(
        from path: Shapefile.Path,
        at index: Int
    ) throws -> (shape: Shapefile.Shape?, record: Shapefile.InfoRecord) {
        let shpFile = try SHPFileReader(url: path.shp)
        let dbfFile = try DBFFileReader(url: path.dbf)
        let shxFile = try SHXFileReader(url: path.shx)

        let offset = shxFile.offset(for: index)
        let shape = try shpFile.readShape(at: offset)
        let record = try dbfFile.readRecord(at: offset)

        return (shape, record)
    }
}
