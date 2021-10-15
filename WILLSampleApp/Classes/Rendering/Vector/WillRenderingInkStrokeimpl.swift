//
//  InkStrokeImplementation.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 10.03.20.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

class WillRendering {
    class InkStrokeFactory : InkStrokeFactoryProtocol {
        func createStroke(_ newSpline: Spline, _ originalStroke: InkStrokeProtocol, inkStrokeId: Identifier?, firstPointIndex: UInt32, pointsCount: UInt32) -> InkStrokeProtocol {
            let identifier = inkStrokeId ?? Identifier.fromNewUUID()
            let resultStroke = InkStroke(
                identifier: identifier!,
                spline: newSpline,
                layout: originalStroke.layout,
                vectorBrush: originalStroke.vectorBrush,
                constants: originalStroke.constants as! WillRendering.ConstantAttributes)
            
            return resultStroke
        }
    }
    
    public class ConstantAttributes : StrokeAttributesProtocol {
        /// Gets the Size property.
        var size: Float = 1.0

        /// Gets the Rotation property.
        var rotation: Float = 0.0

        /// Gets the ScaleX property.
        var scaleX: Float = 1.0

        /// Gets the ScaleY property.
        var scaleY: Float = 1.0

        /// Gets the ScaleZ property.
        var scaleZ: Float = 1.0

        /// Gets the OffsetX property.
        var offsetX: Float = 0.0

        /// Gets the OffsetY property.
        var offsetY: Float = 0.0

        /// Gets the OffsetZ property.
        var offsetZ: Float = 0.0 

        /// Gets the Red property.
        var red: Float = 0.5

        /// Gets the Green property.
        var green: Float = 0.5

        /// Gets the Blue property.
        var blue: Float = 0.5

        /// Gets the Alpha property.
        var alpha: Float = 0.5
        
        init(size: Float = 1, rotation: Float = 0, scale: DIFloat3 = DIFloat3(1, 1, 1), offset: DIFloat3 = DIFloat3(0, 0, 0), colorRGBA: DIFloat4 = DIFloat4(0.5, 0.5, 0.5, 0.5)) {
            self.size = size
            self.rotation = rotation
            self.scaleX = scale.x
            self.scaleY = scale.y
            self.scaleZ = scale.z
            self.offsetX = offset.x
            self.offsetY = offset.y
            self.offsetZ = offset.z
            self.red = colorRGBA.x
            self.green = colorRGBA.y
            self.blue = colorRGBA.z
            self.alpha = colorRGBA.w
        }
        
    }

    public class InkStroke : InkStrokeProtocol {
        public var id: Identifier
        public var constants: StrokeAttributesProtocol = ConstantAttributes()
        public var spline: Spline
        public var layout: PathPointLayout
        public var vectorBrush: Geometry.VectorBrush
        public var sensorDataOffset: UInt32 = 0
        public var sensorDataMappings: [UInt32] = []
        
        public init(
            identifier: Identifier,
            spline: Spline,
            layout: PathPointLayout,
            vectorBrush: Geometry.VectorBrush,
            constants: ConstantAttributes) {
            self.id = identifier
            self.spline = spline
            self.layout = layout
            self.vectorBrush = vectorBrush
            self.constants = constants
        }
    }
}
