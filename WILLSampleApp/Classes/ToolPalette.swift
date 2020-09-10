//
//  ToolPalette.swift
//  WILLSampleApp
//
//  Created by Mincho Dzhagalov on 20.05.20.
//  Copyright © 2020 Mincho Dzhagalov. All rights reserved.
//

import Foundation
import UIKit
import WacomInk

protocol RasterTool {
    var particleSpacing: Float { get }
    
    func particleBrush(graphics: Graphics?) -> ParticleBrush
    func getCalculator(inputType: UITouch.TouchType) -> Calculator?
    func getLayout(inputType: UITouch.TouchType) -> PathPointLayout?
}

protocol VectorTool {
    func brush() -> Geometry.VectorBrush
    func getCalculator(inputType: UITouch.TouchType) -> Calculator?
    func getLayout(inputType: UITouch.TouchType) -> PathPointLayout?
}

class Pen: VectorTool {
    func brush() -> Geometry.VectorBrush {
        return Geometry.VectorBrush(polygons: [
            BrushPolygon(minScale: 0, points: BrushApplier.createUnitCirclePolygon(verticesCount: 4)),
            BrushPolygon(minScale: 2, points: BrushApplier.createUnitCirclePolygon(verticesCount: 8)),
            BrushPolygon(minScale: 6, points: BrushApplier.createUnitCirclePolygon(verticesCount: 16)),
            BrushPolygon(minScale: 8, points: BrushApplier.createUnitCirclePolygon(verticesCount: 32))
        ])
    }
    
    func getCalculator(inputType: UITouch.TouchType) -> Calculator? {
        if inputType == .direct {
            return { previous, current, next in
                var size: DIFloat?
                
                size = current?.computeValueBasedOnSpeed(previous,
                                                         next,
                                                         minValue: 0.8,
                                                         maxValue: 1.7,
                                                         initialValue: nil,
                                                         finalValue: nil,
                                                         minSpeed: 180,
                                                         maxSpeed: 2100,
                                                         remap: { (v) -> (DIFloat) in
                                                            MathUtils.power(v: v, p: 0.35)
                })
                
                if size == nil {
                    size = 1.5
                }
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.size = size
                
                return pathPoint
            }
        } else if inputType == .pencil {
            return { previous, current, next in
                var size = current?.computeValueBasedOnPressure(minValue: 0.5,
                                                                maxValue: 1.0,
                                                                minPressure: 0,
                                                                maxPressure: 5,
                                                                reverse: false,
                                                                remap: { (v) -> (Float) in
                    MathUtils.power(v: v, p: 0.35)
                })
                
                if size == nil {
                    size = 1.5
                }
                
                //let cosAltitudeAngle = cos((current?.altitudeAngle!)!)
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.size = size
                
                return pathPoint
            }
        }
        
        return nil
    }
    
    func getLayout(inputType: UITouch.TouchType) -> PathPointLayout? {
        if inputType == .direct {
            return PathPointLayout([.x, .y, .size])
        } else if inputType == .pencil {
            return PathPointLayout([.x, .y, .size])
        }
        
        return nil
    }
}

class Felt: VectorTool {
    func brush() -> Geometry.VectorBrush {
        return Geometry.VectorBrush(polygons: [
            BrushPolygon(minScale: 0, points: BrushApplier.createUnitCirclePolygon(verticesCount: 4)),
            BrushPolygon(minScale: 2, points: BrushApplier.createUnitCirclePolygon(verticesCount: 8)),
            BrushPolygon(minScale: 6, points: BrushApplier.createUnitCirclePolygon(verticesCount: 16)),
            BrushPolygon(minScale: 8, points: BrushApplier.createUnitCirclePolygon(verticesCount: 32))
        ])
    }
    
