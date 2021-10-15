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
    var brushName: String = ""
    private var defaultBrushPolygon: [DIPoint2] = BrushApplier.createUnitCirclePolygon(verticesCount: 4)//[DIPoint2(-0.4, -0.1), DIPoint2(-0.4, 0.1 ), DIPoint2(0.4, 0.1), DIPoint2(0.4, -0.1)]//BrushApplier.createUnitCirclePolygon(verticesCount: 32)//[DIPoint2(-0.4, -0.1), DIPoint2(-0.4, 0.1 ), DIPoint2(0.4, 0.1), DIPoint2(0.4, -0.1)]//BrushApplier.createUnitCirclePolygon(verticesCount: 5)
    
    init(collectPointData: Bool = false,_ pathLayout: PathPointLayout? = nil) {
        layout = pathLayout ?? InkBuilder.defaultPointLayout
        
        self.brushApplier = try! BrushApplier(layout: layout, brush: try! Geometry.VectorBrush(polygons: [
            try! BrushPolygon.createNormalized(minScale: 0.0, points: BrushFactory.createEllipseBrush(pointsCount: 4, width: 1.0, height: 1.0)),
            try! BrushPolygon.createNormalized(minScale: 2.0, points: BrushFactory.createEllipseBrush(pointsCount: 8, width: 1.0, height: 1.0)),
            try! BrushPolygon.createNormalized(minScale: 6.0, points: BrushFactory.createEllipseBrush(pointsCount: 16, width: 1.0, height: 1.0)),
            try! BrushPolygon.createNormalized(minScale: 18.0, points: BrushFactory.createEllipseBrush(pointsCount: 32, width: 1.0, height: 1.0))
        ]))
        
        self.convexHullProducer = ConvexHullChainProducer()
        self.polygonMerger = PolygonMerger()
        //initPolygonSimplifier()
        self.polygonSimplifier = PolygonSimplifier(epsilon : 0.1, keepAllData: true)
        self.bezierPathBuilder = PolygonToBezierPathProducer()
        
        super.init(collectPointData: collectPointData)
        
        self.smoother = SmoothingFilter(dimsCount: layout.count)
        self.splineProducer = SplineProducer(layout: self.pathPointLayout)
        
        try! self.splineInterpolator = CurvatureBasedInterpolator(inputLayout: layout, calculateDerivatives: false, keepAllData: true)
        
        
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
    
    func updatePipeline(layout: PathPointLayout, calculator: @escaping Calculator, brush: ExtendedVectorBrush) {
        do {
            pathPointLayout = layout
            
            pathProducer = try PathProducer(pathPointLayout, calculator)
            
            smoother = SmoothingFilter(dimsCount: pathPointLayout.count)

            splineProducer = SplineProducer(layout: pathPointLayout, keepAllData: true)

            splineInterpolator = try CurvatureBasedInterpolator(inputLayout: pathPointLayout, calculateDerivatives: false, keepAllData: false)

            brushApplier = try BrushApplier(layout: pathPointLayout, brush: brush.vectorBrush)
            
            brushName = brush.name
            
            convexHullProducer = ConvexHullChainProducer(keepAllData: true)
            
            polygonMerger = PolygonMerger();
            
            polygonSimplifier = PolygonSimplifier(epsilon: 0.1, keepAllData: true)
        } catch let error {
            print("ERROR: \(error)")
        }
    }
 
    public func setDefault(size: Float)
    {
        brushApplier.defaultSize = size
    }
    
    func initPolygonSimplifier(epsilon : Float = 0.1, keepAllData: Bool = true) -> PolygonSimplifier {
        return PolygonSimplifier(epsilon : epsilon, keepAllData: keepAllData)
    }
    
    var addedSpline: Spline?
    var predictedSpline: Spline?
    func getPath() -> (UIBezierPath? , UIBezierPath?)
    {
        do {
            let (smoothAddedGeometry, smoothPredictedGeometry) = try smoother!.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: m_pathSegment.accumulateAddition, prediction: m_pathSegment.lastPrediction)
            
            (addedSpline, predictedSpline) = try splineProducer!.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: smoothAddedGeometry, prediction: smoothPredictedGeometry)
            
            let (addedInterpolatedSpline, predictedInterpolatedSpline) = try splineInterpolator!.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedSpline, prediction: predictedSpline)
            
            let (addedPolys, predictedPolys) = try brushApplier.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedInterpolatedSpline, prediction: predictedInterpolatedSpline)
            
            let (addedHulls, predictedHulls) = try convexHullProducer.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedPolys, prediction: predictedPolys)
            
            let (addedMerged, predictedMerged) = try polygonMerger.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedHulls, prediction: predictedHulls)
            
            let (addedSimplified, predictedSimplified) = try polygonSimplifier.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedMerged, prediction: predictedMerged)
            
            let (addedBezier, predictedBezier) = try bezierPathBuilder.add(isFirst: m_pathSegment.isFirst, isLast: m_pathSegment.isLast, addition: addedSimplified, prediction: predictedSimplified)
            
            resetSegment()
            
            return (addedBezier, predictedBezier)
        } catch let error {
            print("ERROR: \(error)")
        }
        
        return (nil, nil)
    }
    
    func getBezierPathBy(spline: Spline) -> UIBezierPath? {
        do {
            let (addition, _) = try splineInterpolator!.add(isFirst: true, isLast: true, addition: spline, prediction: nil)
            
            let (addedPolys, _) = try brushApplier.add(isFirst: true, isLast: true, addition: addition, prediction: nil)
            
            let (addedHulls, _) = try convexHullProducer.add(isFirst: true, isLast: true, addition: addedPolys, prediction: nil)
            
            let (addedMerged, _) = try polygonMerger.add(isFirst: true, isLast: true, addition: addedHulls, prediction: nil)
            
            let (addedSimplified, _) = try polygonSimplifier.add(isFirst: true, isLast: true, addition: addedMerged, prediction: nil)
            
            let (addedBezier, _) = try bezierPathBuilder.add(isFirst: true, isLast: true, addition: addedSimplified, prediction: nil)
            
            return addedBezier
        } catch let error {
            print("ERROR: \(error)")
        }
        
        return nil
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
