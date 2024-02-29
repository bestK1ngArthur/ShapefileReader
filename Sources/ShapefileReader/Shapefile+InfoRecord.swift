import Foundation

extension Shapefile {

    public struct InfoProperty: Equatable {

        public enum Value: Equatable {
            case date(Date)
            case double(Double)
            case int(Int)
            case bool(Bool)
            case string(String)
        }

        public let name: String
        public let value: Value
    }

    public typealias InfoRecord = [InfoProperty]
}

extension Shapefile.InfoRecord {

    public func value(for name: String) -> Shapefile.InfoProperty.Value? {
        return first(where: { $0.name == name })?.value
    }
}

extension Shapefile.InfoProperty.Value {

    public var date: Date? {
        if case .date(let date) = self {
            return date
        } else {
            return nil
        }
    }

    public var double: Double? {
        if case .double(let double) = self {
            return double
        } else {
            return nil
        }
    }

    public var int: Int? {
        if case .int(let int) = self {
            return int
        } else {
            return nil
        }
    }

    public var bool: Bool? {
        if case .bool(let bool) = self {
            return bool
        } else {
            return nil
        }
    }

    public var string: String? {
        if case .string(let string) = self {
            return string
        } else {
            return nil
        }
    }
}
