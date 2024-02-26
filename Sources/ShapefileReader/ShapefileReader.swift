import Foundation

public class ShapefileReader {

    public init() {}

    public func read(path: Shapefile.Path) throws -> Shapefile {
        let shpFile = try SHPFileReader(url: path.shp)
        return .init(
            minBoundingBox: shpFile.minBoundingBox,
            zRange: shpFile.zRange,
            mRange: shpFile.mRange,
            shapes: try shpFile.readShapes()
        )
    }
}
