//
//  WillGraphicsEraser.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 24.10.19.
//  Copyright © 2019 Nikolay Atanasov. All rights reserved.
//

import WacomInk

@available(iOS 13.0, *)
class IntersectModel: ManipulationModel {
    init(backgroundColor: UIColor, isCached: Bool, _ pathPointLayout: PathPointLayout? = nil) {
        super.init(pathPointLayout, isCached: isCached)
        self.backgroundColor = backgroundColor
    }
    
    override func touchesBeganBody() {
        path = UIBezierPath()
        canvas = canvasCache.layer!.rect!.createCanvas()
        canvas.path = path.cgPath
        inkColor = activeManipulationType == ManipulationType.intersect ? backgroundColor! :  UIColor.random().withAlphaComponent(0.5)
        canvas.fillColor = inkColor.cgColor
        canvasCache.layer!.metalLayer!.addSublayer(canvas)
        
        if activeManipulationType == ManipulationType.intersect {
            instantUpdateBounds = nil
        }
        else {
            if isBezierCached {
                uiBezierPathCache!.startBezierPathCacheCollecting()
            }
        }
    }
    
    override func touchesEndedBody() {
        if activeManipulationType == ManipulationType.intersect {
            canvas.removeFromSuperlayer()
        } else {
            collectPointsFor()
        }
    }
    
    override func drawingAddedPath(renderingContext: RenderingContext) throws {
        if activeManipulationType == ManipulationType.intersect {
            needRedrawing = false
            
            if let spline = manipulatingInkBuilder.addedSpline {
                let erasedStroke = WillRendering.InkStroke(
                    identifier: Identifier.fromNewUUID()!,
                    spline: spline,
                    layout: manipulatingInkBuilder.pathPointLayout,
                    vectorBrush: try manipulatingInkBuilder.brushApplier.getPrototype(),
                    constants: WillRendering.ConstantAttributes(
                        size: manipulatingInkBuilder.brushApplier.defaultSize,
                        rotation: manipulatingInkBuilder.brushApplier.defaultRotation,
                        scale: manipulatingInkBuilder.brushApplier.defaultScale,
                        offset: manipulatingInkBuilder.brushApplier.defaultOffset)
                )
                
                try manipulator!.intersect(stroke: erasedStroke, isBezierCached: isBezierCached, integrityMode, onStrokeSelected: onIntersectStroke)
            }
        } else // drawing
        {
            if isBezierCached {
                //drawingInkBuilder.splineProducer!.allData.path.count / drawingInkBuilder.splineProducer!.dimsCount
                uiBezierPathCache!.addBezierPathCache(for: addedPath, controlPointsCount: drawingInkBuilder.splineProducer!.allData!.path.count / (try drawingInkBuilder.splineProducer!.getDimsCount()))
                //uiBezierPathCache!.addBezierPathCache(for: addedPath, drawingSplineProducer: drawingInkBuilder.splineProducer!)
            }
        }
        
        if addedPath != nil && !addedPath!.cgPath.isEmpty {
            path.append(addedPath!)
            
            let copyPath: UIBezierPath? = path.copy() as? UIBezierPath
            
            canvas.path = copyPath?.cgPath
            
            if activeManipulationType == ManipulationType.intersect {
                instantUpdateBounds = (instantUpdateBounds ==  nil ? addedPath!.cgPath.boundingBox : instantUpdateBounds!.union(addedPath!.cgPath.boundingBox))
            }
        }
        
        try super.drawingAddedPath(renderingContext: renderingContext)
    }
    
    private func onIntersectStroke(_ resultStroke: ResultManipulatedStroke) {
        var index: Int? = nil
        var fillColor: CGColor? = nil
        if let deletedDirtyStroke = canvasCache.dryStrokes[resultStroke.originalStrokeIndex] {
            index = canvasCache.layer!.metalLayer!.sublayers!.firstIndex(of: deletedDirtyStroke.canvas)
            fillColor = deletedDirtyStroke.canvas.fillColor
            instantUpdateBounds = (instantUpdateBounds ==  nil ? deletedDirtyStroke.canvas.path!.boundingBox : instantUpdateBounds!.union(deletedDirtyStroke.canvas.path!.boundingBox))
            
            needRedrawing = true
            deletedDirtyStroke.canvas.removeFromSuperlayer()
            canvasCache.dryStrokes.removeValue(forKey: resultStroke.originalStrokeIndex)
        }
        
        addResultStrokes(strokes: resultStroke.notSelectedResultStrokes, canvasCache.layer!.metalLayer!, fillColor!, index!)
        
        for resultStroke in resultStroke.selectedResultStrokes {
            do {
                try manipulator!.spatialContext!.remove(inkStrokeId: resultStroke.stroke.id)
            } catch let error {
                print("ERROR: \(error)")
            }
        }
    }
}
