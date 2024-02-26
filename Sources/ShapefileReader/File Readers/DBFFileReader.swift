import Foundation

final class DBFFileReader {

    private let fileHandle: FileHandle
    private var header: Header!

    init(url: URL) throws {
        fileHandle = try .init(forReadingFrom: url)
        header = try readHeader()
    }

    deinit {
        try? fileHandle.close()
    }

    func readRecords() throws -> [String] {
        return []
    }

    private func readHeader() throws -> Header {
        return .init()
    }
}

private extension DBFFileReader {

    struct Header: Equatable {}
}
