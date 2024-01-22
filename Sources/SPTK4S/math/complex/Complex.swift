import Foundation
import Accelerate

public final class Complex: Equatable, Hashable, CustomStringConvertible {
    public var description: String {
        return "(\(self.realp()) \(self.imagp() >= 0 ? "+" : "-") \(Swift.abs(self.imagp())))"
    }
    
    private var realDA: [Double]
    private var imagDA: [Double]
    
    private var wrapped: DSPDoubleSplitComplex!

    public static func == (_ lhs: Complex, _ rhs: Complex) -> Bool {
        return lhs.wrapped.realp[0] == rhs.wrapped.imagp[0] && lhs.wrapped.realp[0] == rhs.wrapped.realp[0]
    }

    /**
     * Constructs a {@code Complex} number with real and imaginary part equal to zero.
     */
    public init() {
        realDA = [0.0]
        imagDA = [0.0]
        
        realDA.withUnsafeMutableBufferPointer { realpPtr in
            imagDA.withUnsafeMutableBufferPointer { imagpPtr in
                self.wrapped = DSPDoubleSplitComplex(realp: realpPtr.baseAddress!, imagp: imagpPtr.baseAddress!)
            }
        }
    }

    /**
     * Constructs a {@code Complex} number from the real and imaginary parts.
     *
     * @param real The real part of the complex number.
     * @param imag The imaginary part of the complex number.
     */
    public init(real: Double, imag: Double) {
        realDA = [real]
        imagDA = [imag]
        
        realDA.withUnsafeMutableBufferPointer { realpPtr in
            imagDA.withUnsafeMutableBufferPointer { imagpPtr in
                self.wrapped = DSPDoubleSplitComplex(realp: realpPtr.baseAddress!, imagp: imagpPtr.baseAddress!)
            }
        }
    }
    
    public final func realp() -> Double {
        return self.wrapped.realp[0]
    }
    
    public final func imagp() -> Double {
        return self.wrapped.imagp[0]
    }

    /**
     * Copy Constructor
     * @param c The Complex number to be copied.
     */
    public init(c: Complex) {
        realDA = [c.realp()]
        imagDA = [c.imagp()]
        
        realDA.withUnsafeMutableBufferPointer { realpPtr in
            imagDA.withUnsafeMutableBufferPointer { imagpPtr in
                self.wrapped = DSPDoubleSplitComplex(realp: realpPtr.baseAddress!, imagp: imagpPtr.baseAddress!)
            }
        }
    }

    /**
     * Constructs a complex number with only real part and zero imaginary port.
     *
     * @param d The real part of the complex number.
     * @return A complex number with real part equal to {@code d} nd imaginary part equal to zero.
     */
    public static func fromReal(d: Double) -> Complex {
        return SPTK4S.Complex(real: d, imag: 0.0)
    }

    /**
     * Constructs a complex number with real part equal to zero and only imaginary port.
     *
     * @param d The imaginary part of the complex number.
     * @return A complex number with real part equal to zero and imaginary part equal to {@code d}.
     */
    public static func fromImaginary(d: Double) -> Complex {
        return SPTK4S.Complex(real: 0.0, imag: d)
    }

    /**
     * Constructs a complex number from magnitude and phase angle
     *
     * @param r The magnitude of the complex number.
     * @param theta The phase angle in radians.
     * @return (r * cos ( theta), r * sin(theta))
     */
    public static func fromPolar(r: Double, theta: Double) -> Complex {
        return SPTK4S.Complex(real: r * Darwin.cos(theta), imag: r * Darwin.sin(theta))
    }

    /**
     * @see java.lang.Object#hashCode()
     */
    public func hash(into hasher: inout Hasher) {
        let prime: Int = 31
        var result: Int = 1
        var temp: Int64 = 0
        
        temp = Int64(self.imagp().bitPattern)
        result = prime &* result &+ Int(temp ^ (temp >> 32))
        
        temp = Int64(self.realp().bitPattern)
        result = prime &* result &+ Int(temp ^ (temp >> 32))
        
        hasher.combine(result)
    }

