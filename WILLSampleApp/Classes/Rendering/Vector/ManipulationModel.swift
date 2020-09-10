//
//  EraseVectorBrushModel.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 7.11.19.
//  Copyright © 2019 Nikolay Atanasov. All rights reserved.
//

import WacomInk

@available(iOS 13.0, *)
class ManipulationModel: VectorBrushModel {
    class CanvasCache {
        class DryStroke {
            public private(set) var canvas: CAShapeLayer
            public var stroke: InkStrokeProtocol
            
            init(canvas: CAShapeLayer, stroke: InkStrokeProtocol) {
                self.canvas = canvas
                self.stroke = stroke
            }
        }
        
        var dryStrokes: [Identifier: DryStroke]
        var layer: Layer?
        
        public init() {
            dryStrokes = [:]
        }
    }
    
    var integrityMode: Manipulator.IntegrityMode = .partial
    var canvasCache = CanvasCache()
    var backgroundColor: UIColor?
    var activeManipulationType: ManipulationType? = nil
    var recostructInkBilder: ManipulationVectorInkBuilder? = nil
    var drawingInkBuilder = ManipulationVectorInkBuilder(collectPointData: true, keepSplineProducerAllData: true)
    var manipulatingInkBuilder = ManipulationVectorInkBuilder(collectPointData: true, PathPointLayout([.x, .y, .alpha, .rotation, .scaleX, .scaleY, .offsetX, .offsetY, .offsetZ]), keepSplineProducerAllData: false)
    
    var spatialContext: SpatialContext? = nil
    var canvas = CAShapeLayer()
    var path: UIBezierPath = UIBezierPath()
    
    var manipulator: Manipulator?
    var uiBezierPathCache: UIBezierPathCache? = nil
    let strokeFactory: InkStrokeFactoryProtocol?
    var isBezierCached: Bool = false
    
    var instantUpdateBounds: CGRect? = nil
    var needRedrawing = false
    
    init(_ pathPointLayout: PathPointLayout? = nil, isCached: Bool = true) {
        if isCached {
            uiBezierPathCache = UIBezierPathCache()
            isBezierCached = true
        }
        
        strokeFactory = WillRendering.InkStrokeFactory()
        spatialContext = SpatialContext()
        manipulator = Manipulator(strokeFactory: strokeFactory!)
        manipulator!.spatialContext = spatialContext
        
        super.init(pathPointLayout)
    }
    
    func toggleWhole() {
        integrityMode = (integrityMode == Manipulator.IntegrityMode.partial ? Manipulator.IntegrityMode.whole : Manipulator.IntegrityMode.partial)
    }
    
    func set(manipulationType: ManipulationType) {
        activeManipulationType = manipulationType
        if activeManipulationType == ManipulationType.draw {
            ink = drawingInkBuilder
            
        } else {
            ink = manipulatingInkBuilder
        }
    }
    
    func getRtreeNodeBounds(bounds: CGRect) -> [CGRect] {
        return manipulator!.spatialContext!.getAllNodesBounds(in: bounds)
    }
    
//    func setDefault(size: Float) {
//        //if let inkBuilder = manipulatingInkBuilder as? RasterInkBuilder
//        manipulatingInkBuilder.setDefault(size: size)
//    }
    
