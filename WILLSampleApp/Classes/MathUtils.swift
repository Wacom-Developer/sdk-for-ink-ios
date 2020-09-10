//
//  MathUtils.swift
//  WILLSampleApp
//
//  Created by Mincho Dzhagalov on 27.05.20.
//  Copyright © 2020 Mincho Dzhagalov. All rights reserved.
//

import Foundation

class MathUtils {
    static func power(v: Float, p: Float) -> Float {
        return Float(pow(Double(v), Double(p)))
    }
    
    static func periodic(v: Float, p: Float) -> Float {
        return Float(0.5 - 0.5 * cos(p * Float.pi * v))
    }
    
    static func sigmoid(t: Float, k:Float) -> Float {
        return (1 + k) * t / (abs(t) + k)
    }
    
    static func sigmoid1(v: Float, p: Float, minValue: Float = 0.0, maxValue: Float = 1.0) -> Float {
        let middle: Float = (maxValue + minValue) * 0.5
        let halInterval = (maxValue - minValue) * 0.5
        let t = (v - middle) / halInterval
        let s = sigmoid(t: t, k: p)
        
        return middle + s * halInterval
    }
}
