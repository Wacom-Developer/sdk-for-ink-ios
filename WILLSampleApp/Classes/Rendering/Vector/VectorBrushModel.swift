//
//  VectorBrushModel.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 22.07.19.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

/*
class DryStroke<DryStrokeModel> {
    var dryStroke: DryStrokeModel? { get }
    //    var dryStroke: DryStrokeModel? {//RedrawModel.DryStroke?
//        return nil
//    }
}*/

/*
class VectorDryStroke : DryStrokeBase{
    public private(set) var vectorPath: UIBezierPath = UIBezierPath()
    public private(set) var color: UIColor?
//    public private(set) var isRasterBrush: Bool

    init(vectorPath: UIBezierPath, color: UIColor) {
        self.vectorPath = vectorPath
        self.color = color
    //    self.isRasterBrush = false
    }
}
*/

protocol VectorInkBuilderProtocol {
    var polygonSimplifier: PolygonSimplifier { get }
    
    func getPath() -> (UIBezierPath? , UIBezierPath?)
}

class VectorBrushModel: RenderingModel {
    private var blendMode: BlendMode = .normal
    
    var drawStrokeResult: CGRect = CGRect.zero
    var addedPath: UIBezierPath? = nil
    var predictedPath: UIBezierPath? = nil
    
    init(_ inkBuilder: InkBuilder?, _ blendMode: BlendMode = .normal) {
        super.init()
        
        ink = inkBuilder
        self.blendMode = blendMode
    }
    
    init(_ pathPointLayout: PathPointLayout? = nil) {
        super.init()
        
        ink = VectorInkBuilder(collectPointData: true, pathPointLayout)
    }
    
    override var addedRect: CGRect? {
        return drawStrokeResult
    }
    
//    override var defaultSize: Float {
//        get {
//            return ink!.splineInterpolator!.defaultSize
//        }
//        set {
//            (ink! as! VectorInkBuilderProtocol).setDefault(size: newValue)
//        }
//    }
    
    override var dryStroke: DryStroke? {
        let polygons: [DIPolygon]
        
        if (ink as? VectorInkBuilderProtocol) != nil {
            polygons = (ink! as! VectorInkBuilderProtocol).polygonSimplifier.allData!
        } else {
            polygons = (ink! as! VectorInkBuilder).polygonSimplifier.allData!
        }
        
        var bezierPath: UIBezierPath?
        generateBezierPolys(polygons, result: &bezierPath)
        
        if let bezierPath = bezierPath {
            return DryStroke(vectorPath: bezierPath, color: inkColor)
        }
                
        return nil
    }
    
    override func touchesBeganBody() {
        
    }
    
    override func touchesEndedBody() {
        
    }
    
    override func initPath() {
        if let inkBuilder = ink as? VectorInkBuilderProtocol {
            (addedPath, predictedPath) = inkBuilder.getPath()
        } else {
            (addedPath, predictedPath) = (ink as! VectorInkBuilder).getPath()
        }
    }
    
    override func drawingAddedPath(renderingContext: RenderingContext) throws {
        do {
            drawStrokeResult = try renderingContext.fillPolygon(addedPath ?? UIBezierPath(), inkColor, blendMode: self.blendMode)
            predictedRect = renderingContext.measurePolygonBounds(polygon: predictedPath)
        } catch let error {
            print("ERROR: \(error)")
        }
    }
    
    override func drawingPredictedPath(at: RenderingContext) {
        do {
            if preliminary == nil {
                _ = try at.fillPolygon(predictedPath ?? UIBezierPath(), inkColor, blendMode: self.blendMode)
            }
            else {
                _ = try at.fillPolygon(predictedPath ?? UIBezierPath(), preliminary!, blendMode: self.blendMode)
            }
        } catch let error {
            print("ERROR: \(error)")
        }
    }
    
    override func renderDryStroke(_ renderingContext: RenderingContext, dryStroke: DryStroke) {
        do {
            _ = try renderingContext.fillPolygon(dryStroke.vectorPath, dryStroke.color!, blendMode: self.blendMode)
        } catch let error {
            print("ERROR: \(error)")
        }
    }
}