    /**
     * Is the complex number comprised of only real part.
     *
     * @return True if the imaginary part is equal to zero.
     */
    public func isReal() -> Bool {
        return imagp() == 0
    }

    /**
     * Compare complex numbers lexicographically.
     * Real parts get compared first and if they are equal then the imaginary parts are compared.
     * @see java.lang.Comparable(java.lang.Object)
     */
    public func compareTo(_ obj: Complex) -> Int {
        if (self == obj) {
            return 0;
        } else {
            if (self.realp() > obj.realp()) {
                return 1;
            } else {
                if (self.realp() < obj.realp()) {
                    return -1;
                } else {
                    if self.imagp() == obj.imagp() {
                        return 0
                    } else {
                        if self.imagp() > obj.imagp() {
                            return 1
                        } else {
                            return -1
                        }
                    }
                }
            }
        }
    }

    /**
     * Compare the absolute values of two complex numbers.
     * @param obj Argument used for comparison.
     * @return {@code this.abs().compareTo(obj.abs())}
     */
    public func compareToAbs(_ obj: Complex) -> Int {
        if (self == obj) {
            return 0;
        }
        
        let selfAbs = self.abs()
        let objAbs = obj.abs()
        
        if selfAbs == objAbs {
            return 0
        } else {
            if selfAbs > objAbs {
                return 1
            } else {
                return -1
            }
        }
    }
    
    /**
     * Absolute value of the complex number.
     *
     * @return The absolute value of the complex number. <br>
     * Theoretically this can be computed as {@code Math.sqrt(real * real + imag * imag)}. <br>
     * For further details, see {@link MathSPTK#hypot(double, double)}
     */
    public func abs() -> Double {
        return MathSPTK.hypot(self.realp(), self.imagp())
    }

    /**
     * Argument of the complex number.
     *
     * @return The angle in radians where the x-axis is in polar coordinates.
     */
    public func arg() -> Double {
        return atan2(self.imagp(), self.realp())
    }

    /***
     * Norm of the complex number.
     *
     * @return The magnitude squared, {@code real * real + imag * imag}.
     */
    public func norm() -> Double {
        let real = self.realp()
        let imag = self.imagp()
        
        return real * real + imag * imag
    }

    /**
     * Conjugate of the complex number.
     *
     * @return {@code new Complex(real, -imag)}.
     */
    public func conj() -> Complex {
        return SPTK4S.Complex(real: self.realp(), imag: -self.imagp())
    }

    /**
     * Inverse of the complex number.
     *
     * @return {@code Complex a = 1 / new Complex(a)}.
     */
    public func invert() -> Complex {
        let result: Complex = SPTK4S.Complex(real: self.realp(), imag: self.imagp())
        Complex.invertOp(result)
        return result
    }

    /**
     * Inverse of the complex number in place.
     *
     * @return {@code Complex a = 1 / a. No new object is created.
     */
    public func invertEquals() -> Void {
        Complex.invertOp(self);
    }

    /**
     * Addition of complex numbers.
     *
     * @param c The complex number to add.
     * @return The complex number + {@code c}.
     */
    public func add(_ c: Complex) -> Complex {
        var result = SPTK4S.Complex(real: self.realp(), imag: self.imagp())

        Complex.addOp(&result, c)
        return result
    }

    /**
     * Addition of a complex number and a real number.
     *
     * @param d The real number to add.
     * @return The complex number + {@code d}.
     */
    public func add(_ d: Double) -> Complex {
        var result: Complex = SPTK4S.Complex(real: self.realp(), imag: self.imagp())
        Complex.addOp(&result, d)
        return result
    }

