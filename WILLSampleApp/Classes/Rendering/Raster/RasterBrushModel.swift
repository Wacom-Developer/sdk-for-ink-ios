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
    
    init(_ inkBuilder: InkBuilder, _ blendMode: BlendMode, particleBrush: ParticleBrush) {
        super.init()
        ink = inkBuilder
        self.blendMode = blendMode
        self.particleBrush = particleBrush
        
        addedParticleList = ParticleList(LayoutProperties: ink!.splineInterpolator!.layoutProperties)
        predictedParticleList = ParticleList(LayoutProperties: ink!.splineInterpolator!.layoutProperties)
        
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
    
    override var dryStroke: DryStroke?//RasterDryStroke?
    {
        let allData = ink!.splineInterpolator!.allData
        
        var points: [Float] = []
        
        if allData != nil
        {
            for el in allData!
            {
                points.append(el)
            }
            
            if points.count > 0
            {
                let particleList = ParticleList(LayoutProperties: ink!.splineInterpolator!.layoutProperties)
                particleList.assign(path: points)
                return DryStroke(particleList: particleList, randomSeed: Int64(startRandomSeed), strokeConstants: strokeConstants.copy() as! StrokeConstants)
            }
        }
        return nil
    }
    
    override func initPath() {
        let (addedSpline, predictedSpline) = (ink as! RasterInkBuilder).getPath()
        
        addedParticleList = ParticleList(LayoutProperties: ink!.splineInterpolator!.layoutProperties)
        predictedParticleList = ParticleList(LayoutProperties: ink!.splineInterpolator!.layoutProperties)

        addedParticleList?.assign(path: addedSpline!)
        predictedParticleList?.assign(path: predictedSpline!)
    }
    
    override func drawingAddedPath(renderingContext: RenderingContext) {
        drawStrokeResult = renderingContext.drawParticleStroke(particleBrush!, addedParticleList!, blendMode: blendMode, randomSeed: drawStrokeResult.randomGeneratedSeed, strokeConstants: strokeConstants)
        
        predictedRect = renderingContext.measureParticleStrokeBounds(particleList: predictedParticleList!, strokeConstants: strokeConstants, scattering: particleBrush!.scattering)
    }
    
    override func drawingPredictedPath(at: RenderingContext) {
        if preliminary != nil {
            strokeConstants.color = preliminary!
        }

        _ = at.drawParticleStroke(particleBrush!, predictedParticleList!, blendMode: blendMode, randomSeed: drawStrokeResult.randomGeneratedSeed, strokeConstants: strokeConstants)
        
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
        
        ink = RasterInkBuilder(collectPointData: true, layout)
        
        particleBrush = tool?.particleBrush(graphics: graphics)
        
        (ink as? RasterInkBuilder)?.updatePipeline(layout: layout, calculator: calculator, spacing: spacing)
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
        //color = UIColor.random().withAlphaComponent(min(0.1, max(0.05, .random())))
        startRandomSeed = UInt32.random(in: 0 ... UInt32.max)
        drawStrokeResult.randomGeneratedSeed = Int64(startRandomSeed)
    }
    
    override func touchesEndedBody() {
        
    }
    
    override func renderDryStroke(_ renderingContext: RenderingContext, dryStroke: DryStroke) {
        _ = renderingContext.drawParticleStroke(particleBrush!, dryStroke.particleList!
            , blendMode: blendMode, randomSeed: dryStroke.randomSeed, strokeConstants: dryStroke.strokeConstants!)
    }
}
