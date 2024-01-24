import Foundation
import Accelerate

public final class ComplexArrays {
    
    private init() {  }
    
    public static func deepCopy(_ complexArray: [Complex]) -> [Complex] {
        var theCopy = [SPTK4S.Complex].init()
        
        for complex in complexArray {
            theCopy.append(SPTK4S.Complex(c: complex))
        }
        
        return theCopy
    }
    
    // TODO: Can replace with a more performant O(n*log n) version using FFT, see https://github.com/kunalkandekar/vDSPxcorr
    /// Convolve two arrays.
    ///
    /// - Parameter a: the left hand array.
    /// - Parameter b: the right hand array
    ///
    /// - Returns The convolution of `a` and `b`.
    public static func convolve(_ a: [Complex], b: [Complex]) -> [Complex] {
        var result = [SPTK4S.Complex].init()
                
        for i in 0..<a.count + b.count - 1 {
            result.append(SPTK4S.Complex())
            for j in Swift.max(0, i + 1 - b.count)..<Swift.min(a.count, i+1) {
                result[i] += a[j] * b[i-j]
            }
        }

        return result;
    }
    

    /// Convolve two arrays.
    ///
    /// - Parameter a: the left hand array.
    /// - Parameter b: the right hand array
    ///
    /// - Returns The convolution of `a` and `b`.
    public static func convolve(_ a: inout DSPCountedDoubleSplitComplex, b: inout DSPCountedDoubleSplitComplex) -> DSPCountedDoubleSplitComplex {
        var signal = a.splitComplexD()
        var filter = b.splitComplexD()
        
        let outputCount = a.count() - b.count() + 1
        let outputReal = UnsafeMutableBufferPointer<Double>.allocate(capacity: outputCount)
        let outputImag = UnsafeMutableBufferPointer<Double>.allocate(capacity: outputCount)
        
        var output = DSPDoubleSplitComplex(realp: outputReal.baseAddress!, imagp: outputImag.baseAddress!)
        
       vDSP_zconvD(
            /*a:*/ &signal,
            /*aStride:*/ 1,
            /*f:*/ &filter,
            /*fStride:*/ -1,
            /*c:*/ &output,
            /*cStride:*/ 1,
            /*outputCount:*/ vDSP_Length(outputCount),
            /*fCount:*/ vDSP_Length(a.count())
        )
        
        return DSPCountedDoubleSplitComplex(wrappedComplex: output, counts: outputCount)
    }
    
    
    
    static let MOD: Int = 998244353;
    
    /// Real part of a Complex array element wise.
    ///
    /// - Parameter complexArray: The input array.
    /// - Returns: An array of doubles containing the real part of each Complex value of the input array.
    public static func real(_ complexArray: [Complex]) -> [Double] {
        var result = [Double].init()
        
        for complex in complexArray {
            result.append(complex.realp())
        }
        
        return result;
    }
    
    
    /// Create a new Complex array from an array of real values.
    ///
    /// - Parameter realArray: The input array.
    /// - Returns: An array of Complex values with real part equal to the values of the input array and imaginary part equal to zero.
    public static func fromReal(_ realArray: [Double]) -> [Complex] {
        var result = [SPTK4S.Complex].init()
        
        for real in realArray {
            result.append(SPTK4S.Complex.fromReal(d: real))
        }

        return result;
    }
    
    /// Imaginary part of a Complex array element wise.
    ///
    /// - Parameter complexArray: The input array.
    /// - Returns: An array of doubles containing the imaginary part of each Complex value of the input array.
    public static func imag(_ complexArray: [Complex]) -> [Double] {
        var result = [Double].init()
        
        for complex in complexArray {
            result.append(complex.imagp())
        }

        return result;
    }
    
    /// Create a new Complex array from an array of real values.
    ///
    /// - Parameter realArray: The input array constituting the imaginary parts of the output array.
    /// - Returns: An array of Complex values with imaginary part equal to the values of the input array and real part equal to zero.
    public static func fromImaginary(_ realArray: [Double]) -> [Complex] {
        var result = [SPTK4S.Complex].init()
        
        for real in realArray {
            result.append(SPTK4S.Complex.fromImaginary(d: real))
        }

        return result;
    }
    
    /// Convert and array representing the real part of an array of Complex number and another array representing the imaginary part of an array of Complex into an array of Complex numbers.
    ///
    /// - Parameter realsArray: The real parts of the array of Complex to be created.
    /// - Parameter imagsArray: The imaginary parts of the array of Complex to be created.
    ///
    /// - Returns: `[Complex(real: realsArray[0], imag: imagsArray[0]), ... [Complex(real: realsArray[n], imag: imagsArray[n])]`
    /// - Throws: `DimensionError.illegalArgumentException(_: String)` if `realsArray` and `imagsArray` sizes don't match.
    public static func zip(_ realsArray: [Double], _ imagsArray: [Double]) throws -> [Complex] {
        try DimensionCheckers.checkXYDimensions(realsArray, imagsArray)
        
        var zipped = [SPTK4S.Complex].init()
        
        for i in 0..<realsArray.count {
            zipped.append(
                SPTK4S.Complex(
                    real: realsArray[i],
                    imag: imagsArray[i]
                )
            )
        }

        return zipped;
    }
    