    /**
     * Addition of complex numbers.
     *
     * @param real Real part of number to add.
     * @param imag Imaginary part of the number to add.
     * @return Complex number + {@code new Complex(real, imag}.
     */
    public func add(real: Double, imag: Double) -> Complex{
        var result: Complex = SPTK4S.Complex(real: self.realp(), imag: self.imagp())
        Complex.addOp(&result, real, imag)
        return result
    }

    /**
     * Addition in place. <br>
     * Performs the equivalent of {@code Complex a += Complex c}.
     *
     * @param c Complex number to add.
     */
    public func addEquals(_ c: Complex) -> Void {
        var selfCopy = SPTK4S.Complex(c: self)
        Complex.addOp(&selfCopy, c)
        
        self.wrapped.realp[0] = selfCopy.realp()
        self.wrapped.imagp[0] = selfCopy.imagp()
    }

    /**
     * Addition in place. <br>
     * Performs the equivalent of {@ code Complex a += d}.
     *
     * @param d The real number to add.
     */
    public func addEquals(_ d: Double) -> Void {
        var selfCopy = SPTK4S.Complex(c: self)
        Complex.addOp(&selfCopy, d)
        
        self.wrapped.realp[0] = selfCopy.realp()
        self.wrapped.imagp[0] = selfCopy.imagp()
    }

    /**
     * Addition in place. <br>
     * Performs the equivalent of {@code Complex a += new Complex(real, imag)}
     *
     * @param real the real part of the number to add.
     * @param imag the imaginary part of the number to add.
     */
    public func addEquals(real: Double, imag: Double) {
        var selfCopy = SPTK4S.Complex(c: self)
        Complex.addOp(&selfCopy, real, imag)
        
        self.wrapped.realp[0] = selfCopy.realp()
        self.wrapped.imagp[0] = selfCopy.imagp()
    }

    /**
     * Subtraction of complex numbers.
     *
     * @param c Complex number to subtract.
     * @return The complex number - {@code c}.
     */
    public func subtract(_ c: Complex) -> Complex {
        var result = SPTK4S.Complex(real: self.realp(), imag: self.imagp())
        Complex.subtractOp(&result, c)
        return result
    }

    /**
     * Subtraction of a complex number and a real number.
     *
     * @param d Real number to subtract.
     * @return The complex number - {@code d}.
     */
    public func subtract(_ d: Double) -> Complex {
        var result = SPTK4S.Complex(real: self.realp(), imag: self.imagp())
        Complex.subtractOp(&result, d)
        return result
    }

    /**
     * Subtraction in place. <br>
     * Performs the equivalent of {@code Complex a -= Complex c}.
     *
     * @param c Complex number to subtract.
     */
    public func subtractEquals(_ c: Complex) {
        var selfCopy = SPTK4S.Complex(c: self)
        Complex.subtractOp(&selfCopy, c)
        
        self.wrapped.realp[0] = selfCopy.realp()
        self.wrapped.imagp[0] = selfCopy.imagp()
    }

    /**
     * Subtraction in place. <br>
     * Performs the equivalent of {@code Complex a -= d}.
     *
     * @param d Real number to subtract.
     */
    public func subtractEquals(_ d: Double) {
        var selfCopy = SPTK4S.Complex(c: self)
        Complex.subtractOp(&selfCopy, d)
        
        self.wrapped.realp[0] = selfCopy.realp()
        self.wrapped.imagp[0] = selfCopy.imagp()
    }

    /**
     * Complex number multiplication.
     * @param c The Complex number to multiply.
     * @return The Complex number * {@code c}.
     */
    public func multiply(_ c: Complex) -> Complex {
        var result = SPTK4S.Complex(real: self.realp(), imag: self.imagp());
        Complex.multiplyOp(&result, c);
        return result
    }

    /**
     * Complex number multiplication.
     * @param real Real part of the number to multiply.
     * @param imag Imaginary part of the number to multiply.
     * @return Complex number * {@code Complex(real, imag}.
     */
    public func multiply(real: Double, imag: Double) -> Complex {
        var result = SPTK4S.Complex(real: self.realp(), imag: self.imagp());
        Complex.multiplyOp(&result, real, imag);
        return result
    }

