//
//  SerializationQuartz2DModel.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 17.03.20.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

class SerializationQuartz2DModel {
    var applicationModel: ApplicationModel!
    var inkColor = UIColor.gray
    var backgroundColor = UIColor.white
    var selectedManipulationType: ManipulationType? = nil
    var selectedSpatialContextType: DemosSpatialContextType? = nil
    var selectedManipulationAction: ManipulationAction? = nil
    var selectedManipulatorCollectionType: ManipulatorCollectionType? = nil
    private var recostructInkBilder: ManipulationVectorInkBuilder? = nil
    private var currentInkBuilder: ManipulationVectorInkBuilder? = nil
    private var drawingInkBuilder = ManipulationVectorInkBuilder(collectPointData: true, keepSplineProducerAllData: true)
    private var intersectingInkBuilder = ManipulationVectorInkBuilder(collectPointData: true, PathPointLayout([.x, .y]), keepSplineProducerAllData: true)
    private var selectingInkBuilder = ManipulationVectorInkBuilder(collectPointData: true, PathPointLayout([.x, .y]), keepSplineProducerAllData: true)
    private let greenWithAlpha = UIColor.green.withAlphaComponent(0.3).cgColor
    private let blueWithAlpha = UIColor.blue.withAlphaComponent(0.3).cgColor
    var greenSpatialContext = SpatialContext()
    var blueSpatialContext = SpatialContext()
    var isBlueSpatialContext: Bool = false
    private let manipulator: Manipulator?
    private var uiBezierPathCache: UIBezierPathCache? = nil
    private let strokeFactory: InkStrokeFactoryProtocol?
    private var isBezierCached: Bool = false
    var integrityMode: Manipulator.IntegrityMode = Manipulator.IntegrityMode.partial
    var isErasing = true
    var selectOverlapMode: Manipulator.OverlapMode = Manipulator.OverlapMode.noOverlap
    
    private var canvas = CAShapeLayer()
    private var path: UIBezierPath?
    private var selectCanvas = CAShapeLayer()
    var selectedSpline: Spline? = nil
    private var selectedContour: DIPolygon? = nil
    private var selectContourCenter: (CGFloat, CGFloat)? = nil
    
    var selectedStrokeIndexes: [Identifier] = []
    var hasSelection: Bool {
        return selectedStrokeIndexes.count > 0
    }
    