    /// Convert and array representing the real part of an array of Complex number and another array representing the imaginary part of an array of Complex into an array of Complex numbers.
    ///
    /// - Parameter realsArray: The real parts of the array of Complex to be created.
    /// - Parameter imagsArray: The imaginary parts of the array of Complex to be created.
    ///
    /// - Returns: `[Complex(real: realsArray[0], imag: imagsArray[0]), ... [Complex(real: realsArray[n], imag: imagsArray[n])]`
    /// - Throws: `DimensionError.illegalArgumentException(_: String)` if `realsArray` and `imagsArray` sizes don't match.
    ///
    /// - Note: The memory returned along with the output is unmanaged and must be handled by the client, including deallocation.
    public static func zip(_ realsArray: [Double], _ imagsArray: [Double]) throws -> DSPCountedDoubleSplitComplex {
        try DimensionCheckers.checkXYDimensions(realsArray, imagsArray)
        
        let realPtr = UnsafeMutablePointer<Double>.allocate(capacity: realsArray.count)
        let imagPtr = UnsafeMutablePointer<Double>.allocate(capacity: imagsArray.count)
        
        realPtr.initialize(from: realsArray, count: realsArray.count)
        imagPtr.initialize(from: imagsArray, count: imagsArray.count)
        
        return DSPCountedDoubleSplitComplex(
            wrappedComplex: DSPDoubleSplitComplex(realp: realPtr, imagp: imagPtr),
            counts: realsArray.count
        )
    }
    

    /// Mean of the array
    ///
    /// - Parameter complexArray: The input array.
    /// - Returns: The mean of the input array.
    public static func mean(_ complexArray: [Complex]) -> Complex {
        var realMean: Double = 0.0
        var imagMean: Double = 0.0
        
        for complex in complexArray {
            realMean += complex.realp()
            imagMean += complex.imagp()
        }
        
        return SPTK4S.Complex(
            real: realMean / Double(complexArray.count),
            imag: imagMean / Double(complexArray.count)
        )
    }

    
    /// Creates and array of 0 + j0
    ///
    /// - Parameter length: The length of the array of zeros.
    /// - Returns: An array containing `length` Complex(real: 0, imag: 0)
    public static func zeros(_ length: Int) -> [Complex] {
        assert(length >= 0)
        
        return [SPTK4S.Complex].init(repeating: SPTK4S.Complex(), count: length)
    }

    
    
    /// Flattens a 2D array into a 1D array by copying every row of the second array into the first array
    ///
    ///     let a = {{1, 2, 3}, {4, 5, 6}};
    ///     thus flatten(a) returns:
    ///     {1, 2, 3, 4, 5, 6}
    ///
    /// - Parameter complex2DArray: An array to flatten.
    /// - Returns: A new row-packed 1D array.
    /// - Throws: `ComplexArrayError.illegalArgumentException(_:String)` if the rows of `complex2DArray` do not have all the same length
    public static func flatten(_ complex2DArray: [[Complex]]) throws -> [Complex] {
        let columns = complex2DArray.first?.count ?? 0

        var result = [SPTK4S.Complex].init()
        
        for row in complex2DArray {
            if row.count != columns {
                throw ComplexArraysError.illegalArgumentException(reason: "All rows must have the same length.")
            }
            
            result.append(contentsOf: row)
        }
        
        return result
    }

    
    /// Add a Complex value to an array of Complex values, element wise
    ///
    /// - Parameter complexArray: The input array.
    /// - Parameter scalar: The Complex value to be added.
    ///
    /// - Returns: `complexArray + scalar`
    public static func addElementWise(_ complexArray: [Complex], _ scalar: Complex) -> [Complex] {
        var result = [SPTK4S.Complex].init()
        
        for complex in complexArray {
            result.append(complex + scalar)
        }

        return result;
    }

    /// Add a Complex value to an array of Complex values, element wise.
    /// - Parameter complexArray1: The input array.
    /// - Parameter complexArray2: The Complex value to be added.
    ///
    /// - Returns: `complexArray1 + complexArray1`
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if the dimensions of `complexArray1` and `complexArray2` mismatch.
    public static func addElementWise(_ complexArray1: [Complex], _ complexArray2: [Complex]) throws -> [Complex] {
        try DimensionCheckers.checkXYDimensions(complexArray1, complexArray2)
        
        var result: [SPTK4S.Complex] = .init()
        
        for i in 0..<complexArray1.count {
            result.append(complexArray1[i] + complexArray2[i])
        }
        
        return result;
    }
    