    func getCalculator(inputType: UITouch.TouchType) -> Calculator? {
        if inputType == .direct {
            return { previous, current, next in
                var size = current?.computeValueBasedOnSpeed(previous,
                                                             next,
                                                             minValue: 2.8,
                                                             maxValue: 1.6,
                                                             initialValue: 2.6,
                                                             finalValue: 3.4,
                                                             minSpeed: 300,
                                                             maxSpeed: 1400,
                                                             remap: { (v) -> (DIFloat) in
                                                                Float(pow(Double(v), 0.65))
                                                                //MathUtils.power(v: v, p: 0.65)
                })
                
                if size == nil {
                    size = 3
                }
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.size = size
                
                return pathPoint
            }
        } else if inputType == .pencil {
            return { previous, current, next in
                var size: DIFloat?
                
                if current!.force! == -1 {
                    size = current?.computeValueBasedOnSpeed(previous,
                                                             next,
                                                             minValue: 2.5,
                                                             maxValue: 1.3,
                                                             initialValue: 2.4,
                                                             finalValue: 3.2,
                                                             minSpeed: 0,
                                                             maxSpeed: 3500,
                                                             remap: { (v) -> (DIFloat) in
                                                                Float(pow(Double(v), 1.17))
                    })
                } else {
                    size = current?.computeValueBasedOnPressure(minValue: 0.9,
                                                                maxValue: 1.1,
                                                                minPressure: 0,
                                                                maxPressure: 5,
                                                                reverse: false,
                                                                remap: { (v) -> (Float) in
                                                                    Float(pow(Double(v), 1.17))
                    })
                }
                
                if size == nil {
                    size = 1.1
                }
                
                let cosAltitudeAngle = abs(cos((current?.altitudeAngle!)!))
                
                let tiltScale = 1.5 * cosAltitudeAngle
                let scaleX = 1 + tiltScale
                let offsetX = size! * tiltScale
                let rotation = current?.computeNearestAzimuthAngle(previous: previous)
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.size = size! + 0.1 * (current?.force ?? 0)
                pathPoint.rotation = rotation
                pathPoint.scaleX = scaleX
                pathPoint.offsetX = offsetX
                
                return pathPoint
            }
        }
        
        return nil
    }
    
    func getLayout(inputType: UITouch.TouchType) -> PathPointLayout? {
        if inputType == .direct {
            return PathPointLayout([.x, .y, .size])
        } else if inputType == .pencil {
            return PathPointLayout([.x, .y, .size, .rotation, .scaleX, .offsetX])
        }
        
        return nil
    }
}

class Brush: VectorTool {
    func brush() -> Geometry.VectorBrush {
        return Geometry.VectorBrush(polygons: [
            BrushPolygon(minScale: 0, points: BrushApplier.createUnitCirclePolygon(verticesCount: 4)),
            BrushPolygon(minScale: 2, points: BrushApplier.createUnitCirclePolygon(verticesCount: 8)),
            BrushPolygon(minScale: 6, points: BrushApplier.createUnitCirclePolygon(verticesCount: 16)),
            BrushPolygon(minScale: 8, points: BrushApplier.createUnitCirclePolygon(verticesCount: 32))
        ])
    }
    
    func getCalculator(inputType: UITouch.TouchType) -> Calculator? {
        if inputType == .direct {
            return { previous, current, next in
                var size = current?.computeValueBasedOnSpeed(previous,
                                                             next,
                                                             minValue: 3,
                                                             maxValue: 8,
                                                             initialValue: nil,
                                                             finalValue: nil,
                                                             minSpeed: 182,
                                                             maxSpeed: 3547,
                                                             remap: { (v) -> (DIFloat) in
                                                                MathUtils.power(v: v, p: 1.19)
                })
                
                if size == nil {
                    size = 10
                }
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.size = size
                
                return pathPoint
            }
        } else if inputType == .pencil {
            return { previous, current, next in
                var size: DIFloat?
                
                if current!.force == -1 {
                    size = current?.computeValueBasedOnSpeed(previous,
                                                             next,
                                                             minValue: 1.5,
                                                             maxValue: 5,
                                                             initialValue: nil,
                                                             finalValue: nil,
                                                             minSpeed: 0,
                                                             maxSpeed: 3500,
                                                             remap: { (v) -> (DIFloat) in
                                                                Float(pow(Double(v), 1.17))
                    })
                } else {
                    size = current?.computeValueBasedOnPressure(minValue: 1.5,
                                                                maxValue: 5,
                                                                minPressure: 0,
                                                                maxPressure: 1,
                                                                reverse: false,
                                                                remap: { (v) -> (Float) in
                                                                    Float(pow(Double(v), 1.17))
                    })
                }
                
                if size == nil {
                    size = 1.5
                }
                
                let cosAltitudeAngle = abs(cos((current?.altitudeAngle!)!))
                
                let tiltScale = 1.5 * cosAltitudeAngle
                let scaleX = 1 + tiltScale
                let offsetX = size! * tiltScale
                let rotation = current?.computeNearestAzimuthAngle(previous: previous)
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.size = size
                pathPoint.rotation = rotation
                pathPoint.scaleX = scaleX
                pathPoint.offsetX = offsetX
                
                return pathPoint
            }
        }
        
        return nil
    }
    
