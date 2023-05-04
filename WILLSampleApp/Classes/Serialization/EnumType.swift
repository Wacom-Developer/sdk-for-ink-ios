//
//  ManipulationType.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 14.11.19.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

enum ManipulationType: Int, CustomStringConvertible {
    case draw = 0
    case intersect
    case select
    
    static func allValues() -> [String] {
        return [draw, intersect, select].map({$0.description})
    }
    
    static func count() -> Int {
        return allValues().count
    }
    
    public var description: String {
        switch self {
        case .draw:
            return "Drawing"
        case .intersect:
            return "Intersecting"
        case .select:
            return "Selecting"
        }
    }
}

enum DemosSpatialContextType: Int, CustomStringConvertible {
    case blue = 0
    case green
    
    static func allValues() -> [String] {
        return [blue, green].map({$0.description})
    }
    
    static func count() -> Int {
        return allValues().count
    }
    
    public var description: String {
        switch self {
        case .blue:
            return "Blue"
        case .green:
            return "Green"
        }
    }
}

enum TransformationType: Int, CustomStringConvertible {
    case move = 0
    case rotate
    
    static func allValues() -> [String] {
        return [move, rotate].map({$0.description})
    }
    
    static func count() -> Int {
        return allValues().count
    }
    
    public var description: String {
        switch self {
        case .move:
            return "Move"
        case .rotate:
            return "Rotate"
        }
    }
}

enum ManipulatorCollectionType: Int, CustomStringConvertible {
    case bySimplifiedPolygon = 0
    case bySpline
    
    static func allValues() -> [String] {
        return [bySimplifiedPolygon, bySpline].map({$0.description})
    }
    
    static func count() -> Int {
        return allValues().count
    }
    
    public var description: String {
        switch self {
        case .bySimplifiedPolygon:
            return "Polygon"
        case .bySpline:
            return "Spline"
        }
    }
}

internal class Predicates {
    internal static var manipulation = "wt:manipulation";
}

internal enum TestManipulationType: String {
    case ErasePartialStroke = "ErasePartialStroke"
    case EraseWholeStroke = "EraseWholeStroke"
    case SelectPartialStroke = "SelectPartialStroke"
    case SelectWholeStroke = "SelectWholeStroke"
}
