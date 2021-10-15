//
//  URIShapeResolver.swift
//  WILLSampleApp
//
//  Created by Mincho Dzhagalov on 6.10.21.
//  Copyright © 2021 Mincho Dzhagalov. All rights reserved.
//

import Foundation
import WacomInk

class URIShapeResolver {
    static func resolveShape(uri: BrushPolygonUri) throws -> BrushPolygon {
        let url = URL(string: uri.shapeUri)
        let pairs = url?.query?.components(separatedBy: "&")
        
        let type = uri.shapeUri.components(separatedBy: "?").first?.replacingOccurrences(of: "will://brush/3.0/shape/", with: "")
        
        switch type?.lowercased() {
        case "circle":
            var precision: Float = 0
            var radius: Float = 0
            
            for pair in pairs! {
                let key = pair.components(separatedBy: "=")[0]
                let value = pair.components(separatedBy: "=")[1]
                
                switch key {
                case "precision":
                    precision = Float(value) ?? 20.0
                case "radius":
                    radius = Float(value) ?? 1.0
                default:
                    throw "Unknown key in brush prototype URI -> \(key)"
                }
            }
            return try BrushPolygon.createNormalized(minScale: uri.minScale, points: ShapeFactory.createCircle(n: precision, r: radius))
        case "ellipse":
            var precision: Float = 0
            var radiusX: Float = 0
            var radiusY: Float = 0
            
            for pair in pairs! {
                let key = pair.components(separatedBy: "=")[0]
                let value = pair.components(separatedBy: "=")[1]
                
                switch key {
                case "precision":
                    precision = Float(value) ?? 20.0
                case "radiusX":
                    radiusX = Float(value) ?? 1.0
                case "radiusY":
                    radiusY = Float(value) ?? 0.5
                default:
                    throw "Unknown key in brush prototype URI -> \(key)"
                }
            }
            
            return try BrushPolygon.createNormalized(minScale: uri.minScale, points: ShapeFactory.createEllipse(n: precision, rx: radiusX, ry: radiusY))
        default:
            throw "Unknown shape type when parsing URI"
        }
    }
}
