import Foundation

public protocol Extrapolator {
    func extrapolate(at: Double) throws -> Double
}

public enum ExtrapolationError: Error {
    case illegalArgumentException(reason: String)
    case arrayIndexOutOfBoundsException(reason: String)
}
