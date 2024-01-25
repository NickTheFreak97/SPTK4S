import Foundation

/// Simulates the abstract class `PiecewiseFunction`.
///
/// Default initializer should go like this:
///
/// ```swift
///init(_ x: [Double]) {
///     self.breaks = breaks
///     self.numberOfSegments = breaks.count - 1
///
///     // TODO: Check Parameters for Validity [Effective Java]:
///     // breaks must be sorted in ascending order.
///     // if this invariant is broken, `findSegmentIndex(at: Double)`
///     // behavior is undefined.
///
///     self.x0 = breaks[0]
///     self.xn = breaks[breaks.count - 1]
///
///     self.extrapolator = Extrapolators.ThrowExtrapolator(x0: x0, xn: xn)
///}
/// ```
public protocol PiecewiseFunction: UnivariateFunction {
    var numberOfSegments: Int { get }
    var breaks: [Double] { get }
    var coefficients: [Double]? { get }
    var extrapolator: Extrapolator { get set }
    
    var x0: Double { get }
    var xn: Double { get }
    
    func setExtrapolator(_ extrapolator: Extrapolator) -> Void
    func findSegmentIndex(at: Double) -> Int
    func getNumberOfSegments() -> Int
    
    /// - Note: Default implementation self-uses `UnivariateFunction.evaluate(at:Double)`
    func evaluateAt(_ doubleArray: [Double]) -> [Double]
    func evaluateAt(index: Int, at: Double) -> Double
    
    func getSegment(_ number: Int) -> UnivariateFunction
    
    /// - Note: Default implementation self-uses `getSegment(_:Int)`
    func getFirstSegment() -> UnivariateFunction
    
    /// - Note: Default implementation self-uses `getSegment(_:Int)`
    func getLastSegment() -> UnivariateFunction
    
    func extrapolate(at: Double) throws -> Double
    func getBreaks() -> [Double]
}

extension PiecewiseFunction {
    mutating func setExtrapolator(_ extrapolator: Extrapolator) -> Void {
        self.extrapolator = extrapolator
    }
    
    func findSegmentIndex(at: Double) -> Int {
        let index = DoubleArrays.binarySearch(self.breaks, target: at)
        return index < 0 ? -(index + 2) : Swift.min(index, self.breaks.count - 2)
    }
    
    func getNumberOfSegments() -> Int {
        return self.numberOfSegments
    }
    
    func evaluateAt(_ doubleArray: [Double]) -> [Double] {
        var yi = [Double].init(repeating: 0.0, count: self.breaks.count)
        
        for (i, real) in doubleArray.enumerated() {
            yi[i] = self.evaluate(at: real)
        }
        
        return yi
    }
    
    /// - Note: Default implementation self-uses `findSegmentIndex(at: at)`, 
    /// then the result is fed to `self.evaluateAt(index: Int, at: Double)`,
    /// then the result is fed to `self.extrapolate(at: Double)`
    public func evaluate(at: Double) -> Double {
        var x = at
        x += 0.0;    // convert -0.0 to 0.0
        
        if (x >= x0 && x <= xn) {
            let index = self.findSegmentIndex(at: x)
            return self.evaluateAt(index: index, at: x)
        }
        
        return try! self.extrapolate(at: x)
    }
    
    
    public func getFirstSegment() -> UnivariateFunction {
        return self.getSegment(0)
    }
    
    public func getLastSegment() -> UnivariateFunction {
        return self.getSegment(self.breaks.count - 2)
    }
    
    public func extrapolate(_ x: Double) throws -> Double {
        return try self.extrapolator.extrapolate(at: x)
    }
    
    public func getBreaks(_ x: Double) -> [Double] {
        return DoubleArrays.deepCopy(self.breaks)
    }
}
