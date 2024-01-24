import Foundation

public final class DimensionCheckers {
    private init() { }
    
    public static func checkXYDimensions(_ x: [Double], _ y: [Double]) throws {
        if (x.count != y.count) {
            throw DimensionError.illegalArgumentException(reason: "x and y dimensions must be the same")
        }
    }
    
    public static func checkXYDimensions(_ x: [Complex], _ y: [Complex]) throws {
        if (x.count != y.count) {
            throw DimensionError.illegalArgumentException(reason: "x and y dimensions must be the same")
        }
    }

    public static func checkXYDimensions(_ x: DSPCountedDoubleSplitComplex, _ y: DSPCountedDoubleSplitComplex) throws {
        if (x.count() != y.count()) {
            throw DimensionError.illegalArgumentException(reason: "x and y dimensions must be the same")
        }
    }

    public static func checkMinXLength(_ x: [Double], minLength: Int) throws {
        if (x.count < minLength) {
            throw DimensionError.illegalArgumentException(reason: "x length must be >= \(minLength)")
        }
    }
}

public enum DimensionError: Error {
    case illegalArgumentException(reason: String)
}
