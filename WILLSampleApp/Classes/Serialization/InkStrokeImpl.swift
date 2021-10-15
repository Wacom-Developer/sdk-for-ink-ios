//
//  InkStrokeImplementation.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 10.03.20.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

class Quartz2D {
    class InkStrokeFactory : InkStrokeFactoryProtocol {
        func createStroke(_ newSpline: Spline, _ originalStroke: InkStrokeProtocol, inkStrokeId: Identifier?, firstPointIndex: UInt32, pointsCount: UInt32) -> InkStrokeProtocol {
            let identifier = inkStrokeId ?? Identifier.fromNewUUID()
            
            var newSplineSensorMappings: [UInt32] = []
            let pointsCount = Int(pointsCount) //- 2
            if pointsCount > 0 && originalStroke.sensorDataMappings != [] {
                newSplineSensorMappings.reserveCapacity(pointsCount)
                
                let diff = originalStroke.sensorDataMappings.count - Int(firstPointIndex)
                for i in 0..<pointsCount {
                    if i >= diff {//Int(firstPointIndex) + i >= originalStroke.sensorDataMappings.count {
                        newSplineSensorMappings.append(originalStroke.sensorDataMappings[originalStroke.sensorDataMappings.count - 1])
                    } else {
                        newSplineSensorMappings.append(originalStroke.sensorDataMappings[Int(firstPointIndex) + i])
                    }
                }
            }
            
            let resultStroke = InkStroke(
                identifier: identifier!,
                spline: newSpline,
                layout: originalStroke.layout,
                vectorBrush: originalStroke.vectorBrush,
                constants: originalStroke.constants as! Quartz2D.ConstantAttributes,
                sensorDataOffset: originalStroke.sensorDataOffset + UInt32(firstPointIndex),
                sensorDataMappings: newSplineSensorMappings,
                brushName: "",
                tool: ToolPalette.shared.selectedVectorTool
            )
            
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
        public var constants: StrokeAttributesProtocol = ConstantAttributes()
        public var id: Identifier
        public var spline: Spline
        public var layout: PathPointLayout
        public var vectorBrush: Geometry.VectorBrush
        public var sensorDataOffset: UInt32 = 0
        public var sensorDataMappings: [UInt32] = []
        public var brushName: String
        public var tool: VectorTool?
        
        public init(
            identifier: Identifier,
            spline: Spline,
            layout: PathPointLayout,
            vectorBrush: Geometry.VectorBrush,
            constants: ConstantAttributes,
            sensorDataOffset: UInt32,
            sensorDataMappings: [UInt32],
            brushName: String,
            tool: VectorTool?
        ) {
            self.id = identifier
            self.spline = spline
            self.layout = layout
            self.vectorBrush = vectorBrush
            self.constants = constants
            self.sensorDataOffset = sensorDataOffset
            self.sensorDataMappings = sensorDataMappings
            self.brushName = brushName
            self.tool = tool
        }
        
        public init(
            identifier: Identifier,
            spline: Spline,
            layout: PathPointLayout,
            vectorBrush: Geometry.VectorBrush,
            constants: ConstantAttributes,
            brushName: String,
            tool: VectorTool?
        ) {
            self.id = identifier
            self.spline = spline
            self.layout = layout
            self.vectorBrush = vectorBrush
            self.constants = constants
            self.sensorDataOffset = 0 // Fix review
            self.sensorDataMappings = []
            let pointsCount = self.layout.count == 0 ? 0 : self.spline.path.count / self.layout.count //- 2 // FIX, to be reviseds Remove first and last control points in spline
            self.sensorDataMappings.reserveCapacity(pointsCount)
            self.brushName = brushName
            self.tool = tool
            
            // One to one mapping of sensor data points to spline points
            for i in 0..<pointsCount {
                self.sensorDataMappings.append(UInt32(i));
            }
        }
        // start serialization region
        
        public func getSerializationVectorBrush() -> VectorBrush {
            // TODO: the brush should be cached and only created when there is a change in the brush polygons
            let name = URIBuilder.getBrushURI(type: "vector", name: brushName)
                         
            let URIs = tool!.getURIs()
                
            return try! VectorBrush(name: name, brushPrototypeURIs: URIs)
        }
        
        public func getSerializationStyle(brushName: String ) -> Style {
            // TODO: the style should be cached and only created when there is a change in the constants
            let style = try! Style(brushUri: brushName);
            style.pathPointProperties?.alpha = constants.alpha;
            style.pathPointProperties?.blue = constants.blue;
            style.pathPointProperties?.green = constants.green;
            style.pathPointProperties?.offsetX = constants.offsetX;
            style.pathPointProperties?.offsetY = constants.offsetY;
            style.pathPointProperties?.offsetZ = constants.offsetZ;
            style.pathPointProperties?.red = constants.red;
            style.pathPointProperties?.rotation = constants.rotation;
            style.pathPointProperties?.scaleX = constants.scaleX;
            style.pathPointProperties?.scaleY = constants.scaleY;
            style.pathPointProperties?.scaleZ = constants.scaleZ;
            style.pathPointProperties?.size = constants.size;
            
            return style;
        }
        
        //implementation
        
        private func getUniqueBrushName() -> String {
            // Code from MD5HashGenerator // TODO: discuss better ways for generating brush names
            // Generate VectorBrush
            // unique name based on the brush polygons content
            var stringBuilder = ""//new StringBuilder();
            
            for brushPoly in vectorBrush.polygons {
                stringBuilder += String(format: "%.4f", brushPoly.minScale)
                for point in brushPoly.points {
                    stringBuilder += String(format: "%.4f", point.x)
                    stringBuilder += String(format: "%.4f", point.y)
                }
            }
            
            stringBuilder += "\n"
            
            var bytes = MD5HashGenerator.getMD5Hash(input: stringBuilder)
            // Fix check if neeeded Endian reverse Identifier.reverse
            return NSUUID(uuidBytes: bytes).uuidString
            
        }
        
        // end serialization region
    }
}
