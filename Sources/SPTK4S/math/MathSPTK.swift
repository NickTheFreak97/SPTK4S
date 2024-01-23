import Foundation
import Accelerate

public final class MathSPTK {
    private init() {}

    /***
     * Hypotenuse without under/overflow.
     * @param a
     * @param b
     * @return sqrt(a^2 + b^2)
     */
    public static func hypot(_ a: Double, _ b: Double) -> Double {
        var r: Double;
        
        if (Swift.abs(a) > Swift.abs(b)) {
            r = b / a
            r = Swift.abs(a) * Darwin.sqrt(1 + r * r)
        } else if (b != 0) {
            r = a / b
            r = Swift.abs(b) * Darwin.sqrt(1 + r * r)
        } else {
            r = 0.0
        }
        
        return r
    }

    /***
     * Inverse hyperbolic sine.
     * @param x
     * @return
     */
    public static func asinh(_ x: Double) -> Double {
        return x >= 0 ? Darwin.log(x + Darwin.sqrt(x * x + 1.0)) : -Darwin.log(-x + Darwin.sqrt(x * x + 1.0))
    }

    public static func acosh(_ x: Double) -> Double {
        return Darwin.log(x + Darwin.sqrt(x * x - 1.0))
    }

    public static func atanh(_ x: Double) -> Complex {
        var z = Swift.abs(x)
        
        if(z < 1) {    // -1 < x < 1
            let at = 0.5 * Darwin.log((1 + x) / (1 - x));
            
            copysign(at, x);
            
            return Complex.fromReal(d: at);
            
        }
        let at: Complex = Complex.fromImaginary(d: x).atan();
        at.divideEquals(Complex.fromImaginary(d: 1.0));
        return at;
    }
    
    /***
     * Round towards zero.
     * @param x
     * @return the value of x rounded to the nearest integer toward zero
     */
    public static func fix(_ x: Double) -> Double {
        return x <= 0 ? Darwin.ceil(x) : Darwin.floor(x);
    }
    
    /***
     * Remainder after division.
     * @param a
     * @param b
     * @return
     */
    public static func rem(_ a: Double, _ b: Double) -> Double {
        if(b == 0) {
            return Double.nan;
        }
        return a - b * MathSPTK.fix(a / b);
    }

    /***
     * Find the number rounded down to a multiple of the threshold.
     * @param x
     * @param threshold
     * @return
     */
    public static func floor(_ x: Double, threshold: Double) -> Double {
        var result: Double = 0.0;
        result = x / threshold;
        return Darwin.floor(result) * threshold;
    }

    /***
     * Find the number rounded up to a multiple of the threshold.
     * @param x
     * @param threshold
     * @return
     */
    public static func ceil(_ x: Double, threshold: Double) -> Double {
        var result = 0.0;
        result = x / threshold;
        return Darwin.ceil(result) * threshold;
    }

    /***
     * Determines whether a number is close to another number within a certain tolerance.
     * @param a Argument in which to evaluate the function at.
     * @param b Argument in which to evaluate the function at.
     * @param absTol The absolute tolerance.
     * @param relTol The relative tolerance.
     * @return {@code Math.abs(a - b) <= absTol + relTol * Math.abs(b)}
     * @see <a href="https://numpy.org/doc/stable/reference/generated/numpy.isclose.html">isClose</a>
     */
    public static func isClose(_ a: Double, _ b: Double, absTol: Double, relTol: Double) -> Bool {
        return Swift.abs(a - b) <= absTol + relTol * Swift.abs(b);
    }

    /***
     * Determines whether a number is close to another number within a certain tolerance.
     * @param a Argument in which to evaluate the function at.
     * @param b Argument in which to evaluate the function at.
     * @param absTol The absolute tolerance.
     * @param relTol The relative tolerance.
     * @return {@code Math.abs(a - b) <= absTol + relTol * Math.abs(b)}
     * @see <a href="https://numpy.org/doc/stable/reference/generated/numpy.isclose.html">isClose</a>
     */
    public static func isClose(_ a: Complex, _ b: Complex, absTol: Double, relTol: Double) -> Bool {
        return a.subtract(b).abs() <= absTol + relTol * b.abs();
    }

