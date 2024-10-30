import Foundation
import Accelerate

public class Polynomial: UnivariateFunction, ComplexUnivariateFunction /*, DifferentiableFunction,*/
                        /* IntegrableFunction*/ {
    
    private var coefficients: [Double] = []
    private var roots: [Complex]?
    
    /***
     * Copy constructor
     */
    public init(polynomial: Polynomial) {
        self.coefficients = [Double].init(polynomial.coefficients)
        
        if let roots = polynomial.roots {
            self.roots = ComplexArrays.deepCopy(roots);
        }
    }
    
    /***
     * Constructs a polynomial P(x) and initializes its coefficients to the
     * coefficients passed as parameters. The coefficients are assumed to be in
     * descending order i.e. [1, 3, 2] will generate P(x) = x^2 + 3x + 2
     *
     * @param coefficients
     *            Array of coefficients in descending order
     */
    public init(coefficients: [Double]) {
        
        let numberOfCoeff = coefficients.count
        
        var i = 0
        while (coefficients[i] == 0.0) {
            i = i+1
            if (i == numberOfCoeff) {
                break;
            }
        }
        
        if i == numberOfCoeff {
            self.coefficients = [0.0]
        } else {
            for j in i..<numberOfCoeff {
                self.coefficients.append(coefficients[j])
            }
        }
    }
    
    /***
     * Creates a polynomial P(x) from an array of its roots. Say we have the
     * following set of roots r = [ -1, -2 ] then: P(x) = (x + 1)*(x + 2) which
     * is the solution to the polynomial: P(x) = x^2 + 3x + 2.
     *
     * @param roots Array of roots.
     */
    public init(roots: Complex...) {
        var finiteRoots: [Complex] = .init()
        
        for root in roots {
            if abs(root.realp()) != Double.infinity && abs(root.imagp()) != Double.infinity {
                finiteRoots.append(root)
            }
        }
        
        var tmp: [Complex] = .init()
        var result: [Complex] = .init()
        
        
        for i in 0...finiteRoots.count {
            result.append(SPTK4S.Complex.init())
        }
        
        result[0] = SPTK4S.Complex.fromReal(d: 1.0)
        
        for i in 0..<finiteRoots.count {
            for j in 0...i {
                tmp[j] = finiteRoots[i].multiply(result[j]);
            }
            
            for j in 0...i {
                result[j + 1].subtractEquals(tmp[j]);
            }
        }
        
        coefficients = ComplexArrays.real(result);
        self.roots = ComplexArrays.deepCopy(roots);
    }
    
    /***
     *
     * @return Returns the order of the polynomial
     */
    public func degree() -> Int {
        return coefficients.count - 1
    }
    
    
    /***
     * Forces the lowest order coefficient of
     * the polynomial to be unity by dividing all the other coefficients by
     * the lowest order coefficient.
     */
    public func denormalize() {
        var i = self.coefficients.count - 1
        
        while (self.coefficients[i] == 0.0) {
            i -= 1
            if (i == 0) {
                break
            }
        }
        
        for j in 0..<self.coefficients.count {
            self.coefficients[j] /= self.coefficients[i]
        }
    }
    
    /***
     * Convert to monic Polynomial. Forces the highest order coefficient of
     * the polynomial to be unity by dividing all the other coefficients by
     * the highest order coefficient.
     *
     * @return normalizing factor
     */
    @discardableResult public func normalize() -> Double {
        let cn = 1.0 / self.coefficients[0]
        
        for j in 0..<self.coefficients.count {
            self.coefficients[j] *= cn
        }
        
        return cn;
    }
    
    /***
     * Multiply two polynomials
     *
     * @param p
     *            Another polynomial
     * @return Pnew(x) = P(x) * poly
     */
    public func multiply(by other: Polynomial) -> Polynomial {
        return .init(coefficients: DoubleArrays.convolve(self.coefficients, other.coefficients))
    }
    
    
    public func multiply(coefficients: [Double]) -> Polynomial {
        return .init(coefficients: DoubleArrays.convolve(self.coefficients, coefficients))
    }
    
    /***
     * Multiply two polynomials and stores the result
     *
     * @param p
     *            Another polynomial
     */
    public func multiplyEquals(by polynomial: Polynomial) {
        self.coefficients = DoubleArrays.convolve(coefficients, polynomial.coefficients);
        self.roots = nil
    }
    
    /***
     * Multiply two polynomials and stores the result
     *
     * @param coefs
     *            Another polynomial
     */
    public func multiplyEquals(coefficients: [Double]) {
        self.coefficients = DoubleArrays.convolve(self.coefficients, coefficients);
        self.roots = nil
    }
    
    
    public func multiply(by d: Double) -> Polynomial {
        return .init(coefficients: DoubleArrays.multiplyElementWise(doubleArray: self.coefficients, scalar: d))
    }
    
    
    public func multiplyEquals(by d: Double) {
        var coefficient: Double = d
        
        self.coefficients.withUnsafeMutableBufferPointer { resultPtr in
            vDSP_vsmulD(
                /*array:*/ self.coefficients,
                           /*array1tride:*/ 1,
                           /*scalarPtr:*/ &coefficient,
                           /*outputPtr:*/ resultPtr.baseAddress!,
                           /*outputStride:*/ 1,
                           /*itemsToProcess:*/ vDSP_Length(self.coefficients.count)
            )
        }
    }
    
    
    public func add(to p: Polynomial) -> Polynomial {
        return .init(coefficients: Self.addOp(self, p))
    }
    
    
    public func addEquals(to p: Polynomial) {
        self.coefficients = Self.addOp(self, p)
        self.roots = nil
    }
    
    private static func addOp(_ lhs: Polynomial, _ rhs: Polynomial) -> [Double] {
        
        var result: [Double] = lhs.coefficients.count >= rhs.coefficients.count ?
        Array(lhs.coefficients)
        :
        Array(rhs.coefficients)
        
        
        var i = lhs.coefficients.count - 1
        var j = rhs.coefficients.count - 1
        var k = result.count - 1
        
        while i >= 0 && j >= 0 {
            
            result[k] = lhs.coefficients[i] + rhs.coefficients[j];
            
            i -= 1
            j -= 1
            k -= 1
        }
        
        return result;
    }
    
    public func subtract(by p: Polynomial) -> Polynomial {
        return .init(coefficients: Self.subtractOp(self, p))
    }
    
    public func subtractEquals(by p: Polynomial) {
        self.coefficients = Self.subtractOp(self, p);
        self.roots = nil
    }
    
    private static func subtractOp(_ lhs: Polynomial, _ rhs: Polynomial) -> [Double] {
        var result: [Double] = .init()
        
        if (lhs.coefficients.count > rhs.coefficients.count) {
            let diff = lhs.coefficients.count - rhs.coefficients.count
            
            result.append(contentsOf: [Double].init(repeating: 0, count: lhs.coefficients.count))
            
            for i in diff..<rhs.coefficients.count {
                result[i] = rhs.coefficients[i - diff]
            }
            
            for i in 0..<lhs.coefficients.count {
                result[i] = lhs.coefficients[i] - result[i]
            }
        } else {
            let diff = rhs.coefficients.count - lhs.coefficients.count
            
            result.append(contentsOf: [Double].init(repeating: 0, count: rhs.coefficients.count))
            
            for i in diff..<lhs.coefficients.count {
                result[i] = lhs.coefficients[i - diff]
            }
            
            for i in 0..<rhs.coefficients.count {
                result[i] = rhs.coefficients[i] - result[i]
            }
        }
        
        return result;
    }
    
    
    public func derivative() -> Polynomial {
        let derivativeLen = self.coefficients.count - 1
        
        var coefficients: [Double] = .init(repeating: 0, count: derivativeLen)
        
        for i in 0..<derivativeLen {
            coefficients[i] = self.coefficients[i] * Double(derivativeLen - i)
        }
        
        return .init(coefficients: coefficients)
    }
    
    /***
     * Get polynomial coefficients
     *
     * @return Array containing the coefficients in descending order
     */
    public func getCoefficients() -> [Double]{
        return DoubleArrays.deepCopy(self.coefficients)
    }
    
    /***
     * Evaluates the polynomial at x using Horner's method
     *
     * @param x
     * @return The value of the polynomial at x
     */
    public func evaluate(at: Double) -> Double {
        // Horner's method
        var result: Double = 0.0
        
        for coefficient in self.coefficients {
            result = result * at + coefficient
        }
        
        return result;
    }
    
    public func reverseInPlace() {
        coefficients = DoubleArrays.reverse(coefficients)
        roots = nil
    }
    
    /***
     * Evaluates the polynomial at real + j * imag using Horner's method
     *
     * @param real
     *            part of the complex number
     * @param imag
     *            part of the complex number
     * @return The value of the polynomial at real + j * imag
     */
    public func evaluateAt(realp: Double, imagp: Double) -> Complex {
        // Horner's method
        var result: Complex = .init()
        
        for coefficient in coefficients {
            result.multiplyEquals(real: realp, imag: imagp)
            result.addEquals(coefficient)
        }
        
        return result;
    }
    
    
    public func evaluate(at: SPTK4S.Complex) -> SPTK4S.Complex {
        // Horner's method
        var result = SPTK4S.Complex()
        
        for coefficient in coefficients {
            result.multiplyEquals(coefficient)
            result.addEquals(coefficient)
        }
        
        return result;
    }
    
    /*
     public Complex[] calculateRoots() {
     // lazy creation of roots
     if (roots == null) {
     int N = this.degree();
     switch (N) {
     case 0:
     roots = new Complex[0];
     break;
     case 1:
     roots = new Complex[]{new Complex(-coefficients[1] / coefficients[0], 0)};
     break;
     case 2:
     roots = Formulas.quadraticFormula(coefficients[0], coefficients[1], coefficients[2]);
     break;
     default:
     // Use generalized eigenvalue decomposition to find the roots
     roots = new Complex[N];
     Matrix c = Matrix.companion(coefficients, N);
     EigenvalueDecomposition evd = c.eig();
     double[] realEig = evd.getRealEigenvalues();
     double[] imagEig = evd.getImagEigenvalues();
     roots = ComplexArrays.zip(realEig, imagEig);
     }
     }
     // Defensive copy
     return ComplexArrays.deepCopy(roots);
     }
     
     /***
      * Substitutes polynomial coefficients
      * For a polynomial P(x) = x^2 + x + 1, it substitutes the x by x * d
      * thus P(x * d) = x^2 * d^2 + x * d + 1
      *
      * @param d
      */
     public void substituteInPlace(double d) {
     roots = null;
     if (d == 0) {
     coefficients = new double[]{coefficients[this.degree()]};
     return;
     }
     
     final int deg = this.degree();
     for (int i = 0; i < deg; ++i) {
     for (int j = i; j < deg; ++j) {
     coefficients[i] *= d;
     }
     }
     }
     
     /***
      * Substitutes polynomial coefficients
      * For a polynomial P(x) = x^2 + x + 1, it substitutes the x by x * d
      * thus P(x * d) = x^2 * d^2 + x * d + 1
      * @param d
      * @return P(x * d)
      */
     public Polynomial substitute(double d) {
     final int deg = this.degree();
     double[] result = Arrays.copyOf(coefficients, coefficients.length);
     for (int i = 0; i < deg; ++i) {
     result[i] *= Math.pow(d, deg - i);
     }
     return new Polynomial(result);
     }
     
     /***
      * Substitutes polynomial coefficients with another polynomial
      * For a polynomial P(x) = 2 * x + 1, it substitutes the x by p(x).
      * Say p(x) = 3 * x + 2
      * then P(p(x)) = (3 * x + 2) * 2 + 1 = 6 * x + 5
      * @param p polynomial to be inserted into P(x)
      */
     public void substituteInPlace(Polynomial p) {
     Polynomial result = substituteOp(this, p);
     coefficients = result.coefficients;
     roots = null;
     }
     
     /***
      * Substitutes polynomial coefficients with another polynomial
      * For a polynomial P(x) = 2 * x + 1, it substitutes the x by p(x).
      * Say p(x) = 3 * x + 2
      * then P(p(x)) = (3 * x + 2) * 2 + 1 = 6 * x + 5
      * @param p polynomial to be inserted into P(x)
      * @return P(p ( x))
      */
     public Polynomial substitute(Polynomial p) {
     return substituteOp(this, p);
     }
     
     public RationalFunction substitute(final Polynomial num, final Polynomial den) {
     final int deg = this.degree();
     Polynomial nump = num.pow(deg);
     nump.multiplyEquals(coefficients[0]);
     
     // Pre-calculate powers
     List<Polynomial> pows = new ArrayList<>(deg);
     pows.add(new Polynomial(1.0));
     pows.add(new Polynomial(num));
     for (int i = 2; i < deg; ++i) {
     pows.add(pows.get(i - 1).multiply(num));
     }
     
     Polynomial tmp = null;
     Polynomial denp = new Polynomial(1.0);
     for (int i = deg - 1, j = 1; i >= 0; --i, ++j) {
     tmp = pows.get(i);
     denp.multiplyEquals(den);
     tmp.multiplyEquals(denp);
     tmp.multiplyEquals(coefficients[j]);
     nump.addEquals(tmp);
     }
     return new RationalFunction(nump, denp);
     }
     
     private static Polynomial substituteOp(Polynomial src, Polynomial sub) {
     final int deg = src.degree();
     Polynomial result = sub.pow(deg);
     result.multiplyEquals(src.coefficients[0]);
     Polynomial tmp = null;
     for (int i = deg - 1, j = 1; i >= 0; --i, ++j) {
     tmp = sub.pow(i);
     tmp.multiplyEquals(src.coefficients[j]);
     result.addEquals(tmp);
     }
     return result;
     }
     
     public Polynomial pow(int n) {
     if (n < 0) {
     throw new IllegalArgumentException("Power must be >= 0");
     }
     if (n == 0) {
     return new Polynomial(new double[]{1.0});
     }
     double[] tmp = Arrays.copyOf(coefficients, coefficients.length);
     while (--n > 0) {
     tmp = DoubleArrays.convolve(tmp, coefficients);
     }
     return new Polynomial(tmp);
     }
     
     public double getCoefficientAt(int index) {
     return coefficients[index];
     }
     
     /***
      * Polynomial fit
      * <pre>
      * Finds a polynomial P(x) = c0 + c1*x + * c2*x^2 + ... + cn*x^n
      * of degree n that fits the data in y best in a least-square sense.
      * </pre>
      * @param x
      *            Array of points for the independent variable x
      * @param y
      *            Array of solutions to y(x)
      * @param n
      *            Order of the polynomial
      * @return Returns a polynomial of degree n fits the data y best in a
      *         least-square sense
      */
     public static Polynomial polyFit(double[] x, double[] y, int n) {
     checkXYDimensions(x, y);
     int dim = x.length;
     // Building the coefficient matrix
     Matrix A = Matrix.vandermonde(x, dim, n + 1);
     // Building the solution vector
     Matrix b = new Matrix(y, dim);
     Matrix c = A.solve(b);
     
     double[] coeffs = new double[n + 1];
     for (int i = 0; i <= n; i++) {
     coeffs[i] = c.get(n - i, 0);
     }
     return new Polynomial(coeffs);
     }
     
     /**
      * Indefinite integral of the {@code Polynomial}.
      * This method is equivalent to calling {@link #integral()} with integration constant equal to 0.
      *
      * @return The indefinite integral of the polynomial.
      */
     public Polynomial integral() {
     return this.integral(0.0);
     }
     
     /**
      * Indefinite integral of the {@Polynomial}.
      *
      * @param constant The integration constant.
      * @return The indefinite integral of the polynomial.
      */
     public Polynomial integral(double constant) {
     final int length = coefficients.length;
     double[] integral = new double[length + 1];
     for (int i = 0, j = length; i < length; ++i, --j) {
     integral[i] = (coefficients[i] / j);
     }
     integral[length] = constant;
     return new Polynomial(integral);
     }
     
     /**
      * Definite integral of the {@code Polynomial}.
      *
      * @param a The lower bound of the integration.
      * @param b The upper bound of the integration.
      * @return The definite integral of the polynomial from a to b.
      */
     @Override
     public double integrate(double a, double b) {
     Polynomial integral = this.integral();
     return integral.evaluateAt(b) - integral.evaluateAt(a);
     }
     
     /**
      * Differentiate {@code Polynomial}.
      *
      * @param x The argument at which to evaluate the derivative of the polynomial.
      * @return The derivative of the polynomial evaluate at {@code x}.
      */
     @Override
     public double differentiate(double x) {
     final int length = coefficients.length - 1;
     double result = 0.0;
     for (int i = 0, j = 0; j < length; ++i, ++j) {
     result *= x;
     result += coefficients[i] * (length - j);
     }
     return result;
     }
     
     /**
      * Evaluate a {@Polynomial} from its coefficients.
      *
      * @param coefficients The coefficients of the polynomial to evaluate.
      * @param x            The argument at which to evaluate the polynomial.
      * @returnThe The value of the polynomial at {@code x}.
      */
     public static double polyval(double[] coefficients, double x) {
     return DoubleArrays.horner(coefficients, x);
     }
     
     /**
      * Evaluate a {@Polynomial} from its coefficients.
      *
      * @param coefficients The coefficients of the polynomial to evaluate.
      * @param x            The array of argument at which to evaluate the polynomial.
      * @returnThe The values of the polynomial at {@code x}.
      */
     public static double[] polyval(double[] coefficients, double[] x) {
     final int length = x.length;
     double[] result = new double[length];
     for (int i = 0; i < length; ++i) {
     result[i] = polyval(coefficients, x[i]);
     
     }
     return result;
     }
     
     /**
      * Evaluate a {@code Polynomial}.
      *
      * @param roots The roots of teh polynomial.
      * @param x     Argument at which to evaluate the polynomial.
      * @return The value of the polynomial at {@code x}.
      * @see <a href="https://numpy.org/doc/stable/reference/generated/numpy.polynomial.polynomial.polyfromroots.html">
      * polyfromroots</a>
      */
     public static Complex polyvalFromRoots(Complex[] roots, Complex x) {
     return ComplexArrays.product(ComplexArrays.subtractElementWise(x, roots));
     }
     */
    
}