    /**
     * Complex number multiplication.
     * @param d The real number to add.
     * @return The Complex number + {@code d}.
     */
    public func multiply(_ d: Double) -> Complex {
        var result = SPTK4S.Complex(real: self.realp(), imag: self.imagp());
        Complex.multiplyOp(&result, d);
        return result
    }

    /**
     * Multiplication in place. <br>
     * Performs the equivalent of {@code Complex a *= c}.
     *
     * @param c The Complex number to multiply.
     */
    public func multiplyEquals(_ c: Complex) {
        var selfCopy = Complex(c: self)

        Complex.multiplyOp(&selfCopy, c)
        
        self.wrapped.realp[0] = selfCopy.realp()
        self.wrapped.imagp[0] = selfCopy.imagp()
    }

    /**
     * Multiplication in place. <br>
     * Performs the equivalent of {@code Complex a *= Complex(real, imag)}.
     * @param real The real part of the Complex number.
     * @param imag the imag part of the Complex number.
     */
    public func multiplyEquals(real: Double, imag: Double) {
        var selfCopy = Complex(c: self)

        Complex.multiplyOp(&selfCopy, real, imag)
        
        self.wrapped.realp[0] = selfCopy.realp()
        self.wrapped.imagp[0] = selfCopy.imagp()
    }

    /**
     * Multiplication in place. <br>
     * Performs the equivalent of {@code Complex a *= d}.
     * @param d The real number to multiply
     */
    public func multiplyEquals(_ d: Double) {
        var selfCopy = Complex(c: self)

        Complex.multiplyOp(&selfCopy, d)
        
        self.wrapped.realp[0] = selfCopy.realp()
        self.wrapped.imagp[0] = selfCopy.imagp()
    }

    /**
     * Complex number division.
     * @param c The Complex number to divide.
     * @return The Complex number / {@code c}.
     */
    public func divide(_ c: Complex) -> Complex {
        var result = c.invert()
        Complex.multiplyOp(&result, self)
        return result
    }

    /**
     * Complex number division.
     * @param d The real number to divide.
     * @return The Complex number / {@code d}.
     */
    public func divide(_ d: Double) -> Complex {
        var result = SPTK4S.Complex(real: self.realp(), imag: self.imagp())
        Complex.multiplyOp(&result, 1.0 / d)
        return result;
    }

    /**
     * Division in place. <br>
     * Performs the equivalent of {@code Complex a /= c}.
     *
     * @param c The Complex number to divide.
     */
    public func divideEquals(_ c: Complex) {
        let result = c.invert()
        var selfCopy = Complex(c: self)
        Complex.multiplyOp(&selfCopy, result)
        
        self.wrapped.realp[0] = selfCopy.realp()
        self.wrapped.imagp[0] = selfCopy.imagp()
    }

    /**
     * Division in place. <br>
     * Performs the equivalent of {@code Complex a /= d}.
     *
     * @param d The real number to divide.
     */
    public func divideEquals(_ d: Double) {
        var selfCopy = Complex(c: self)
        Complex.multiplyOp(&selfCopy, 1.0 / d)
    }

    /**
     * Square root ot the complex number.
     * @return The square root of the complex number.
     */
    public func sqrt() -> Complex {
        if (self.realp() == 0 && self.imagp() == 0) {
            return SPTK4S.Complex()
        }

        let z = Darwin.sqrt(0.5 * (Swift.abs(self.realp()) + self.abs()))
        if (self.realp() >= 0) {
            return SPTK4S.Complex(real: z, imag: 0.5 * self.imagp() / z)
        } else {
            return SPTK4S.Complex(real: 0.5 * Swift.abs(self.imagp()) / z, imag: copysign(z, self.imagp()))
        }
    }

