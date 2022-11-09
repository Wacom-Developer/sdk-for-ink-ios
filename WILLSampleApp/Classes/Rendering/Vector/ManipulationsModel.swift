//
//  UnifiedEraseControllerImpl.swift
//  WILLSampleApp
//
//  Created by Mincho Dzhagalov on 8.07.22.
//  Copyright © 2022 Mincho Dzhagalov. All rights reserved.
//

import Foundation
import WacomInk

extension CGPath {
    func forEach( body: @escaping @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }
    func getPathElementsPoints() -> [CGPoint] {
        var arrayPoints : [CGPoint]! = [CGPoint]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
            default: break
            }
        }
        return arrayPoints
    }
    func getPathElementsPointsAndTypes() -> ([CGPoint],[CGPathElementType]) {
        var arrayPoints : [CGPoint]! = [CGPoint]()
        var arrayTypes : [CGPathElementType]! = [CGPathElementType]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
                arrayTypes.append(element.type)
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
                arrayTypes.append(element.type)
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
            default: break
            }
        }
        return (arrayPoints,arrayTypes)
    }
}


class ManipulationsModel {
    class DryStroke {
        public private(set) var canvas: CAShapeLayer
        public var stroke: InkStrokeProtocol
        
        init(canvas: CAShapeLayer, stroke: InkStrokeProtocol) {
            self.canvas = canvas
            self.stroke = stroke
        }
    }
    
    var applicationModel: ApplicationModel!
    var inkColor = UIColor.gray
    var m_spatialModel: SpatialModel = SpatialModel()
    var m_erasePartManipulation: EraseStrokePartManipulation?
    var m_eraseWholeManipulation: EraseWholeStrokeManipulation?
    var backgroundColor = UIColor.white
    var selectedManipulationType: ManipulationType? = nil
    
    private var selectCanvas = CAShapeLayer()
    
    var selectedSpline: Spline? = nil
    private var selectedContour: DIPolygon? = nil
    
    var translateX: CGFloat? = 0
    var translateY: CGFloat? = 0
    var previousX: CGFloat? = nil
    var previousY: CGFloat? = nil
    var dx: CGFloat? = nil
    var dy: CGFloat? = nil
    
    private var recostructInkBilder: SampleVectorInkBuilder? = nil
    private var currentInkBuilder: SampleVectorInkBuilder? = nil
    private var drawingInkBuilder = try! SampleVectorInkBuilder()
    private var intersectingInkBuilder = try! SampleVectorInkBuilder()
    private var selectingInkBuilder = try! SampleVectorInkBuilder()
    
    private let polygonSimplifier = PolygonSimplifier(epsilon: 0.1)
    private let bezierPathProducer = PolygonToBezierPathProducer()
    private var mergedToBezierPipeline: InkPipeline?
    private let reconstructPolygonSimplifier = PolygonSimplifier(epsilon: 0.1)
    private let reconstructBezierPathProducer = PolygonToBezierPathProducer()
    private var reconstructInkPipeline: InkPipeline?

    var integrityMode: Manipulator.IntegrityMode = Manipulator.IntegrityMode.partial
    var isErasing = true
    private var canvas = CAShapeLayer()
    private var path: UIBezierPath = UIBezierPath()
    private var selectContourCenter: (CGFloat, CGFloat)? = nil
    
    private let strokeFactory: InkStrokeFactoryProtocol?
    
    var m_selectPartManipulation: SelectStrokePartManipulation?
    var m_selectWholeManipulation: SelectWholeStrokeManipulation?
    var selectedTransformationType: TransformationType? = .move
    
    var accumulateRotation: CGFloat = 0
    var previousRotation: CGFloat = 0
    var dRotation: CGFloat = 0
    
    var selectedStrokeIndexes: [Identifier] = []
    var hasSelection: Bool {
        return selectedStrokeIndexes.count > 0
    }
    
    init() throws {
        applicationModel = ApplicationModel()
        
        m_spatialModel = SpatialModel()
        
        m_selectPartManipulation = SelectStrokePartManipulation(spatialModel: &m_spatialModel)
        m_selectWholeManipulation = SelectWholeStrokeManipulation(spatialModel: &m_spatialModel)
        
        m_erasePartManipulation = EraseStrokePartManipulation(spatialModel: &m_spatialModel)
        m_eraseWholeManipulation = EraseWholeStrokeManipulation(spatialModel: &m_spatialModel)
        
        drawingInkBuilder = try! SampleVectorInkBuilder()
        intersectingInkBuilder = try! SampleVectorInkBuilder()
        selectingInkBuilder = try! SampleVectorInkBuilder()
        selectingInkBuilder.brushApplier.defaultSize = 1
        
        strokeFactory = Quartz2D.InkStrokeFactory()
    }
    
