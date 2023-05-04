//
//  Extensions.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 15.08.19.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import MetalKit
import WacomInk

extension Float {
    public func toString(precision: Int) -> String {
        return String(format: "%.\(precision)f", self)
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension String {
    func toCGFloat() -> CGFloat {
        let sourceText = self
        return CGFloat((sourceText as NSString).floatValue)
    }
}

extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int {
        string.distance(to: self)
    }
}

extension StringProtocol {
    func distance(of element: Element) -> Int? {
        firstIndex(of: element)?.distance(in: self)
    }
    
    func distance<S: StringProtocol>(of string: S) -> Int? {
        range(of: string)?.lowerBound.distance(in: self)
    }
}

extension Collection {
    func distance(to index: Index) -> Int {
        distance(from: startIndex, to: index)
    }
}

extension UIColor {
    public var inverted: UIColor {
        var a: CGFloat = 0.0, r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
        
        return getRed(&r, green: &g, blue: &b, alpha: &a) ? UIColor(red: 1.0-r, green: 1.0-g, blue: 1.0-b, alpha: a) : .black
    } // in demo project
    
    public var rgba: DIFloat4 {
        var a: CGFloat = 0.0, r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
        
        return getRed(&r, green: &g, blue: &b, alpha: &a) ?
            DIFloat4(Float(r), Float(g), Float(b), Float(a)):
            DIFloat4(Float(0), Float(0), Float(0), Float(1))
    }
    
    public static func random() -> UIColor {
        return UIColor(
            red: .random(),
            green: .random(),
            blue: .random(),
            alpha: CGFloat.minimum(0.15, .random())
        )
    }
    
    private static var randomColors = [
        UIColor.yellow.withAlphaComponent(0.3),
        UIColor.brown.withAlphaComponent(0.3),
        UIColor.red.withAlphaComponent(0.3),
        UIColor.green.withAlphaComponent(0.3),
        UIColor.blue.withAlphaComponent(0.3),
        UIColor.purple.withAlphaComponent(0.3)
    ]
    
    public static func randomFromArray() -> UIColor {
        randomColors.randomElement()!
    }
}

extension CGRect {
    func createCanvas() -> CAShapeLayer {
        let newCanvas = CAShapeLayer()
        
        newCanvas.bounds = self
        newCanvas.isOpaque = false
        newCanvas.backgroundColor = UIColor.clear.cgColor
        newCanvas.anchorPoint = CGPoint(x: 0, y: 0)
        
        return newCanvas
    }
}

extension URL    {
    func checkFileExist() -> Bool {
        let path = self.path
        if (FileManager.default.fileExists(atPath: path))   {
            print("FILE EXISTS")
            return true
        }else        {
            print("FILE DOES NOT EXIST")
            return false;
        }
    }
}

extension PointerData {
    /**
     * A helper method that calculates a normalized value based on the pressure of the pointer.
     *
     * @param minValue Min result value.
     * @param maxValue Max result value.
     * @param minPressure Pressure is clamped to this value if speed is below the value.
     * @param maxPressure Pressure is clamped to this value if speed is above the value.
     * @param reverse Pressure will be reversed
     * @param remap A lambda that that defines a custom transformation on the normalized speed value.
     * @return
     */
    func computeValueBasedOnPressure(minValue: Float,
                                     maxValue: Float,
                                     minPressure: Float = 100,
                                     maxPressure: Float = 4000,
                                     reverse: Bool = false,
                                     remap: ((Float) -> (Float))? = nil) -> Float? {
        let normalizePressure: Float
        
        var force2 = force
        
        if force == 0.33333334 {
            force2 = 0
        }
        
        if reverse {
            normalizePressure = minPressure + (1 - force2!) * (maxPressure - minPressure)
        } else {
            normalizePressure = minPressure + force2! * (maxPressure - minPressure)
        }
        
        let pressureClamped = Float.minimum(Float.maximum(normalizePressure, minPressure), maxPressure)
        var k = (pressureClamped - minPressure) / (maxPressure - minPressure)
        
        if let remap = remap {
            k = remap(k)
        }
        
        return minValue + k * (maxValue - minValue)
    }
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

extension UIImage {
  func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        
    guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
    defer { UIGraphicsEndImageContext() }
        
    let rect = CGRect(origin: .zero, size: size)
    ctx.setFillColor(color.cgColor)
    ctx.fill(rect)
    ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
    ctx.draw(image, in: rect)
        
