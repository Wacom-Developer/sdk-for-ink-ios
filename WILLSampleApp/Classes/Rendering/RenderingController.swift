//
//  RenderingController.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 19.07.19.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import MetalKit
import WacomInk

class DryStroke {//RasterAndVectorDryStroke: DryStrokeBase {
    public private(set) var vectorPath: UIBezierPath = UIBezierPath()
    public private(set) var color: UIColor?
    public private(set) var isRasterBrush: Bool
    public private(set) var particleList: ParticleList?
    public private(set) var randomSeed: Int64?
    public private(set) var strokeConstants: StrokeConstants?

    init(vectorPath: UIBezierPath, color: UIColor) {
        self.vectorPath = vectorPath
        self.color = color
        self.isRasterBrush = false
    }

    init(particleList: ParticleList, randomSeed: Int64, strokeConstants: StrokeConstants) {
        self.particleList = particleList
        self.isRasterBrush = true
        self.randomSeed = randomSeed
        self.strokeConstants = strokeConstants
    }
}

protocol RenderingProtocol {
    var addedRect: CGRect? { get }
    
    func initPath()
    func drawingAddedPath(renderingContext: RenderingContext) throws
    func drawingPredictedPath(at: RenderingContext)
    func touchesBeganBody()
    func touchesEndedBody()
}

class RenderingModel: RenderingProtocol {
    var ink: StockRasterInkBuilder?
    var preliminary: UIColor?
    var inkColor: UIColor = UIColor.clear
    var defaultSize: Float = 0.0
    var predictedRect: CGRect? = nil
    
    var addedRect: CGRect? {
        return nil
    }
    
    var dryStroke: DryStroke? {
        return nil
    }
    
    func initPath() {
        assertionFailure("[ERROR] initPath() must be overridden by all subclasses of RenderingModel!")
    }
    
    func drawingAddedPath(renderingContext: RenderingContext) throws {
        assertionFailure("[ERROR] drawingAddedPath(renderingContext: RenderingContext) must be overridden by all subclasses of RenderingModel!")
    }
    
    func drawingPredictedPath(at: RenderingContext) {
        assertionFailure("[ERROR] drawingPredictedPath(at: RenderingContext) must be overridden by all subclasses of RenderingModel!")
    }
    
    func touchesBeganBody() {
        assertionFailure("[ERROR] touchesBeganBody() must be overridden by all subclasses of RenderingModel!")
    }
    
    func touchesEndedBody() {
        assertionFailure("[ERROR] touchesBeganBody() must be overridden by all subclasses of RenderingModel!")
    }
    
    func renderDryStroke(_ renderingContext: RenderingContext, dryStroke: DryStroke) {
        assertionFailure("[ERROR] renderDryStroke(_ renderingContext: RenderingContext, dryStroke: RedrawModel.DryStroke) must be overridden by all subclasses of RenderingModel!")
    }
}

class RenderingController: UIViewController {
    var mustPresent = false
    var renderingModel: RenderingModel?
    var backgroundColor = UIColor.white
    var renderingContext: RenderingContext?
    var graphics: Graphics?
    var dirtyRectManager: DirtyRectManager?
    var backbufferLayer: Layer! = nil
    var currentStrokeLayer: Layer! = nil
    var allStrokesLayer: Layer! = nil
    var preliminaryLayer: Layer! = nil
    var sceneLayer: Layer! = nil
    
    var metalView: MTKView
    {
        return self.view as! MTKView
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        dirtyRectManager = DirtyRectManager()
        metalView.device = MTLCreateSystemDefaultDevice()
        
        resetDrawableSizeDependableFields()
        
        metalView.delegate = self
    }
    
    func resetDrawableSizeDependableFields() {
        graphics = Graphics(metalView)
        
        renderingContext = graphics!.getRenderingContext()
        
        initLayers()
        
        drawableSizeDependableFieldsBody()
    }
    
    func initLayers() {
        createLayers()
        clearLayers()
        
        prepareLayersForDrawing()
        
        mustPresent = true
    }
    
    
    func drawableSizeDependableFieldsBody() {}
    
//    func drawSceneLayerToBackbufferLayer() {
//        renderingContext?.setTarget(backbufferLayer)
//        renderingContext!.drawLayer(sceneLayer, nil, blendMode: BlendMode.none)
//    }
    
    func prepareLayersForDrawing()
    {
        do {
            renderingContext?.setTarget(sceneLayer)
            try renderingContext?.clearColor(backgroundColor)
            
            renderingContext?.setTarget(allStrokesLayer)
            try renderingContext?.clearColor(UIColor.clear)
        } catch let error {
            print("ERROR: \(error)")
        }
        
        prepareLayersForDrawingBody()
    }
    
    func prepareLayersForDrawingBody() {}
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        (renderingModel as? RasterBrushModel)?.touchesBegan(touches, with: event, graphics: graphics!)
        
        renderingModel?.ink?.pointerDataProvider.add(phase: .begin, touches: touches, event: event!, view: view)
        //renderingModel!.ink!.add(phase: .begin, touches: touches, event: event!, view: view)
        
