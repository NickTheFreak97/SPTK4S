
import Foundation
import Accelerate

/// The `DoubleArrays` utility class provides methods to manipulate arrays of native `Double` values.
public final class DoubleArrays {

    private init() { }

    ///  Creates `count` linearly spaced samples between x0 and x1.
    ///
    ///  - Parameter lowerBound: The starting point.
    ///  - Parameter upperBound: The end point.
    ///
    ///  - Returns: An array of `count` equally spaced samples in [lowerBound, upperBound]
    public static func linSpace(lowerBound: Double, upperBound: Double, count: Int) -> [Double] {
        
        var result = [Double].init()
        let delta: Double = (upperBound - lowerBound)/(Double(count)-1)

        for i in 0..<count-1 {
            result.append(lowerBound + Double(i) * delta)
        }

        result[count - 1] = upperBound;
        return result;
    }


    /// Creates n linearly spaced samples between x0 and x1.
    ///
    /// - Parameter lowerBound: The starting point.
    /// - Parameter upperBound: The end point.
    /// - Parameter step: The step size.
    ///
    /// - Returns: An array of samples spaced by `step` from one another, between [lowerBound, upperBound]
    public static func linSteps(lowerBound: Double, upperBound: Double, step: Double = 1.0) -> [Double] {
        
        let resultCount = Int(Darwin.ceil((upperBound - lowerBound)/step))
        
        var result: [Double] = .init()

        for i in 0..<resultCount {
            result.append(lowerBound + Double(i) * step)
        }
        
        result.append(upperBound)
        
        return result;
    }
    