    func getLayout(inputType: UITouch.TouchType) -> PathPointLayout? {
        if inputType == .direct {
            return PathPointLayout([.x, .y, .size])
        } else if inputType == .pencil {
            return PathPointLayout([.x, .y, .size, .rotation, .scaleX, .offsetX])
        }
        
        return nil
    }
}

class Pencil: RasterTool {
    var particleSpacing: Float = 0.15
    
    var previousSize: DIFloat = 3
    var previousAlpha: DIFloat = 0.2
    let MIN_PENCIL_SIZE: DIFloat = 2
    let MAX_PENCIL_SIZE: DIFloat = 5.5
    let MIN_ALPHA: DIFloat = 0.1
    let MAX_ALPHA: DIFloat = 0.7
    
    func particleBrush(graphics: Graphics?) -> ParticleBrush {
        let brush = ParticleBrush()
        
        brush.scattering = 0.15
        brush.rotationMode = .random
        brush.shapeTexture = graphics?.createTexture(by: UIImage(named: "essential_shape.png")!)
        brush.fillTexture = graphics?.createTexture(by: UIImage(named: "essential_fill_11.png")!)
        
        return brush
    }
    
    func getCalculator(inputType: UITouch.TouchType) -> Calculator? {
        if inputType == .direct {
            return { previous, current, next in
                var size = current?.computeValueBasedOnSpeed(previous,
                                                             next,
                                                             minValue: self.MIN_PENCIL_SIZE,
                                                             maxValue: 7,
                                                             initialValue: self.MIN_PENCIL_SIZE,
                                                             finalValue: 10,
                                                             minSpeed: 80,
                                                             maxSpeed: 1400,
                                                             remap: nil)
                
                if size == nil {
                    size = self.previousSize
                } else {
                    self.previousSize = size!
                }
                
                var alpha = current?.computeValueBasedOnSpeed(previous,
                                                              next,
                                                              minValue: 0.1,
                                                              maxValue: 0.5,
                                                              initialValue: 0.1,
                                                              finalValue: 0.5,
                                                              minSpeed: 80,
                                                              maxSpeed: 1400,
                                                              remap: nil)

                if alpha == nil {
                    alpha = self.previousAlpha
                } else {
                    self.previousAlpha = alpha!
                }
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.size = size
                pathPoint.alpha = alpha
                
                return pathPoint
            }
        } else if inputType == .pencil {
            return { previous, current, next in
                let cosAltitudeAngle = cos(current!.altitudeAngle!)
                let sinAzimuthAngle = sin(current!.azimuthAngle!)
                let cosAzimuthAngle = cos(current!.azimuthAngle!)
                
                // calculate the offset of the pencil tip due to tilted position
                let x = sinAzimuthAngle * cosAzimuthAngle
                let y = cosAltitudeAngle * cosAzimuthAngle
                let offsetX = 5 * -y
                let offsetY = 5 * -x
                
                let rotation = current!.computeNearestAzimuthAngle(previous: previous)
                // now, based on the tilt of the pencil the size of the brush is increasing, as the pencil tip is covering a larger area
                let size = Float.maximum(self.MIN_PENCIL_SIZE, Float.minimum(self.MAX_PENCIL_SIZE, self.MIN_PENCIL_SIZE + 20 * cos(current!.altitudeAngle!)))
                
                // Change the intensity of alpha value by pressure of speed, if available else use speed
                var alpha: DIFloat?
                
                if current!.force! == -1 {
                    alpha = current!.computeValueBasedOnSpeed(previous,
                                                              next,
                                                              minValue: self.MIN_ALPHA,
                                                              maxValue: self.MAX_ALPHA,
                                                              initialValue: nil,
                                                              finalValue: nil,
                                                              minSpeed: 0,
                                                              maxSpeed: 3500) { (v) -> (DIFloat) in
                                                                1 - v
                    }
                } else {
                    alpha = current!.computeValueBasedOnPressure(minValue: self.MIN_ALPHA,
                                                                 maxValue: self.MAX_ALPHA,
                                                                 minPressure: 0,
                                                                 maxPressure: 5,
                                                                 reverse: false,
                                                                 remap: { (v) -> (Float) in
                                                                    Float(pow(Double(v), 1))
                    })
                }
                
                if alpha == nil {
                    alpha = self.previousAlpha
                } else {
                    self.previousAlpha = alpha!
                }
                
                print("size -> \(size)")
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.alpha = alpha
                pathPoint.size = size
                pathPoint.rotation = rotation
                pathPoint.offsetX = 1
                pathPoint.offsetY = 1
                
                return pathPoint
            }
        }
        
        return nil
    }
    
