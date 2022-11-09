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
                               
                if let brush = brushes.tryGetBrush(brushName: strokeNode.stroke.style.brushUri!) {
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
                               
                if let brush = brushes.tryGetBrush(brushName: strokeNode.stroke.style.brushUri!) {
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
                               
                if let brush = brushes.tryGetBrush(brushName: strokeNode.stroke.style.brushUri!) {
                    if brush is VectorBrush {
                        do {
                            let inkStroke = try deserializeStroke(vectorBrush: brush as! VectorBrush, stroke: strokeNode.stroke)
                            var touchType: UITouch.TouchType? = nil
                            var sensorDataId: Identifier? = nil
                            
                            if let id = strokeNode.stroke.sensorDataId {
                                if let sensorDataToAdd = sensorDataRepository.TryGetValue(id: id) {
                                    sensorDataId = strokeNode.stroke.sensorDataId
                                    resultAppModel.sensorDataMaps[sensorDataId!] = sensorDataToAdd // Fix to  be reviewed
                                    
                                    if let inputContext = inputConfiguration.inputContexts.find(identifierStr: sensorDataToAdd.inputContextID.toString()) {
                                        if let sensorContext = inputConfiguration.sensorContexts.find(identifierStr: inputContext.sensorContextId.toString()) {
                                            if let inkProvider = sensorContext.defaultSensorChannelsContext!.inkInputProvider {
                                                touchType = ApplicationModel.getTouchType(by: inkProvider)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            
                            let applicationStroke = ApplicationStroke(inkStroke: inkStroke, touchType: .direct)
                            applicationStroke.sensorDataId = sensorDataId
                            resultAppModel.strokes.append(key: inkStroke.id, value: applicationStroke)
                        } catch let error {
                            print("ERROR: \(error)")
                        }
                    }
                }
                processedStrokes = processedStrokes + 1
            }
        }
        
        return resultAppModel
    }
    
    private func deserializeStroke(vectorBrush: VectorBrush, stroke: Stroke) throws -> Quartz2D.InkStroke {
        var geometryVectorBrush: Geometry.VectorBrush?
        if vectorBrush.brushPolygons != nil && vectorBrush.brushPolygons!.count > 0 {
            geometryVectorBrush = try Geometry.VectorBrush(polygons:
                vectorBrush.brushPolygons!.map {
                    try BrushPolygon.createNormalized(minScale: $0.minScale, points: $0.points.map { DIFloat2($0.x, $0.y)})
                }
            )
        } else {
            if vectorBrush.brushPrototypeURIs.count > 0 {
                var polygons = [BrushPolygon]()
                
                for uri in vectorBrush.brushPrototypeURIs {
                    polygons.append(try URIShapeResolver.resolveShape(uri: uri))
                }
                
                geometryVectorBrush = try Geometry.VectorBrush(polygons: polygons)
            } else {
                geometryVectorBrush = try Geometry.VectorBrush(polygons: [BrushPolygon.createNormalized(minScale: 1.0, points: BrushApplier.createUnitCirclePolygon(verticesCount: 4, center: DIPoint2(0, 0)))])
            }
        }
        
        let constants = Quartz2D.ConstantAttributes()
        if let ppp = stroke.style.pathPointProperties {
            if ppp.size != nil {
                constants.size = ppp.size!
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
        }
        
        let returnInkStroke = Quartz2D.InkStroke(
            identifier: stroke.id,
            spline: try stroke.getSpline().copy() as! Spline,
            vectorBrush: geometryVectorBrush!,
            constants: constants,
            brushName: "",
            tool: ToolPalette.shared.selectedVectorTool)
        
        returnInkStroke.sensorDataOffset = stroke.sensorDataOffset
        returnInkStroke.sensorDataMappings = stroke.sensorDataMappings
        
        return returnInkStroke;
    }
}