    func set(manipulationType: ManipulationType) {
        selectedManipulationType = manipulationType
        if selectedManipulationType == .draw {
            clearSelectCanvas(saveStrokeIndexes: false)
            currentInkBuilder = drawingInkBuilder
        } else if selectedManipulationType == .intersect {
            clearSelectCanvas(saveStrokeIndexes: false)
            currentInkBuilder = intersectingInkBuilder
        } else if selectedManipulationType == .select {
            currentInkBuilder = selectingInkBuilder
        }
        
        currentInkBuilder?.dynamicInkPipeline.reset()
        polygonSimplifier.setDataProvider(dataProvider: currentInkBuilder!.polygonMerger)
        bezierPathProducer.setDataProvider(dataProvider: polygonSimplifier)
        mergedToBezierPipeline = try! InkPipeline(inputStage: currentInkBuilder!.polygonMerger, outputStage: bezierPathProducer)
    }
    
    func set(transformationType: TransformationType) {
        selectedTransformationType = transformationType
    }
    
    func getAllNodes(bounds: CGRect) -> [CGRect] {
        return m_spatialModel.getAllNodesBounds(in: bounds)
    }
    
    func setDefault(size: Float) {
        intersectingInkBuilder.brushApplier.defaultSize = size
    }
    
    func toggleWholeStroke() {
        integrityMode = (integrityMode == Manipulator.IntegrityMode.partial ? Manipulator.IntegrityMode.whole : Manipulator.IntegrityMode.partial)
    }
    
    func toggleIsErasing() {
        isErasing = !isErasing
    }
    
    var testDefaultSize: Float = 5
    
    func removeAll(view: UIView) {
        applicationModel.strokes.removeAll()

        for sublayer in view.layer.sublayers! {
            if sublayer is CAShapeLayer {
                sublayer.removeFromSuperlayer()
            }
        }
    }

    func hasRasterInk(url: URL) -> Bool {
        return applicationModel.hasRasterInk(url: url)
    }
    
    func load(url: URL, viewLayer: CALayer) throws {
        if let loadedApplicationModel = applicationModel.read(from: url), let addedApplicationStrokes = loadedApplicationModel.strokes.values {
            resetApplicationModel(by: loadedApplicationModel)
            try addCanvasesAndRTreeFor(applicationStrokes: addedApplicationStrokes,in: viewLayer)
        }
    }
    
    private func resetApplicationModel(by resetModel: ApplicationModel) {
        m_spatialModel = SpatialModel()
        m_erasePartManipulation = EraseStrokePartManipulation(spatialModel: &m_spatialModel)
        m_eraseWholeManipulation = EraseWholeStrokeManipulation(spatialModel: &m_spatialModel)
        m_selectPartManipulation = SelectStrokePartManipulation(spatialModel: &m_spatialModel)
        m_selectWholeManipulation = SelectWholeStrokeManipulation(spatialModel: &m_spatialModel)
        
        applicationModel.removeCanvases()
        applicationModel = resetModel
    }
    
    private func addCanvasesAndRTreeFor(applicationStrokes: [ApplicationStroke],in viewLayer: CALayer) throws {
        for appStroke in applicationStrokes {
            if appStroke.inkStroke.spline.path.count > 0 {
                try initReconstructInkBuilder(appStroke.inkStroke, touchType: appStroke.touchType)

                try addStroke(inkStroke: appStroke.inkStroke, updateBezierCache: true)

                if let canvas = getCanvas(by: appStroke.inkStroke, viewLayer: viewLayer) {
                    appStroke.canvas = canvas
                }
            }
        }
    }
    
    private func getCanvas(by inkStroke: Quartz2D.InkStroke, viewLayer: CALayer) -> CAShapeLayer? {
        try! recostructInkBilder?.getBezierPathBy(spline: inkStroke.spline, inkPipeline: reconstructInkPipeline!)
        
        if let path = try! reconstructBezierPathProducer.getAddition() {
            let canvas = viewLayer.bounds.createCanvas()
            canvas.path = path.cgPath
            canvas.fillColor = UIColor(red: CGFloat(inkStroke.constants.red), green: CGFloat(inkStroke.constants.green), blue: CGFloat(inkStroke.constants.blue), alpha: CGFloat(inkStroke.constants.alpha)).cgColor
            viewLayer.addSublayer(canvas)
            return canvas
        } else {
            return nil
        }
    }
    
