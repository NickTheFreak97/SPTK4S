import Foundation

public final class Extrapolators {

    private init() { }

    /// The `ClampToEndPointExtrapolator` class clamps the value of the extrapolation to the values prescribed by `y0` and `yn`
    public class ClampToEndPointExtrapolator: Extrapolator {
        private let x0: Double
        private let xn: Double
        private let y0: Double
        private let yn: Double
        
        public init(x0: Double, xn: Double, y0: Double, yn: Double) {
            self.x0 = x0
            self.xn = xn
            self.y0 = y0
            self.yn = yn
        }
        
        /// Extrapolation.
        ///
        /// - Parameter at: Argument at which to evaluate the extrapolation.
        /// - Returns: `y0` if `x < x0`, `yn` if `x > xn`
        /// - Throws: `ExtrapolationError.illegalArgumentException(_:String)` if `at ∈[x0, xn]`
        public func extrapolate(at: Double) throws -> Double {
            if at < x0 {
                return y0
            } else {
                if at > xn {
                    return yn
                } else {
                    throw ExtrapolationError.illegalArgumentException(reason: "\(at) is not outside [\(x0), \(xn)]")
                }
            }
        }
    }
        
                
    /// The `ClampToValueExtrapolator` class clamps the value of the extrapolation to a prescribed value.
    public class ClampToValueExtrapolator: Extrapolator {
        private let value: Double

        public init(value: Double) {
            self.value = value;
        }


        /// Extrapolate.
        ///
        /// - Parameter at: Argument at which to evaluate the extrapolation.
        /// - Returns: The value assigned during construction
        ///
        /// - Note: This implementation of `extrapolate(_:Double)` never throws.
        public func extrapolate(at: Double) throws -> Double {
            return value
        }
    }

    
    public class ClampToNanExtrapolator: ClampToValueExtrapolator {
        public init() {
            super.init(value: Double.nan)
        }
    }

    
    public class ClampToZeroExtrapolator: ClampToValueExtrapolator {
        public init() {
            super.init(value: .zero)
        }
    }

    
    /// The `LinearExtrapolator` class constructs a line `y = m * (x - xi) + yi` where `m` is calculated by
    /// differentiating the ``DifferentiableFunction``.  `(xi, yi)` are the left-hand side coordinates if x is
    /// less than the minimum value for extrapolation or the right-hand side values otherwise.
    public class LinearExtrapolator: Extrapolator {

        private let dfn: DifferentiableFunction
        private let x0: Double
        private let xn: Double
        private let y0: Double
        private let yn: Double

        public init(dfn: DifferentiableFunction, x0: Double, xn: Double, y0: Double, yn: Double) {
            self.dfn = dfn
            self.x0 = x0
            self.xn = xn
            self.y0 = y0
            self.yn = yn
        }

        
        public func extrapolate(at: Double) throws -> Double {
            var xi = x0
            var yi = y0
            
            if at > xn {
                xi = xn
                yi = yn
            }
            
            let di = dfn.differentiate(at: xi)
            return yi + di * (at - xi)
        }
    }


    /// The `NaturalExtrapolator` class evaluates the extrapolation at a function specified for the left-hand side
    /// of the extrapolation if x is on the left-hand side of the extrapolation or evaluates the extrapolation at a
    /// function specified for the right-hand side otherwise.
    public class NaturalExtrapolator: Extrapolator {

        private let leftFn: UnivariateFunction
        private let rightFn: UnivariateFunction

        private let x0: Double
        private let xn: Double

        public init(leftFn: UnivariateFunction, rightFn: UnivariateFunction, x0: Double, xn: Double) {
            self.leftFn = leftFn;
            self.rightFn = rightFn;
            self.x0 = x0;
            self.xn = xn;
        }

        
        public func extrapolate(at: Double) throws -> Double {
            if at < x0 {
                return leftFn.evaluate(at: at)
            } else {
                if at > xn {
                    return rightFn.evaluate(at: at)
                } else {
                    throw ExtrapolationError.illegalArgumentException(reason: "\(at) is not outside of [\(x0),\(xn)]")
                }
            }
        }
    }


    /// The `ThrowExtrapolator` class throws an `ExtrapolationError.arrayIndexOutOfBoundsException(_:String)` if x is outside of the
    /// valid range or `ExtrapolationError.illegalArgumentException(_:String)` if x is within the allowed range.
    public class ThrowExtrapolator: Extrapolator {
        private let x0: Double
        private let xn: Double
        
        public init(x0: Double, xn: Double) {
            self.x0 = x0
            self.xn = xn
        }
        
        
        public func extrapolate(at: Double) throws -> Double {
            if at < x0 {
                throw ExtrapolationError.arrayIndexOutOfBoundsException(reason: "\(at) is smaller than every number in [\(x0), \(xn)]")
            } else {
                if at > xn {
                    throw ExtrapolationError.arrayIndexOutOfBoundsException(reason: "\(at) is bigger than every number in [\(x0), \(xn)]")
                } else {
                    throw ExtrapolationError.illegalArgumentException(reason: "\(at) is not outside [\(x0), \(xn)]")
                }
            }
        }
    }
}
