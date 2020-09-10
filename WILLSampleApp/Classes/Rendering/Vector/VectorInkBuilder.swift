//
//  VectorInkBuilder.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 13.08.19.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

class VectorInkBuilder: InkBuilder
{
    let layout: PathPointLayout
    var brushApplier : BrushApplier
    var convexHullProducer : ConvexHullChainProducer
    var polygonMerger : PolygonMerger
    var polygonSimplifier : PolygonSimplifier
    let bezierPathBuilder : PolygonToBezierPathProducer
    private var defaultBrushPolygon: [DIPoint2] = BrushApplier.createUnitCirclePolygon(verticesCount: 4)//[DIPoint2(-0.4, -0.1), DIPoint2(-0.4, 0.1 ), DIPoint2(0.4, 0.1), DIPoint2(0.4, -0.1)]//BrushApplier.createUnitCirclePolygon(verticesCount: 32)//[DIPoint2(-0.4, -0.1), DIPoint2(-0.4, 0.1 ), DIPoint2(0.4, 0.1), DIPoint2(0.4, -0.1)]//BrushApplier.createUnitCirclePolygon(verticesCount: 5)
    
    init(collectPointData: Bool = false,_ pathLayout: PathPointLayout? = nil) {
        layout = pathLayout ?? InkBuilder.defaultPointLayout
        self.brushApplier = BrushApplier(layout: layout, prototype: defaultBrushPolygon)
        self.convexHullProducer = ConvexHullChainProducer()
        self.polygonMerger = PolygonMerger()
        //initPolygonSimplifier()
        self.polygonSimplifier = PolygonSimplifier(epsilon : 0.1, keepAllData: true)
        self.bezierPathBuilder = PolygonToBezierPathProducer()
        
        super.init(collectPointData: collectPointData)
        
        self.smoother = SmoothingFilter(dimsCount: layout.count)
        self.splineProducer = SplineProducer(pathPointLayout: self.pathPointLayout)
        self.splineInterpolator = CurvatureBasedInterpolator(inputLayout: layout, calculateDerivatives: false, keepAllData: true)
        //self.splineInterpolator = SplineInterpolator(inputLayout: layout, spacing: 0.4, splitCount : 8)
        self.pathPointLayout = layout
        
        self.calculatePathPointForPen = {previous, current, next in
            let size: Float = 14
            let cosAltitudeAngle = cos((current?.altitudeAngle!)!)
            
            var pathPoint = PathPoint(x: current!.x, y: current!.y)
            pathPoint.size = size + 1 * (current?.force ?? 0)
            pathPoint.alpha = current?.force == nil ? 0.0 : (0.1 + 0.5 * (current?.force!)!)
            pathPoint.rotation = current?.computeNearestAzimuthAngle(previous: previous)
            pathPoint.scaleX = 1.0 + cosAltitudeAngle//2 * cosAltitudeAngle
            pathPoint.scaleY = 1.0
            pathPoint.offsetX = 0.5 * cosAltitudeAngle / pathPoint.size!
            pathPoint.offsetY = 0
            pathPoint.offsetZ = 0
            
            return pathPoint
        }
        
        self.calculatePathPointForTouchOrMouse = {previous, current, next in
            let size: Float = 2
            let speed =  current!.computeValueBasedOnSpeed(previous, next, minValue: 0.05, maxValue: 1)

            var pathPoint = PathPoint(x: current!.x, y: current!.y)
            pathPoint.size = size + size * speed
            pathPoint.alpha = 0.5
            //pathPoint.alpha = current!.force == nil ? 0.0 : (0.1 + 0.5 * current!.force!)
            pathPoint.rotation = 0 //Tilt support next current
            pathPoint.scaleX = 1
            pathPoint.scaleY = 1
            pathPoint.offsetX = 0
            pathPoint.offsetY = 0
            pathPoint.offsetZ = 0
            
            return pathPoint
        }
    }
    
    func updatePipeline(layout: PathPointLayout, calculator: @escaping Calculator, brush: Geometry.VectorBrush) {
        pathPointLayout = layout
        
        pathProducer = PathProducer(pathPointLayout, calculator)
        
        smoother = SmoothingFilter(dimsCount: pathPointLayout.count)

        splineProducer = SplineProducer(pathPointLayout: pathPointLayout, keepAllData: true)

        splineInterpolator = CurvatureBasedInterpolator(inputLayout: pathPointLayout, calculateDerivatives: false, keepAllData: false)

        brushApplier = BrushApplier(layout: pathPointLayout, brush: brush)
        
        convexHullProducer = ConvexHullChainProducer(keepAllData: true)
        
        polygonMerger = PolygonMerger();
        
        polygonSimplifier = PolygonSimplifier(epsilon: 0.1, keepAllData: true)
    }
    
    func initPolygonSimplifier(epsilon : Float = 0.1, keepAllData: Bool = true) -> PolygonSimplifier {
        return PolygonSimplifier(epsilon : epsilon, keepAllData: keepAllData)
    }
    
    var addedSpline: Spline?
    var predictedSpline: Spline?
    func getPath() -> (UIBezierPath? , UIBezierPath?)
    {
        
        let (smoothAddedGeometry, smoothPredictedGeometry) = smoother!.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: m_pathSegment.accumulateAddition, prediction: m_pathSegment.lastPrediction)
        
        (addedSpline, predictedSpline) = splineProducer!.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: smoothAddedGeometry, prediction: smoothPredictedGeometry)
        
        let (addedInterpolatedSpline, predictedInterpolatedSpline) = splineInterpolator!.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedSpline, prediction: predictedSpline)
        
        let (addedPolys, predictedPolys) = brushApplier.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedInterpolatedSpline, prediction: predictedInterpolatedSpline)
        
        let (addedHulls, predictedHulls) = convexHullProducer.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedPolys, prediction: predictedPolys)
        
        let (addedMerged, predictedMerged) = polygonMerger.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedHulls, prediction: predictedHulls)
        
        let (addedSimplified, predictedSimplified) = polygonSimplifier.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedMerged, prediction: predictedMerged)
        
        let (addedBezier, predictedBezier) = bezierPathBuilder.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedSimplified, prediction: predictedSimplified)
        
        resetSegment()
        
        return (addedBezier, predictedBezier)
    }
    
    func getBezierPathBy(spline: Spline) -> UIBezierPath? { 
        let (addition, _) = splineInterpolator!.add(isFirst: true, isLast: true, addition: spline, prediction: nil)
        
        let (addedPolys, _) = brushApplier.add(isFirst: true, isLast: true, addition: addition, prediction: nil)
        
        let (addedHulls, _) = convexHullProducer.add(isFirst: true, isLast: true, addition: addedPolys, prediction: nil)
        
        let (addedMerged, _) = polygonMerger.add(isFirst: true, isLast: true, addition: addedHulls, prediction: nil)
        
        let (addedSimplified, _) = polygonSimplifier.add(isFirst: true, isLast: true, addition: addedMerged, prediction: nil)
        
        let (addedBezier, _) = bezierPathBuilder.add(isFirst: true, isLast: true, addition: addedSimplified, prediction: nil)
        
        return addedBezier
    }
        
    public override func layoutStride() -> Int
    {
        return pathPointLayout.count
    }
    
    public override func resetBuilder() {
        super.resetBuilder()
        self.brushApplier.reset()
        self.convexHullProducer.reset()
        self.polygonMerger.reset()
        self.polygonSimplifier.reset()
        self.bezierPathBuilder.reset()
    }
}
