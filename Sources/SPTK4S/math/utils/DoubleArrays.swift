
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
        
        var output = [Double].init(repeating: 0, count: doubleArray1.count)
        
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
        var result = [Double].init(repeating: 0, count: doubleArray.count)
        
        for i in 0..<doubleArray.count {
            result[i] = scalar - doubleArray[i]
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
        var result = [Double].init(repeating: 0.0, count: doubleArray.count)
        
        var theScalar = -scalar
        
        result.withUnsafeMutableBufferPointer { resultPtr in
            vDSP_vsaddD(
                /*array:*/ doubleArray,
                /*array1Stride:*/ 1,
                /*scalar:*/ &theScalar,
                /*outputPtr:*/ resultPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
            )
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
        var array = doubleArray1
        
        array.withUnsafeMutableBufferPointer { lhsPtr in
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
        
        doubleArray1 = array
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
        return DoubleArrays.subtractElementWise(doubleArray: doubleArray, scalar: -scalar)
    }

    
    /// Add an array and a scalar element wise.
    ///
    /// - Parameter doubleArray: The array to add.
    /// - Parameter scalar: The scalar.
    public static func addElementWiseInPlace(doubleArray: inout [Double], scalar: Double) -> Void {
        var scalar = scalar
        var array = doubleArray
        
        array.withUnsafeMutableBufferPointer { resultPtr in
            vDSP_vsaddD(
                /*array:*/ doubleArray,
                /*array1Stride:*/ 1,
                /*scalar:*/ &scalar,
                /*outputPtr:*/ resultPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
            )
        }
        
        doubleArray = array
    }

    
    /// Add two arrays element wise in place. The result of the addition is stored in array `doubleArray1`.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if `doubleArray1` and `doubleArray2` sizes mismatch.
    public static func addElementWiseInPlace(_ doubleArray1: inout [Double], _ doubleArray2: [Double]) throws -> Void {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        var array = doubleArray1
        
        array.withUnsafeMutableBufferPointer { doubleArray1Ptr in
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
        
        doubleArray1 = array
    }


    /// Multiply two and array a scalar element wise.
    ///
    /// - Parameter doubleArray: The array to multiply.
    /// - Parameter scalar: The scalar.
    ///
    /// - Returns: `doubleArray * scalar`
    public static func multiplyElementWise(doubleArray: [Double], scalar: Double) -> [Double] {
        var result = [Double].init(repeating: 0.0, count: doubleArray.count)
        
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
    public static func multiplyElementWiseInPlace(doubleArray: inout [Double], scalar: Double) -> Void {
        var scalar = scalar
        var array = doubleArray
        
        array.withUnsafeMutableBufferPointer { doubleArrayPtr in
            vDSP_vsmulD(
                /*array:*/ doubleArray,
                /*array1tride:*/ 1,
                /*scalarPtr:*/ &scalar,
                /*outputPtr:*/ doubleArrayPtr.baseAddress!,
                /*outputStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
            )
        }
        
        doubleArray = array
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
        
        var result = [Double].init(repeating: 0, count: doubleArray1.count)

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
        var array = doubleArray1
        
        array.withUnsafeMutableBufferPointer { resultPtr in
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
        
        doubleArray1 = array
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
        
        var result = [Double].init(repeating: 0, count: doubleArray1.count)

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
    public static func diveElementWiseInPlace(_ doubleArray1: inout [Double], _ doubleArray2: [Double]) throws -> Void {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        var array = doubleArray1
        
        array.withUnsafeMutableBufferPointer { resultPtr in
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
        
        doubleArray1 = array
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

    
    /// Norm one of array.
    ///
    /// - Parameter doubleArray: The array whose norm needs to be found.
    ///
    /// - Returns: ∑ abs(a)
    public static func norm1(_ doubleArray: [Double]) -> Double {
        return cblas_dasum(
            /*arrayLength:*/ Int32(doubleArray.count),
            /*theArray:*/ doubleArray,
            /*arrayStride:*/ 1
        )
    }

    
    /// Norm two of array
    ///
    /// - Parameter doubleArray: The array whose norm needs to be found.
    /// - Returns: `√(∑|doubleArray_i|^2)`
    public static func norm2(_ doubleArray: [Double]) -> Double {
        return cblas_dnrm2(
            /*arrayLength:*/ Int32(doubleArray.count),
            /*theArray:*/ doubleArray,
            /*arrayStride:*/ 1
        )
    }

    
    /// Infinite norm of array.
    ///
    /// - Parameter doubleArray: The array whose norm needs to be found.
    /// - Returns: `max(|doubleArray|)`
    public static func normInf(_ doubleArray: [Double]) -> Double {
        var normInf: Double = -Double.infinity
        
        vDSP_maxmgvD(
            /*array:*/ doubleArray,
            /*arrayStride:*/ 1,
            /*normInfPtr:*/ &normInf,
            /*arrayLength:*/ vDSP_Length(doubleArray.count)
        )
        
        return normInf
    }

    
    /// Negative Infinite norm of array.
    ///
    /// - Parameter doubleArray: The array whose norm needs to be found.
    /// - Returns: `min(|doubleArray|)`
    public static func normNegInf(_ doubleArray: [Double]) -> Double {
        var normInf: Double = -Double.infinity
        
        vDSP_minmgvD(
            /*array:*/ doubleArray,
            /*arrayStride:*/ 1,
            /*normInfPtr:*/ &normInf,
            /*arrayLength:*/ vDSP_Length(doubleArray.count)
        )
        
        return normInf
    }

    
    
    /***
     * Euclidean distance between two arrays.
     *
     * @param a The left-hand array.
     * @param b The right-hand array.
     * @return {@code sqrt(sum((a[i] - b[i])<sup>2</sup>))}
     */
    /// Euclidean distance between two arrays.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns √ (∑(doubleArray1_i - doubleArray2_i)^2)
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if sizes of `doubleArray1` and `doubleArray2` mismatch.
    public static func distance(_ doubleArray1: [Double], _ doubleArray2: [Double]) throws -> Double {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        var differencesSquared = [Double].init(repeating: 0.0, count: doubleArray1.count)

        differencesSquared.withUnsafeMutableBufferPointer { differencesSquaredPtr in
            vDSP_distancesqD(
                /*firstArray:*/ doubleArray1,
                /*firstArrayStride:*/ 1,
                /*secondArray*/ doubleArray2,
                /*secondArrayStride*/ 1,
                /*outputArrayPtr:*/ differencesSquaredPtr.baseAddress!,
                /*itemsToProcess:*/ vDSP_Length(doubleArray1.count)
            )
        }
        
        var theSum: Double = 0.0
                
        vDSP_sveD(
            /*arrayToSum:*/ differencesSquared,
            /*arrayStride:*/ 1,
            /*sumPtr:*/ &theSum,
            /*itemsToProcess:*/ vDSP_Length(differencesSquared.count)
        )
        
        return Darwin.sqrt(theSum)
    }

    
    /// Kronecker array product.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: An array formed by taking all possible products between the elements of `doubleArray1` and `doubleArray2`
    ///
    /// - Complexity: O(`doubleArray1.count * doubleArray2.count`)
    public static func kronecker(_ doubleArray1: [Double], _ doubleArray2: [Double]) -> [Double] {
        var result = [Double].init(repeating: 0, count: doubleArray1.count * doubleArray2.count)
        
        if doubleArray1.count == 1 {
            return DoubleArrays.multiplyElementWise(doubleArray: doubleArray2, scalar: doubleArray1.first!)
        }
        
        if doubleArray2.count == 1 {
            return DoubleArrays.multiplyElementWise(doubleArray: doubleArray1, scalar: doubleArray2.first!)
        }

        for i in 0..<doubleArray1.count {
            for j in 0..<doubleArray2.count {
                result[i * doubleArray2.count + j] = doubleArray1[i] * doubleArray2[j]
            }
        }

        return result;
    }

    
    /// Array concatenation
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: `{doubleArray1, doubleArray2}`
    public static func concatenate(_ doubleArray1: [Double], _ doubleArray2: [Double]) -> [Double] {
        var result = [Double].init(repeating: 0, count: doubleArray1.count + doubleArray2.count)
        
        result.withUnsafeMutableBufferPointer { outputPtr in
            cblas_dcopy(
                /*#elements:*/ Int32(doubleArray1.count),
                /*sourceArray:*/ doubleArray1,
                /*sourceArrayStride:*/ Int32(1),
                /*destArrayPtr:*/ outputPtr.baseAddress!,
                /*destArrayStride:*/ Int32(1)
            )
            
            cblas_dcopy(
               /*#elements:*/ Int32(doubleArray2.count),
               /*sourceArray:*/ doubleArray2,
               /*sourceArrayStride:*/ Int32(1),
               /*destArrayPtr:*/ outputPtr.baseAddress!.advanced(by: doubleArray1.count),
               /*destArrayStride:*/ Int32(1)
            )
        }
        
        return result
    }

    
    /**
     * Concatenate series of arrays.
     * @param a The left-hand array.
     * @param rest The rest of the arrays to concatenate.
     * @return {@code {a, rest[0], rest[1], ... , rest[n}}
     */

    /// Concatenate series of arrays.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter rest: The rest of the arrays to concatenate.
    ///
    /// - Returns: `{doubleArray1, rest[0], ..., rest[n]}`
    public static func concatenateAll(_ doubleArray1: [Double], rest: [Double]...) -> [Double] {
        let totalLength = doubleArray1.count + rest.reduce(0) { partialCount, nextArray in
            return partialCount + nextArray.count
        }
        
        var result = [Double].init(repeating: 0.0, count: totalLength)
        
        result.withUnsafeMutableBufferPointer { outputPtr in
            cblas_dcopy(
                /*#elements:*/ Int32(doubleArray1.count),
                /*sourceArray:*/ doubleArray1,
                /*sourceArrayStride:*/ Int32(1),
                /*destArrayPtr:*/ outputPtr.baseAddress!,
                /*destArrayStride:*/ Int32(1)
            )
            
            var currentOffset = doubleArray1.count
            for remainingArray in rest {
                cblas_dcopy(
                   /*#elements:*/ Int32(remainingArray.count),
                   /*sourceArray:*/ remainingArray,
                   /*sourceArrayStride:*/ Int32(1),
                   /*destArrayPtr:*/ outputPtr.baseAddress!.advanced(by: currentOffset),
                   /*destArrayStride:*/ Int32(1)
                )

                currentOffset += remainingArray.count
            }
            
        }

        return result
    }


    /// Repeat an array.
    ///
    /// - Parameter doubleArray: The array to repeat.
    /// - Parameter count: The number of times to repeat the array.
    ///
    /// - Returns: The input array repeated `count` times.
    public static func `repeat`(_ doubleArray: [Double], count: Int) -> [Double] {
        var result = [Double].init(repeating: 0, count: doubleArray.count * count)
        
        result.withUnsafeMutableBufferPointer { outputPtr in
            for i in 0..<count {
                cblas_dcopy(
                    /*#elements:*/ Int32(doubleArray.count),
                    /*sourceArray:*/ doubleArray,
                    /*sourceArrayStride:*/ Int32(1),
                    /*destArrayPtr:*/ outputPtr.baseAddress!.advanced(by: doubleArray.count * i),
                    /*destArrayStride:*/ Int32(1)
                )
            }
        }

        return result
    }
    

    /**
     * The sum of all the elements in the array.
     * @param a The array whose sum needs to be found.
     * @return {@code sum(a)}.
     */
    /// Reversed the input array.
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[doubleArray[doubleArray.count -1 ], ..., doubleArray[0] ]`
    public static func reverse(_ doubleArray: [Double]) -> [Double] {
        return doubleArray.reversed()
    }


    /// Computes the sum of the elements of the array.
    ///
    /// - Parameter doubleArray: The input array
    /// - Returns: `∑ doubleArray_i`
    public static func sum(_ doubleArray: [Double]) -> Double {
        var theSum: Double = .zero
        
        vDSP_sveD(
            /*arrayToSum:*/ doubleArray,
            /*arrayStride:*/ 1,
            /*sumPtr:*/ &theSum,
            /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
        )
        
        return theSum
    }
    
    
    /// Computes the sum of the elements of the array.
    ///
    /// - Parameter doubleArray: The input array
    /// - Returns: `∑ doubleArray_i^2`
    public static func sumSquares(_ doubleArray: [Double]) -> Double {
        var theSumSq: Double = .zero
        
        vDSP_svesqD(
            /*arrayToSum:*/ doubleArray,
            /*arrayStride:*/ 1,
            /*sumPtr:*/ &theSumSq,
            /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
        )
        
        
        return theSumSq
    }

    

    /// Cumulative sum of the input array.
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `doubleArray_i + ∑_j=0->i-1 doubleArray_j`, i = {0, 1, ... `doubleArray.count - 1`}
    public static func cumulativeSum(_ doubleArray: [Double]) -> [Double] {
        var result = [Double].init(repeating: 0, count: doubleArray.count)
        var weight: Double = 1.0
        
        result.withUnsafeMutableBufferPointer { resultPtr in
            vDSP_vrsumD(
                /*inputArray:*/ doubleArray,
                /*inputArrayStride: */1,
                /*weight:*/ &weight,
                /*resultPtr:*/ resultPtr.baseAddress!,
                /*resultStride:*/ 1,
                /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
            )
        }
                
        return result
    }
    
    
    
    /// Root Mean Square
    ///
    /// - Parameter doubleArray: The array whose RMS value needs to be found.
    /// - Returns: `√(1/doubleArray.count * ∑ doubleArray_i^2)`
    public static func rms(_ doubleArray: [Double]) -> Double {
        var rms: Double = .zero
        
        vDSP_rmsqvD(
            /*inputArray:*/ doubleArray,
            /*inputArrayStride:*/ 1,
            /*resultPtr:*/ &rms,
            /*itemsToProcess:*/ vDSP_Length(doubleArray.count)
        )
        
        return rms
    }

    
    /**
     * Is array ascending.
     * @param a The input array.
     * @return {@cde true} if all the elements in the array are sorted in ascending order, {@code false} otherwise.
     */
    /// Is array ascending.
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `true` if all the elements in the array are sorted in ascending order, `false` otherwise.
    public static func isAscending(_ doubleArray: [Double]) -> Bool {
        for i in 0..<doubleArray.count-1 {
            if doubleArray[i] > doubleArray[i+1] {
                return false
            }
        }
        
        return true
    }

    
    /**
     * Converts (flattens) a 2d array into a 1d array by copying
     * every row of the 2d array into the 1d array.
     * <pre>
     * let a = {{1, 2, 3}, {4, 5, 6}};
     * thus flatten(a) returns:
     * {1, 2, 3, 4, 5, 6}
     *</pre>
     * @param a array to flatten
     * @return a new row-packed 1d array
     * @throws IllegalArgumentException if the input array a is jagged (i.e. not all rows have the same length)
     */
    /// Converts (flattens) a 2d array into a 1d array by copying every row of the 2d array into the 1d array.
    ///
    ///         let a = {{1, 2, 3}, {4, 5, 6}}
    ///         thus flatten(a) returns:
    ///         {1, 2, 3, 4, 5, 6}
    ///
    /// - Parameter doubleArrayOfArrays: The array to flatten.
    /// - Returns: A new row-packed 1d array
    /// - Throws: `DoubleArraysError.illegalArgumentException(_:String)` if `doubleArrayOfArrays` contains arrays of different lengths.
    public static func flatten(_ doubleArrayOfArrays: [[Double]]) throws -> [Double] {
        if doubleArrayOfArrays.count > 0 {
            let columns: Int = doubleArrayOfArrays.first!.count
            var result = [Double].init(repeating: 0, count: columns * doubleArrayOfArrays.count)
            
            try result.withUnsafeMutableBufferPointer { resultPtr in
                var currentOffset = 0
                for subArray in doubleArrayOfArrays {
                    if subArray.count != columns {
                        throw DoubleArraysError.illegalArgumentException(reason: "All rows must have the same length.")
                    }
                    
                    cblas_dcopy(
                        /*#elements:*/ Int32(columns),
                        /*sourceArray:*/ subArray,
                        /*sourceArrayStride:*/ Int32(1),
                        /*destArrayPtr:*/ resultPtr.baseAddress!.advanced(by: currentOffset),
                        /*destArrayStride:*/ Int32(1)
                    )
                    
                    currentOffset += subArray.count
                }
            }
            
            return result
        } else {
            return []
        }
    }

    
    /// Mean of the array.
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: The mean of the input array.
    public static func mean(_ doubleArray: [Double]) -> Double {
        return DoubleArrays.sum(doubleArray)/Double(doubleArray.count)
    }

    
    /// Horner's method of evaluating a polynomial.
    ///
    /// - Parameter coefficients: The coefficients of the polynomial.
    /// - Parameter x: Argument at which to evaluate the polynomial.
    ///
    /// - Returns: p(x)
    public static func horner(coefficients: [Double], x: Double) -> Double {
        var result: Double = .zero
        
        for coefficient in coefficients {
            result = result * x + coefficient
        }

        return result;
    }

    
    /// Differences between adjacent elements in the array.
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: The difference between adjacent elements in the array.
    public static func difference(_ doubleArray: [Double]) -> [Double] {
        var result = [Double].init(repeating: 0, count: doubleArray.count - 1)
        
        for i in 0..<doubleArray.count-1 {
            result[i] = doubleArray[i + 1] - doubleArray[i];
        }

        return result;
    }

    
    /// Numerical gradient of an array. The spacing between the elements is assumed to be one.
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: The numerical gradient of the array.
    public static func gradient(_ doubleArray: [Double]) -> [Double] {
        var gradient = [Double].init(repeating: 0, count: doubleArray.count)
        
        gradient[0] = doubleArray[1] - doubleArray[0]
        
        if doubleArray.count > 1 {
            gradient[gradient.count - 1] = gradient[gradient.count - 1] - gradient[gradient.count - 2]
        }
        
        for i in 0..<doubleArray.count-1 {
            gradient[i] = 0.5 * (doubleArray[i+1] - doubleArray[i-1])
        }

        return gradient;
    }


    /// Outer product of two arrays.
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: `result[i][j] = doubleArray1[i] * doubleArray2[j]`
    ///
    /// - Complexity: O(`doubleArray1.count * doubleArray2.count`)
    public static func outer(_ doubleArray1: [Double], _ doubleArray2: [Double]) -> [[Double]] {
        var result = [[Double]].init(repeating: [Double].init(repeating: 0, count: doubleArray2.count), count: doubleArray1.count)
        
        for i in 0..<doubleArray1.count {
            for j in 0..<doubleArray2.count {
                result[i][j] = doubleArray1[i] * doubleArray2[j]
            }
        }
        
        return result
    }
    
    
    /// Dot product between two arrays
    ///
    /// - Parameter doubleArray1: The left-hand array.
    /// - Parameter doubleArray2: The right-hand array.
    ///
    /// - Returns: The dot (inner) product of arrays `doubleArray1` and `doubleArray2`
    /// - Throws: `DimensionError.illegalArgumentException(_:String)` if sizes of `doubleArray1` and `doubleArray2` mismatch.
    public static func dot(_ doubleArray1: [Double], _ doubleArray2: [Double]) throws -> Double {
        try DimensionCheckers.checkXYDimensions(doubleArray1, doubleArray2)
        
        var dotProd: Double = .zero
        
        vDSP_dotprD(
            /*firstArray:*/ doubleArray1,
            /*firstArrayStride:*/ 1,
            /*secondArray:*/ doubleArray2,
            /*secondArrayStride:*/ 1,
            /*resultPtr:*/ &dotProd,
            /*itemsToProcess:*/ vDSP_Length(doubleArray1.count)
        )
        
        return dotProd
    }

    
    /// Array product.
    ///
    /// - Parameter doubleArray: The input array
    /// - Returns: The product of multiplying all the elements in the array.
    public static func product(_ doubleArray: [Double]) -> Double {
        
        var product: Double = 1.0
        
        for element in doubleArray {
            product *= element
        }
        
        return product
    }
    

    /// Checks if all elements of the array are close numerically to a given target.
    ///
    /// - Parameter doubleArray: The input array.
    /// - Parameter target: The target value.
    ///
    /// - Returns: `true`  all the values in the array are close to the given target, `false` otherwise.
    /// - Note: See `MathSPTK#isClose(_:Double, _:Double)`
    public static func allClose(_ doubleArray: [Double], target: Double) -> Bool {
        
        for element in doubleArray {
            if !MathSPTK.isClose(element, target) {
                return false
            }
        }
        
        return true
    }

    
    /// Checks if all elements of the array are close numerically to a given target.
    ///
    /// - Parameter doubleArray: The input array.
    /// - Parameter target: The target value.
    /// - Parameter absTol: The absolute tolerance.
    /// - Parameter relTol The relative tolerance.
    ///
    /// - Returns: `true` if all the values in the array are close to the given target, `false` otherwise.
    /// - Note: See `MathSPTK#isClose(_:Double, _:Double, absTol: Double, relTol: Double)`
    public static func allClose(_ doubleArray: [Double], target: Double, absTol: Double, relTol: Double) -> Bool {
        for element in doubleArray {
            if !MathSPTK.isClose(element, target, absTol: absTol, relTol: relTol) {
                return false
            }
        }
        
        return true
    }


    /// Creates and array of `count` ones.
    ///
    /// - Parameter count: The length of the array of ones.
    /// - Returns: An array containing `count` ones.
    public static func ones(count: Int) -> [Double] {
        return [Double].init(repeating: 1.0, count: count)
    }

    
    /// Transpose a 2d array.
    ///
    /// - Parameter twoDDoubleArray: The array to transpose.
    /// - Returns: The transposed array.
    ///
    /// - Note: Also refer to [stackoverflow](https://stackoverflow.com/a/17634025/6383857).
    /// - Throws: `DoubleArraysError.illegalArgumentException(_:String)` if the rows of twoDDoubleArray aren't all the same size
    public static func transpose(_ twoDDoubleArray: [[Double]]) throws -> [[Double]] {
        if twoDDoubleArray.count <= 0 {
            return twoDDoubleArray
        } else {
            let rows = twoDDoubleArray.count
            let cols = twoDDoubleArray.first!.count
            
            var result = [[Double]].init(repeating: [Double].init(repeating: 0.0, count: cols), count: rows)
            
            for i in 0..<rows {
                for j in 0..<cols {
                    if twoDDoubleArray[i].count != cols {
                        throw DoubleArraysError.illegalArgumentException(reason: "All the columns of input parameter must be the same length.")
                    }
                    
                    result[j][i] = twoDDoubleArray[i][j]
                }
            }
            
            return result
        }
    }
    
    
    /// Transpose a matrix represented as a linear array.
    ///
    /// - Parameter doubleArray: The array to transpose.
    /// - Parameter columns: The number of columns of the array.
    /// - Returns: The transposed array.
    ///
    /// - Throws: `DoubleArraysError.illegalArgumentException(_:String)` if `doubleArray.count / columns` is not an integer.
    public static func transpose(_ doubleArray: [Double], columns: Int) throws -> [Double] {
        if doubleArray.count <= 0 {
            return doubleArray
        } else {
            let rowsCount = doubleArray.count/columns
            
            if Double(doubleArray.count)/Double(columns) != Double(rowsCount) {
                throw DoubleArraysError.illegalArgumentException(reason: "doubleArray.count / columns must be an integer")
            }
            
            var transposed = [Double].init(repeating: 0.0, count: doubleArray.count)
            
            transposed.withUnsafeMutableBufferPointer { transposedPtr in
                vDSP_mtransD(
                    /*sourceArray:*/ doubleArray,
                    /*sourceArrayStride:*/ 1,
                    /*transposedPtr:*/ transposedPtr.baseAddress!,
                    /*transposedStride:*/ 1,
                    /*outputRows:*/ vDSP_Length(columns),
                    /*outputColumns:*/ vDSP_Length(rowsCount)
                )
            }
 
            return transposed
        }
    }
    
    
    /// Zero-pads the array with the specified amount of leading and trailing zeros
    ///
    /// - Parameter doubleArray: The input array,
    /// - Parameter leadingZeros: The number of zeros before `doubleArray[0]` in the output array.
    /// - Parameter trailingZeros: The number of zeros after `doubleArray.last` in the output array.
    public static func zeroPad(_ doubleArray: [Double], leadingZeros: Int, trailingZeros: Int) -> [Double] {
        
        precondition(leadingZeros >= 0 && trailingZeros >= 0)
        var output = [Double].init(repeating: 0.0, count: leadingZeros + doubleArray.count + trailingZeros)
        
        output.withUnsafeMutableBufferPointer { outputPtr in
            cblas_dcopy(
                /*#elements:*/ Int32(leadingZeros),
                /*sourceArray:*/ doubleArray,
                /*sourceArrayStride:*/ Int32(1),
                /*destArrayPtr:*/ outputPtr.baseAddress!.advanced(by: leadingZeros),
                /*destArrayStride:*/ Int32(1)
            )
        }
         
        return output
    }
    
    
    /// An array of `count` zeros.
    ///
    /// - Parameter count: The number of zeros in the output array.
    /// - Returns: An array with `count` 0.0d
    public static func zeros(count: Int) -> [Double] {
        return [Double].init(repeating: 0.0, count: count)
    }
    
    
    /// Computes the sin of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[sin(doubleArray[0]), ..., sin(doubleArray[n])]
    public static func sin(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvsin(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the sinh of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[sinh(doubleArray[0]), ..., sinh(doubleArray[n])]
    public static func sinh(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvsinh(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the cos of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[cos(doubleArray[0]), ..., cos(doubleArray[n])]
    public static func cos(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvcos(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the cosh of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[cosh(doubleArray[0]), ..., cosh(doubleArray[n])]
    public static func cosh(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvcosh(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the tan of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[tan(doubleArray[0]), ..., tan(doubleArray[n])]
    public static func tan(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvtan(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the tanh of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[tanh(doubleArray[0]), ..., tang(doubleArray[n])]
    public static func tanh(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvtanh(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the exp of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[e^doubleArray[0], ..., e^doubleArray[n]]
    public static func exp(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvexp(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the log_e of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[e^doubleArray[0], ..., e^doubleArray[n]]
    public static func log_e(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvlog(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the log2 of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[e^doubleArray[0], ..., e^doubleArray[n]]
    public static func log_2(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvlog2(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the log2 of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[e^doubleArray[0], ..., e^doubleArray[n]]
    public static func log_10(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvlog10(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the sqrt of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[√doubleArray[0], ..., √doubleArray[n]]
    public static func sqrt(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvsqrt(resultPtr.baseAddress!, sourcePtr.baseAddress!, &itemsCount)
            }
        }
        
        return output
    }
    
    
    /// Computes the absolute value of every element of the array
    ///
    /// - Parameter doubleArray: The input array.
    /// - Returns: `[|doubleArray[0]|, ..., |doubleArray[n]|]
    public static func abs(_ doubleArray: [Double]) -> [Double] {
        var output = [Double].init(repeating: 0.0, count: doubleArray.count)
        var sourceArray = doubleArray
        var itemsCount = Int32(doubleArray.count)
        
        
        sourceArray.withUnsafeMutableBufferPointer { sourcePtr in
            output.withUnsafeMutableBufferPointer { resultPtr in
                vvfabs(sourcePtr.baseAddress!, resultPtr.baseAddress!, &itemsCount)
            }
        }
        
        
        return output
    }
}


enum DoubleArraysError: Error {
    case illegalArgumentException(reason: String)
}
