

import WacomInk


class ManipulationVectorInkBuilder: VectorInkBuilder, CacheProtocol, VectorInkBuilderProtocol {
    var drawingSplineProducer: SplineProducer {
        return splineProducer!
    }
    
    func getPath(from spline: Spline) -> UIBezierPath? {
        return getBezierPathBy(spline: spline)
    }
    
    init(collectPointData: Bool,_ pathLayout: PathPointLayout? = nil, keepSplineProducerAllData: Bool) {
        super.init(collectPointData: collectPointData, pathLayout)
        
        splineProducer = SplineProducer(layout: pathPointLayout, keepAllData: keepSplineProducerAllData)
    }
    
    init(collectPointData: Bool,_ pathLayout: PathPointLayout? = nil, brushPrototype: Geometry.VectorBrush, defaultSize: Float, defaultRotation: Float, defaultScale: DIFloat3, defaultOffset: DIFloat3, keepSplineProducerAllData: Bool) {
        do {
            super.init(collectPointData: collectPointData, pathLayout)
            brushApplier = try BrushApplier(layout: pathLayout!, brush: brushPrototype, keepAllData: false)
            splineProducer = SplineProducer(layout: pathLayout!, keepAllData: keepSplineProducerAllData)
            brushApplier.defaultRotation = defaultRotation
            brushApplier.defaultScale = defaultScale
            brushApplier.defaultOffset = defaultOffset
            brushApplier.defaultSize = defaultSize
        } catch let error {
            print("ERROR: \(error)")
        }
    }
}
