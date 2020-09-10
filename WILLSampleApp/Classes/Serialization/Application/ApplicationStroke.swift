//
//  ApplicationStroke.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 6.04.20.
//  Copyright © 2020 nikolay.atanasov. All rights reserved.
//

import WacomInk

class ApplicationStroke {
    public var canvas: CAShapeLayer?
    public var inkStroke: Quartz2D.InkStroke
    public var touchType: UITouch.TouchType? = nil
    public var sensorDataId: Identifier? = nil
    
    init(canvas: CAShapeLayer? = nil, inkStroke: Quartz2D.InkStroke, touchType: UITouch.TouchType? = nil) {
        self.canvas = canvas
        self.inkStroke = inkStroke
        self.touchType = touchType
    }
}