        renderingModel!.touchesBeganBody()
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        renderingModel?.ink?.pointerDataProvider.add(phase: .update, touches: touches, event: event!, view: view)
        //renderingModel!.ink!.add(phase: .update, touches: touches, event: event!, view: view)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        do {
            renderingModel?.ink?.pointerDataProvider.add(phase: .end, touches: touches, event: event!, view: view)
            //renderingModel!.ink!.add(phase: .end, touches: touches, event: event!, view: view)
           
           try renderNewStroke()
           
           renderingModel!.touchesEndedBody()
           storeCurrentStroke()
        } catch {
            NSException(name:NSExceptionName(rawValue: "RenderingController.touchesEnded"), reason:"\(error)", userInfo:nil).raise()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        renderingModel!.ink!.resetBuilder()
//
//        clearLayers()
//
//        touchesCancelledBody()
    }
    
//    func touchesCancelledBody() {
//        prepareLayersForDrawing()
//
//        renderingContext?.setTarget(currentStrokeLayer)
//        renderingContext?.clearColor(UIColor.clear)
//
//        // Copy the scene to the backbuffer
//        renderingContext?.setTarget(backbufferLayer)
//        renderingContext?.drawLayer(sceneLayer, nil, blendMode: BlendMode.none)
//        mustPresent = true
//    }
    
    func renderNewStroke() throws {
        renderingContext?.setTarget(currentStrokeLayer)
        renderingModel!.initPath()
        try! renderingModel!.drawingAddedPath(renderingContext: renderingContext!)
        
        let updateRect: CGRect = dirtyRectManager!.getUpdateRect(addedStrokeRect: renderingModel!.addedRect , predictedStrokeRect: renderingModel!.predictedRect)
        
        renderingContext?.setTarget(preliminaryLayer, updateRect)
        
        do {
            try renderingContext!.drawLayerAtPoint(currentStrokeLayer, sourceRect: updateRect, destinationLocation: CGPoint(x: updateRect.minX, y: updateRect.minY), blendMode: BlendMode.none)
            
            renderingModel!.drawingPredictedPath(at: renderingContext!)
            renderingContext?.setTarget(sceneLayer, updateRect)
            try renderingContext?.clearColor(backgroundColor)
            try renderingContext?.drawLayerAtPoint(allStrokesLayer, sourceRect: updateRect, destinationLocation: CGPoint(x: updateRect.minX, y: updateRect.minY), blendMode: BlendMode.normal)
            try renderingContext!.drawLayerAtPoint(preliminaryLayer, sourceRect: updateRect, destinationLocation: CGPoint(x: updateRect.minX, y: updateRect.minY), blendMode: BlendMode.normal)
            renderingContext?.setTarget(backbufferLayer)
            try renderingContext!.drawLayer(sceneLayer, nil, blendMode: BlendMode.none)
        } catch let error {
            print("ERROR: \(error)")
        }
    }
    
    func storeCurrentStrokeBody() {}
    
    func storeCurrentStroke() {
        storeCurrentStrokeBody()
        
        renderingContext?.setTarget(allStrokesLayer)
        do {
            try renderingContext!.drawLayer (currentStrokeLayer, nil, blendMode: BlendMode.normal)
            
            renderingContext?.setTarget(currentStrokeLayer)
            try renderingContext?.clearColor(UIColor.clear)
        } catch let error {
            print("ERROR: \(error)")
        }
        
        dirtyRectManager!.reset()
        mustPresent = true
    }
    
    func clearLayers() {
        do {
            renderingContext?.setTarget(backbufferLayer)
            try renderingContext?.clearColor(backgroundColor)
            
            renderingContext?.setTarget(sceneLayer)
            try renderingContext?.clearColor(backgroundColor)
            
            renderingContext?.setTarget(allStrokesLayer)
            try renderingContext?.clearColor(UIColor.clear)
            
            renderingContext?.setTarget(preliminaryLayer)
            try renderingContext?.clearColor(UIColor.clear)
            
            renderingContext?.setTarget(currentStrokeLayer)
            try renderingContext?.clearColor(UIColor.clear)
        } catch let error {
            print("ERROR: \(error)")
        }
    }
    
    func createLayers() {
        let scale: CGFloat = graphics!.scale
        let bounds: CGRect = graphics!.bounds
        
        backbufferLayer = graphics!.createBackbufferLayer()
        sceneLayer = graphics?.createLayer(bounds: bounds, scale: scale) 
        allStrokesLayer = graphics!.createLayer(bounds: bounds, scale: scale)
        preliminaryLayer = graphics?.createLayer(bounds: bounds, scale: scale)
        currentStrokeLayer = graphics!.createLayer(bounds: bounds, scale: scale)//CGRect(x: 40, y: 150, width: 550, height: 720), scale: scale)
    }
    
    func drawBody() throws
    {
        if renderingModel!.ink!.hasNewPoints {
            try renderNewStroke()
            graphics?.present()
        }
        else if mustPresent {
            graphics?.present()
            mustPresent = false
        }
    }
}

extension RenderingController: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if UIApplication.shared.applicationState != .background {
            resetDrawableSizeDependableFields()
        }
    }
    
    func draw(in view: MTKView) {
        // drawing code goes here
        autoreleasepool {
            do {
                try drawBody()
            } catch {
                NSException(name:NSExceptionName(rawValue: "RenderingModel.draw"), reason:"\(error)", userInfo:nil).raise()
            }
        }
    }
}