    /***
     * Determines whether a number is close to another number within a certain tolerance. <br>
     * This calls {@link #isClose(double, double, double, double) with relative tolerance of 1e-5}.
     * @param a Argument in which to evaluate the function at.
     * @param b Argument in which to evaluate the function at.
     * @param absTol The absolute tolerance.
     * @return {@code Math.abs(a - b) <= absTol + 1e-5 * Math.abs(b)}
     * @see <a href="https://numpy.org/doc/stable/reference/generated/numpy.isclose.html">isClose</a>
     */
    public static func isClose(_ a: Double, _ b: Double, absTol: Double) -> Bool {
        return isClose(a, b, absTol: absTol, relTol: 1e-5);
    }

    /***
     * Determines whether a number is close to another number within a certain tolerance. <br>
     * This calls {@link #isClose(double, double, double, double) with absolute tolerance of 1e-8 and <br>
     * relative tolerance of 1e-5}.
     * @param a Argument in which to evaluate the function at.
     * @param b Argument in which to evaluate the function at.
     * @return {@code Math.abs(a - b) <= 1e-8 + 1e-5 * Math.abs(b)}
     * @see <a href="https://numpy.org/doc/stable/reference/generated/numpy.isclose.html">isClose</a>
     */
    public static func isClose(_ a: Double, _ b: Double) -> Bool {
        return isClose(a, b, absTol: 1e-8, relTol: 1e-5);
    }

    public static func logb(_ x: Double, base: Int) -> Double {
        return Darwin.log(x) / Darwin.log(Double(base));
    }

    /***
     * Round to the next even number.
     * @param d number to be rounded.
     * @return the input number rounded to the next even number.
     */
    public static func roundEven(_ d: Double) -> Double {
        return Darwin.round(d / 2) * 2;
    }

    public class FRexpResult {
        public var exponent: Int = 0;
        public var mantissa: Double = 0.0;
    }

    /**
     * Find the mantissa and exponent of a number.
     *
     * @param value Breaks the floating point number value into its binary significand and an integral exponent for 2.
     * @return The mantissa and exponent of a number such that number = m * 2^e.
     * @see <a href="https://stackoverflow.com/a/3946294/6383857">https://stackoverflow.com/a/3946294/6383857</a>
     */
    public static func frexp(_ value: Double) -> FRexpResult {
        let result = FRexpResult();

        result.exponent = 0;
        result.mantissa = 0;

        if (value == 0.0) {
            return result;
        }
        if (value.isNaN) {
            result.mantissa = Double.nan;
            result.exponent = -1;
            return result;
        }
        if (value.isInfinite) {
            result.mantissa = value;
            result.exponent = -1;
            return result;
        }
        
        let bits: UInt64 = value.bitPattern
        var realMantissa: Double = 1.0

        let neg: Bool = (bits < 0);
        var exponent: Int = Int( ((bits >> 52) & UInt64(0x7ff)));
        var mantissa = bits & UInt64(0xfffffffffffff);

        if (exponent == 0) {
            exponent += 1;
        } else {
            mantissa = mantissa | (UInt64(1) << 52);
        }

        // bias the exponent - actually biased by 1023.
        // we are treating the mantissa as m.0 instead of 0.m
        //  so subtract another 52.
        exponent -= 1075;
        realMantissa = Double(mantissa);

        // normalize
        while (realMantissa >= 1.0) {
            mantissa >>= 1;
            realMantissa /= 2.0;
            exponent += 1;
        }

        if (neg) {
            realMantissa = realMantissa * -1;
        }

        result.exponent = exponent;
        result.mantissa = realMantissa;

        return result;
    }
}
