import Foundation

final class DataUnpacker {

    enum Value {
        case string(String)
        case bool(Bool)
        case int(Int)
        case double(Double)
    }

    enum UnpackError: Error {
        case formatNotMatchDataLength(format: String, dataLength: Int)
        case unsupportedFormatCharacter(character: Character)
    }

    /// Python analogue to `struct.unpack(fmt, string)`
    static func unpack(
        _ data: Data,
        with format: String,
        stringEncoding: String.Encoding = .windowsCP1252
    ) throws -> [Value] {
        assert(
            Int(OSHostByteOrder()) == OSLittleEndian,
            "\(#file) assumes little endian, but host is big endian"
        )

        let isBigEndian = isBigEndianFromMandatoryByteOrderFirstCharacter(format)

        if isFormatMatchDataLength(format, data: data) == false {
            throw UnpackError.formatNotMatchDataLength(format: format, dataLength: data.count)
        }

        var values: [Value] = []

        var location = 0
        let bytes = data.bytes
        var n = 0

        var mutableFormat = format
        mutableFormat.remove(at: mutableFormat.startIndex)

        while mutableFormat.count > 0 {
            let char = mutableFormat.remove(at: mutableFormat.startIndex)

            if let i = Int(String(char)), 0...9 ~= i {
                if n > 0 { n *= 10 }
                n += i
                continue
            }

            if char == "s" {
                let length = max(n,1)
                let sub = Array(bytes[location..<location+length])

                guard 
                    let string = NSString(
                        bytes: sub,
                        length: length,
                        encoding: stringEncoding.rawValue
                    )
                else {
                    assertionFailure("It's not a string: \(sub)")
                    return []
                }

                values.append(.string(string as String))
                
                location += length
                n = 0

                continue
            }

            for _ in 0..<max(n,1) {
                var value: Value?

                switch(char) {
                    case "c":
                        let optionalString = NSString(
                            bytes: [bytes[location]],
                            length: 1,
                            encoding: String.Encoding.utf8.rawValue
                        )
                        location += 1

                        guard let string = optionalString else {
                            assertionFailure()
                            return []
                        }

                        value = .string(string as String)

                    case "b":
                        let rawInt = readIntegerType(
                            Int8.self,
                            bytes: bytes,
                            location: &location
                        )
                        value = .int(Int(rawInt))

                    case "B":
                        let rawInt = readIntegerType(
                            UInt8.self,
                            bytes: bytes,
                            location: &location
                        )
                        value = .int(Int(rawInt))

                    case "?":
                        let rawBool = readIntegerType(
                            Bool.self,
                            bytes: bytes,
                            location: &location
                        )
                        value = .bool(rawBool ? true : false)

                    case "h":
                        let rawInt = readIntegerType(
                            Int16.self,
                            bytes: bytes,
                            location: &location
                        )
                        value = .int(Int(isBigEndian ? Int16(bigEndian: rawInt) : rawInt))

                    case "H":
                        let rawInt = readIntegerType(
                            UInt16.self,
                            bytes: bytes,
                            location:&location
                        )
                        value = .int(Int(isBigEndian ? UInt16(bigEndian: rawInt) : rawInt))

                    case "i":
                        fallthrough

                    case "l":
                        let rawInt = readIntegerType(
                            Int32.self,
                            bytes: bytes,
                            location: &location
                        )
                        value = .int(Int(isBigEndian ? Int32(bigEndian: rawInt) : rawInt))

                    case "I":
                        fallthrough

                    case "L":
                        let rawInt = readIntegerType(
                            UInt32.self,
                            bytes: bytes,
                            location: &location
                        )
                        value = .int(Int(isBigEndian ? UInt32(bigEndian: rawInt) : rawInt))

                    case "q":
                        let rawInt = readIntegerType(
                            Int64.self,
                            bytes: bytes,
                            location: &location
                        )
                        value = .int(Int(isBigEndian ? Int64(bigEndian: rawInt) : rawInt))

                    case "Q":
                        let rawInt = readIntegerType(
                            UInt64.self,
                            bytes: bytes,
                            location: &location
                        )
                        value = .int(Int(isBigEndian ? UInt64(bigEndian: rawInt) : rawInt))

                    case "f":
                        let rawDouble = readFloatingPointType(
                            Float32.self,
                            bytes: bytes,
                            location: &location,
                            isBigEndian: isBigEndian
                        )
                        value = .double(Double(rawDouble))

                    case "d":
                        let rawDouble = readFloatingPointType(
                            Float64.self,
                            bytes: bytes,
                            location: &location,
                            isBigEndian: isBigEndian
                        )
                        value = .double(Double(rawDouble))

                    case "x":
                        location += 1

                    case " ":
                        break

                    default:
                        throw UnpackError.unsupportedFormatCharacter(character: char)
                }

                if let value {
                    values.append(value)
                }
            }

            n = 0
        }

        return values
    }

