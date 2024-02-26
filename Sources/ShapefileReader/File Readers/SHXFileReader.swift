import Foundation

final class SHXFileReader {

    private let fileHandle: FileHandle
    private var header: Header!

    init(url: URL) throws {
        fileHandle = try .init(forReadingFrom: url)
        header = try readHeader()
    }

    deinit {
        try? fileHandle.close()
    }

    private func readHeader() throws -> Header {
        return .init()
    }
}

private extension SHXFileReader {

    struct Header: Equatable {}
}
