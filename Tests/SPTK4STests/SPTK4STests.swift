import XCTest
@testable import SPTK4S

final class SPTK4STests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        
        let someComplex = Complex(real: Double.pi, imag: ConstantsSPTK.TWO_PI)
        someComplex.addEquals(Complex(real: 1.0, imag: 2.0))
        
        print(someComplex)
    }
}