    /// Creates `count` logarithmically spaced samples between decades `lowerBound` and `upperBound`
    ///
    /// - Parameter lowerBound: The starting decade.
    /// - Parameter upperBound: The ending decade.
    /// - Parameter count: The number of samples
    ///
    /// - Returns: Array of `count` logarithmically spaced samples between [lowerBound, upperBound]
    public static func logSpace(lowerBound: Int, upperBound: Int, count: Int) -> [Double] {
        var result = [Double].init()
        let delta: Double = Double((upperBound - lowerBound))/Double((count - 1))

        for i in 0..<count-1 {
            result.append(Darwin.powl(10.0, Double(lowerBound) + Double(i) * delta))
        }

        result.append(Darwin.powl(10.0, Double(upperBound)))
        
        
        return result;
    }

    
    /// Subtract two arrays element wise.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: `doubleArray1 + doubleArray2`
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `doubleArray1` and `doubleArray2` sizes mismatch.
    public static func subtractElementWise(_ doubleArray1: [Double], _ doubleArray2: [Double]) throws -> [Double] {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        var output = [Double].init()
        output.reserveCapacity(doubleArray1.count)
        
        output.withUnsafeMutableBufferPointer { outputPtr in
            vDSP_vsubD(
                /*array1:*/ doubleArray1,
                /*array1Stride:*/ 1,
                /*array2:*/ doubleArray2,
                /*array2Stride:*/ 1,
                /*outputPtr:*/ outputPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray1.count)
            )
        }
        
        
        return output
    }
    
    
    /// Subtract an array element wise from a scalar.
    ///
    /// - Parameter scalar: The scalar argument
    /// - Parameter doubleArray: The array to subtract
    ///
    /// - Returns: `scalar - doubleArray`
    public static func subtractElementWise(scalar: Double, doubleArray: [Double]) -> [Double] {
        var result = [Double].init()
        result.reserveCapacity(doubleArray.count)
        
        for element in doubleArray {
            result.append(scalar - element)
        }
        
        return result;
    }

    
    
    /// Subtract an array element wise from a scalar.
    ///
    /// - Parameter doubleArray: The array to subtract
    /// - Parameter scalar: The scalar argument
    ///
    /// - Returns: `doubleArray - scalar`
    public static func subtractElementWise(doubleArray: [Double], scalar: Double) -> [Double] {
        var result = [Double].init()
        result.reserveCapacity(doubleArray.count)
        
        for element in doubleArray {
            result.append(element - scalar)
        }
        
        return result;
    }

    
    /// Subtract two arrays element wise in place. The result of the subtraction is stored in array `doubleArray1`.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `doubleArray1` and `doubleArray2` sizes mismatch.
    public static func subtractElementWiseInPlace(doubleArray1: inout [Double], doubleArray2: [Double]) throws -> Void {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        doubleArray1.withUnsafeMutableBufferPointer { lhsPtr in
            vDSP_vsubD(
                /*array1:*/ doubleArray1,
                /*array1Stride:*/ 1,
                /*array2:*/ doubleArray2,
                /*array2Stride:*/ 1,
                /*outputPtr:*/ lhsPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray1.count)
            )
        }
    }


    // TODO: Improve performance turning to FFT based convolution to achieve O(nlogn) complexity
    /// Convolve two arrays.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: The convolution of `doubleArray1` and `doubleArray2`
    /// - Complexity: Currently O(`doubleArray1.count * doubleArray2.count`)
    public static func convolve(_ doubleArray1: [Double], _ doubleArray2: [Double]) -> [Double] {
        var result = [Double].init(repeating: 0.0, count: doubleArray1.count + doubleArray2.count - 1)
        
        for i in 0..<doubleArray1.count {
            for j in 0..<doubleArray2.count {
                result[i + j] += doubleArray1[i] * doubleArray2[j]
            }
        }
        
        return result
    }


    /// Add an array and a scalar element wise.
    ///
    /// - Parameter doubleArray: The array to add.
    /// - Parameter scalar: The scalar to add.
    ///
    /// - Returns `doubleArray + scalar`
    public static func addElementWise(doubleArray: [Double], scalar: Double) -> [Double] {
        var result = [Double].init()
        result.reserveCapacity(doubleArray.count)
        
        for element in doubleArray {
            result.append(element + scalar)
        }
        
        return result
    }

    
    /// Add an array and a scalar element wise.
    ///
    /// - Parameter doubleArray: The array to add.
    /// - Parameter scalar: The scalar.
    public static func addElementWiseInPlace(doubleArray: inout [Double], scalar: Double) -> Void {
        for i in 0..<doubleArray.count {
            doubleArray[i] += scalar
        }
    }

    
    /// Add two arrays element wise in place. The result of the addition is stored in array `doubleArray1`.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `doubleArray1` and `doubleArray2` sizes mismatch.
    public static func addElementWiseInPlace(_ doubleArray1: inout [Double], _ doubleArray2: [Double]) throws -> Void {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        doubleArray1.withUnsafeMutableBufferPointer { doubleArray1Ptr in
            vDSP_vaddD(
                /*array1:*/ doubleArray1,
                /*array1Stride:*/ 1,
                /*array2:*/ doubleArray2,
                /*array2Stride:*/ 1,
                /*outputPtr:*/ doubleArray1Ptr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray1.count)
            )
        }
    }


    /// Multiply two and array a scalar element wise.
    ///
    /// - Parameter doubleArray: The array to multiply.
    /// - Parameter scalar: The scalar.
    ///
    /// - Returns: `doubleArray * scalar`
    public static func multiplyElementWise(doubleArray: [Double], scalar: Double) -> [Double] {
        var result = [Double.init()]
        result.reserveCapacity(doubleArray.count)
        
        var scalar = scalar
        
        result.withUnsafeMutableBufferPointer { resultPtr in
            vDSP_vsmulD(
                /*array:*/ doubleArray,
                /*array1tride:*/ 1,
                /*scalarPtr:*/ &scalar,
                /*outputPtr:*/ resultPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
            )
        }
        
        return result;
    }

    
    
    /// Multiply two and array a scalar element wise.
    ///
    /// - Parameter doubleArray: The array to multiply.
    /// - Parameter scalar: The scalar.
    ///
    /// - Returns: `doubleArray * scalar`
    public static func multiplyElementWiseInPlace(doubleArray: inout [Double], scalar: Double) -> [Double] {
        var scalar = scalar
        
        doubleArray.withUnsafeMutableBufferPointer { doubleArrayPtr in
            vDSP_vsmulD(
                /*array:*/ doubleArray,
                /*array1tride:*/ 1,
                /*scalarPtr:*/ &scalar,
                /*outputPtr:*/ doubleArrayPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
            )
        }
    }
    
    
    /// Multiply two arrays element wise.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: `doubleArray1 * doubleArray2`
    ///
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `doubleArray1` and `doubleArray2` sizes mismatch.
    public static func multiplyElementWise(_ doubleArray1: [Double], _ doubleArray2: [Double]) throws -> [Double] {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        var result = [Double].init()
        result.reserveCapacity(doubleArray1.count)

        result.withUnsafeMutableBufferPointer { resultPtr in
            vDSP_vmulD(
                /*array1:*/ doubleArray1,
                /*array1Stride:*/ 1,
                /*array2:*/ doubleArray2,
                /*array2Stride:*/ 1,
                /*outputPtr:*/ resultPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray1.count)
            )
        }
        
        return result
    }

    
    /// Multiply two arrays element wise.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: `doubleArray1 * doubleArray2`
    ///
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `doubleArray1` and `doubleArray2` sizes mismatch.
    public static func multiplyElementWiseInPlace(_ doubleArray1: inout [Double], _ doubleArray2: [Double]) throws -> Void {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        doubleArray1.withUnsafeMutableBufferPointer { resultPtr in
            vDSP_vmulD(
                /*array1:*/ doubleArray1,
                /*array1Stride:*/ 1,
                /*array2:*/ doubleArray2,
                /*array2Stride:*/ 1,
                /*outputPtr:*/ resultPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray1.count)
            )
        }
    }

    
    
    /// Divide two arrays element wise.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: `doubleArray1 / doubleArray2`
    ///
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `doubleArray1` and `doubleArray2` sizes mismatch.
    public static func diveElementWise(_ doubleArray1: [Double], _ doubleArray2: [Double]) throws -> [Double] {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        var result = [Double].init()
        result.reserveCapacity(doubleArray1.count)

        result.withUnsafeMutableBufferPointer { resultPtr in
            vDSP_vdivD(
                /*array1:*/ doubleArray1,
                /*array1Stride:*/ 1,
                /*array2:*/ doubleArray2,
                /*array2Stride:*/ 1,
                /*outputPtr:*/ resultPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray1.count)
            )
        }
        
        return result
    }
    
    
    /// Divide two arrays element wise in place.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: `doubleArray1 / doubleArray2`
    ///
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `doubleArray1` and `doubleArray2` sizes mismatch.
    public static func diveElementWiseInPlace(_ doubleArray1: inout [Double], _ doubleArray2: [Double]) throws -> [Double] {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        doubleArray1.withUnsafeMutableBufferPointer { resultPtr in
            vDSP_vdivD(
                /*array1:*/ doubleArray1,
                /*array1Stride:*/ 1,
                /*array2:*/ doubleArray2,
                /*array2Stride:*/ 1,
                /*outputPtr:*/ resultPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray1.count)
            )
        }
        
    }
    
    
    /// Maximum value in the array.
    ///
    /// - Parameter doubleArray: The array whose maximum has to be found.
    /// - Returns: `max(doubleArray)`
    public static func max(_ doubleArray: [Double]) -> Double {
        var maximum: Double = -Double.infinity
        
        vDSP_maxvD(
            /*array:*/ doubleArray,
            /*array1Stride:*/ 1,
            /*maximumPtr:*/ &maximum,
            /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
        )
        
        return maximum
    }
    
    
    
    /// Minimum value in the array.
    ///
    /// - Parameter doubleArray: The array whose maximum has to be found.
    /// - Returns: `min(doubleArray)`
    public static func min(_ doubleArray: [Double]) -> Double {
        var minimum: Double = -Double.infinity
        
        vDSP_minvD(
            /*array:*/ doubleArray,
            /*array1Stride:*/ 1,
            /*minimumPtr:*/ &minimum,
            /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
        )
        
        return minimum
    }

    
    /// Index of minimum value.
    ///
    /// - Parameter doubleArray: The array whose maximum has to be found.
    /// - Returns: The index at which the minimum of array `doubleArray` occurs
    public static func argMin(_ doubleArray: [Double]) -> Int {
        var minimum: Double = -Double.infinity
        var minimumIndex: Int = -1
        
        vDSP_minviD(
            /*array:*/ doubleArray,
            /*array1Stride:*/ 1,
            /*minimumPtr:*/ &minimum,
            /*minimumIdxPtr: */ &minimumIndex,
            /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
        )
        
        return minimumIndex
    }
    
    

    /// Returns the indices that would sort an array.
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: The indexes that would sort the array `doubleArray`.
    public static func argSort(_ doubleArray: [Double], ascending: Bool = true) -> [Int] {
        var indices = Array(0..<doubleArray.count)
        
        indices.withUnsafeMutableBufferPointer { indicesPtr in
            vDSP_vsortiD(
                /*arrayToSortPtr:*/  doubleArray,
                /*indicesPtr:*/ indicesPtr.baseAddress!,
                /*alwaysNil:*/ nil,
                /*elementsToProcess:*/ vDSP_Length(doubleArray.count),
                /*ascending:*/ ascending ? 1 : -1
            )
        }
        
        return indices
    }

    
    
}
