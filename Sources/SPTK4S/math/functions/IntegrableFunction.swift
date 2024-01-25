import Foundation

public protocol IntegrableFunction {
    func integrate(lowerBound: Double, upperBound: Double) -> Double
}
