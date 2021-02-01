//
//  InkModelToApplicationModel.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 5.04.20.
//  Copyright © 2020 nikolay.atanasov. All rights reserved.
//
import WacomInk

extension InkModel {
    var hasRasterInk: Bool {
        let enumerator = inkTree.root!.getRecursiveEnumerator()
        
        while let currentNode = enumerator.next() {
            if (currentNode is StrokeNode) {
                
                let strokeNode = (currentNode as! StrokeNode)
                               
                if let brush = brushes.tryGetBrush(brushName: strokeNode.stroke.style.brushUri) {
                    if brush is RasterBrush {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    var hasVectorInk: Bool {
        let enumerator = inkTree.root!.getRecursiveEnumerator()
        
        while let currentNode = enumerator.next() {
            if (currentNode is StrokeNode) {
                
                let strokeNode = (currentNode as! StrokeNode)
                               
                if let brush = brushes.tryGetBrush(brushName: strokeNode.stroke.style.brushUri) {
                    if brush is VectorBrush {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    var applicationModel: ApplicationModel {
        let resultAppModel = ApplicationModel(devices: self.inputConfiguration.devices.items, environments: self.inputConfiguration.environments.items, inkInputProviders: self.inputConfiguration.inkInputProviders.items, sensorContexts: self.inputConfiguration.sensorContexts.items, inputContexts: self.inputConfiguration.inputContexts.items) 
        
        
        var processedStrokes = 0
        let enumerator = inkTree.root!.getRecursiveEnumerator();
        
        while let currentNode = enumerator.next() {
            if (currentNode is StrokeNode) {
                
                let strokeNode = (currentNode as! StrokeNode)
                               
                if let brush = brushes.tryGetBrush(brushName: strokeNode.stroke.style.brushUri) {
                    if brush is VectorBrush {
                        let inkStroke = deserializeStroke(vectorBrush: brush as! VectorBrush, stroke: strokeNode.stroke)
                        var touchType: UITouch.TouchType? = nil
                        var sensorDataId: Identifier? = nil
                        if let sensorDataToAdd = sensorDataRepository.TryGetValue(id: strokeNode.stroke.sensorDataId) {
                            sensorDataId = strokeNode.stroke.sensorDataId
                            resultAppModel.sensorDataMaps[sensorDataId!] = sensorDataToAdd // Fix to  be reviewed
                            
                            if let inputContext = inputConfiguration.inputContexts.find(indetifierString: sensorDataToAdd.inputContextID.toString()) {
                                if let sensorContex = inputConfiguration.sensorContexts.find(indetifierString: inputContext.sensorContextId.toString()) {
                                    if let inkProvider = sensorContex.defaultSensorChannelsContext!.inkInputProvider {
                                        touchType = ApplicationModel.getTouchType(by: inkProvider)
                                    }
                                }
                            }
                        }
                        
                        let applicationStroke = ApplicationStroke(inkStroke: inkStroke, touchType: touchType)
                        applicationStroke.sensorDataId = sensorDataId
                        resultAppModel.strokes.append(key: inkStroke.id, value: applicationStroke)
                    }
                }
                processedStrokes = processedStrokes + 1
            }
        }
        
        return resultAppModel
    }
    
    private func deserializeStroke(vectorBrush: VectorBrush, stroke: Stroke) -> Quartz2D.InkStroke {
        var brushPolygons = [BrushPolygon]()
        
        if vectorBrush.brushPolygons?.count ?? 0 > 0 {
            brushPolygons = vectorBrush.brushPolygons!
        } else if vectorBrush.brushPrototypeURIs.count > 0 {
            for prototype in vectorBrush.brushPrototypeURIs {
                let uri = prototype.shapeUri
                let minScale = prototype.minScale
                //stroke.style.pathPointProperties.size
                if uri != "" {
                    var precision = 20
                    var radius: Float = 1.0
                    
                    let lastPart = uri.split(separator: "/").last
                    let shape = lastPart?.split(separator: "?").first
                    
                    if shape == "Circle" {
                        if lastPart?.split(separator: "?").count ?? 0 > 1 { // check if there's any parameters at all
                            if let parameters = lastPart?.split(separator: "?").last?.split(separator: "&") {
                                for param in parameters {
                                    let parts = param.split(separator: "=")
                                    let paramName = parts.first
                                    let paramValue = parts.last
                                    
                                    if paramName == "precision" {
                                        precision = Int(String(paramValue ?? "")) ?? 20
                                    } else if paramName == "radius" {
                                        radius = Float(String(paramValue ?? "")) ?? 1.0
                                    }
                                }
                            }
                        }
                    }
                    
                    let points = VectorBrushFactory.createElipseBrush(pointsCount: precision, width: radius, height: radius)
                    
                    brushPolygons.append(BrushPolygon(minScale: minScale, points: points))
                }
            }
        }
        
        let constants = Quartz2D.ConstantAttributes()
        let ppp = stroke.style.pathPointProperties
        if ppp.size != nil {
            constants.size = ppp.size!
            //(returnInkStroke.constants as! Quartz2D.ConstantAttributes).size = ppp.size!
        }

        if ppp.rotation != nil {
            constants.rotation = ppp.rotation!
        }

        if ppp.scaleX != nil {
            constants.scaleX = ppp.scaleX!
        }

        if ppp.scaleY != nil {
            constants.scaleY = ppp.scaleY!
        }

        if ppp.scaleZ != nil {
            constants.scaleZ = ppp.scaleZ!
        }

        if ppp.offsetX != nil {
            constants.offsetX = ppp.offsetX!
        }

        if ppp.offsetY != nil {
            constants.offsetY = ppp.offsetY!
        }

        if ppp.offsetZ != nil {
            constants.offsetZ = ppp.offsetZ!
        }

        if ppp.red != nil {
            constants.red = ppp.red!
        }

        if ppp.green != nil {
            constants.green = ppp.green!
        }

        if ppp.blue != nil {
            constants.blue = ppp.blue!
        }

        if ppp.alpha != nil {
            constants.alpha = ppp.alpha!
        }
        
        let returnInkStroke = Quartz2D.InkStroke(
            identifier: stroke.id,
            spline: stroke.spline,
            layout: stroke.layout,
            vectorBrush: Geometry.VectorBrush(polygons: brushPolygons),
            constants: constants)
        
        returnInkStroke.sensorDataOffset = stroke.sensorDataOffset
        returnInkStroke.sensorDataMappings = stroke.sensorDataMappings
        
        return returnInkStroke;
    }
}
