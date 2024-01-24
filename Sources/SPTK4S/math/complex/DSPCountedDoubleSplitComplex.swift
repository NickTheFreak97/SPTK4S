import Foundation
import Accelerate

public final class DSPCountedDoubleSplitComplex {
    private var wrappedComplex: DSPDoubleSplitComplex
    private let counts: Int
    
    init(wrappedComplex: DSPDoubleSplitComplex, counts: Int) {
        self.wrappedComplex = wrappedComplex
        self.counts = counts
    }
    
    public func count() -> Int {
        return self.counts
    }
    
    public func splitComplexD() -> DSPDoubleSplitComplex {
        return self.wrappedComplex
    }
    
    public func realp() -> UnsafeMutablePointer<Double> {
        return wrappedComplex.realp
    }
    
    public func imagp() -> UnsafeMutablePointer<Double> {
        return wrappedComplex.imagp
    }
    
    public func deallocate() -> Void {
        self.realp().deallocate()
        self.imagp().deallocate()
    }
    
    deinit {
        self.deallocate()
    }
}