    init(isCached: Bool) {
        if isCached {
            uiBezierPathCache = UIBezierPathCache()
            isBezierCached = true
        }
        
        strokeFactory = Quartz2D.InkStrokeFactory()
        manipulator = Manipulator(strokeFactory: strokeFactory!)
        //selectingInkBuilder.setDefault(size: 1)
        applicationModel = ApplicationModel()
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
    
    func set(spatialContextType: DemosSpatialContextType) {
        selectedSpatialContextType = spatialContextType
        if selectedSpatialContextType == DemosSpatialContextType.blue {
            isBlueSpatialContext = true
            manipulator!.spatialContext = blueSpatialContext
            
        } else if selectedSpatialContextType == DemosSpatialContextType.green {
            isBlueSpatialContext = false
            manipulator!.spatialContext = greenSpatialContext
        }
    }
    
    func set(manipulationType: ManipulationType) {
        selectedManipulationType = manipulationType
        
        if selectedManipulationType == ManipulationType.draw {
            currentInkBuilder = drawingInkBuilder
            clearSelectCanvas()
        } else if selectedManipulationType == ManipulationType.intersect {
            currentInkBuilder = intersectingInkBuilder
            clearSelectCanvas()
        } else {
            currentInkBuilder = selectingInkBuilder
        }
    }
    
    func set(transformationType: ManipulationAction) {
        selectedManipulationAction = transformationType
    }
    
    func set(manipulatorCollectionType: ManipulatorCollectionType) {
        selectedManipulatorCollectionType = manipulatorCollectionType
    }
    
    func set(selectOverlapMode: Manipulator.OverlapMode) {
        self.selectOverlapMode = selectOverlapMode
    }
    
    func getAllNodes(bounds: CGRect) -> [CGRect] {
        manipulator!.spatialContext!.getAllNodesBounds(in: bounds)
    }
    
//    func setDefault(size: Float) {
//        intersectingInkBuilder.setDefault(size: size)
//    }
    
    func toggleWholeStroke() {
        integrityMode = (integrityMode == Manipulator.IntegrityMode.partial ? Manipulator.IntegrityMode.whole : Manipulator.IntegrityMode.partial)
    }
//
//    func toggleIsInnerContourIncluded() {
//        isInnerContourIncluded = !isInnerContourIncluded
//    }
//
//    func toggleIsOuterContourIncluded() {
//        isOuterContourIncluded = !isOuterContourIncluded
//    }
    
    func toggleIsErasing() {
        isErasing = !isErasing
    }
    
    var translateX: CGFloat? = 0
    var translateY: CGFloat? = 0
    var previousX: CGFloat? = nil
    var previousY: CGFloat? = nil
    var dx: CGFloat? = nil
    var dy: CGFloat? = nil
    
    var accumulateRotation: CGFloat = 0
    var previousRotation: CGFloat = 0//previousX
    var dRotation: CGFloat = 0
    
    func rotateAffineTransformByAngle(_ angle: CGFloat) -> CGAffineTransform {
        return CGAffineTransform.identity.translatedBy(x: selectContourCenter!.0, y: selectContourCenter!.1).rotated(by: angle).translatedBy(x: -selectContourCenter!.0, y: -selectContourCenter!.1)
    }
    
    func rotateBegan(_ sender: UIRotationGestureRecognizer) {
        if selectedManipulationAction == ManipulationAction.rotate {
            accumulateRotation = 0
            previousRotation = 0
            
            updateRotatePerFrame(sender)
        }
    }
    
    func rotateMoved(_ sender: UIRotationGestureRecognizer) {
        if selectedManipulationAction == ManipulationAction.rotate {
            updateRotatePerFrame(sender)
        }
    }
    
    func rotateEnded(_ sender: UIRotationGestureRecognizer) {
        if selectedManipulationAction == ManipulationAction.rotate {
            updateRotatePerFrame(sender)
            try! update(rotateAffineTransformByAngle(accumulateRotation), rotate: true)
        }
    }
    
    var testDefaultSize: Float = 5
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, view: UIView) {
        path = UIBezierPath()
        
        if selectedManipulationType == ManipulationType.select {
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
                selectCanvas.path = path?.cgPath ?? UIBezierPath().cgPath
                selectCanvas.fillColor = UIColor.clear.cgColor
                selectCanvas.strokeColor = UIColor.black.cgColor
                selectCanvas.lineWidth = 2
                selectCanvas.lineJoin = CAShapeLayerLineJoin.round
                selectCanvas.lineDashPattern = [6,3]
                view.layer.addSublayer(selectCanvas)
            }
        } else {
            if selectedManipulationType == ManipulationType.draw {
                //setDrawingInkBuilder()
                uiBezierPathCache?.startBezierPathCacheCollecting()
            }
            else { // intersecting
                intersectingInkBuilder.polygonSimplifier = intersectingInkBuilder.initPolygonSimplifier(keepAllData: selectedManipulatorCollectionType == ManipulatorCollectionType.bySimplifiedPolygon)
            }
            
            canvas = view.layer.bounds.createCanvas()
            canvas.path = path?.cgPath ?? UIBezierPath().cgPath
            canvas.fillColor = selectedManipulationType == ManipulationType.intersect ? backgroundColor.cgColor : inkColor.cgColor
            view.layer.addSublayer(canvas)
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

        currentInkBuilder?.updatePipeline(layout: layout, calculator: calculator, brush: brush)
        
        renderNewStroke(phase: .begin, touches, event: event, view: view)
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, view: UIView) {
        renderNewStroke(phase: .update, touches, event: event, view: view)
    }
    
    func removeAll(view: UIView) {
        applicationModel.strokes.removeAll()
        
        for sublayer in view.layer.sublayers! {
            if sublayer is CAShapeLayer {
                sublayer.removeFromSuperlayer()
            }
        }
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, view: UIView) {
        renderNewStroke(phase: .end, touches, event: event, view: view)
        
        if selectedManipulationType == ManipulationType.draw {
            storeCurrentStroke(touches.first!.type)
        } else if selectedManipulationType == ManipulationType.intersect {
            canvas.removeFromSuperlayer()
        } else {
            if(hasSelection) {
                if selectedManipulationAction == ManipulationAction.move {
                    try! update(CGAffineTransform(translationX: translateX!, y: translateY!))
                }
            } else {
                selectedSpline = selectingInkBuilder.splineProducer!.allData
                onEndSelect()
            }
            
        }
    }
    
