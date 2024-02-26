import Foundation

public class ShapefileReader {

    public init() {}

    public func read(
        from path: Shapefile.Path
    ) throws -> Shapefile {
        let shpFile = try SHPFileReader(url: path.shp)
        let dbfFile = try DBFFileReader(url: path.dbf)
        return .init(
            minBoundingBox: shpFile.minBoundingBox,
            zRange: shpFile.zRange,
            mRange: shpFile.mRange,
            shapes: try shpFile.readShapes(),
            records: try dbfFile.readRecords()
        )
    }

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
