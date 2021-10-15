//
//  SelectVectorBrushModel.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 12.11.19.
//  Copyright © 2019 Nikolay Atanasov. All rights reserved.
//

import WacomInk

@available(iOS 13.0, *)
class SelectionModel: ManipulationModel {
    private var selectCanvas = CAShapeLayer()
    private var selectedContour: DIPolygon? = nil
    
    init(backgroundColor: UIColor, isCached: Bool,_ pathPointLayout: PathPointLayout? = nil) {
        super.init(pathPointLayout, isCached: isCached)
        
        self.backgroundColor = backgroundColor
        manipulatingInkBuilder = ManipulationVectorInkBuilder(collectPointData: true, PathPointLayout([.x, .y]), keepSplineProducerAllData: true)
        //manipulatingInkBuilder.setDefault(size: 1)
    }
  
    func clearSelectCanvas() {
        instantUpdateBounds = nil
        selectedContour = nil
        selectCanvas.removeFromSuperlayer()
    }
    
    override func touchesBeganBody() {
        path = UIBezierPath()
        if activeManipulationType == ManipulationType.select {
            clearSelectCanvas()
            selectCanvas = canvasCache.layer!.rect!.createCanvas()
            selectCanvas.path = path.cgPath
            inkColor = UIColor.randomFromArray()
            selectCanvas.fillColor = inkColor.cgColor
            instantUpdateBounds = nil
            canvasCache.layer!.metalLayer!.addSublayer(selectCanvas)
        } else {
            if isBezierCached { uiBezierPathCache!.startBezierPathCacheCollecting()
            }
            
            canvas = canvasCache.layer!.rect!.createCanvas()
            canvas.path = path.cgPath
            inkColor = UIColor.random().withAlphaComponent(0.5)
            canvas.fillColor = inkColor.cgColor
            instantUpdateBounds = nil
            canvasCache.layer!.metalLayer!.addSublayer(canvas)
        }
    }
    
    override func touchesEndedBody() {
        if activeManipulationType == ManipulationType.select {
            let spline = manipulatingInkBuilder.splineProducer!.allData
            
            if let indexX = manipulatingInkBuilder.splineInterpolator?.interpolatedSplineLayout?.indexOf(property: .x),
               let indexY = manipulatingInkBuilder.splineInterpolator?.interpolatedSplineLayout?.indexOf(property: .y) {
                do {
                    if let stride = try manipulatingInkBuilder.splineProducer?.getDimsCount() {
                        var offsetIndex = 0
                        assert(spline!.path.count % stride == 0)
                        let steps = spline!.path.count / stride
                        if steps > 0 {
                            selectedContour = []
                            for _ in 0..<steps {
                                selectedContour!.append(DIPoint2(spline!.path[offsetIndex + indexX], spline!.path[offsetIndex + indexY]))
                                offsetIndex = offsetIndex + stride
                            }
                            
                            instantUpdateBounds =  nil
                            instantUpdateBounds = path.bounds
                            
                            var generatedPath: UIBezierPath?
                            generateBezierPolys([selectedContour!], result: &generatedPath)
                            path = generatedPath ?? UIBezierPath()
                            selectCanvas.path = (path.copy() as! UIBezierPath).cgPath
                            
                            instantUpdateBounds = (instantUpdateBounds ==  nil ? selectCanvas.path!.boundingBox : instantUpdateBounds!.union(selectCanvas.path!.boundingBox))
                        }
                    } else {
                        print("Couldn't get stride")
                    }
                } catch let error {
                    print("ERROR: \(error)")
                }
            }
        } else {
            collectPointsFor()
        }
    }
    
    override func drawingAddedPath(renderingContext: RenderingContext) throws {
        if activeManipulationType == ManipulationType.draw {
            if isBezierCached {
                uiBezierPathCache?.addBezierPathCache(for: addedPath, controlPointsCount: drawingInkBuilder.splineProducer!.allData!.path.count)
                //drawingInkBuilder.splineProducer!.allData.path.count
               //uiBezierPathCache!.addBezierPathCache(for: addedPath, drawingSplineProducer: drawingInkBuilder.splineProducer!)
            }
        }
        
        if addedPath != nil && !addedPath!.cgPath.isEmpty {
            path.append(addedPath!)
            
            let copyPath: UIBezierPath? = path.copy() as? UIBezierPath
            
            if activeManipulationType == ManipulationType.select {
                selectCanvas.path = copyPath?.cgPath
            } else {
                canvas.path = copyPath?.cgPath
            }
        }
        
        try super.drawingAddedPath(renderingContext: renderingContext)
    }
    
    override func set(manipulationType: ManipulationType) {
        super.set(manipulationType: manipulationType)
        if manipulationType == ManipulationType.draw {
            clearSelectCanvas()
        }
    }
    
    func select() -> Bool {
        if selectedContour == nil {
            return false
        }
        else {
            do {
                try manipulator!.select(points: selectedContour!, integrityMode, .bilateralOverlap, isBezierCached: isBezierCached, onStrokeSelected: selectCallback)
                clearSelectCanvas()
            } catch let error {
                print("ERROR: \(error)")
            }
        }
        
        return true
    }
    
    func selectCallback(_ resultStroke: ResultManipulatedStroke) {
        var index: Int? = nil
        var fillColor: CGColor? = nil

        if let deletedDirtyStroke = canvasCache.dryStrokes[resultStroke.originalStrokeIndex] {
           instantUpdateBounds = (instantUpdateBounds ==  nil ? deletedDirtyStroke.canvas.path!.boundingBox : instantUpdateBounds!.union(deletedDirtyStroke.canvas.path!.boundingBox))
            if integrityMode == Manipulator.IntegrityMode.whole {
               deletedDirtyStroke.canvas.fillColor = selectCanvas.fillColor!
           } else {
               index = canvasCache.layer!.metalLayer!.sublayers!.firstIndex(of: deletedDirtyStroke.canvas)
               fillColor = deletedDirtyStroke.canvas.fillColor
                canvasCache.dryStrokes.removeValue(forKey: resultStroke.originalStrokeIndex)
               deletedDirtyStroke.canvas.removeFromSuperlayer()
               canvasCache.dryStrokes.removeValue(forKey: resultStroke.originalStrokeIndex)
           }
        }

        if integrityMode == Manipulator.IntegrityMode.partial {
            addResultStrokes(strokes: resultStroke.notSelectedResultStrokes, canvasCache.layer!.metalLayer!, fillColor, index)
            addResultStrokes(strokes: resultStroke.selectedResultStrokes, canvasCache.layer!.metalLayer!, selectCanvas.fillColor, index, isSelected: true)
        }
    }
}