    func addResultStrokes(strokes: [WacomInk.ResultManipulatedStroke.ResultStroke],_ metalLayer: CAMetalLayer,_ fillColor: CGColor?,_ canvasIndex: Int?, isSelected: Bool = false) {
        for resultStroke in strokes {
            
            let stroke = resultStroke.stroke
            initReconstructInkBuilder(stroke)
            
            var addedBezier: UIBezierPath?
            if isBezierCached == true {
                addedBezier = UIBezierPath()
                let (startSpline, cachedPath, endSpline) = resultStroke.cachedUIBezierPath
                if startSpline != nil {
                    if let pathToAdd = recostructInkBilder!.getBezierPathBy(spline: startSpline!) {
                        addedBezier!.append(pathToAdd)
                    }
                }
                
                if cachedPath != nil {
                    addedBezier!.append(cachedPath!)
                }
                
                if endSpline != nil {
                    if let pathToAdd = recostructInkBilder!.getBezierPathBy(spline: endSpline!) {
                        addedBezier!.append(pathToAdd)
                    }
                }
                
                instantUpdateBounds = (instantUpdateBounds ==  nil ? addedBezier!.bounds : instantUpdateBounds!.union(addedBezier!.bounds))
            } else {
                addedBezier = recostructInkBilder?.getBezierPathBy(spline: stroke.spline)
            }
            
            if addedBezier != nil && !addedBezier!.isEmpty {
                let canvas = metalLayer.bounds.createCanvas()
                canvas.path = addedBezier!.cgPath
                canvas.fillColor = fillColor!
                metalLayer.sublayers?.insert(canvas, at: canvasIndex!)
                
                
                
                canvasCache.dryStrokes[resultStroke.stroke.id] = CanvasCache.DryStroke(canvas: canvas,
                                                                                       stroke: resultStroke.stroke)
                
                if isSelected {
                    canvas.fillColor = UIColor(cgColor: fillColor!).withAlphaComponent(min(fillColor!.alpha  * 1.2, 1)).cgColor
                }
            }
        }
    }
    
    func collectPointsFor() {
        if let allDataSpline = drawingInkBuilder.splineProducer!.allData {
            let stroke = WillRendering.InkStroke(
                identifier: Identifier.fromNewUUID(),
                spline: Spline(layoutMask: drawingInkBuilder.splineProducer!.pathLayout.channelMask, path: allDataSpline.path, tStart: allDataSpline.tStart, tFinal: allDataSpline.tFinal),
                layout: drawingInkBuilder.pathPointLayout,
                vectorBrush: drawingInkBuilder.brushApplier.prototype,
                constants: WillRendering.ConstantAttributes(
                    size: drawingInkBuilder.brushApplier.defaultSize,
                    rotation: drawingInkBuilder.brushApplier.defaultRotation,
                    scale: drawingInkBuilder.brushApplier.defaultScale,
                    offset: drawingInkBuilder.brushApplier.defaultOffset)
            )
            
            
            if let strokeIndex = manipulator!.add(stroke: stroke, bezierCache:  isBezierCached ? uiBezierPathCache! : nil) {//spline: spline) {
                canvasCache.dryStrokes[strokeIndex] = CanvasCache.DryStroke(canvas: canvas, stroke: stroke)
            }
        }
    }
    
    private func initReconstructInkBuilder(_ stroke: InkStrokeProtocol) {
        if recostructInkBilder == nil || (
            recostructInkBilder!.brushApplier.prototype != stroke.vectorBrush ||
                recostructInkBilder!.brushApplier.defaultSize != stroke.constants.size ||
                recostructInkBilder!.brushApplier.defaultRotation != stroke.constants.rotation ||
                recostructInkBilder!.brushApplier.defaultScale.x != stroke.constants.scaleX ||
                recostructInkBilder!.brushApplier.defaultScale.y != stroke.constants.scaleY ||
                recostructInkBilder!.brushApplier.defaultScale.z != stroke.constants.scaleZ ||
                recostructInkBilder!.brushApplier.defaultOffset.x != stroke.constants.offsetX ||
                recostructInkBilder!.brushApplier.defaultOffset.y != stroke.constants.offsetY ||
                recostructInkBilder!.brushApplier.defaultOffset.z != stroke.constants.offsetZ ||
                recostructInkBilder!.pathPointLayout != stroke.layout
            ) {
            recostructInkBilder = ManipulationVectorInkBuilder(
                collectPointData: true, 
                stroke.layout,
                brushPrototype: stroke.vectorBrush,
                defaultSize: stroke.constants.size,
                defaultRotation: stroke.constants.rotation,
                defaultScale: DIFloat3(stroke.constants.scaleX, stroke.constants.scaleY, stroke.constants.scaleZ),
                defaultOffset: DIFloat3(stroke.constants.offsetX, stroke.constants.offsetY, stroke.constants.offsetZ),
                keepSplineProducerAllData: true)
        }
    }
    
    override func renderDryStroke(_ renderingContext: RenderingContext, dryStroke: DryStroke) {
        assert(false, "Dry stroke is rendering without RedrawController redraw engine.")
    }
}
