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
