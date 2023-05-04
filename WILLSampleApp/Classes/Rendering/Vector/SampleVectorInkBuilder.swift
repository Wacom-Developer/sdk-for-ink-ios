//
//  SampleVectorInkBuilder.swift
//  WILLSampleApp
//
//  Created by Mincho Dzhagalov on 11.08.22.
//  Copyright © 2022 Mincho Dzhagalov. All rights reserved.
//

import Foundation
import WacomInk

class SampleVectorInkBuilder: StockVectorInkBuilder {
    private var pointerDataList: [PointerData] = []
    
    public func getPointerDataList() -> [PointerData] {
        return pointerDataList;
    }
    
    func addPointerData(phase: Phase, touches: Set<UITouch>, event: UIEvent, view: UIView) {
        for touch in touches {
            let touchData = getTouchDataBy(phase: phase, touch: touch, view: view)
            
            pointerDataList.append(touchData)
        }
    }
    
    private func getTouchDataBy(phase: Phase, touch: UITouch, view: UIView) -> PointerData {
        let location = touch.location(in: view)
        let x: Float = Float(location.x)
        let y: Float = Float(location.y)
        let force: Float = Float(touch.force)
        let azymuthAngle: Float = Float(touch.azimuthAngle(in: view))
        let altitudeAngle: Float = Float(touch.altitudeAngle)
        var result = PointerData(phase:phase, timestamp: touch.timestamp, x: x, y: y, force: force)
        result.azimuthAngle = azymuthAngle
        result.altitudeAngle = altitudeAngle
        
        return result
    }
}