    func getLayout(inputType: UITouch.TouchType) -> PathPointLayout? {
        if inputType == .direct {
            return PathPointLayout([.x, .y, .size, .alpha])
        } else if inputType == .pencil {
            return PathPointLayout([.x, .y, .size, .alpha, .offsetX, .offsetY])
        }
        
        return nil
    }
}

class WaterBrush: RasterTool {
    var particleSpacing: Float = 0.0
    
    func particleBrush(graphics: Graphics?) -> ParticleBrush {
        let brush = ParticleBrush()
        
        brush.scattering = 0.03
        brush.rotationMode = .random
        brush.shapeTexture = graphics?.createTexture(by: UIImage(named: "essential_shape.png")!)
        brush.fillTexture = graphics?.createTexture(by: UIImage(named: "essential_fill_14.png")!)
        
        return brush
    }
    
    func getCalculator(inputType: UITouch.TouchType) -> Calculator? {
        if inputType == .direct {
            return { previous, current, next in
                var size = current?.computeValueBasedOnSpeed(previous,
                                                             next,
                                                             minValue: 28,
                                                             maxValue: 32,
                                                             initialValue: nil,
                                                             finalValue: nil,
                                                             minSpeed: 38,
                                                             maxSpeed: 1500,
                                                             remap: { (v) -> (DIFloat) in
                                                                return MathUtils.power(v: v, p: 3)
                })
                
                if size == nil {
                    size = 1
                }
                
                var alpha = current?.computeValueBasedOnSpeed(previous,
                                                              next,
                                                              minValue: 0.02,
                                                              maxValue: 0.25,
                                                              initialValue: nil,
                                                              finalValue: nil,
                                                              minSpeed: 38,
                                                              maxSpeed: 1500,
                                                              remap: { (v) -> (DIFloat) in
                                                                return MathUtils.power(v: v, p: 3)
                })

                if alpha == nil {
                    alpha = 1
                }
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                
                pathPoint.size = size
                pathPoint.alpha = alpha
                pathPoint.rotation = 0
                pathPoint.scaleX = 1
                pathPoint.scaleY = 1
                pathPoint.offsetX = 0
                pathPoint.offsetY = 0
                
                return pathPoint
            }
        } else if inputType == .pencil {
            return { previous, current, next in
                let size: Float = 9.0
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.size = size + 5 * (current?.force ?? 0)
            
                pathPoint.alpha = current?.force == nil ? 0.0 : min((0.1 + 0.2 * (current?.force!)!), 1.0)
                pathPoint.rotation = current?.computeNearestAzimuthAngle(previous: previous)
                let cosAltitudeAngle = cos((current?.altitudeAngle!)!)
                
                pathPoint.scaleX = 1.0 + 20 * cosAltitudeAngle
                pathPoint.scaleY = 1.0
                pathPoint.offsetX = 0.5 * 10.0 * cosAltitudeAngle
                pathPoint.offsetY = 0
                
                pathPoint.blue = 1
                pathPoint.green = 0.3
                pathPoint.red = 0.5
                
                return pathPoint
            }
        }
        
        return nil
    }
    