    /// Add a Complex value to an array of Complex values, element wise.
    /// - Parameter complexArray1: The input array.
    /// - Parameter complexArray2: The Complex value to be added.
    ///
    /// - Returns: `complexArray1 + complexArray1`
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if the dimensions of `complexArray1` and `complexArray2` mismatch.
    ///
    /// - Note: The memory returned along with the output is unmanaged and must be handled by the client, including deallocation.
    public static func addElementWise(_ complexArray1: DSPCountedDoubleSplitComplex, _ complexArray2: DSPCountedDoubleSplitComplex) throws -> DSPCountedDoubleSplitComplex {
        try DimensionCheckers.checkXYDimensions(complexArray1, complexArray2)
        
        let outputCapacity = complexArray1.count()
        
        let resultReal = UnsafeMutableBufferPointer<Double>.allocate(capacity: complexArray1.count())
        let resultImag = UnsafeMutableBufferPointer<Double>.allocate(capacity: complexArray1.count())

        var output = DSPDoubleSplitComplex(realp: resultReal.baseAddress!, imagp: resultImag.baseAddress!)
        
        var complexArray1 = complexArray1.splitComplexD()
        var complexArray2 = complexArray2.splitComplexD()
                
        vDSP_zvaddD(
            /*firstInput: */ &complexArray1,
            /*input1Stride: */1,
            /*secondInput: */&complexArray2,
            /*input2Stride: */1,
            /*output: */&output,
            /*outputStride: */1,
            /*itemsToProcess: */ vDSP_Length(outputCapacity)
        )
        
        return DSPCountedDoubleSplitComplex(wrappedComplex: output, counts: outputCapacity)
    }
    
    /// Sum all the elements of the array element wise.
    ///
    /// - Parameter complexArray: The input array.
    /// - Returns `Σ a_i`
    public static func sum(_ complexArray: [Complex]) -> Complex {
        
        var sum = SPTK4S.Complex()
        
        for complex in complexArray {
            sum += complex
        }

        return sum;
    }
    
    
    /// Multiply and array of Complex values times a Complex value.
    ///
    /// - Parameter complexArray: The input array.
    /// - Parameter scalar: The Complex value to multiply.
    ///
    /// - Returns: complexArray * scalar
    public static func multiplyElementWise(_ complexArray: [Complex], scalar: Complex) -> [Complex] {
        var result = [SPTK4S.Complex].init()
        
        for complex in complexArray {
            result.append(complex * scalar)
        }
        
        return result
    }
    
    
    /// Multiply and array of Complex values times a Complex value.
    ///
    /// - Parameter complexArray: The input array.
    /// - Parameter scalar: The Double value to multiply.
    ///
    /// - Returns: complexArray * scalar
    public static func multiplyElementWise(_ complexArray: [Complex], scalar: Double) -> [Complex] {
        var result = [SPTK4S.Complex].init()
        
        for complex in complexArray {
            result.append(complex * scalar)
        }
        
        return result
    }
    
    /// Multiply and array of Complex values times a Complex value.
    ///
    /// - Parameter complexArray: The input array.
    /// - Parameter scalar: The Complex value to multiply.
    ///
    /// - Returns: complexArray * scalar
    public static func multiplyElementWiseInPlace(_ complexArray: inout [Complex], scalar: Double) {
        var result = [SPTK4S.Complex].init()
        
        for i in 0..<complexArray.count {
            result[i] *= scalar
        }
    }
    
    
    /// Divides a real number by an array of Complex number element wise.
    ///
    /// - Parameter scalar: The left-hand double value.
    /// - Parameter complexArray: The right-hand array of Complex values.
    ///
    /// - Returns: scalar / complexArray
    public static func divideElementWise(_ scalar: Double, _ complexArray: [Complex]) -> [Complex] {
        
        var result = [SPTK4S.Complex].init()
        
        for complex in complexArray {
            result.append(complex.invert() * scalar)
        }
        
        return result;
    }
    
    /// Array concatenation (shallow)
    ///
    /// - Parameter complexArray1: The left-hand array.
    /// - Parameter complexArray2: The right-hand array.
    ///
    /// - Returns {a, b}
    public static func concatenate(_ complexArray1: [Complex], _ complexArray2: [Complex]) -> [Complex] {
        var result = [SPTK4S.Complex].init()

        result.append(contentsOf: complexArray1)
        result.append(contentsOf: complexArray2)

        return result;
    }
    
