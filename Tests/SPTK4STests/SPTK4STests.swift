import XCTest
@testable import SPTK4S

final class SPTK4STests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        
        let someArray = [0.0, 1.0, 2.0, 3.0, 4.0]
        let someOtherArray = [5.1, 9.4, 6.3, 12.12, 22.1]
        let someOtherOtherArray = [6.3, 1.1]
        
        print(DoubleArrays.concatenateAll(someArray, rest: someOtherArray, someOtherOtherArray))
        

    }
}
