import Foundation

final class DBFFileReader {

    typealias InfoRecord = Shapefile.InfoRecord
    typealias InfoProperty = Shapefile.InfoProperty

    private let fileHandle: FileHandle
    private var header: Header!

    private let dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let valueDateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    init(url: URL) throws {
        fileHandle = try .init(forReadingFrom: url)
        header = try readHeader()
    }

    deinit {
        try? fileHandle.close()
    }

    func readRecords() throws -> [InfoRecord] {
        try fileHandle.seek(toOffset: 0)

        assert(header.headerSize != 0, "Empty header")

        var records: [InfoRecord] = []

        for i in 0..<header.recordsCount {
            let offset = header.headerSize + (i * header.recordSize)
            let record = try readRecord(at: UInt64(offset))
            records.append(record)
        }

        return records
    }

    private func readHeader() throws -> Header {
        try fileHandle.seek(toOffset: 0)

        let values = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 32),
            with: "<BBBBIHH20x"
        ).map { $0.int! }

        let lastUpdateString = "\(1900+values[1])-\(String(format: "%02d", values[2]))-\(String(format: "%02d", values[3]))"
        guard let lastUpdateDate = dateFormatter.date(from: lastUpdateString) else {
            fatalError("Can't find last update date")
        }

        let recordsCount = values[4]
        let headerSize = values[5]
        let recordSize = values[6]

        let fieldsCount = (headerSize - 33) / 32
        var fieldDescriptors: [DBFFileReader.FieldDescriptor] = []
        for _ in 0..<fieldsCount {
            let fieldDescriptorValues = try DataUnpacker.unpack(
                fileHandle.readData(ofLength: 32),
                with: "<11sc4xBB14x"
            )

            let name = fieldDescriptorValues[0].string!
            let typeCharacter = fieldDescriptorValues[1].string!
            let size = fieldDescriptorValues[2].int!
            let isDecimal = fieldDescriptorValues[3].int! == 1

            guard let type = FieldType(rawValue: typeCharacter) else {
                assertionFailure("Invalid field descriptor type")
                continue
            }

            fieldDescriptors.append(
                .init(
                    name: name,
                    type: type,
                    size: size,
                    isDecimal: isDecimal
                )
            )
        }

        fieldDescriptors.insert(
            .init(
                name: "DeletionFlag",
                type: .character,
                size: 1,
                isDecimal: false
            ),
            at: 0
        )

        let terminator = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: 1),
            with: "<s"
        )[0].string!
        assert(terminator == "\r", "Unexpected terminator")

        let recordSizes = fieldDescriptors.map(\.size)
        let totalSize = recordSizes.reduce(0, +)
        let recordFormat = "<" + recordSizes
            .map { String($0) + "s" }
            .joined(separator: "")

        if totalSize != recordSize {
            assertionFailure("Invalid total record sizes")
        }

        return .init(
            lastUpdateDate: lastUpdateDate,
            recordsCount: recordsCount,
            headerSize: headerSize,
            recordSize: recordSize,
            recordFormat: recordFormat,
            fieldDescriptors: fieldDescriptors
        )
    }

    private func readRecord(at offset: UInt64) throws -> InfoRecord {
        try fileHandle.seek(toOffset: offset)

        let contentValues = try DataUnpacker.unpack(
            fileHandle.readData(ofLength: header.recordSize),
            with: header.recordFormat,
            stringEncodings: [.windowsCP1252, .unicode]
        ).map { $0.string! }

//        let isDeletedRecord = contentValues.first != " "
//        if isDeletedRecord {
//            return []
//        }

        assert(header.fieldDescriptors.count == contentValues.count, "Invalid content count")

        var properties: [InfoProperty] = []

        for (field, valueString) in Array(zip(header.fieldDescriptors, contentValues)) {
            if field.name == "DeletionFlag" {
                continue
            }

            let trimmedValue = valueString.trimmingCharacters(in: CharacterSet.whitespaces)

            var value: InfoProperty.Value
            switch field.type {
                case .character:
                    value = .string(trimmedValue)

                case .date:
                    if let date = valueDateFormatter.date(from: trimmedValue) {
                        value = .date(date)
                    } else {
                        continue
                    }

                case .decimal:
                    if trimmedValue == "" {
                        value = .string(trimmedValue)
                    } else if field.isDecimal || trimmedValue.contains(".") {
                        value = .double(.init(trimmedValue)!)
                    } else if let int = Int(trimmedValue) {
                        value = .int(int)
                    } else {
                        continue
                    }

                case .floating:
                    if let double = Double(trimmedValue) {
                        value = .double(double)
                    } else {
                        continue
                    }

                case .logical:
                    value = .bool(["T","t","Y","y"].contains(trimmedValue))

                case .memo:
                    value = .string(trimmedValue)
            }

            properties.append(
                .init(
                    name: field.name,
                    value: value
                )
            )
        }

        return properties
    }
}

private extension DBFFileReader {

    struct Header: Equatable {
        let lastUpdateDate: Date
        let recordsCount: Int
        let headerSize: Int
        let recordSize: Int
        let recordFormat: String
        let fieldDescriptors: [FieldDescriptor]
    }

    struct FieldDescriptor: Equatable {
        let name: String
        let type: FieldType
        let size: Int
        let isDecimal: Bool
    }

    enum FieldType: String {
        case character = "C"
        case date = "D"
        case decimal = "N"
        case floating = "F"
        case logical = "L"
        case memo = "M"
    }
}