    /**
     * Complex power.
     * @param c The complex power.
     * @return {@code Complex a<sup>c</sup>}.
     */
    public func pow(_ c: Complex) -> Complex {
        return self.log().multiply(c).exp()
    }

    /**
     * Complex power.
     * @param d The real power.
     * @return {@code Complex a<sup>d</sup>}.
     */
    public func pow(_ d: Double) -> Complex {
        return self.log().multiply(d).exp()
    }

    /**
     * Complex number squared.
     * @return {@code a<sup>2</sup>}
     */
    public func pow2() -> Complex {
        let real = self.realp() * self.realp() - self.imagp() * self.imagp()
        let imag = 2 * self.realp() * self.imagp()
        return SPTK4S.Complex(real: real, imag: imag)
    }

    /**
     * Complex natural logarithm.
     * @return The natural logarithm of the complex number.
     */
    public func log() -> Complex {
        return SPTK4S.Complex(real: Darwin.log(self.abs()), imag: self.arg())
    }

    /**
     * Complex exponential.
     * @return {@code e<sup>c</sup>}.
     */
    public func exp() -> Complex {
        let exp = Darwin.exp(self.realp());
        return SPTK4S.Complex(real: exp * Darwin.cos(self.imagp()), imag: exp * Darwin.sin(self.imagp()))
    }

    /**
     * Square root of {@code 1 - Complex<sup>2</sup>}.
     * @return {@code 1 - Complex<sup>2</sup>}.
     */
    public func sqrt1z() -> Complex {
        let result = SPTK4S.Complex.fromReal(d: 1.0)
        result.subtractEquals(self.pow2())
        return result.sqrt()
    }

    /**
     * Sine of Complex number.
     * @return The Sine evaluated at the Complex number.
     */
    public func sin() -> Complex {
        return SPTK4S.Complex(
            real: Darwin.sin(self.realp()) * Darwin.cosh(self.imagp()),
            imag: Darwin.cos(self.realp()) * Darwin.sinh(self.imagp())
        )
    }

    /**
     * Arc-sine of Complex number.
     * @return The Arc-sine evaluated at the Complex number.
     */
    public func asin() -> Complex {
        return sqrt1z().add(self.multiply(real: 0.0, imag: 1.0)).log().multiply(real: 0.0, imag: -1.0);
    }

    /**
     * Cosine of Complex number.
     * @return The Cosine evaluated at the Complex number.
     */
    public func cos() -> Complex {
        return SPTK4S.Complex(
            real: Darwin.cos(self.realp()) * Darwin.cosh(self.imagp()),
            imag: -Darwin.sin(self.realp()) * Darwin.sinh(self.imagp())
        );
    }

    /**
     * Arc-cosine of the Complex number.
     * @return The Arc-cosine evaluated at the Complex number.
     */
    public func acos() -> Complex {
        return self.add(self.sqrt1z().multiply(real: 0.0, imag: 1.0)).log().multiply(real: 0.0, imag: -1.0);
    }

    /**
     * Tangent of the Complex number.
     * @return The Tangent evaluated at the Complex number.
     */
    public func tan() -> Complex {
        if (self.imagp() > 20.0) {
            return SPTK4S.Complex.fromImaginary(d: 1.0)
        }
        if (self.imagp() < -20) {
            return SPTK4S.Complex.fromImaginary(d: -1.0)
        }

        let dreal: Double = 2.0 * self.realp()
        let dimag: Double = 2.0 * self.imagp()

        let tmp = 1.0 / (Darwin.cos(dreal) + Darwin.cosh(dimag))
        return SPTK4S.Complex(real: Darwin.sin(dreal) * tmp, imag: Darwin.sinh(dimag) * tmp)
    }

    /**
     * Arc-tangent of the Complex number.
     * @return The Arc-tangent evaluated at the Complex number.
     */
    public func atan() -> Complex {
        let copy = SPTK4S.Complex(real: self.realp(), imag: self.imagp())
        let i: Complex = SPTK4S.Complex.fromImaginary(d: 1.0);
        
        return copy
            .add(i)
            .divide(i.subtract(self))
            .log()
            .multiply(i.multiply(SPTK4S.Complex(real: 0.5, imag: 0.0)))
    }

