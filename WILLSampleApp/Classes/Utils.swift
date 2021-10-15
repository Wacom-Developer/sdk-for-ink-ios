//
//  Utils.swift
//  WILLSampleApp
//
//  Created by Mincho Dzhagalov on 11.08.21.
//  Copyright © 2021 Mincho Dzhagalov. All rights reserved.
//

import Foundation
import WacomInk

class BrushFactory {
    static func createEllipseBrush(pointsCount: Int , width: Float , height: Float , startAngleRadians: Float = 0.0) -> [DIFloat2] {
        var brushPoints: [DIFloat2] = [];
        
        let radiansStep = Float.pi * 2 / Float(pointsCount);
        
        for i in 0..<pointsCount {
            let currentRadian = startAngleRadians + Float(i) * radiansStep;
            brushPoints.append(DIFloat2(width * cos(currentRadian), height * sin(currentRadian)));
        }
        
        return brushPoints;
    }
}

class URIBuilder {
    static func getBrushURI(type: String, name: String) -> String {
        return "app://com.wacom.will3sample/\(type)-brush/\(name)"
    }
}

class ShapeFactory {
    static let circle_precision: Float = 20
    static let circle_radius: Float = 0.5
    static let ellipse_precision: Float = 20
    static let ellipse_radius_x: Float = 0.5
    static let ellipse_radius_y: Float = 0.25
    
    static func createCircle(n: Float = ShapeFactory.circle_precision, r: Float = ShapeFactory.circle_radius, c: DIPoint2 = DIPoint2(0, 0)) -> [DIPoint2] {
        return ShapeFactory.createEllipse(n: n, rx: r, ry: r, c: c)
    }

    static func createEllipse(n: Float = ShapeFactory.circle_precision, rx: Float = ShapeFactory.ellipse_radius_x, ry: Float = ShapeFactory.ellipse_radius_y, c: DIPoint2 = DIPoint2(0, 0)) -> [DIPoint2] {
        var points = [DIPoint2]()
        let angleStep = 2 * Float.pi / n
        
        if rx <= 0 {
            print("rx cannot be equal to or lower than 0")
        }
        if ry <= 0 {
            print("ry cannot be equal to or lower than 0")
        }
        
        for i in 0...Int(n) {
            let theta = Float(i) * angleStep
            let x = rx * Float(cos(theta))
            let y = ry * Float(sin(theta))
            
            points.append(DIPoint2(c.x + x, c.y + y))
        }
        
        return points
    }
}
