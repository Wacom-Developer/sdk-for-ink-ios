//
//  InkBuilder.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 13.08.19.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

class InkBuilder {
    static var defaultPointLayout: PathPointLayout = PathPointLayout([.x, .y, .size, .alpha, .rotation, .scaleX, .scaleY, .offsetX, .offsetY])
    var pathPointLayout: PathPointLayout
    var m_pathSegment: PathSegment = PathSegment()
    var m_pointerDataUploadCount: UInt32 = 0
    var pathProducer: PathProducer?
    var smoother: SmoothingFilter? = nil
    var splineProducer: SplineProducer? = nil
    var splineInterpolator: SplineInterpolator? = nil
    var collectPointerData = false
    var pointerDataList: [PointerData] = []
    
    private var multipleAddStart: Bool = false
    
    init(collectPointData: Bool) {
        self.pathPointLayout = InkBuilder.defaultPointLayout
        
        self.collectPointerData = collectPointData
        
        if self.collectPointerData {
            pointerDataList = []
        }
    }
    
    public var hasNewPoints: Bool {
        get {
            return m_pointerDataUploadCount > 0
        }
    }
    
    public var pointsCount: UInt32 {
        get {
            return m_pointerDataUploadCount
        }
    }
    
    var calculatePathPointForTouchOrMouse: Calculator = { previous, current, next in
        return nil
    }
    
    var calculatePathPointForPen: Calculator = { previous, current, next in
        return nil
    }
    
    public func getPointerDataList() -> [PointerData] {
        if !collectPointerData {
            assertionFailure("InkBuilder is not constructed to collect pointer data.");
        }
        
        return pointerDataList;
    }
    
    public func add(phase: Phase,_ touchData: PointerData?,_ predictedeTouchData: PointerData?) {
        if collectPointerData {
            if multipleAddStart == false {
                multipleAddStart = true
                if phase == .begin {
                    pointerDataList = []
                }
            }
        
            pointerDataList.append(touchData!)
        }
        
        let (addedGeometry, predictedGeometry) = pathProducer!.add(phase: phase, addition: touchData, prediction: predictedeTouchData)
        
        m_pathSegment.add(phase: phase, addedGeometry!, predictedGeometry!)
        m_pointerDataUploadCount = m_pointerDataUploadCount + 1
    }
    
    open func add(phase: Phase, touches: Set<UITouch>, event: UIEvent, view: UIView)
    {
        multipleAddStart = false
        
        for touch in touches {
            let touchData = getTouchDataBy(phase: phase, touch: touch, view: view)
            
            var predictedeTouchData: PointerData? = nil
            
            if let predictedTouches = event.predictedTouches(for: touch), let predictedTouch = predictedTouches.last {
                predictedeTouchData = getTouchDataBy(phase: phase, touch: predictedTouch, view: view)
            }
            
            add(phase: phase, touchData, predictedeTouchData)
        }
        
        multipleAddStart = false
    }
    
    public func setDefaultStrokeSize(defaultSize: Float) {}
    
    public func layoutStride() -> Int {
        return -1
    }
   
    public func resetSegment() {
        m_pathSegment.reset()
        m_pointerDataUploadCount = 0
    }
    
    public func resetBuilder() {
        resetSegment()
        self.smoother!.reset()
        self.splineProducer!.reset()
        self.splineInterpolator!.reset()
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
