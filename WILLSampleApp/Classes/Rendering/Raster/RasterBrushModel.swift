//
//  RasterBrushModel.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 22.07.19.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

protocol RasterInkBuilderProtocol {
    func getPath() -> ([Float]?, [Float]?)
}

class RasterBrushModel: RenderingModel {
    public var particleBrush: ParticleBrush?
    var strokeConstants: StrokeConstants = StrokeConstants()
    var addedParticleList: ParticleList?
    var predictedParticleList: ParticleList?
    var drawStrokeResult: DrawStrokeResult = DrawStrokeResult(dirtyRect: nil, randomGeneratedSeed: 0)
    private var backUpColor: UIColor? = nil
    private var startRandomSeed: UInt32 = 0
    private var blendMode: BlendMode = .normal
    
    init(_ inkBuilder: StockRasterInkBuilder, _ blendMode: BlendMode, particleBrush: ParticleBrush) {
        super.init()
        ink = inkBuilder
        self.blendMode = blendMode
        self.particleBrush = particleBrush
        
        do {
            addedParticleList = try ParticleList(layoutMask: try ink!.splineInterpolator.getInterpolatedSplineLayoutMask())
            predictedParticleList = try ParticleList(layoutMask: try ink!.splineInterpolator.getInterpolatedSplineLayoutMask())
        } catch let error {
            print("ERROR: \(error)")
        }
        
        defaultSize = 3.0
    }
    
    override var inkColor: UIColor {
        get {
            return strokeConstants.color
        }
        set {
            strokeConstants.color = newValue
            backUpColor = newValue
        }
    }
    
    override var defaultSize: Float {
        get {
            return (ink!.splineInterpolator as! DistanceBasedInterpolator).defaultSize
            //return ink!.splineInterpolator!.defaultSize
        }
        set {
            strokeConstants.size = newValue
            (ink?.splineInterpolator as! DistanceBasedInterpolator).defaultSize = newValue
            //ink!.splineInterpolator!.defaultSize = newValue
        }
    }
    
    override var addedRect: CGRect? {
        return drawStrokeResult.dirtyRect
    }
    
    override var dryStroke: DryStroke? { //RasterDryStroke?
        let allData = ink!.getFullInterpolatedPath()
        
        var points: [Float] = []
        
        if allData != nil
        {
            for el in allData!.data
            {
                points.append(el)
            }
            
            if points.count > 0
            {
                do {
                    let particleList = try ParticleList(layoutMask: try ink!.splineInterpolator.getInterpolatedSplineLayoutMask())
                    particleList.assign(pathData: points)
                    return DryStroke(particleList: particleList, randomSeed: Int64(startRandomSeed), strokeConstants: strokeConstants.copy() as! StrokeConstants)
                } catch let error {
                    print("ERROR: \(error)")
                }
            }
        }
        
        return nil
    }
    
    override func initPath() {
        do {
            let result = try ink?.getCurrentInterpolatedPaths()
            
            let addition = result?.addition
            let prediction = result?.prediction
            
            addedParticleList = try ParticleList(layoutMask: try ink!.splineInterpolator.getInterpolatedSplineLayoutMask())
            predictedParticleList = try ParticleList(layoutMask: try ink!.splineInterpolator.getInterpolatedSplineLayoutMask())

            addedParticleList?.assign(pathData: addition!.data)
            predictedParticleList?.assign(pathData: prediction!.data)
        } catch let error {
            print("ERROR: \(error)")
        }
    }
    
    override func drawingAddedPath(renderingContext: RenderingContext) throws {
        do {
            drawStrokeResult = try renderingContext.drawParticleStroke(particleBrush!, addedParticleList!, blendMode: blendMode, randomSeed: drawStrokeResult.randomGeneratedSeed, strokeConstants: strokeConstants)
            
            predictedRect = try renderingContext.measureParticleStrokeBounds(particleList: predictedParticleList!, strokeConstants: strokeConstants, scattering: particleBrush!.scattering)
        } catch let error {
            print("ERROR: \(error)")
        }
    }
    
    override func drawingPredictedPath(at: RenderingContext) {
        if preliminary != nil {
            strokeConstants.color = preliminary!
        }
        
        do {
            _ = try at.drawParticleStroke(particleBrush!, predictedParticleList!, blendMode: blendMode, randomSeed: drawStrokeResult.randomGeneratedSeed, strokeConstants: strokeConstants)
        } catch let error {
            print("ERROR: \(error)")
        }
        
        if preliminary != nil {
            strokeConstants.color = backUpColor!
        }
    }
    
    func updatePipelineForSelectedTool(inputType: UITouch.TouchType, graphics: Graphics?) {
        let tool = ToolPalette.shared.selectedRasterTool
        
        guard let layout = tool?.getLayout(inputType: inputType) else {
            return
        }
        
        guard let calculator = tool?.getCalculator(inputType: inputType) else {
            return
        }
        
        guard let spacing = tool?.particleSpacing else {
            return
        }
        
        particleBrush = tool?.particleBrush(graphics: graphics)
        
        ink = try! StockRasterInkBuilder()
        
        ink?.updatePipeline(layout: layout, calculator: calculator, spacing: spacing)
    }
    
    func selectPencil(inputType: UITouch.TouchType, graphics: Graphics?) {
        ToolPalette.shared.selectedRasterTool = ToolPalette.shared.pencil
        
        updatePipelineForSelectedTool(inputType: inputType, graphics: graphics)
    }
    
    func selectWaterBrush(inputType: UITouch.TouchType, graphics: Graphics?) {
        ToolPalette.shared.selectedRasterTool = ToolPalette.shared.waterBrush
        
        updatePipelineForSelectedTool(inputType: inputType, graphics: graphics)
    }
    
    func selectCrayon(inputType: UITouch.TouchType, graphics: Graphics?) {
        ToolPalette.shared.selectedRasterTool = ToolPalette.shared.crayon
        
        updatePipelineForSelectedTool(inputType: inputType, graphics: graphics)
    }
    
    func selectEraser(inputType: UITouch.TouchType, graphics: Graphics?) {
        ToolPalette.shared.selectedRasterTool = ToolPalette.shared.rasterEraser
        
        updatePipelineForSelectedTool(inputType: inputType, graphics: graphics)
    }
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, graphics: Graphics) {
        updatePipelineForSelectedTool(inputType: touches.first!.type, graphics: graphics)
    }
    
    override func touchesBeganBody() {
        startRandomSeed = UInt32.random(in: 0 ... UInt32.max)
        drawStrokeResult.randomGeneratedSeed = Int64(startRandomSeed)
    }
    
    override func touchesEndedBody() {
        
    }
    
    override func renderDryStroke(_ renderingContext: RenderingContext, dryStroke: DryStroke) {
        do {
            _ = try renderingContext.drawParticleStroke(particleBrush!, dryStroke.particleList!
                , blendMode: blendMode, randomSeed: dryStroke.randomSeed, strokeConstants: dryStroke.strokeConstants!)
        } catch let error {
            print("ERROR: \(error)")
        }
    }
}