    func getLayout(inputType: UITouch.TouchType) -> PathPointLayout? {
        if inputType == .direct {
            return PathPointLayout([.x, .y, .size, .alpha])
        } else if inputType == .pencil {
            return PathPointLayout([.x, .y, .size, .rotation, .offsetX, .offsetY, .alpha])
        }
        
        return nil
    }
    
    
}

class Crayon: RasterTool {
    var particleSpacing: Float = 0.0
    
    func particleBrush(graphics: Graphics?) -> ParticleBrush {
        let brush = ParticleBrush()
        
        brush.scattering = 0.05
        brush.rotationMode = .random
        brush.shapeTexture = graphics?.createTexture(by: UIImage(named: "essential_shape.png")!)
        brush.fillTexture = graphics?.createTexture(by: UIImage(named: "essential_fill_17")!)

        return brush
    }
    
    func getCalculator(inputType: UITouch.TouchType) -> Calculator? {
        if inputType == .direct {
            return { previous, current, next in
                var size = current?.computeValueBasedOnSpeed(previous,
                                                             next,
                                                             minValue: 18,
                                                             maxValue: 28,
                                                             initialValue: nil,
                                                             finalValue: nil,
                                                             minSpeed: 10,
                                                             maxSpeed: 1400,
                                                             remap: nil)
                
                if size == 0 {
                    size = 1
                }
                
                var alpha = current?.computeValueBasedOnSpeed(previous,
                                                              next,
                                                              minValue: 0.1,
                                                              maxValue: 0.6,
                                                              initialValue: nil,
                                                              finalValue: nil,
                                                              minSpeed: 10,
                                                              maxSpeed: 1400,
                                                              remap: nil)
                
                if alpha == 0 {
                    alpha = 1
                }
                
                
                var pathPoint = PathPoint(x: current!.x, y: current!.y)
                pathPoint.size = size
                pathPoint.alpha = alpha
                pathPoint.rotation = 0
                pathPoint.scaleX = 1
                pathPoint.scaleY = 1
                pathPoint.offsetX = 0
                pathPoint.offsetY = 0
                
                pathPoint.blue = 1
                pathPoint.green = 0.5
                pathPoint.red = 0.2
                
                return pathPoint
            }
        } else if inputType == .pencil {
            return { previous, current, next in
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
                
                pathPoint.blue = 1
                pathPoint.green = 0.3
                pathPoint.red = 0.5
                
                return pathPoint
            }
        }
        
        return nil
    }
    
    func getLayout(inputType: UITouch.TouchType) -> PathPointLayout? {
        if inputType == .direct {
            return PathPointLayout([.x, .y, .size, .alpha])
        } else if inputType == .pencil {
            return PathPointLayout([.x, .y, .size, .alpha])
        }
        
        return nil
    }
}

class ToolPalette {
    static let shared = ToolPalette()
    
    // Raster
    let pencil = Pencil()
    let waterBrush = WaterBrush()
    let crayon = Crayon()
    
    // Vector
    let pen = Pen()
    let felt = Felt()
    let brush = Brush()
    
    var selectedRasterTool: RasterTool?
    var selectedVectorTool: VectorTool?
    
    private init() {
        selectedRasterTool = pencil
        selectedVectorTool = pen
    }
}
