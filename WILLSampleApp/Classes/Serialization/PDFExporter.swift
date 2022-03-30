//
//  PDFExporter.swift
//  WILLSampleApp
//
//  Created by Mincho Dzhagalov on 28.09.21.
//  Copyright © 2021 Mincho Dzhagalov. All rights reserved.
//

import Foundation
import WacomInk
import UIKit

class PDFExporter {
    static var PDF_A4_WIDTH: Float = 595.0
    static var PDF_A4_HEIGHT: Float = 842.0
    
    private var PDF_TEMPLATE: String {
        get {
            "%PDF-1.4\n" +
            "%âãÏÓ\n" +
            "1 0 obj\n" +
            "<</Type/Page/Parent 3 0 R/Contents 2 0 R/MediaBox[0 0 $1$ $2$]/Resources<</ProcSet[/PDF]/ExtGState<<$3$>>>>>>\n" +
            "endobj\n" +
            "2 0 obj\n" +
            "<</Length $4$>>stream\n" +
            "$5$\n" +
            "endstream\n" +
            "endobj\n" +
            "3 0 obj\n" +
            "<</Type/Pages/Count 1/Kids[1 0 R]>>\n" +
            "endobj\n" +
            "4 0 obj\n" +
            "<</Type/Catalog/Pages 3 0 R>>\n" +
            "endobj\n" +
            "5 0 obj\n" +
            "<</Producer($6$)/CreationDate(D:$7$)/ModDate(D:$8$)>>\n" +
            "endobj\n" +
            "xref\n" +
            "0 6\n" +
            "0000000000 65535 f\n" +
            "$9$ 00000 n\n" +
            "$10$ 00000 n\n" +
            "$11$ 00000 n\n" +
            "$12$ 00000 n\n" +
            "$13$ 00000 n\n" +
            "trailer\n" +
            "<</Size 6/Root 4 0 R/Info 5 0 R/ID[<$14$><$15$>]>>\n" +
            "startxref\n" +
            "$16$\n" +
            "%%EOF"
        }
    }
    
    private var mConvexHullChainProducer = ConvexHullChainProducer()
    private var mPolygonMerger = PolygonMerger()
    private var mPolygonSimplifier = PolygonSimplifier(epsilon: 0.1)
    
    private var minX = Float.greatestFiniteMagnitude
    private var minY = Float.greatestFiniteMagnitude
    private var maxX = Float.zero
    private var maxY = Float.zero
    
    private var psCommands: String = String() // PostScript commands for drawing the inking
    private var graphicStates = [Float]() // Store the alphas
    
    func exportToPDF(inkDocument: InkModel, pdfWidth: Float, pdfHeight: Float, fit: Bool) -> String {
        // first of all we need to get the PostScript drawing commands from the stroke list
        drawStrokes(inkDocument: inkDocument, pdfWidth: pdfWidth, pdfHeight: pdfHeight, fit: fit)
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EdMMMyyyyHHmmss"
        let dateString = dateFormatter.string(from: date)
        print("date string -> \(dateString)")
        
        var pdf: String = PDF_TEMPLATE.replacingOccurrences(of: "$1$", with: String(pdfWidth))
            .replacingOccurrences(of: "$2$", with: String(pdfHeight))
            .replacingOccurrences(of: "$3$", with: getGSStates())
            .replacingOccurrences(of: "$4$", with: String(psCommands.count))
            .replacingOccurrences(of: "$5$", with: psCommands)
            .replacingOccurrences(of: "$6$", with: "Wacom")
            .replacingOccurrences(of: "$7$", with: dateString)
            .replacingOccurrences(of: "$8$", with: dateString)

        pdf = pdf.replacingOccurrences(of: "$9$", with: fill(offset: pdf.distance(of: "1 0 obj")!))
            .replacingOccurrences(of: "$10$", with: fill(offset: pdf.distance(of: "2 0 obj")!))
            .replacingOccurrences(of: "$11$", with: fill(offset: pdf.distance(of: "3 0 obj")!))
            .replacingOccurrences(of: "$12$", with: fill(offset: pdf.distance(of: "4 0 obj")!))
            .replacingOccurrences(of: "$13$", with: fill(offset: pdf.distance(of: "5 0 obj")!))
            .replacingOccurrences(of: "$14$", with: NSUUID().uuidString.replacingOccurrences(of: "-", with: ""))
            .replacingOccurrences(of: "$15$", with: NSUUID().uuidString.replacingOccurrences(of: "-", with: ""))
        
        pdf = pdf.replacingOccurrences(of: "$16$", with: String(pdf.distance(of: "xref")!))
        
        return pdf
    }
    
    private func getGSStates() -> String {
        var gsStates = String()
        
        var index = 0
        for state in graphicStates {
            
            gsStates = gsStates.appending("/GS").appending(String(index + 1)).appending("<</ca ").appending(String(state)).appending(">>")
            index += 1
        }
        
        return gsStates
    }
        
    private func fill(offset: Int) -> String {
        let str = "0000000000" + String(offset)
        
        let index = str.index(str.endIndex, offsetBy: -10)
        return String(str.suffix(from: index))
    }
    
    private func drawStrokes(inkDocument: InkModel, pdfWidth: Float, pdfHeight: Float, fit: Bool) {
        if inkDocument.inkTree.root != nil {
            let enumerator = inkDocument.inkTree.root?.getRecursiveEnumerator()
            
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
            
            if fit {
                // if fit we put a transformation matrix scaling the strokes
                let scaleX: Float = pdfWidth / maxX
                let scaleY = pdfHeight / maxY
                let scale = min(scaleX, scaleY)
                
                let matrix = String(scale) + " 0 0 " + String(-scale) + " 0 " + String(pdfHeight) + " cm\n"
                psCommands.insert(contentsOf: matrix, at: psCommands.startIndex)
            } else {
                // 0, 0 for the stroke coordinates means top left
                // 0, 0 for PDFs means bottom left
                // so we need to flip the Y coordinates. We do it with the following transformation matrix.
                let matrix = "1 0 0 -1 0 " + String(pdfHeight) + " cm\n"
                psCommands.insert(contentsOf: matrix, at: psCommands.startIndex)
            }
        }
    }
    
    private func drawStroke(stroke: Stroke, vectorBrush: WacomInk.Geometry.VectorBrush) {
        psCommands.append(contentsOf: "q\n") // save the graphics state
        let alpha: Float = (stroke.style.pathPointProperties?.alpha)!
        if !graphicStates.contains(alpha) {
            graphicStates.append(alpha)
        }
        
        psCommands = psCommands.appending("/GS").appending(String(graphicStates.firstIndex(of: alpha)! + 1)).appending(" gs\n") // put the alpha state
        psCommands = psCommands.appending(String(stroke.style.pathPointProperties?.red ?? 0)).appending(" ").appending(String(stroke.style.pathPointProperties?.green ?? 0)).appending(" ").appending(String(stroke.style.pathPointProperties?.blue ?? 0)).appending(" rg\n") // put the stroke color
        
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
        
        for poly in simplified.0! {
            var j = 0
            
            for p in poly {
                if j == 0 {
                    psCommands = psCommands.appending(String(p.x)).appending(" ").appending(String(p.y)).appending(" m ")
                } else {
                    psCommands = psCommands.appending(String(p.x)).appending(" ").appending(String(p.y)).appending(" l ")
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
        
        psCommands.append("f ");
        psCommands.append("Q\n") // restore the graphics state
    }
}