    return UIGraphicsGetImageFromCurrentImageContext() ?? self
  }
}

extension StockRasterInkBuilder {
    func updatePipeline(layout: LayoutMask, calculator: @escaping Calculator, spacing: Float) {
        do {
            try self.pathProducer.setLayoutMask(layout)
            try self.pathProducer.setPathPointCalculator(newValue: calculator)
            
            try splineInterpolator.setSpacing(newValue: spacing)
            splineInterpolator.splitCount = 8
        } catch let error {
            print("ERROR: \(error)")
        }
    }
}

extension SampleVectorInkBuilder {
    public func updateVectorInkPipeline(layoutMask: LayoutMask, calculator: @escaping Calculator ,brush: Geometry.VectorBrush, constSize: Float = 1.0, constRotation: Float = 0.0, scaleX: Float = 1.0, scaleY: Float = 1.0, offsetX: Float = 0.0, offsetY: Float  = 0.0) throws {
        try self.pathProducer.setLayoutMask(layoutMask)
        try self.pathProducer.setPathPointCalculator(newValue: calculator)
        try self.brushApplier.setPrototype(newValue: brush)
        
        self.brushApplier.defaultSize = constSize;
        self.brushApplier.defaultRotation = constRotation;
        self.brushApplier.defaultScale = DIFloat3(scaleX, scaleY, 1)
        self.brushApplier.defaultOffset = DIFloat3(offsetX, offsetY, 0.0);
    }
    
    func getBezierPathBy(spline: Spline, inkPipeline: InkPipeline) throws {
//        let splineInterpolatorResult = try splineInterpolator.add(isFirst: true, isLast: true, addition: spline, prediction: nil)
//
//        let addedPolysResult = try brushApplier.add(isFirst: true, isLast: true, addition: splineInterpolatorResult.addition, prediction: nil)
//        
//        let addedHullsResult = try convexHullChainProducer.add(isFirst: true, isLast: true, addition: addedPolysResult.addition, prediction: nil)
//        
//        let addedMergedResult = try polygonMerger.add(isFirst: true, isLast: true, addition: addedHullsResult.addition, prediction: nil)
        
        inkPipeline.reset()
        
        _ = try splineToPolygon(spline: spline)
        
        try inkPipeline.process()
//        let addedSimplifiedResult = try polygonSimplifier.add(isFirst: true, isLast: true, addition: addedMergedResult.addition, prediction: nil)
//
//        let addedBezierResult = try bezierpathProducer.add(isFirst: true, isLast: true, addition: addedSimplifiedResult.addition, prediction: nil)
        
        //return addedBezierResult.addition
    }
}

extension PointerDataProvider {
    func add(phase: Phase, touches: Set<UITouch>, event: UIEvent, view: UIView) {
        switch phase {
        case .begin:
            if touches.count != 1 {
                NSException(name:NSExceptionName(rawValue: "VectorInkBuilderUpdatedPipeline.add ,"), reason:"touches count is diff from 1 in .begin phase", userInfo:nil).raise()
            }
            let touchData = getTouchDataBy(phase: phase, touch: touches.first!, view: view)
                        
            do
            {
                try self.add(addition: touchData)
            }
            catch {
                NSException(name:NSExceptionName(rawValue: "VectorInkBuilderUpdatedPipeline.add ,"), reason:"\(error)", userInfo:nil).raise()
            }
            
        case .end:
            addTouchImpl(phase: phase, touches: touches, event: event, view: view)
        default:
            addTouchImpl(phase: phase, touches: touches, event: event, view: view)
        }
    }
    
    private func getTouchDataBy(phase: Phase, touch: UITouch, view: UIView) -> PointerData {
        let location = touch.location(in: view)
        let x: Float = Float(location.x)
        let y: Float = Float(location.y)
        let force: Float = Float(touch.force)
        let azymuthAngle: Float = Float(touch.azimuthAngle(in: view))
        let altitudeAngle: Float = Float(touch.altitudeAngle)
       
        var result = PointerData(phase:phase, timestamp: touch.timestamp, x: x, y: y, force: force)
        result.azimuthAngle = azymuthAngle
        result.altitudeAngle = altitudeAngle
        
        return result
    }
    
    private func addTouchImpl(phase: Phase, touches: Set<UITouch>, event: UIEvent, view: UIView) {
        let sortedTouches: [UITouch] = touches.sorted(by: {$0.timestamp < $1.timestamp})
        let size:Int = touches.count
        
        for i in 1..<touches.count {
            let touch = sortedTouches[size - i]
            let touchData = getTouchDataBy(phase: .update, touch: touch, view: view)

            if (i != touches.count - 1) {
                print(", ")
            }
                
                
            do {
                try self.add(addition: touchData)
            } catch {
                NSException(name:NSExceptionName(rawValue: "InkBuilder.add"), reason:"\(error)", userInfo:nil).raise()
            }
        }
        
        let touch = sortedTouches[0]
        let touchData = getTouchDataBy(phase: phase == .end ? .end : .update, touch: touch, view: view)

        var predictedeTouchData: PointerData! = nil
        
        if let predictedTouches = event.predictedTouches(for: touch), let predictedTouch = predictedTouches.last {
            predictedeTouchData = getTouchDataBy(phase: .end, touch: predictedTouch, view: view)            
        }
        
        do {
            try add(touchData, predictedeTouchData)
        } catch {
            NSException(name:NSExceptionName(rawValue: "InkBuilder.add"), reason:"\(error)", userInfo:nil).raise()
        }
    }
    
    private func add(_ touchData: PointerData?,_ predictedeTouchData: PointerData?) throws {
        if let addition = touchData {
            try self.add(addition: addition)
        }
        
        if let prediction = predictedeTouchData {
            self.setPrediction(prediction: prediction)
        }
    }

}
