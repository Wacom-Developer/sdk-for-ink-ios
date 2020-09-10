//
//  RasterInkBuilder.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 13.08.19.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

class RasterInkBuilder: InkBuilder {
    init(collectPointData: Bool = false,_ pathLayout: PathPointLayout? = nil) {
        super.init(collectPointData: collectPointData)
        self.pathPointLayout = pathLayout ?? InkBuilder.defaultPointLayout
        self.smoother = SmoothingFilter(dimsCount: self.pathPointLayout.count)
        self.splineProducer = SplineProducer(pathPointLayout: self.pathPointLayout)
        self.splineInterpolator = DistanceBasedInterpolator(inputLayout: self.pathPointLayout, spacing: 0.2, splitCount: 8, interpolatedByLength: true, calculateDerivatives: true, keepAllData: true)
        
        self.calculatePathPointForPen = { previous, current, next in
            let size: Float = 5.0
            var pathPoint = PathPoint(x: current!.x, y: current!.y)
            pathPoint.size = size + 2*(current?.force ?? 0)
            
            pathPoint.alpha = current?.force == nil ? 0.0 : min((0.1 + 0.2 * (current?.force!)!), 1.0)
            pathPoint.rotation = current?.computeNearestAzimuthAngle(previous: previous)
            let cosAltitudeAngle = cos((current?.altitudeAngle!)!)
            
            pathPoint.scaleX = 1.0 + 3.0 * cosAltitudeAngle
            pathPoint.scaleY = 1.0
            pathPoint.offsetX = 0.5 * 10.0 * cosAltitudeAngle
            pathPoint.offsetY = 0
            
            pathPoint.blue = min((pathPoint.alpha!), 1)
            pathPoint.green = max((0.8 - pathPoint.alpha!), 0.3)
            pathPoint.red = 1 - pathPoint.alpha!
            
            return pathPoint
        }
        
        self.calculatePathPointForTouchOrMouse = { previous, current, next in
            let size: Float = 25.0
            var pathPoint = PathPoint(x: current!.x, y: current!.y)
            let speed = current!.computeValueBasedOnSpeed(previous, next, minValue: 0.05, maxValue: 1)
            pathPoint.size = (1 - 0.5 * speed) * size
            
            pathPoint.alpha = current?.force == nil ? 0.0 : min((0.1 + speed * 0.3), 1.0)
            pathPoint.rotation = 0//current.azimuthAngle ?? 0// //Tilt support next current
            pathPoint.scaleX = 1
            pathPoint.scaleY = 1
            pathPoint.offsetX = 0
            pathPoint.offsetY = 0
            
            pathPoint.blue = max((0.8 - 2.0 * speed), 0.3)
            pathPoint.green = 1 - speed
            pathPoint.red = min((3.9 * speed), 1)
            
            return pathPoint
        }
    }
    
    func updatePipeline(layout: PathPointLayout, calculator: @escaping Calculator, spacing: Float) {
        pathPointLayout = layout
        
        pathProducer = PathProducer(layout, calculator)
        
        smoother = SmoothingFilter(dimsCount: layout.count)
         
        splineProducer = SplineProducer(pathPointLayout: layout, keepAllData: true)
        
        splineInterpolator = DistanceBasedInterpolator(inputLayout: layout, spacing: spacing, splitCount: 8, interpolatedByLength: true, calculateDerivatives: true, keepAllData: true)
        
        (splineInterpolator as! DistanceBasedInterpolator).spacing = spacing
    }
    
    func getPath() -> ([Float]?, [Float]?) {
        let (smoothAddedGeometry, smoothPredictedGeometry) = smoother!.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: m_pathSegment.accumulateAddition, prediction: m_pathSegment.lastPrediction)
        
        let (addedSpline, predictedSpline) = splineProducer!.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: smoothAddedGeometry, prediction: smoothPredictedGeometry)
        
        let (addedPath, predictedPath) = splineInterpolator!.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedSpline, prediction: predictedSpline)
        
        resetSegment()
        
        return (addedPath, predictedPath)
    }
    
    public override func setDefaultStrokeSize(defaultSize: Float) {
        (splineInterpolator as! DistanceBasedInterpolator).defaultSize = defaultSize
        //splineInterpolator!.defaultSize = defaultSize
    }
    
    public override func layoutStride() -> Int {
        return pathPointLayout.count
    }
}