    func onSelectButton(view: UIView) -> Bool {
        if hasSelection {
            clearSelectCanvas()
            return true
        }
        else {
            if selectedSpline == nil {
                return false
            }
            
            selectedStrokeIndexes = []
            if selectedManipulatorCollectionType == ManipulatorCollectionType.bySimplifiedPolygon {
                do {
                    try manipulator!.select(points: selectedContour!, integrityMode, selectOverlapMode, isBezierCached: isBezierCached, onStrokeSelected: { resultStroke -> () in
                        self.onStrokeSelected(resultStroke, view: view)
                    })
                } catch let error {
                    print("ERROR: \(error)")
                }
            }
            else {
                do {
                    try manipulator!.select(spline: selectedSpline!, selectingInkBuilder.pathPointLayout, isBezierCached: isBezierCached, integrityMode, selectOverlapMode, onStrokeSelected: { resultStroke -> () in
                        self.onStrokeSelected(resultStroke, view: view)
                    })
                } catch let error {
                    print("ERROR: \(error)")
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
    
    func hasRasterInk(url: URL) -> Bool {
        return applicationModel.hasRasterInk(url: url)
    }
    
    func hasVectorInk(url: URL) -> Bool {
        return applicationModel.hasVectorInk(url: url)
    }
    
    func load(url: URL, viewLayer: CALayer) throws {
        if let loadedApplicationModel = applicationModel.read(from: url), let addedApplicationStrokes = loadedApplicationModel.strokes.values {
            resetApplicationModel(by: loadedApplicationModel)
            try addCanvasesAndRTreeFor(applicationStrokes: addedApplicationStrokes,in: viewLayer)
        }
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

        drawingInkBuilder = ManipulationVectorInkBuilder(collectPointData: true, keepSplineProducerAllData: true)
        currentInkBuilder = drawingInkBuilder
        
        drawingInkBuilder.updatePipeline(layout: layout, calculator: calculator, brush: brush)
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
    
    private func resetApplicationModel(by resetModel: ApplicationModel) {
        blueSpatialContext = SpatialContext()
        greenSpatialContext = SpatialContext()
        manipulator!.spatialContext = isBlueSpatialContext ? blueSpatialContext : greenSpatialContext
        
        applicationModel.removeCanvases()
       
//        resetModel.add(devices: Array(applicationModel.devices.values))
//        resetModel.add(environments: Array(applicationModel.environments.values))
       
        applicationModel = resetModel //ApplicationModel(by: resetModel) // Fix memory //ApplicationModel(applicationModel)
    }
    
    private func addCanvasesAndRTreeFor(applicationStrokes: [ApplicationStroke],in viewLayer: CALayer) throws {
        for appStroke in applicationStrokes {
            if appStroke.inkStroke.spline.path.count > 0 {
                try initReconstructInkBuilder(appStroke.inkStroke)
                
                if isBezierCached {
                    try uiBezierPathCache?.updateBezierPathCache(spline: appStroke.inkStroke.spline, cacheProtocol: recostructInkBilder!)
                }
                
                let strokeIndex = try manipulator!.add(stroke: appStroke.inkStroke, bezierCache:  isBezierCached ? uiBezierPathCache! : nil)
                
                if strokeIndex != appStroke.inkStroke.id {
                    
                    throw "Stroke index should be equal to stroke index in manipulation context."
                }
                
                if let canvas = getCanvas(by: appStroke.inkStroke, viewLayer: viewLayer) {
                    appStroke.canvas = canvas
                }
                
                //appStroke.canvas = getCanvas(by: appStroke.inkStroke, viewLayer: viewLayer)
            }
        }
    }
    
    private func getCanvas(by inkStroke: Quartz2D.InkStroke, viewLayer: CALayer) -> CAShapeLayer? {
        if let path = recostructInkBilder!.getBezierPathBy(spline: inkStroke.spline) {
            let canvas = viewLayer.bounds.createCanvas()
            canvas.path = path.cgPath
            canvas.fillColor = UIColor(red: CGFloat(inkStroke.constants.red), green: CGFloat(inkStroke.constants.green), blue: CGFloat(inkStroke.constants.blue), alpha: CGFloat(inkStroke.constants.alpha)).cgColor //inkStroke.constants.color.cgColor
            viewLayer.addSublayer(canvas)
            return canvas
        } else {
            return nil
        }
    }
    
    private func onEndSelect() {
        let indexX = selectingInkBuilder.splineInterpolator!.interpolatedSplineLayout!.indexOf(property: .x)!
        let indexY = selectingInkBuilder.splineInterpolator!.interpolatedSplineLayout!.indexOf(property: .y)!
        let stride = try! selectingInkBuilder.splineProducer!.getDimsCount()
        var offsetIndex = 0
        assert(selectedSpline!.path.count % stride == 0)
        let steps = selectedSpline!.path.count / stride
        if steps > 0 {
            selectedContour = []
            var sumX: Float = 0
            var sumY: Float = 0
            for _ in 0..<steps {
                let x = selectedSpline!.path[offsetIndex + indexX]
                let y = selectedSpline!.path[offsetIndex + indexY]
                selectedContour!.append(DIPoint2(x, y))
                sumX = sumX + x
                sumY = sumY + y
                offsetIndex = offsetIndex + stride
            }
            
            selectContourCenter = (CGFloat(sumX / Float(steps)), CGFloat(sumY / Float(steps)))
            generateBezierPolys([selectedContour!], result: &path)
            //path = generateBezierPolys([selectedContour!])!
            selectCanvas.path = (path?.copy() as! UIBezierPath).cgPath
        }
    }
    
    private func renderNewStroke(phase: Phase, _ touches: Set<UITouch>, event: UIEvent?, view: UIView) {
        if selectedManipulationType == ManipulationType.select {
            if hasSelection {
                if selectedManipulationAction == ManipulationAction.move {
                    let location = touches.first!.location(in: view)
                    dx = location.x - previousX!
                    dy = location.y - previousY!
                    previousX = location.x
                    previousY = location.y
                    translateX = translateX! + dx!
                    translateY = translateY! + dy!
                    
                    applyTransformationToView(CGAffineTransform(translationX: dx!, y: dy!))
                }
                return
            }
        }
        
        currentInkBuilder!.add(phase: phase, touches: touches, event: event!, view: view)
        
        if currentInkBuilder!.hasNewPoints {
            let (addedPath, preliminaryPath) = currentInkBuilder!.getPath()
            
            if selectedManipulationType == ManipulationType.draw {
                if isBezierCached {
                    uiBezierPathCache!.addBezierPathCache(for: addedPath, controlPointsCount: currentInkBuilder!.splineProducer!.allData!.path.count / (try! currentInkBuilder!.splineProducer!.getDimsCount()))
                }
            }
            
            if addedPath == nil || addedPath!.cgPath.isEmpty {
                return
            }
            
            if selectedManipulationType == ManipulationType.intersect {
                if selectedManipulatorCollectionType == ManipulatorCollectionType.bySimplifiedPolygon {
                    if let points = intersectingInkBuilder.polygonSimplifier.allData?.last {
                        try! manipulator!.intersect(points, isBezierCached: isBezierCached, integrityMode, onStrokeSelected: { resultStroke -> () in
                            self.onIntersectStroke(resultStroke, view: view)
                        })
                    }
                }
                else {
                    if let spline = intersectingInkBuilder.addedSpline {
                        let erasedStroke = Quartz2D.InkStroke(
                            identifier: Identifier.fromNewUUID()!,
                            spline: spline,
                            layout: intersectingInkBuilder.pathPointLayout,
                            vectorBrush: try! intersectingInkBuilder.brushApplier.getPrototype(),
                            constants: Quartz2D.ConstantAttributes(
                                size: intersectingInkBuilder.brushApplier.defaultSize,
                                rotation: intersectingInkBuilder.brushApplier.defaultRotation,
                                scale: intersectingInkBuilder.brushApplier.defaultScale,
                                offset: intersectingInkBuilder.brushApplier.defaultOffset),
                            brushName: intersectingInkBuilder.brushName,
                            tool: ToolPalette.shared.selectedVectorTool
                        ) //InkStrokeProtocol
                        try! manipulator!.intersect(stroke: erasedStroke, isBezierCached: isBezierCached, integrityMode, onStrokeSelected: { resultStroke -> () in
                            self.onIntersectStroke(resultStroke, view: view)
                        })  //.intersect (spline: spline, isBezierCached: isBezierCached, integrityMode, intersectBrushApplier: intersectingInkBuilder.brushApplier, )
                    }
                }
            }
            
            path?.append(addedPath!)
            
            let copyPath: UIBezierPath? = path?.copy() as? UIBezierPath
            if selectedManipulationType == ManipulationType.select {
                if !hasSelection {
                    selectCanvas.path = copyPath?.cgPath
                }
            } else {
                if preliminaryPath != nil {
                    copyPath!.append(preliminaryPath!)
                }
                
                canvas.path = copyPath?.cgPath
            }
        }
    }
    
    private func applyTransformationToView(_ cgAffineTranform: CGAffineTransform) {
        for selectedStrokeIndex in selectedStrokeIndexes {
            let applicationStroke = applicationModel.findStroke(by: selectedStrokeIndex)
            //let dryStroke = serializationModel.dryStrokes[selectedStrokeIndex]
            let transformedPath = UIBezierPath(cgPath: applicationStroke!.canvas!.path!)
            transformedPath.apply(cgAffineTranform)
            applicationStroke!.canvas!.path = transformedPath.cgPath
        }
        
        let transformedPath = UIBezierPath(cgPath: selectCanvas.path!)
        transformedPath.apply(cgAffineTranform)
        selectCanvas.path = transformedPath.cgPath
    }
    
    private func updateRotatePerFrame(_ sender: UIRotationGestureRecognizer) {
        dRotation = sender.rotation - previousRotation
        accumulateRotation = accumulateRotation + dRotation
        previousRotation = sender.rotation
        applyTransformationToView(rotateAffineTransformByAngle(dRotation))
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
            let applicationStroke = applicationModel.findStroke(by: selectedStrokeIndex) //serializationModel.dryStrokes[selectedStrokeIndex]
            let allDataSpline = try Spline(layoutMask: applicationStroke!.inkStroke.spline.layoutMask, path: applicationStroke!.inkStroke.spline.path, tStart: applicationStroke!.inkStroke.spline.tStart, tFinal: applicationStroke!.inkStroke.spline.tFinal)
            
            let layout = applicationStroke!.inkStroke.layout //.splineLayout
            let stride = layout.count //dryStroke!.stroke.stride
            // start transform
            let indexX = layout.indexOf(property: .x)!
            let indexY = layout.indexOf(property: .y)!
            let indexRotation = layout.indexOf(property: .rotation)
            //let stride = drawingInkBuilder.splineProducer!.dimsCount
            var offsetIndex = 0
            assert(allDataSpline.path.count % stride == 0)
            let steps = allDataSpline.path.count / stride
            
            if steps > 0 {
                for _ in 0..<steps {
                    let result = transform.matrix! * DIFloat4(
                        allDataSpline.path[offsetIndex + indexX],
                        allDataSpline.path[offsetIndex + indexY],
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
                
                let spline = try Spline(layoutMask: allDataSpline.layoutMask, path: allDataSpline.path, tStart: allDataSpline.tStart, tFinal: allDataSpline.tFinal)
                
                if rotate && indexRotation == nil {
                    let constants: Quartz2D.ConstantAttributes = applicationStroke!.inkStroke.constants as! Quartz2D.ConstantAttributes
                    constants.rotation = constants.rotation + Float(accumulateRotation)
                    applicationStroke!.inkStroke.constants = constants//Quartz2D.ConstantAttributes()
                }
                
                try initReconstructInkBuilder(applicationStroke!.inkStroke)
                
                if let addedBezier = recostructInkBilder!.getBezierPathBy(spline: allDataSpline) {
                    if !addedBezier.isEmpty {
                        applicationStroke!.canvas!.path = addedBezier.cgPath
                    }
                }
                
                applicationStroke!.inkStroke.spline = spline
                
                if isBezierCached {
                    try uiBezierPathCache!.updateBezierPathCache(spline: applicationStroke!.inkStroke.spline, cacheProtocol: recostructInkBilder!)
                    try manipulator!.update(stroke: applicationStroke!.inkStroke, editStrokeIndex: selectedStrokeIndex, bezierCache: uiBezierPathCache!)
                } else {
                    try manipulator!.update(stroke: applicationStroke!.inkStroke, editStrokeIndex: selectedStrokeIndex)
                }
            }
        }
    }
    
    private func storeCurrentStroke(_ touchType: UITouch.TouchType) {//,_ spline: Spline) {
        if let allDataSpline = drawingInkBuilder.splineProducer!.allData {
            let stroke = Quartz2D.InkStroke(
                identifier: Identifier.fromNewUUID()!,
                spline: allDataSpline.copy() as! Spline,
                layout: drawingInkBuilder.pathPointLayout,
                vectorBrush: try! drawingInkBuilder.brushApplier.getPrototype(),
                constants: Quartz2D.ConstantAttributes(
                    size: drawingInkBuilder.brushApplier.defaultSize,
                    rotation: drawingInkBuilder.brushApplier.defaultRotation,
                    scale: drawingInkBuilder.brushApplier.defaultScale,
                    offset: drawingInkBuilder.brushApplier.defaultOffset,
                    colorRGBA: UIColor(cgColor: canvas.fillColor!).rgba
                ),
                brushName: drawingInkBuilder.brushName,
                tool: ToolPalette.shared.selectedVectorTool
            )
            
            let strokeIndex = try! manipulator!.add(stroke: stroke, bezierCache:  isBezierCached ? uiBezierPathCache! : nil)
            assert(strokeIndex == stroke.id, "Stroke index should be equal to stroke index in manipulation context.")
            
            applicationModel.addStroke(ApplicationStroke(canvas: canvas, inkStroke: stroke, touchType: touchType), sensorPointerData: drawingInkBuilder.getPointerDataList())
        }
    }
    
    private func onIntersectStroke(_ manipulatedStroke: ResultManipulatedStroke, view: UIView) {
        var index: Int? = nil
        var fillColor: CGColor? = nil
        if let deletedApplicationStroke = applicationModel.findStroke(by: manipulatedStroke.originalStrokeIndex) { //serializationModel.dryStrokes[manipulatedStroke.originalStrokeIndex] {
            index = view.layer.sublayers!.firstIndex(of: deletedApplicationStroke.canvas!)
            fillColor = deletedApplicationStroke.canvas!.fillColor
            deletedApplicationStroke.canvas!.removeFromSuperlayer()
            
            addResultStrokes(manipulatedStroke.notSelectedResultStrokes, view, fillColor, index, deletedApplicationStroke)
            
            if isErasing {
                removeStrokesFromContext(manipulatedStroke.selectedResultStrokes)
            }
            else {
                addResultStrokes(manipulatedStroke.selectedResultStrokes, view, selectedSpatialContextType == DemosSpatialContextType.green ? greenWithAlpha : blueWithAlpha, index, deletedApplicationStroke)
            }
            
            let removeResult = applicationModel.removeStroke(by: manipulatedStroke.originalStrokeIndex)
            assert(removeResult != nil, "Should find stroke by index to be removed.")
           // serializationModel.removeDryStroke(index: manipulatedStroke.originalStrokeIndex)
        }
        else {
            assert(false, "dryStrokes doesn't contain stroke which is selected")
        }
    }
    
    private func onStrokeSelected(_ resultStroke: ResultManipulatedStroke, view: UIView) {
        var index: Int? = nil
        var fillColor: CGColor? = nil
        
        if let deletedApplicationStroke = applicationModel.findStroke(by: resultStroke.originalStrokeIndex) { //serializationModel.dryStrokes[resultStroke.originalStrokeIndex] {
            if self.integrityMode == Manipulator.IntegrityMode.whole {
                self.selectedStrokeIndexes.append(resultStroke.originalStrokeIndex)
            } else {
                index = view.layer.sublayers!.firstIndex(of: deletedApplicationStroke.canvas!)
                fillColor = deletedApplicationStroke.canvas!.fillColor
                //serializationModel.dryStrokes.removeValue(forKey: resultStroke.originalStrokeIndex)
                deletedApplicationStroke.canvas!.removeFromSuperlayer()
                
                self.addResultStrokes(resultStroke.notSelectedResultStrokes, view, fillColor, index, deletedApplicationStroke)
                self.addResultStrokes(resultStroke.selectedResultStrokes, view, fillColor, index, isSelected: true, deletedApplicationStroke)
                
                let removeResult = applicationModel.removeStroke(by: resultStroke.originalStrokeIndex)
                assert(removeResult != nil, "Should find stroke by index to be removed.")
               // serializationModel.removeDryStroke(index: resultStroke.originalStrokeIndex)
            }
        }
        else {
            assert(false, "dryStrokes doesn't contain stroke which is selected")
        }
    }
    
    private func addResultStrokes(_ strokes: [WacomInk.ResultManipulatedStroke.ResultStroke],_ view: UIView,_ fillColor: CGColor?,_ canvasIndex: Int?, isSelected: Bool = false,_ originalStroke: ApplicationStroke) {
        for resultStroke in strokes {
            let stroke = resultStroke.stroke
            try! initReconstructInkBuilder(stroke)
            
            var addedBezier: UIBezierPath?
            if isBezierCached == true {
                addedBezier = UIBezierPath()
                let (startSpline, cachedPath, endSpline) = resultStroke.cachedUIBezierPath
                if startSpline != nil {
                    if let pathToAdd = recostructInkBilder?.getBezierPathBy(spline: startSpline!) {
                        addedBezier!.append(pathToAdd)
                    }
                }
                
                if cachedPath != nil {
                    addedBezier!.append(cachedPath!)
                }
                
                if endSpline != nil {
                    if let pathToAdd = recostructInkBilder?.getBezierPathBy(spline: endSpline!) {
                        addedBezier!.append(pathToAdd)
                    }
                }
                
            } else {
                addedBezier = recostructInkBilder!.getBezierPathBy(spline: stroke.spline)
            }
            
            if addedBezier != nil && !addedBezier!.isEmpty {
                let canvas = view.layer.bounds.createCanvas()
                canvas.path = addedBezier!.cgPath
                canvas.fillColor = fillColor!
                view.layer.sublayers?.insert(canvas, at: canvasIndex!)
                
                applicationModel.addSubStroke(ApplicationStroke(canvas: canvas, inkStroke: resultStroke.stroke as! Quartz2D.InkStroke, touchType: originalStroke.touchType), from: originalStroke) // FIX chech if sensorPointerData is needed
                
                if isSelected {
                    selectedStrokeIndexes.append(resultStroke.stroke.id)
                }
            }
        }
    }
    
    private func removeStrokesFromContext(_ resultStrokes: [WacomInk.ResultManipulatedStroke.ResultStroke]) {
        for resultStroke in resultStrokes {
            try! manipulator!.spatialContext!.remove(inkStrokeId: resultStroke.stroke.id)
        }
    }
    
    private func initReconstructInkBuilder(_ stroke: InkStrokeProtocol) throws {
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
                recostructInkBilder!.layout != stroke.layout
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
    
    private func setDrawingInkBuilder() throws {
        drawingInkBuilder = ManipulationVectorInkBuilder(collectPointData: true, PathPointLayout([.x, .y, .rotation]), keepSplineProducerAllData: true)
        
        drawingInkBuilder.brushApplier = try BrushApplier(
            layout: drawingInkBuilder.layout,
            brush: try Geometry.VectorBrush(polygons: [
                try BrushPolygon.createNormalized(
                    minScale: 0,
                    points: BrushApplier.createUnitCirclePolygon(verticesCount: 4)
                ),
                try BrushPolygon.createNormalized(
                    minScale: 20,
                    points: BrushApplier.createUnitCirclePolygon(verticesCount: 6)
                ),
                try BrushPolygon.createNormalized(
                    minScale: 45,
                    points: BrushApplier.createUnitCirclePolygon(verticesCount: 9)
                ),
                try BrushPolygon.createNormalized(
                    minScale: 80,
                    points: BrushApplier.createUnitCirclePolygon(verticesCount: 16)
                )
                
            ])
        )
        
        testDefaultSize =  5 + Float(Int.random(in: -1...35)) * 0.1
        drawingInkBuilder.setDefault(size: testDefaultSize)
        drawingInkBuilder.brushApplier.defaultRotation = 0.6
        drawingInkBuilder.brushApplier.defaultScale = DIFloat3(1.5, 0.5, 0.7)
        drawingInkBuilder.brushApplier.defaultOffset = DIFloat3(-10.5, 8.75, -0.7)
        
        currentInkBuilder = drawingInkBuilder
    }
}
