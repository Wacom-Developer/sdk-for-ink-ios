//
//  VectorBrushFactory.swift
//  WILLSampleApp
//
//  Created by Mincho Dzhagalov on 8.07.20.
//  Copyright © 2020 Mincho Dzhagalov. All rights reserved.
//

import Foundation
import WacomInk

class VectorBrushFactory {
    public static func createElipseBrush(pointsCount: Int, width: Float, height: Float, startAngleRadians: Double = 0.0) -> [DIFloat2] {
        var brushPoints = [DIPoint2]()
        let radianStep = Double.pi * 2 / Double(pointsCount)
        
        for i in 0...pointsCount {
            let currentRadian = startAngleRadians + Double(i) * radianStep
            
            brushPoints.append(DIPoint2(arrayLiteral: width * Float(cos(currentRadian)), height * Float(sin(currentRadian))))
        }
        
        return brushPoints
    }
}