    private func addStroke(inkStroke: InkStrokeProtocol, updateBezierCache: Bool) throws {
        try m_spatialModel.tryAdd(stroke: inkStroke)
    }
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, view: UIView) {
        path = UIBezierPath()
        
        do {
            if selectedManipulationType == ManipulationType.select {
                selectingInkBuilder.splineAccumulator.reset()

                if hasSelection {
                    previousX = (touches.first!).location(in: view).x
                    previousY = (touches.first!).location(in: view).y
                    dx = 0
                    dy = 0
                    translateX = 0
                    translateY = 0
                } else {
                    clearSelectCanvas(saveStrokeIndexes: true)
                    selectCanvas = view.layer.bounds.createCanvas()
                    selectCanvas.path = path.cgPath
                    selectCanvas.fillColor = UIColor.clear.cgColor
                    selectCanvas.strokeColor = UIColor.black.cgColor
                    selectCanvas.lineWidth = 2
                    selectCanvas.lineJoin = CAShapeLayerLineJoin.round
                    selectCanvas.lineDashPattern = [6,3]
                    view.layer.addSublayer(selectCanvas)
                }
            }
            
            let selectedTool = ToolPalette.shared.selectedVectorTool
            let inputType = touches.first!.type
            
            guard let layout = selectedTool?.getLayout(inputType: inputType) else {
                return
            }
            
            guard let calculator = selectedTool?.getCalculator(inputType: inputType) else {
                return
            }
            
            guard let brush = selectedTool?.brush() else {
                return
            }

            try currentInkBuilder?.updateVectorInkPipeline(layoutMask: layout, calculator: calculator, brush: brush.vectorBrush)
            //currentInkBuilder?.updatePipeline(layout: layout, calculator: calculator, brush: brush) // TODO: vector brush doesn't have name
            
            canvas = view.layer.bounds.createCanvas()
            canvas.path = path.cgPath
            view.layer.addSublayer(canvas)
            
            canvas.fillColor = selectedManipulationType == ManipulationType.intersect ? backgroundColor.cgColor : inkColor.cgColor
            
            try renderNewStroke(phase: .begin, touches, event: event, view: view)
        } catch {
            NSException(name:NSExceptionName(rawValue: "UnifiedEraseControllerImpl.touchesBegan"), reason:"\(error)", userInfo:nil).raise()
        }
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, view: UIView) {
        do {
            try renderNewStroke(phase: .update, touches, event: event, view: view)
        } catch {
            NSException(name:NSExceptionName(rawValue: "UnifiedEraseControllerImpl.touchesMoved"), reason:"\(error)", userInfo:nil).raise()
        }
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, view: UIView) {
        do {
            try renderNewStroke(phase: .end, touches, event: event, view: view)
                        
            if selectedManipulationType == .draw {
                //try! storeCurrentStroke(touches.first!.type)
                try collectPointsFor(sourceSpline: drawingInkBuilder.splineAccumulator.accumulated, touchType: touches.first!.type)
            } else if selectedManipulationType == .intersect {
                canvas.removeFromSuperlayer()
            } else if selectedManipulationType == .select {
                if hasSelection {
                    if selectedTransformationType == TransformationType.move {
                        try update(CGAffineTransform(translationX: translateX!, y: translateY!))
                    }
                    
                    //selectingInkBuilder.pointerDataProvider.reset()
                } else {
                    selectedSpline = selectingInkBuilder.splineAccumulator.accumulated
                    do {
                        try onEndSelect()
                    } catch {
                        NSException(name:NSExceptionName(rawValue: "ManipulationsQaurtz2DControllerImpl.touchesEnded"), reason:"\(error)", userInfo:nil).raise()
                    }
                }
            }
        } catch {
            NSException(name:NSExceptionName(rawValue: "UnifiedEraseControllerImpl.touchesEnded"), reason:"\(error)", userInfo:nil).raise()
        }
        
    }
    
    private func storeCurrentStroke(_ touchType: UITouch.TouchType) throws {
        let allDataSpline = currentInkBuilder!.splineAccumulator.accumulated
        let stroke = Quartz2D.InkStroke(
            identifier: Identifier.fromNewUUID()!,
            spline: allDataSpline.copy() as! Spline,
            vectorBrush: try currentInkBuilder!.brushApplier.getPrototype(),
            constants: Quartz2D.ConstantAttributes(
                size: currentInkBuilder!.brushApplier.defaultSize,
                rotation: currentInkBuilder!.brushApplier.defaultRotation,
                scale: currentInkBuilder!.brushApplier.defaultScale,
                offset: currentInkBuilder!.brushApplier.defaultOffset,
                colorRGBA: UIColor(cgColor: canvas.fillColor!).rgba
            )
        )
        
        applicationModel.addStroke(ApplicationStroke(canvas: canvas, inkStroke: stroke, touchType: touchType), sensorPointerData: currentInkBuilder?.getPointerDataList())
    }
        
    func rotateBegan(_ sender: UIRotationGestureRecognizer) {
        if selectedTransformationType == TransformationType.rotate {
            accumulateRotation = 0
            previousRotation = 0
            
            updateRotatePerFrame(sender)
        }
    }
    
    func rotateMoved(_ sender: UIRotationGestureRecognizer) {
        if selectedTransformationType == TransformationType.rotate {
            updateRotatePerFrame(sender)
        }
    }
    
    func rotateEnded(_ sender: UIRotationGestureRecognizer) throws {
        if selectedTransformationType == TransformationType.rotate {
            updateRotatePerFrame(sender)
            try update(rotateAffineTransformByAngle(accumulateRotation), rotate: true)
        }
    }
    
    private func update(_ affineTransform: CGAffineTransform, rotate: Bool = false) throws {
        let transform = AffineTransform()
        transform.set(affineTransform)
        let newSelectedContourCenter = transform.matrix! * DIFloat4(
            Float(selectContourCenter!.0),
            Float(selectContourCenter!.1),
            0,
            1
        )
        selectContourCenter = (CGFloat(newSelectedContourCenter.x), CGFloat(newSelectedContourCenter.y))
        
        for selectedStrokeIndex in selectedStrokeIndexes {
            let dryStroke = applicationModel.strokes[selectedStrokeIndex]
            let allDataSpline = try Spline(path: dryStroke!.inkStroke.spline.path, tStart: dryStroke!.inkStroke.spline.tStart, tFinal: dryStroke!.inkStroke.spline.tFinal)
            
            let layoutMask = dryStroke!.inkStroke.layoutMask
            let stride = layoutMask.count
            // start transform
            let indexX = layoutMask.getChannelIndex(property: .x)!
            let indexY = layoutMask.getChannelIndex(property: .y)!
            let indexRotation = layoutMask.getChannelIndex(property: .rotation)
            var offsetIndex = 0
            
            if (allDataSpline.path.count % stride != 0) {
                throw RuntimeError("ManipulationsQaurtz2DControllerImpl.update")
            }
            
            let steps = allDataSpline.path.count / stride
            
            if steps > 0 {
                for _ in 0..<steps {
                    let result = transform.matrix! * DIFloat4(
                        allDataSpline.path.getX(pointStartIndex: offsetIndex, channelIndex: indexX),
                        allDataSpline.path.getY(pointStartIndex: offsetIndex, channelIndex: indexY),
                        0,
                        1
                    )
                    allDataSpline.path[offsetIndex + indexX] = result.x
                    allDataSpline.path[offsetIndex + indexY] = result.y
                    if rotate && indexRotation != nil {
                        allDataSpline.path[offsetIndex + indexRotation!] = allDataSpline.path[offsetIndex + indexRotation!] + Float(accumulateRotation)
                    }
                    offsetIndex = offsetIndex + stride
                }
                
                let spline = try Spline(path: allDataSpline.path, tStart: allDataSpline.tStart, tFinal: allDataSpline.tFinal)
                
                if rotate && indexRotation == nil {
                    let constants: Quartz2D.ConstantAttributes = dryStroke!.inkStroke.constants as! Quartz2D.ConstantAttributes
                    constants.rotation = constants.rotation + Float(accumulateRotation)
                    dryStroke!.inkStroke.constants = constants//Quartz2D.ConstantAttributes()
                }
                
                try initReconstructInkBuilder(dryStroke!.inkStroke, touchType: dryStroke?.touchType)
                
                try recostructInkBilder?.getBezierPathBy(spline: allDataSpline, inkPipeline: reconstructInkPipeline!)
                
                if let addedBezier = try reconstructBezierPathProducer.getAddition() {
                    if !addedBezier.isEmpty {
                        dryStroke!.canvas!.path = addedBezier.cgPath
                    }
                }
                m_spatialModel.remove(stroke: dryStroke!.inkStroke)
                dryStroke!.inkStroke = strokeFactory!.createStroke(spline, dryStroke!.inkStroke, inkStrokeId: dryStroke!.inkStroke.id, firstPointIndex: 0, pointsCount: 0) as! Quartz2D.InkStroke
               
                try m_spatialModel.tryAdd(stroke: dryStroke!.inkStroke)
            }
        }
    }
    
    private func onEndSelect() throws {
        let indexX = selectingInkBuilder.splineInterpolator.interpolatedSplineLayout!.getChannelIndex(property: .x)
        let indexY = selectingInkBuilder.splineInterpolator.interpolatedSplineLayout!.getChannelIndex(property: .y)!
        let stride = selectedSpline!.layoutMask.count
        var offsetIndex = 0
        
        if selectedSpline!.path.count % stride != 0 {
            throw RuntimeError("ManipulationsQaurtz2DControllerImpl.onEndSelect() selectedSpline!.path.count % stride != 0")
        }
        
        let steps = selectedSpline!.path.count / stride
        if steps > 0 {
            selectedContour = []
            var sumX: Float = 0
            var sumY: Float = 0
            for _ in 0..<steps {
                let x = selectedSpline!.path.getX(pointStartIndex: offsetIndex, channelIndex: indexX)
                let y = selectedSpline!.path.getX(pointStartIndex: offsetIndex, channelIndex: indexY)
                selectedContour!.append(DIPoint2(x, y))
                sumX = sumX + x
                sumY = sumY + y
                offsetIndex = offsetIndex + stride
            }
            
            selectContourCenter = (CGFloat(sumX / Float(steps)), CGFloat(sumY / Float(steps)))
            var result: UIBezierPath?
            generateBezierPolys([selectedContour!], result: &result)
            
            selectCanvas.path = (result!.copy() as! UIBezierPath).cgPath
        }
    }
    
    private func renderNewStroke(phase: Phase, _ touches: Set<UITouch>, event: UIEvent?, view: UIView) throws {
        currentInkBuilder!.pointerDataProvider.add(phase: phase, touches: touches, event: event!, view: view)
        
        if selectedManipulationType == ManipulationType.select {
            if hasSelection {
                if selectedTransformationType == TransformationType.move {
                    let location = touches.first!.location(in: view)
                    dx = location.x - previousX!
                    dy = location.y - previousY!
                    previousX = location.x
                    previousY = location.y
                    translateX = translateX! + dx!
                    translateY = translateY! + dy!
                    
                    applyTransformationToView(CGAffineTransform(translationX: dx!, y: dy!))
                }
                
                selectingInkBuilder.pointerDataProvider.reset()
                
                return
            }
        }
        
        if currentInkBuilder!.hasNewPoints {
            let polygons = try currentInkBuilder?.getCurrentPolygons()
            
            mergedToBezierPipeline?.reset()
            try mergedToBezierPipeline?.process()
            let addition = try bezierPathProducer.getAddition()
            
            let prediction = try bezierPathProducer.getPrediction()
                
            if addition == nil || addition!.cgPath.isEmpty {
                return
            }
            
            if selectedManipulationType == .select {
                if addition == nil || addition!.cgPath.isEmpty {
                    return
                }
                
                path.append(addition!)
                
                let copyPath: UIBezierPath? = path.copy() as? UIBezierPath
                
                if !hasSelection {
                    selectCanvas.path = copyPath?.cgPath
                }
            } else if selectedManipulationType == ManipulationType.intersect {
                if let spline = try currentInkBuilder?.splineProducer.getAddition() {
                    let erasedStroke = Quartz2D.InkStroke(
                        identifier: Identifier.fromNewUUID()!,
                        spline: spline,
                        vectorBrush: try intersectingInkBuilder.brushApplier.getPrototype(),
                        constants: Quartz2D.ConstantAttributes(
                            size: intersectingInkBuilder.brushApplier.defaultSize,
                            rotation: intersectingInkBuilder.brushApplier.defaultRotation,
                            scale: intersectingInkBuilder.brushApplier.defaultScale,
                            offset: intersectingInkBuilder.brushApplier.defaultOffset,
                            colorRGBA: UIColor(cgColor: canvas.fillColor!).rgba)
                    )
                    
                    if integrityMode == .whole {
                        try m_eraseWholeManipulation!.eraseQuery(eraserStroke: erasedStroke)
                        var it =  m_eraseWholeManipulation!.getIterator()
                        var canvasIndex: Int? = nil
                        var fillColor: CGColor? = nil
                        
                        while let resItem = it.next() {
                            let stroke2Delete = resItem.value
                            
                            m_spatialModel.remove(stroke: stroke2Delete)
                            
                            if let deletedDirtyStroke = applicationModel.strokes[stroke2Delete.id] {
                                canvasIndex = view.layer.sublayers!.firstIndex(of: deletedDirtyStroke.canvas!)
                                fillColor = deletedDirtyStroke.canvas!.fillColor
                                deletedDirtyStroke.canvas!.removeFromSuperlayer()
                                applicationModel.strokes.remove(key: stroke2Delete.id)
                            }
                        }
                    } else {
                        try m_erasePartManipulation?.eraseQuery(eraserStroke: erasedStroke)
                        var it =  m_erasePartManipulation?.result.getIterator()
                        var canvasIndex: Int? = nil
                        var fillColor: CGColor? = nil
                        while let resItem = it!.next() {
                            let stroke2Delete = resItem.value.0
                            m_spatialModel.remove(stroke: stroke2Delete)
                            var it = resItem.value.1.makeIterator()
                            
                            if let deletedDirtyStroke = applicationModel.strokes[stroke2Delete.id] {
                                canvasIndex = view.layer.sublayers!.firstIndex(of: deletedDirtyStroke.canvas!)
                                fillColor = deletedDirtyStroke.canvas!.fillColor
                                deletedDirtyStroke.canvas!.removeFromSuperlayer()
                                applicationModel.strokes.remove(key: stroke2Delete.id)
                                
                                while let fragment = it.next() {
                                    var newStroke = Quartz2D.InkStroke(
                                        identifier: Identifier.fromNewUUID()!,
                                        spline: try Spline(path: stroke2Delete.spline.path.getPart(firstPointIndex: fragment.beginPointIndex, pointsCount: fragment.pointsCount), tStart: fragment.ts, tFinal: fragment.tf),
                                        vectorBrush: stroke2Delete.vectorBrush,
                                        constants: stroke2Delete.constants as! Quartz2D.ConstantAttributes
                                    )
                                    
                                    try m_spatialModel.tryAdd(stroke: newStroke)
                                    
                                    try initReconstructInkBuilder(newStroke, touchType: touches.first?.type)
                                    
                                    try recostructInkBilder!.getBezierPathBy(spline: newStroke.spline, inkPipeline: reconstructInkPipeline!)
                                    
                                    let addedBezier: UIBezierPath? = try reconstructBezierPathProducer.getAddition()
                                    
                                    if addedBezier != nil && !addedBezier!.isEmpty {
                                        let canvas = view.layer.bounds.createCanvas()
                                        canvas.path = addedBezier!.cgPath
                                        canvas.fillColor = fillColor!
                                        view.layer.sublayers?.insert(canvas, at: canvasIndex!)
                                        
                                        applicationModel.strokes[newStroke.id] = ApplicationStroke(canvas: canvas, inkStroke: newStroke, touchType: touches.first!.type)
                                    }
                                }
                            }
                            else {
                                throw RuntimeError("dryStrokes doesn't contain stroke which is selected")
                            }
                        }
                    }
                }
            }
            
            if selectedManipulationType != .select {
                path.append(addition!)
                
                let copyPath: UIBezierPath? = path.copy() as? UIBezierPath
                
                if prediction != nil {
                    copyPath!.append(prediction!)
                }
                    
                canvas.path = copyPath?.cgPath
            }
        }
        
        mergedToBezierPipeline?.reset()
    }
    
    func clearSelectCanvas(saveStrokeIndexes: Bool = false) {
        selectedSpline = nil
        selectedContour = nil
        selectContourCenter = nil
        selectCanvas.removeFromSuperlayer()
        if saveStrokeIndexes == false {
            selectedStrokeIndexes = []
        }
    }

    func onSelectButton(view: UIView) throws -> Bool {
        if hasSelection {
            clearSelectCanvas()
            return true
        }
        else {
            if selectedSpline == nil {
                return false
            }
            
            selectedStrokeIndexes = []
            if integrityMode == .whole {
                try m_selectWholeManipulation!.selectQuery(selection: SelectionContours.fromPath(selectorPath: selectedSpline!.path.toPolygon()))
               
                var it = m_selectWholeManipulation!.getIterator()
                while let resItem = it.next() {
                    selectedStrokeIndexes.append(resItem.value.id)
                }
            } else {
            
                try m_selectPartManipulation!.selectQuery(selection: SelectionContours.fromPath(selectorPath: selectedSpline!.path.toPolygon()))
                
                var it =  m_selectPartManipulation!.result.getIterator()
                var canvasIndex: Int? = nil
                var fillColor: CGColor? = nil
                while let resItem = it.next() {
                    let stroke2Delete = resItem.value.0
                    m_spatialModel.remove(stroke: stroke2Delete)
                    var it = resItem.value.1.makeIterator()
                    
                    if let deletedDirtyStroke = applicationModel.strokes[stroke2Delete.id] {
                        canvasIndex = view.layer.sublayers!.firstIndex(of: deletedDirtyStroke.canvas!)
                        fillColor = deletedDirtyStroke.canvas!.fillColor
                        deletedDirtyStroke.canvas!.removeFromSuperlayer()
                        
                        var previousSplineFragment: SplineFragment? = nil
                        
                        while let item = it.next() {
                            if item.isInsideSelection && !item.isOverlapped {
                                if let previousSplineFrag = previousSplineFragment {
                                    try addStroke(canvasIndex: canvasIndex!, fillColor: fillColor!, view: view, stroke2Delete: stroke2Delete as! Quartz2D.InkStroke, splineFragment: previousSplineFrag, isInside: false, touchType: deletedDirtyStroke.touchType!)
                                }
                                
                                
                                previousSplineFragment = item.fragment
                            
                                try addStroke(canvasIndex: canvasIndex!, fillColor: fillColor!, view: view, stroke2Delete: stroke2Delete as! Quartz2D.InkStroke, splineFragment: previousSplineFragment!, isInside: true, touchType: deletedDirtyStroke.touchType!)
                            
                                previousSplineFragment = nil
                            }
                            else {
                                if previousSplineFragment == nil {
                                    previousSplineFragment = item.fragment
                                } else {
                                    let currentFragment = item.fragment
                                    if currentFragment.beginPointIndex < previousSplineFragment!.endPointIndex || (
                                        currentFragment.beginPointIndex == previousSplineFragment!.endPointIndex && currentFragment.ts <= previousSplineFragment!.tf ){
                                        var pEndIndex = previousSplineFragment!.endPointIndex
                                        var pTf = previousSplineFragment!.tf

                                        if currentFragment.endPointIndex > previousSplineFragment!.endPointIndex {
                                            pEndIndex = currentFragment.endPointIndex
                                            pTf = currentFragment.tf
                                        } else if currentFragment.endPointIndex == previousSplineFragment!.endPointIndex {
                                            pTf = currentFragment.tf
                                        }

                                        previousSplineFragment = SplineFragment(beginPointIndex: previousSplineFragment!.beginPointIndex, endPointIndex: pEndIndex, ts: previousSplineFragment!.ts, tf: pTf)
                                    }
                                    
                                    else {
                                        try addStroke(canvasIndex: canvasIndex!, fillColor: fillColor!,  view: view, stroke2Delete: stroke2Delete as! Quartz2D.InkStroke, splineFragment: previousSplineFragment!, isInside: false, touchType: deletedDirtyStroke.touchType!)
                                        
                                        previousSplineFragment = currentFragment
                                    }
                                }
                            }
                        }
                        
                        if let previousSplineFragment = previousSplineFragment {
                            try addStroke(canvasIndex: canvasIndex!, fillColor: fillColor!, view: view, stroke2Delete: stroke2Delete as! Quartz2D.InkStroke, splineFragment: previousSplineFragment, isInside: false, touchType: deletedDirtyStroke.touchType!)
                        }
                        
                        applicationModel.strokes.remove(key: stroke2Delete.id)
                    }
                    else {
                        throw RuntimeError("dryStrokes doesn't contain stroke which is selected")
                    }
                }
            }
            return true
        }
    }
    
    func save(_ url: URL) throws {
        try applicationModel.write(to: url)
    }
    
    func savePDF(_ url: URL) throws {
        try applicationModel.writePDF(to: url)
    }
    
    func saveSVG(_ url: URL) throws {
        try applicationModel.writeSVG(to: url)
    }
    
    func savePNG(_ url: URL) throws {
        try applicationModel.writePNG(to: url)
    }
    
    func selectPen(inputType: UITouch.TouchType) {
        ToolPalette.shared.selectedVectorTool = ToolPalette.shared.pen
        
        updatePipelineForSelectedTool(inputType: inputType)
    }
    
    func selectFelt(inputType: UITouch.TouchType) {
        ToolPalette.shared.selectedVectorTool = ToolPalette.shared.felt
        
        updatePipelineForSelectedTool(inputType: inputType)
    }
    
    func selectBrush(inputType: UITouch.TouchType) {
        ToolPalette.shared.selectedVectorTool = ToolPalette.shared.brush
        
        updatePipelineForSelectedTool(inputType: inputType)
    }
    
    func selectPartialStrokeEraser(inputType: UITouch.TouchType) {
        ToolPalette.shared.selectedVectorTool = ToolPalette.shared.partialStrokeEraser
        
        updatePipelineForSelectedTool(inputType: inputType)
    }
    
    func selectWholeStrokeEraser(inputType: UITouch.TouchType) {
        ToolPalette.shared.selectedVectorTool = ToolPalette.shared.wholeStrokeEraser
        
        updatePipelineForSelectedTool(inputType: inputType)
    }
    
    func selectPartialStrokeSelector(inputType: UITouch.TouchType) {
        ToolPalette.shared.selectedVectorTool = ToolPalette.shared.partialStrokeSelector
        
        updatePipelineForSelectedTool(inputType: inputType)
    }
    
    func selectWholeStrokeSelector(inputType: UITouch.TouchType) {
        ToolPalette.shared.selectedVectorTool = ToolPalette.shared.wholeStrokeSelector
        
        updatePipelineForSelectedTool(inputType: inputType)
    }
    
    func updatePipelineForSelectedTool(inputType: UITouch.TouchType) {
        let tool = ToolPalette.shared.selectedVectorTool
        
        guard let layout = tool?.getLayout(inputType: inputType) else {
            return
        }
        
        guard let calculator = tool?.getCalculator(inputType: inputType) else {
            return
        }
        
        guard let brush = tool?.brush() else {
            return
        }
        
        drawingInkBuilder = try! SampleVectorInkBuilder()
        currentInkBuilder = drawingInkBuilder
        
        try! drawingInkBuilder.updateVectorInkPipeline(layoutMask: layout, calculator: calculator, brush: brush.vectorBrush)
    }
    
    private func updateRotatePerFrame(_ sender: UIRotationGestureRecognizer) {
        dRotation = sender.rotation - previousRotation
        accumulateRotation = accumulateRotation + dRotation
        previousRotation = sender.rotation
        applyTransformationToView(rotateAffineTransformByAngle(dRotation))
    }
    
    func rotateAffineTransformByAngle(_ angle: CGFloat) -> CGAffineTransform {
        return CGAffineTransform.identity.translatedBy(x: selectContourCenter!.0, y: selectContourCenter!.1).rotated(by: angle).translatedBy(x: -selectContourCenter!.0, y: -selectContourCenter!.1)
    }
    
    private func applyTransformationToView(_ cgAffineTranform: CGAffineTransform) {
        for selectedStrokeIndex in selectedStrokeIndexes {
            let dryStroke = applicationModel.strokes[selectedStrokeIndex]
            let transformedPath = UIBezierPath(cgPath: dryStroke!.canvas!.path!)
            transformedPath.apply(cgAffineTranform)
            dryStroke?.canvas!.path = transformedPath.cgPath
        }
        
        let transformedPath = UIBezierPath(cgPath: selectCanvas.path!)
        transformedPath.apply(cgAffineTranform)
        selectCanvas.path = transformedPath.cgPath
    }
    
    private func addStroke(canvasIndex: Int, fillColor: CGColor, view: UIView, stroke2Delete: Quartz2D.InkStroke, splineFragment: SplineFragment, isInside: Bool = false, touchType: UITouch.TouchType) throws {
        let spline = try Spline(path: stroke2Delete.spline.path.getPart(firstPointIndex: splineFragment.beginPointIndex, pointsCount: splineFragment.pointsCount), tStart: splineFragment.ts, tFinal: splineFragment.tf)
        
        let newStroke = Quartz2D.InkStroke(
            identifier: Identifier.fromNewUUID()!,
            spline: spline,
            vectorBrush: stroke2Delete.vectorBrush,
            constants: stroke2Delete.constants as! Quartz2D.ConstantAttributes
        )
        
        try m_spatialModel.tryAdd(stroke: newStroke)
        
        try initReconstructInkBuilder(newStroke, touchType: touchType)
        
        try recostructInkBilder?.getBezierPathBy(spline: newStroke.spline, inkPipeline: reconstructInkPipeline!)
        
        let addedBezier: UIBezierPath? = try reconstructBezierPathProducer.getAddition()
        
        if addedBezier != nil && !addedBezier!.isEmpty {
            let canvas = view.layer.bounds.createCanvas()
            canvas.path = addedBezier!.cgPath
            canvas.fillColor = fillColor
            view.layer.sublayers?.insert(canvas, at: canvasIndex)
            
            applicationModel.strokes[newStroke.id] = ApplicationStroke(canvas: canvas, inkStroke: newStroke, touchType: touchType)
            
            if isInside {
                selectedStrokeIndexes.append(newStroke.id)
            }
        }
    }
    
    private func collectPointsFor(sourceSpline: Spline?, touchType: UITouch.TouchType) throws {
        if let allDataSpline = sourceSpline {
            let stroke = Quartz2D.InkStroke(
                identifier: Identifier.fromNewUUID()!,
                spline: allDataSpline.copy() as! Spline,
                vectorBrush: try drawingInkBuilder.brushApplier.getPrototype(),
                constants: Quartz2D.ConstantAttributes(
                    size: drawingInkBuilder.brushApplier.defaultSize,
                    rotation: drawingInkBuilder.brushApplier.defaultRotation,
                    scale: drawingInkBuilder.brushApplier.defaultScale,
                    offset: drawingInkBuilder.brushApplier.defaultOffset,
                    colorRGBA: UIColor(cgColor: canvas.fillColor!).rgba)
            )
            
            try m_spatialModel.tryAdd(stroke: stroke)
            applicationModel.strokes[stroke.id] = ApplicationStroke(canvas: canvas, inkStroke: stroke, touchType: touchType)
        }
    }
 
    private func initReconstructInkBuilder(_ stroke: InkStrokeProtocol, touchType: UITouch.TouchType? = nil) throws {
        if try recostructInkBilder == nil || (
            try recostructInkBilder!.brushApplier.getPrototype() != stroke.vectorBrush ||
                recostructInkBilder!.brushApplier.defaultSize != stroke.constants.size ||
                recostructInkBilder!.brushApplier.defaultRotation != stroke.constants.rotation ||
                recostructInkBilder!.brushApplier.defaultScale.x != stroke.constants.scaleX ||
                recostructInkBilder!.brushApplier.defaultScale.y != stroke.constants.scaleY ||
                recostructInkBilder!.brushApplier.defaultScale.z != stroke.constants.scaleZ ||
                recostructInkBilder!.brushApplier.defaultOffset.x != stroke.constants.offsetX ||
                recostructInkBilder!.brushApplier.defaultOffset.y != stroke.constants.offsetY ||
                recostructInkBilder!.brushApplier.defaultOffset.z != stroke.constants.offsetZ ||
            recostructInkBilder?.pathProducer.layout != stroke.layoutMask
        ) {
            recostructInkBilder = try! SampleVectorInkBuilder()
            reconstructPolygonSimplifier.setDataProvider(dataProvider: recostructInkBilder!.polygonMerger)
            reconstructBezierPathProducer.setDataProvider(dataProvider: reconstructPolygonSimplifier)
            reconstructInkPipeline = try! InkPipeline(inputStage: recostructInkBilder!.polygonMerger, outputStage: reconstructBezierPathProducer)
            let calculator = ToolPalette.shared.selectedVectorTool?.getCalculator(inputType: touchType ?? .direct)
            try! recostructInkBilder?.updateVectorInkPipeline(layoutMask: stroke.layoutMask, calculator: calculator!, brush: stroke.vectorBrush, constSize: stroke.constants.size, constRotation: stroke.constants.rotation, scaleX: stroke.constants.scaleX, scaleY: stroke.constants.scaleY, offsetX: stroke.constants.offsetX, offsetY: stroke.constants.offsetY)
        }
    }
}