    /// Array product
    ///
    /// - Parameter complexArray: The input array.
    /// - Returns: The product of multiplying all the elements in the array.
    public static func product(_ complexArray: [Complex]) -> Complex {
        var product = SPTK4S.Complex.fromReal(d: 1.0)
        
        for complex in complexArray {
            product *= complex
        }
        
        return product
    }
    
    /// Subtract a Complex value from an array of Complex values element wise.
    ///
    /// - Parameter complexArray: The left-hand array.
    /// - Parameter scalar: The right-hand Complex value to be subtracted.
    ///
    /// - Returns: `complexArray - scalar`.
    public static func subtractElementWise(_ complexArray: [Complex], _ scalar: Complex) -> [Complex] {
        var result = [SPTK4S.Complex].init()

        for complex in complexArray {
            result.append(complex - scalar)
        }
        
        return result
    }
    
    /// Subtract a Complex value from an array of Complex values element wise.
    ///
    /// - Parameter complexArray: The left-hand array.
    /// - Parameter scalar: The right-hand Double value to be subtracted.
    ///
    /// - Returns: `complexArray - scalar`.
    public static func subtractElementWise(_ complexArray: [Complex], _ scalar: Double) -> [Complex] {
        var result = [SPTK4S.Complex].init()

        for complex in complexArray {
            result.append(complex - scalar)
        }
        
        return result
    }
    
    /// Subtract a Complex value from an array of Complex values element wise.
    ///
    /// - Parameter complexArray1: The left-hand array.
    /// - Parameter complesArray2: The right-hand array.
    ///
    /// - Returns: `complexArray1 - complexArray2`.
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `complexArray1` and `complexArray2` sizes mismatch.
    public static func subtractElementWise(_ complexArray1: [Complex], _ complexArray2: [Complex]) throws -> [Complex] {
        try DimensionCheckers.checkXYDimensions(complexArray1, complexArray2)
        var result = [SPTK4S.Complex].init()

        for i in 0..<complexArray1.count {
            result.append(complexArray1[i] - complexArray2[i])
        }
        
        return result
    }

    
    /// Subtract a Complex value from an array of Complex values element wise.
    ///
    /// - Parameter complexArray1: The left-hand array.
    /// - Parameter complesArray2: The right-hand array.
    ///
    /// - Returns: `complexArray1 - complexArray2`.
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `complexArray1` and `complexArray2` sizes mismatch.
    public static func subtractElementWise(
        _ complexArray1: DSPCountedDoubleSplitComplex,
        _ complexArray2: DSPCountedDoubleSplitComplex
    ) throws -> DSPCountedDoubleSplitComplex {
        try DimensionCheckers.checkXYDimensions(complexArray1, complexArray2)

        let outputCapacity = complexArray1.count()
        
        let resultReal = UnsafeMutableBufferPointer<Double>.allocate(capacity: complexArray1.count())
        let resultImag = UnsafeMutableBufferPointer<Double>.allocate(capacity: complexArray1.count())

        var output = DSPDoubleSplitComplex(realp: resultReal.baseAddress!, imagp: resultImag.baseAddress!)
        
        var complexArray1 = complexArray1.splitComplexD()
        var complexArray2 = complexArray2.splitComplexD()
                
        vDSP_zvsubD(
            /*firstInput: */ &complexArray1,
            /*input1Stride: */1,
            /*secondInput: */&complexArray2,
            /*input2Stride: */1,
            /*output: */&output,
            /*outputStride: */1,
            /*itemsToProcess: */ vDSP_Length(outputCapacity)
        )
        
        return DSPCountedDoubleSplitComplex(wrappedComplex: output, counts: outputCapacity)
    }
    
    /// Splits an array of Complex into two arrays of the same sizes containing the real and imaginary parts.
    ///
    /// - Parameter complexArray: The input array.
    /// - Returns: A SplitComplex instance containing the real and imaginary arrays extracted from `complexArray`
    public static func split(_ complexArray: [Complex]) -> DSPCountedDoubleSplitComplex {
        let reals = ComplexArrays.real(complexArray)
        let imags = ComplexArrays.imag(complexArray)
        
        assert(reals.count == imags.count)
        
        let realPtr = UnsafeMutablePointer<Double>.allocate(capacity: reals.count)
        let imgPtr = UnsafeMutablePointer<Double>.allocate(capacity: imags.count)
        
        realPtr.initialize(from: reals, count: reals.count)
        imgPtr.initialize(from: imgPtr, count: imags.count)
        
        return DSPCountedDoubleSplitComplex(
            wrappedComplex: DSPDoubleSplitComplex(realp: realPtr, imagp: imgPtr),
            counts: reals.count
        )
    }

}
 
enum ComplexArraysError: Error {
    case illegalArgumentException(reason: String)
}


