//
//  ApplicationModelToInkModel.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 5.04.20.
//  Copyright © 2020 nikolay.atanasov. All rights reserved.
//

import WacomInk

extension ApplicationModel {
    func getInkModel() throws -> InkModel {
        let resultInkModel: InkModel = InkModel()
        
        for device in devices.values {
            _ = try resultInkModel.inputConfiguration.devices.tryAdd(item: device)
        }
        
        for environment in environments.values {
            _ = try resultInkModel.inputConfiguration.environments.tryAdd(item: environment)
        }
        
        for inkInputProvider in inkInputProviders.values {
            _ = try resultInkModel.inputConfiguration.inkInputProviders.tryAdd(item: inkInputProvider)
        }
        
        for inputContext in inputContexts.values {
            _ = try resultInkModel.inputConfiguration.inputContexts.tryAdd(item: inputContext)
        }
        
        for sensorContext in sensorContexts.values {
            _ = try resultInkModel.inputConfiguration.sensorContexts.tryAdd(item: sensorContext)
        }
        
        try resultInkModel.inkTree.setRoot(newValue: StrokeGroupNode(id: Identifier.fromNewUUID()!))
        if let applicationStrokes = strokes.values {
            for applicationStroke in applicationStrokes {
                let vectorBrush = try applicationStroke.inkStroke.getSerializationVectorBrush();
            
                
                if resultInkModel.brushes.tryGetBrush(brushName: vectorBrush.name) == nil {
                    try resultInkModel.brushes.addVectorBrush(vectorBrush: vectorBrush);
                }
                
                let style = try applicationStroke.inkStroke.getSerializationStyle(brushName: vectorBrush.name);
                
                let stroke = Stroke(
                    Identifier.fromNewUUID()!,
                    applicationStroke.inkStroke.spline,
                    style,
                    applicationStroke.sensorDataId,
                    sensorDataOffset: applicationStroke.inkStroke.sensorDataOffset,
                    sensorDataMappings: applicationStroke.inkStroke.sensorDataMappings
                )
                
                
                let strokeNode = try StrokeNode(stroke)
                _ = try resultInkModel.inkTree.root!.childNodes.add(node: strokeNode);
                if let sensorDataIdentifier = applicationStroke.sensorDataId {
                    let sensorData = sensorDataMaps[sensorDataIdentifier]!
                    
                    try printSensorMappingsInfo(for: stroke)
                    
                    if !resultInkModel.sensorDataRepository.containsId(id: sensorData.id) {
                        try resultInkModel.sensorDataRepository.add(sensorData: sensorData)
                    }
                }
            }
        }
        
        return resultInkModel
    }
    
    func printSensorMappingsInfo(for stroke: Stroke, skip: Bool = true) throws {
        if skip { return }
        
        if stroke.sensorDataId == nil {
            throw RuntimeError("No sensorDataId for stroke \(stroke.id)")
        }
        
        let sensorData = sensorDataMaps[stroke.sensorDataId!]!
        let sensorContext = sensorContexts[inputContexts[sensorData.inputContextID]!.sensorContextId]
        let xChannel = sensorContext!.defaultSensorChannelsContext!.getChannel(typeUri: InkSensorType.x)!
        let yChannel = sensorContext!.defaultSensorChannelsContext!.getChannel(typeUri: InkSensorType.y)!
        
        let sensorChannelXData = sensorData.allChannelData[xChannel.id]!.map({ covertToFloat($0, Float(xChannel.precision))})
        let sensorChannelYData = sensorData.allChannelData[yChannel.id]!.map({ covertToFloat($0, Float(yChannel.precision))})
        
        let strokeXData = try stroke.getCoordsList(property: PathPoint.Property.x)
        let strokeYData = try stroke.getCoordsList(property: PathPoint.Property.y)
        let strokeDataCount = strokeXData.count
        
        let sensorDataOffset = Int(stroke.sensorDataOffset)
        let sensorDataMappingsCount = stroke.sensorDataMappings.count
        let sensorDataCount = sensorChannelXData.count
        
        print()
        print("SensorChannels: for stroke id: \(stroke.id.toString())")
        print("# |   x   |   y  ")
        for i in 0..<sensorDataCount {
            print("\(i) | \(sensorChannelXData[i]) | \(sensorChannelYData[i])")
        }
        print("=======================================")
        print("sensorDataOffset | sensorDataMappings")
        print("     \(sensorDataOffset)    | \(stroke.sensorDataMappings)")
        
        print("=======================================")
        if strokeDataCount > 0 {
            print("First stroke control point (\(strokeXData[0]), \(strokeYData[0]))")
        }
        print("i + sensorDataOffset | sensorDataMappings[i] | sensorChannel (x, y) | stroke control point (x, y)")
        for i in 0..<sensorDataMappingsCount {
            if sensorDataCount > i + sensorDataOffset {
                print("\(i) + \(sensorDataOffset)           | \(stroke.sensorDataMappings[i])    | (\(sensorChannelXData[i + sensorDataOffset]), \(sensorChannelYData[i + sensorDataOffset])) | (\(strokeXData[i+1]), \(strokeYData[i+1]))")
            }
            else {
                print("\(i) + \(sensorDataOffset)           | \(stroke.sensorDataMappings[i])    |----No sensor data----| (\(strokeXData[i+1])]), \(strokeYData[i+1]))")
                
            }
        }
        
        if sensorDataMappingsCount < strokeDataCount {
            for i in (sensorDataMappingsCount + 1)..<strokeDataCount {
                print("Last stroke control point (\(strokeXData[i]), \(strokeYData[i]))")
            }
        }
    }
    
    func covertToFloat(_ value: Int32,_ precision: Float) -> Float {
        return Float(value) / Float(pow(Float(10), Float(precision)))
    }
}
