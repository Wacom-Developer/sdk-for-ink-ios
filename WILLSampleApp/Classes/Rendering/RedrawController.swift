//
//  RedrawController.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 26.07.19.
//  Copyright © 2019 nikolay.atanasov. ll rights reserved.
//

import MetalKit
import WacomInk

class RedrawModel {
    let redrawStrokeLimit: Int = Graphics.redrawStrokeLimitation
    var dryStrokes: [DryStroke] = []
    var isRedrawing: Bool = false
    var chunkIndex = 0
    var dryStrokesCount = 0
    
    init() {
        reset()
    }
    
    func reset() {
        dryStrokes = []
        finishRedrawing()
    }
    
    func finishRedrawing() {
        isRedrawing = false
        startNewRedrawing()
        dryStrokesCount = 0
    }
    
    func startNewRedrawing() {
        chunkIndex = 0
    }
    
    func addStroke(dryStroke: DryStroke!) {
        if dryStroke != nil {
            dryStrokes.append(dryStroke!)
        }
    }
    
    func startRedrawing() -> Bool {
        dryStrokesCount = dryStrokes.count
        
        if dryStrokesCount > 0 {
            chunkIndex = 0
            isRedrawing = true
            return true
        }
        
        return false
    }
    
    func isAllChunkDrawn() -> Bool {
        return chunkIndex > dryStrokesCount
    }
    
    func getNextChunk() -> [DryStroke] {
        let result = dryStrokes[chunkIndex..<min(dryStrokesCount, chunkIndex + redrawStrokeLimit)]
        chunkIndex = chunkIndex + redrawStrokeLimit
        return [DryStroke](result)
    }
    
    func hasStrokes() -> Bool {
        return dryStrokesCount > 0
    }
}

class RedrawController: RenderingController {
    var redrawModel: RedrawModel = RedrawModel()
    var loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingIndicator.backgroundColor = backgroundColor
        loadingIndicator.color = backgroundColor.inverted
        loadingIndicator.isHidden = true
        loadingIndicator.frame = graphics!.bounds
        metalView.addSubview(loadingIndicator)
    }
    
   override func drawableSizeDependableFieldsBody() {
        super.drawableSizeDependableFieldsBody()
        loadingIndicator.frame = graphics!.bounds
        redrawAllStrokes()
    }
    
    //override func touchesCancelledBody() {
        //redrawAllStrokes()
    //}
    
    override func storeCurrentStrokeBody() {
        redrawModel.addStroke(dryStroke: renderingModel!.dryStroke)
    }
    
    func redrawAllStrokes() {
        if redrawModel.isRedrawing == false {
            prepareLayersForDrawing()
            
            if redrawModel.startRedrawing() {
                mustPresent = false
                
                loadingIndicator.isHidden = false
                loadingIndicator.startAnimating()
            }
        }
    }
    
    func redrawDryStroke(_ dryStroke: DryStroke,_ renderingContext: RenderingContext) {
        renderingModel!.renderDryStroke(renderingContext, dryStroke: dryStroke)
    }
    
    func redrawNextChunk() {
        let nextChunk = redrawModel.getNextChunk()
        for dryPath in nextChunk {
            renderingContext?.setTarget(currentStrokeLayer)
            renderingContext?.clearColor(UIColor.clear)
            
            redrawDryStroke(dryPath, renderingContext!)
            
            renderingContext?.setTarget(sceneLayer)
            renderingContext?.drawLayer(currentStrokeLayer, nil, blendMode: BlendMode.normal)
            
            // Blend Current Stroke to All Strokes Layer
            renderingContext?.setTarget(allStrokesLayer)
            renderingContext?.drawLayer(currentStrokeLayer, nil, blendMode: BlendMode.normal)
        }
        
        // Clear CurrentStroke to prepare for next draw
        renderingContext?.setTarget(currentStrokeLayer)
        renderingContext?.clearColor(UIColor.clear)
        
        // Copy the scene to the backbuffer
        renderingContext?.setTarget(backbufferLayer)
        renderingContext?.drawLayer(sceneLayer, nil, blendMode: BlendMode.none)
    }
    
    func drawStrokes() {
        if redrawModel.isAllChunkDrawn() {
            redrawModel.finishRedrawing()
            mustPresent = false
        }
        else {
            redrawNextChunk()
            graphics?.present()
        }
    }
    
    override func drawBody() {
        // drawing code goes here
        if redrawModel.isRedrawing {
            drawStrokes()
        }
        else {
            super.drawBody()
            if loadingIndicator.isAnimating {
                loadingIndicator.isHidden = true
                loadingIndicator.stopAnimating()
            }
        }
    }
    
    func resetRedraw() {
        redrawModel.reset()
    }
}





