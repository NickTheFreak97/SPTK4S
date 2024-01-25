import Foundation

public protocol DifferentiableFunction {
    func differentiate(at: Double) -> Double
}
