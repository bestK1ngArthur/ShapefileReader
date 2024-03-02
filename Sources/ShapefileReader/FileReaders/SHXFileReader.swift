import Foundation

/// `.shx` format file reader
final class SHXFileReader {

    private let fileHandle: FileHandle
    private var shapeOffsets: [Int]!

    init(url: URL) throws {
        fileHandle = try .init(forReadingFrom: url)
        shapeOffsets = try readOffsets()
    }

    deinit {
        try? fileHandle.close()
    }

    func offset(for index: Int) -> Int {
        guard index < shapeOffsets.count else {
            fatalError("Index out of bounds")
        }

        return shapeOffsets[index]
    }

    private func readOffsets() throws -> [Int] {
        try fileHandle.seek(toOffset: 24)

        let halfSize = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 4),
            with: ">i"
        )[0].int!
        let shxRecordSize = (halfSize * 2) - 100
        var recordsCount = shxRecordSize / 8

        fileHandle.seekToEndOfFile()

        let endOfFile = fileHandle.offsetInFile
        let sizeWithoutHeaders = endOfFile - 100
        let recordsCountMeasured = Int(sizeWithoutHeaders / 8)

        if recordsCount != recordsCountMeasured {
            assertionFailure("Invalid records count in file")
            recordsCount = recordsCountMeasured
        }

        var offsets: [Int] = []

        for recordIndex in 0..<recordsCount {
            let offset = UInt64(100 + 8 * recordIndex)
            try fileHandle.seek(toOffset: offset)

            let index = try DataUnpacker.unpack(
                fileHandle.readData(ofLength: 4),
                with: ">i"
            )[0].int!
            offsets.append(index * 2)
        }

        return offsets  
    }
}
