import Foundation
import Accelerate

public final class DSPComplexArrays {
    private init() {  }
    
    
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
    
    
    /// Create a new Complex array from an array of real values.
    ///
    /// - Parameter realArray: The input array.
    /// - Returns: An array of Complex values with real part equal to the values of the input array and imaginary part equal to zero.
    public static func fromReal(_ realArray: [Double]) -> DSPCountedDoubleSplitComplex {
        let reals = UnsafeMutablePointer<Double>.allocate(capacity: realArray.count)
        let imags = UnsafeMutablePointer<Double>.allocate(capacity: realArray.count)
        
        reals.initialize(from: realArray, count: realArray.count)
        imags.initialize(from: DoubleArrays.zeros(count: realArray.count), count: realArray.count)
        
        
        return DSPCountedDoubleSplitComplex(
            wrappedComplex: DSPDoubleSplitComplex(realp: reals, imagp: imags),
            counts: realArray.count
        )   
    }
    
    
    /// Create a new complex array from an array of real values.
    ///
    /// - Parameter realArray: The input array constituting the imaginary parts of the output array.
    /// - Returns: An array of Complex values with imaginary part equal to the values of the input array and real part equal to zero.
    public static func fromImaginary(_ realArray: [Double]) -> DSPCountedDoubleSplitComplex {
        let reals = UnsafeMutablePointer<Double>.allocate(capacity: realArray.count)
        let imags = UnsafeMutablePointer<Double>.allocate(capacity: realArray.count)
        
        reals.initialize(from: DoubleArrays.zeros(count: realArray.count), count: realArray.count)
        imags.initialize(from: realArray, count: realArray.count)
        
        
        return DSPCountedDoubleSplitComplex(
            wrappedComplex: DSPDoubleSplitComplex(realp: reals, imagp: imags),
            counts: realArray.count
        )
    }
    
    
    /// Convert and array representing the real part of an array of Complex number and another array representing the imaginary part of an array of Complex into an array of Complex numbers.
    ///
    /// - Parameter realsArray: The real parts of the array of Complex to be created.
    /// - Parameter imagsArray: The imaginary parts of the array of Complex to be created.
    ///
    /// - Returns: An instance of DSPCountedDoubleSplitComplex with the specified real and imaginary parts.
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

    
    /// Creates and array of 0 + j0
    ///
    /// - Parameter length: The length of the array of zeros.
    /// - Returns: An array containing `length` Complex(real: 0, imag: 0)
    public static func zeros(_ length: Int) -> DSPCountedDoubleSplitComplex {
        assert(length >= 0)
        
        let realPtr = UnsafeMutablePointer<Double>.allocate(capacity: length)
        let imagPtr = UnsafeMutablePointer<Double>.allocate(capacity: length)
        
        realPtr.initialize(from: DoubleArrays.zeros(count: length), count: length)
        imagPtr.initialize(from: DoubleArrays.zeros(count: length), count: length)
        
        return DSPCountedDoubleSplitComplex(
            wrappedComplex: DSPDoubleSplitComplex(realp: realPtr, imagp: imagPtr),
            counts: length
        )
    }
    
    
    /// Add a Complex value to an array of Complex values, element wise.
    /// - Parameter complexArray1: The input array.
    /// - Parameter complexArray2: The Complex value to be added.
    ///
    /// - Returns: `complexArray1 + complexArray1`
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if the dimensions of `complexArray1` and `complexArray2` mismatch.
    public static func addElementWise(
        _ complexArray1: DSPCountedDoubleSplitComplex,
        _ complexArray2: DSPCountedDoubleSplitComplex
    ) throws -> DSPCountedDoubleSplitComplex {
        try DimensionCheckers.checkXYDimensions(complexArray1, complexArray2)
        
        var resultReal = UnsafeMutablePointer<Double>.allocate(capacity: complexArray1.count())
        var resultImag = UnsafeMutablePointer<Double>.allocate(capacity: complexArray2.count())
        
        resultReal.initialize(from: DoubleArrays.zeros(count: complexArray1.count()), count: complexArray1.count())
        resultImag.initialize(from: DoubleArrays.zeros(count: complexArray1.count()), count: complexArray1.count())
        
        var sourceArrayLHS = complexArray1.splitComplexD()
        var sourceArrayRHS = complexArray2.splitComplexD()
        var splitComplexResult = DSPDoubleSplitComplex(realp: resultReal, imagp: resultImag)
        
        vDSP_zvaddD(
            /*sourceArray1:*/ &sourceArrayLHS,
            /*sourceArray1Stride:*/ 1,
            /*sourceArray2:*/ &sourceArrayRHS,
            /*sourceArray2Stride:*/ 1,
            /*resultPtr:*/ &splitComplexResult,
            /*resultStride:*/ 1,
            /*itemsToProcess:*/ vDSP_Length(complexArray1.count())
        )
        
        
        return DSPCountedDoubleSplitComplex(
            wrappedComplex: splitComplexResult,
            counts: complexArray1.count()
        )
    }

    
    /// Subtract a complex value from an array of complex values element wise.
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
        
        var resultReal = UnsafeMutablePointer<Double>.allocate(capacity: complexArray1.count())
        var resultImag = UnsafeMutablePointer<Double>.allocate(capacity: complexArray2.count())
        
        resultReal.initialize(from: DoubleArrays.zeros(count: complexArray1.count()), count: complexArray1.count())
        resultImag.initialize(from: DoubleArrays.zeros(count: complexArray1.count()), count: complexArray1.count())
        
        var sourceArrayLHS = complexArray1.splitComplexD()
        var sourceArrayRHS = complexArray2.splitComplexD()
        var splitComplexResult = DSPDoubleSplitComplex(realp: resultReal, imagp: resultImag)
        
        vDSP_zvsubD(
            /*sourceArray1:*/ &sourceArrayLHS,
            /*sourceArray1Stride:*/ 1,
            /*sourceArray2:*/ &sourceArrayRHS,
            /*sourceArray2Stride:*/ 1,
            /*resultPtr:*/ &splitComplexResult,
            /*resultStride:*/ 1,
            /*itemsToProcess:*/ vDSP_Length(complexArray1.count())
        )
        
        
        return DSPCountedDoubleSplitComplex(
            wrappedComplex: splitComplexResult,
            counts: complexArray1.count()
        )
    }
    
}
