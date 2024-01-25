import Foundation

public final class Grids {
    
    public final class GridData {
        public let X: [Double]
        public let Y: [Double]
        
        public let rows: Int
        public let cols: Int

        private init(_ x: [Double], _ y: [Double], rows: Int, cols: Int) {
            X = x;
            Y = y;
            self.rows = rows
            self.cols = cols
        }

        
        public static func of(_ x: [Double], _ y: [Double]) -> GridData {
            let cols = x.count
            let rows = y.count
            
            let gridX = DoubleArrays.repeat(x, count: rows)
            var gridY = DoubleArrays.repeat(y, count: cols)

            DoubleArrays.sort(&gridY)
            
            return GridData(gridX, gridY, rows: rows, cols: cols)
        }
        
        
        public static func meshGrid(_ x: [Double], _ y: [Double]) -> GridData {
            return GridData.of(x, y)
        }
    }
}
