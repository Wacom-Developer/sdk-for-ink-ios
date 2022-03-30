//
//  SVGExporter.swift
//  WILLSampleApp
//
//  Created by Mincho Dzhagalov on 14.10.21.
//  Copyright © 2021 Mincho Dzhagalov. All rights reserved.
//

import Foundation
import WacomInk

class SVGExporter {
    private var mConvexHullChainProducer = ConvexHullChainProducer()
    private var mPolygonMerger = PolygonMerger()
    private var mPolygonSimplifier = PolygonSimplifier(epsilon: 0.1)
    
    private var minX = Float.greatestFiniteMagnitude
    private var minY = Float.greatestFiniteMagnitude
    private var maxX = Float.zero
    private var maxY = Float.zero
    
    let htmlTag = XML(name: "html")
    let bodyTag = XML(name: "body")
    let svgTag = XML(name: "svg")
    
    func exportToSVG(inkDocument: InkModel, svgWidth: Float, svgHeight: Float, fit: Bool) -> XML {
        drawStrokes(inkDocument: inkDocument, svgWidth: svgWidth, svgHeight: svgHeight, fit: true)
        
        return htmlTag
    }
    
    func drawStrokes(inkDocument: InkModel, svgWidth: Float, svgHeight: Float, fit: Bool) {
        if inkDocument.inkTree.root != nil {
            let enumerator = inkDocument.inkTree.root?.getRecursiveEnumerator()
            
            svgTag.addAttribute(name: "width", value: svgWidth)
            svgTag.addAttribute(name: "height", value: svgHeight)
            svgTag.addAttribute(name: "xmlns", value: "http://www.w3.org/2000/svg")
            
            // process every stroke by using the appropriate vector brush geometry
            while ((enumerator?.next()) != nil) {
                if let strokeNode = enumerator?.current as? StrokeNode {
                    if let brushUri = strokeNode.stroke.style.brushUri {
                        let brush = inkDocument.brushes.tryGetBrush(brushName: brushUri)
                        // only exports vector strokes
                        if let vectorBrush = brush as? VectorBrush {
                            var vb: Geometry.VectorBrush
                            
                            // if the brush has geometry
                            if vectorBrush.brushPolygons?.count ?? 0 > 0 {
                                var brushPolygons = [BrushPolygon]()
                                
                                for polygon in vectorBrush.brushPolygons! {
                                    var newPoints = [DIPoint2]()
                                    for point in polygon.points {
                                        newPoints.append(DIPoint2(x: point.x, y: point.y))
                                    }
                                    
                                    brushPolygons.append(try! BrushPolygon.createNormalized(minScale: polygon.minScale, points: newPoints))
                                }
                                
                                vb = try! Geometry.VectorBrush(polygons: brushPolygons)
                            } else if vectorBrush.brushPrototypeURIs.count > 0 { // the geometry was missing, so it needs to be generated by using the supplied URIs
                                var brushPolygons = [BrushPolygon]()
                                
                                for uri in vectorBrush.brushPrototypeURIs {
                                    brushPolygons.append(try! URIShapeResolver.resolveShape(uri: uri))
                                }
                                
                                vb = try! Geometry.VectorBrush(polygons: brushPolygons)
                            } else {
                                continue
                            }
                            
                            drawStroke(stroke: strokeNode.stroke, vectorBrush: vb)
                        }
                    }
                }
            }
            
            bodyTag.addChild(svgTag)
            htmlTag.addChild(bodyTag)
        }
    }
    
    private func drawStroke(stroke: Stroke, vectorBrush: WacomInk.Geometry.VectorBrush) {
        let alpha: Float = (stroke.style.pathPointProperties?.alpha)!
        
        // go through the pipeline and process the countours
        let layout = PathPointLayout(layoutMask: try! stroke.getSpline().layoutMask)
        let splineInterpolator = try! CurvatureBasedInterpolator(inputLayout: layout)
        let brushApplier = try! BrushApplier(layout: layout, brush: vectorBrush)
        let readOnlySpline = try! stroke.getSpline()
        let spline = try! Spline(layoutMask: readOnlySpline.layoutMask, path: readOnlySpline.path, tStart: readOnlySpline.tStart, tFinal: readOnlySpline.tFinal)
        let points = try! splineInterpolator.add(isFirst: true, isLast: true, addition: spline, prediction: nil)
        let polys = try! brushApplier.add(isFirst: true, isLast: true, addition: points.0, prediction: points.1)
        let hulls = try! mConvexHullChainProducer.add(isFirst: true, isLast: true, addition: polys.0, prediction: polys.1)
        let merged = try! mPolygonMerger.add(isFirst: true, isLast: true, addition: hulls.0, prediction: hulls.1)
        let simplified = try! mPolygonSimplifier.add(isFirst: true, isLast: true, addition: merged.0, prediction: merged.1)
        
        if simplified.0 == nil {
            return
        }
        
        var pathStr = ""
        
        for poly in simplified.0! {
            var j = 0
            
            for p in poly {
                if j == 0 {
                    pathStr.append("M \(p.x) \(p.y)")
                } else {
                    pathStr.append(" L \(p.x) \(p.y)")
                }
                                
                if p.x > maxX {
                    maxX = p.x
                }
                if p.x < minX {
                    minX = p.x
                }
                if p.y > maxY {
                    maxY = p.y
                }
                if p.y < minY {
                    minY = p.y
                }
                
                j += 1
            }
        }
        
        // get the hex value of the color and create the path tag
        let red = Float(stroke.style.pathPointProperties?.red ?? 0)
        let green = Float(stroke.style.pathPointProperties?.green ?? 0)
        let blue = Float(stroke.style.pathPointProperties?.blue ?? 0)
        
        let colorHex = String(format: "#%02X%02X%02X",
            Int(red * 0xff),
            Int(green * 0xff),
            Int(blue * 0xff))
        
        let pathTag = XML(name: "path").addAttribute(name: "fill", value: colorHex).addAttribute(name: "fill-opacity", value: alpha).addAttribute(name: "d", value: pathStr)
        
        svgTag.addChild(pathTag)
    }
}