    private static func isFormatMatchDataLength(
        _ format: String,
        data: Data
    ) -> Bool {
        let sizeAccordingToFormat = numberOfBytesInFormat(format)
        let dataLength = data.count
        return sizeAccordingToFormat == dataLength
    }

    private static func isBigEndianFromMandatoryByteOrderFirstCharacter(
        _ format: String
    ) -> Bool {
        guard let firstChar = format.first else {
            assertionFailure("Empty format")
            return false
        }

        let s = String(firstChar) as NSString
        let c = s.substring(to: 1)

        if c == "@" {
            assertionFailure("Native size and alignment is unsupported")
        }

        if c == "=" || c == "<" {
            return false
        }

        if c == ">" || c == "!" {
            return true
        }

        assertionFailure("Format '\(format)' first character must be among '=<>!'")
        return false
    }

    /// Python analogue to `struct.calcsize(fmt)`
    private static func numberOfBytesInFormat(_ format: String) -> Int {
        var numberOfBytes = 0
        var n = 0
        var mutableFormat = format

        while mutableFormat.count > 0 {
            let c = mutableFormat.remove(at: mutableFormat.startIndex)

            if let i = Int(String(c)) , 0...9 ~= i {
                if n > 0 { n *= 10 }
                n += i
                continue
            }

            if c == "s" {
                numberOfBytes += max(n,1)
                n = 0
                continue
            }

            for _ in 0..<max(n,1) {
                switch(c) {
                    case "@", "<", "=", ">", "!", " ":
                        ()
                    case "c", "b", "B", "x", "?":
                        numberOfBytes += 1
                    case "h", "H":
                        numberOfBytes += 2
                    case "i", "l", "I", "L", "f":
                        numberOfBytes += 4
                    case "q", "Q", "d":
                        numberOfBytes += 8
                    case "P":
                        numberOfBytes += MemoryLayout<Int>.size
                    default:
                        assertionFailure("-- unsupported format \(c)")
                }
            }

            n = 0
        }

        return numberOfBytes
    }

    private static func readIntegerType<T:DataConvertible>(
        _ type: T.Type,
        bytes: [UInt8],
        location: inout Int
    ) -> T {
        let size = MemoryLayout<T>.size
        let sub = Array(bytes[location..<(location+size)])
        location += size
        return T(bytes: sub)!
    }

    private static func readFloatingPointType<T:DataConvertible>(
        _ type: T.Type,
        bytes: [UInt8],
        location: inout Int,
        isBigEndian: Bool
    ) -> T {
        let size = MemoryLayout<T>.size
        let sub = Array(bytes[location..<(location+size)])
        location += size
        let finalSub = isBigEndian ? sub.reversed() : sub
        return T(bytes: finalSub)!
    }
}

extension DataUnpacker.Value {

    var string: String? {
        if case .string(let string) = self {
            return string
        } else {
            return nil
        }
    }

    var bool: Bool? {
        if case .bool(let bool) = self {
            return bool
        } else {
            return nil
        }
    }

    var int: Int? {
        if case .int(let int) = self {
            return int
        } else {
            return nil
        }
    }

    var double: Double? {
        if case .double(let double) = self {
            return double
        } else {
            return nil
        }
    }
}

private extension Data {

    var bytes: [UInt8] {
        withUnsafeBytes { pointer in
            [UInt8](UnsafeBufferPointer(start: pointer, count: count))
        }
    }
}

// MARK: - DataConvertible

private protocol DataConvertible {}

private extension DataConvertible {

    init?(data: Data) {
        guard data.count == MemoryLayout<Self>.size else { return nil }
        self = data.withUnsafeBytes { $0.pointee }
    }

    init?(bytes: [UInt8]) {
        let data = Data(bytes: bytes, count: bytes.count)
        self.init(data:data)
    }

    var data: Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Bool: DataConvertible {}

extension Int8: DataConvertible {}
extension Int16: DataConvertible {}
extension Int32: DataConvertible {}
extension Int64: DataConvertible {}

extension UInt8: DataConvertible {}
extension UInt16: DataConvertible {}
extension UInt32: DataConvertible {}
extension UInt64: DataConvertible {}

extension Float32: DataConvertible {}
extension Float64: DataConvertible {}
