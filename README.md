# ShapefileReader

> [!NOTE]  
> The main points were tested on a small number of files. If something is not handled correctly, welcome to improve.

Simple [shapefile](https://en.wikipedia.org/wiki/Shapefile) `.shp`, `.dbf`, `.shx` files reader in Swift. Based on [nst/ShapefileReader](https://github.com/nst/ShapefileReader) and improved for new versions of language.

## Install

You can add **ShapefileReader** to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Add Package Dependencies...**.
2. Enter `https://github.com/bestK1ngArthur/ShapefileReader` into the package repository URL text field and add the package to your project.

## Examples

### Simple usage

```swift
import ShapefileReader

let shapefileReader = ShapefileReader()
let shapefile = try shapefileReader.read(
    from: .init(pathToFilesWithEqualName: "/path/to/files/with/equal/name")
)

print(shapefile.shapes)
```

### Show country boundaries in MapKit

This example located in **Examples** folder.

```swift
let result = try shapefileReader.readShape(
    from: .init(shp: shp, dbf: dbf, shx: shx),
    at: 100
)

guard
    let partableShape = result.shape?.partable,
    let name = result.record.value(for: "NAME")?.string,
    let code = result.record.value(for: "ISO_A2")?.string,
    let minBoundingBox = result.shape?.minBoundingBox
else {
    fatalError("Can't parse shape data")
}

let polygons = partableShape.pointsByParts.map { points in
    let coordinates = points.map { point in
        CLLocationCoordinate2D(latitude: point.y, longitude: point.x)
    }
    return MKPolygon(coordinates: coordinates, count: coordinates.count)
}

let country = Country(
    name: name,
    code: code,
    polygons: polygons,
    center: .init(
        latitude: (minBoundingBox.yMax + minBoundingBox.yMin) / 2,
        longitude: (minBoundingBox.xMax + minBoundingBox.xMin) / 2
    )
)
```

<img width="700" alt="Screenshot" src="https://github.com/bestK1ngArthur/ShapefileReader/assets/9194359/416f3f2e-da09-46ea-9bcb-5ad0ba74b6de">