    /**
     * Urinary minus.
     * @return For a complex number {@code c} it return {@code -c}.
     */
    public func uminus() -> Complex {
        return SPTK4S.Complex(real: -self.realp(), imag: -self.imagp())
    }

    /**
     * Hyperbolic Sine of the Complex number.
     * @return The Hyperbolic Sine evaluated at the Complex number.
     */
    public func sinh() -> Complex {
        return SPTK4S.Complex(
            real: Darwin.sinh(self.realp()) * Darwin.cos(self.imagp()),
            imag: Darwin.cosh(self.realp()) * Darwin.sin(self.imagp())
        )
    }

    /**
     * Hyperbolic Cosine of the Complex number.
     * @return The Hyperbolic Cosine evaluated at the Complex number.
     */
    public func cosh() -> Complex {
        return SPTK4S.Complex(
            real: Darwin.cosh(self.realp()) * Darwin.cos(self.imagp()),
            imag: Darwin.sinh(self.realp()) * Darwin.sin(self.imagp())
        )
    }

    /**
     * Hyperbolic Tangent of the Complex number.
     * @return The Hyperbolic Tangent evaluated at the Complex number.
     */
    public func tanh() -> Complex {
        let num = SPTK4S.Complex(real: Darwin.tanh(self.realp()), imag: Darwin.tan(self.imagp()));
        let den = SPTK4S.Complex(real: 1.0, imag: Darwin.tanh(self.realp()) * Darwin.tan(self.imagp()));
        return num.divide(den);
    }

    public func isFinite() -> Bool {
        return self.realp().isFinite && self.imagp().isFinite;
    }

    private static func invertOp(_ c: Complex) -> Void {
        let mag = 1.0 / c.norm();
        c.wrapped.realp[0] *= mag;
        c.wrapped.imagp[0] *= -mag;
    }

    private static func addOp(_ c: inout Complex, _ d: Double) -> Void {
        c.wrapped.realp[0] += d;
    }

    private static func addOp(_ c: inout Complex, _ real: Double, _ imag: Double) -> Void {
        c.wrapped.realp[0] += real;
        c.wrapped.imagp[0] += imag;
    }

    /*
     C1 <- C1 + C2
     */
    private static func addOp(_ c1: inout Complex, _ c2: Complex) -> Void {
        c1.wrapped.realp[0] += c2.realp();
        c1.wrapped.imagp[0] += c2.imagp();
    }

    private static func subtractOp(_ c: inout Complex, _ d: Double) -> Void {
        c.wrapped.realp[0] -= d;
    }

    /*
     C1 <- C1 - C2
     */
    private static func subtractOp(_ c1: inout Complex, _ c2: Complex) -> Void {
        c1.wrapped.realp[0] -= c2.realp();
        c1.wrapped.imagp[0] -= c2.imagp();
    }

    /*
     C1 <- C1 * C2
     */
    private static func multiplyOp(_ c1: inout Complex, _ c2: Complex) -> Void {
        let re = c1.realp() * c2.realp() - c1.imagp() * c2.imagp();
        c1.wrapped.realp[0] = c1.realp() * c2.realp() + c1.imagp() * c2.imagp();
        c1.wrapped.imagp[0] = re;
    }

    private static func multiplyOp(_ c1: inout Complex, _ real: Double, _ imag: Double) -> Void {
        let re = c1.realp() * real - c1.imagp() * imag;
        c1.wrapped.imagp[0] = c1.realp() * imag + c1.imagp() * real;
        c1.wrapped.realp[0] = re;
    }

    private static func multiplyOp(_ c: inout Complex, _ d: Double) -> Void {
        c.wrapped.realp[0] *= d;
        c.wrapped.imagp[0] *= d;
    }
}
