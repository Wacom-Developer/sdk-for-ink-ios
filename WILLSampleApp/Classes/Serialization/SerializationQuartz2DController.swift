//
//  SerializationQuartz2DController.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 17.03.20.
//  Copyright © 2020 nikolay.atanasov. All rights reserved.
//

import UIKit
import WacomInk

class SerializationQuartz2DController : UIViewController {
    public var serializationModel: SerializationQuartz2DModel?
    var saveModel: UIDocumentPickerSaveModel?
    var isLoad: Bool = false
    private var rTreeLayer: CAShapeLayer?
    private var rTreeBezierPath: UIBezierPath?
    private var countNodes = 0
    
    private var fileNameLabel: UILabel!
    public private(set) var fileNameTextField: UITextField!
    private var browseButton: UIButton!
    var absolutePathLabel: UILabel!
    private var saveButton: UIButton!
    
    private var loadButton: UIButton!
    private var intersectBrushSizeLabel: UILabel!
    private var intersectBrushSizeSlider: UISlider!
    private var isRTreeLeavesShowLabel: UILabel!
    private var isRTreeLeavesShowSwitch: UISwitch!
    private var isErasingLabel: UILabel!
    private var isErasingSwitch: UISwitch!
    private var isRTreeWholeStrokeLabel: UILabel!
    private var isRTreeWholeStrokeSwitch: UISwitch!
    private var spatialContextLabel: UILabel!
    private var spatialContextSegmentedControl: UISegmentedControl!
    private var manipulationTypeLabel: UILabel!
    private var manipulationTypeSegmentedControl: UISegmentedControl!
    private var transformationTypeSegmentedControl: UISegmentedControl!
    private var manipulatorCollectionTypeSegmentedControl: UISegmentedControl!
    private var selectionButton: UIButton!
    private var rotateGestureRecognizer: UIRotationGestureRecognizer?
    private var selectionOverlapModeSegmentedControl: UISegmentedControl!

    var isCached: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationSize = navigationController?.navigationBar.frame.size
        
        fileNameLabel = UILabel(frame: CGRect(x: 10, y: 1.9 * navigationSize!.height, width: 92, height: 30))
        fileNameLabel!.text = "File name: "
        
        fileNameTextField = UITextField(frame: CGRect(x: 10 + fileNameLabel.frame.maxX, y: 1.9 * navigationSize!.height, width: 90, height: 30))
        fileNameTextField.layer.cornerRadius = 5
        fileNameTextField.layer.masksToBounds = true;
        fileNameTextField.layer.borderColor = UIColor.black.cgColor
        fileNameTextField.layer.borderWidth = 1.0
        
        browseButton = UIButton(frame: CGRect(x: 10 + fileNameTextField!.frame.maxX, y: fileNameTextField!.frame.minY, width: 90, height: 30))
        browseButton!.setTitle("Browse", for: .normal)//.text = "rTree precision: "
        browseButton!.setTitleColor(UIColor.white.inverted, for: .normal)// = backgroundColor.inverted
        browseButton!.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9)
        browseButton.layer.cornerRadius = 5
        
        saveButton = UIButton(frame: CGRect(x: 10, y: browseButton!.frame.maxY + 10, width: 90, height: 30))
        saveButton!.setTitle("Save", for: .normal)//.text = "rTree precision: "
        saveButton!.setTitleColor(UIColor.white.inverted, for: .normal)// = backgroundColor.inverted
        saveButton!.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9)
        saveButton.layer.cornerRadius = 5
        
        absolutePathLabel = UILabel(frame: CGRect(x: 10 + saveButton.frame.maxX, y: saveButton.frame.minY, width: view.layer.frame.width - 10 + saveButton.frame.maxX, height: 30))
        absolutePathLabel!.text = ""
        
        loadButton = UIButton(frame: CGRect(x: 10, y: saveButton!.frame.maxY + 10, width: 90, height: 30))
        loadButton!.setTitle("Load", for: .normal)
        loadButton!.setTitleColor(UIColor.white.inverted, for: .normal)// = backgroundColor.inverted
        loadButton!.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9)
        loadButton.layer.cornerRadius = 5
        
        spatialContextLabel = UILabel(frame: CGRect(x: 10, y: loadButton!.frame.maxY + 10, width: 120, height: 30))
        spatialContextLabel!.text = "Spatial context: "
        
        spatialContextSegmentedControl = UISegmentedControl(items: DemosSpatialContextType.allValues())
        spatialContextSegmentedControl.frame = CGRect(x: 10 + spatialContextLabel.frame.maxX, y: loadButton!.frame.maxY + 10, width: 250, height: 30)
        spatialContextSegmentedControl.selectedSegmentIndex = 0
        spatialContextSegmentedControl.tintColor = UIColor.black
        
        manipulationTypeLabel = UILabel(frame: CGRect(x: 10, y: spatialContextSegmentedControl.frame.maxY + 10, width: 140, height: 30))
        manipulationTypeLabel!.text = "Type of operation: "
        
        manipulationTypeSegmentedControl = UISegmentedControl(items: ManipulationType.allValues())
        manipulationTypeSegmentedControl.frame = CGRect(x: 10 + manipulationTypeLabel.frame.maxX, y: spatialContextSegmentedControl.frame.maxY + 10, width: 250, height: 30)
        manipulationTypeSegmentedControl.selectedSegmentIndex = 0
        manipulationTypeSegmentedControl.tintColor = UIColor.black
        
        isRTreeLeavesShowLabel = UILabel(frame: CGRect(x: 10, y: manipulationTypeSegmentedControl.frame.maxY + 10, width: 92, height: 30))
        isRTreeLeavesShowLabel!.text = "Show rtree: "
        isRTreeLeavesShowSwitch = UISwitch(frame: CGRect(x: 10 + isRTreeLeavesShowLabel.frame.maxX, y: isRTreeLeavesShowLabel.frame.minY, width: 30, height: 30))
        
        isRTreeWholeStrokeLabel = UILabel(frame: CGRect(x: 10, y: isRTreeLeavesShowLabel.frame.maxY + 10, width: 112, height: 30))
        isRTreeWholeStrokeLabel!.text = "Whole stroke: "
        isRTreeWholeStrokeSwitch = UISwitch(frame: CGRect(x: 10 + isRTreeWholeStrokeLabel.frame.maxX, y: isRTreeWholeStrokeLabel.frame.minY, width: 30, height: 30))
        isRTreeWholeStrokeSwitch.isOn = false
        
        manipulatorCollectionTypeSegmentedControl = UISegmentedControl(items: ManipulatorCollectionType.allValues())
        manipulatorCollectionTypeSegmentedControl.frame = CGRect(x: isRTreeWholeStrokeSwitch.frame.maxX + 10, y: isRTreeWholeStrokeSwitch.frame.minY, width: 150, height: 30)
        manipulatorCollectionTypeSegmentedControl.selectedSegmentIndex = 0
        manipulatorCollectionTypeSegmentedControl.tintColor = UIColor.black
        
        intersectBrushSizeLabel = UILabel(frame: CGRect(x: 10, y: isRTreeWholeStrokeLabel.frame.maxY + 10, width: 90, height: 30))
        intersectBrushSizeLabel!.text = "Brush size: "
        intersectBrushSizeSlider = UISlider(frame: CGRect(x: 10 + intersectBrushSizeLabel.frame.maxX, y: intersectBrushSizeLabel.frame.minY, width: 120, height: 30))
        intersectBrushSizeSlider.maximumValue = 30
        intersectBrushSizeSlider.minimumValue = 1
        intersectBrushSizeSlider.value = 3
        
        isErasingLabel = UILabel(frame: CGRect(x: 10, y: intersectBrushSizeLabel.frame.maxY + 10, width: 80, height: 30))
        isErasingLabel!.text = "Is erasing: "
        isErasingSwitch = UISwitch(frame: CGRect(x: 10 + isErasingLabel.frame.maxX, y: isErasingLabel.frame.minY, width: 30, height: 30))
        isErasingSwitch.isOn = true
        
        selectionButton = UIButton(frame: CGRect(x: 10, y: isRTreeWholeStrokeLabel!.frame.maxY + 10, width: 90, height: 30))
        selectionButton!.setTitle("Select", for: .normal)//.text = "rTree precision: "
        selectionButton!.setTitleColor(UIColor.white.inverted, for: .normal)// = backgroundColor.inverted
        selectionButton!.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 0.9)
        selectionButton.layer.cornerRadius = 5
        
        selectionOverlapModeSegmentedControl = UISegmentedControl(items: Manipulator.OverlapMode.allValues())
        selectionOverlapModeSegmentedControl.frame = CGRect(x: 10, y: selectionButton.frame.maxY + 10, width: 420, height: 30)
        selectionOverlapModeSegmentedControl.selectedSegmentIndex = 0
        selectionOverlapModeSegmentedControl.tintColor = UIColor.black
        
        transformationTypeSegmentedControl = UISegmentedControl(items: ManipulationAction.allValues())
        transformationTypeSegmentedControl.frame = CGRect(x: selectionButton!.frame.maxX + 10, y: selectionButton!.frame.minY, width: 150, height: 30)
        transformationTypeSegmentedControl.selectedSegmentIndex = 0
        transformationTypeSegmentedControl.tintColor = UIColor.black
        
        fileNameTextField!.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged) 
        browseButton!.addTarget(self, action: #selector(clickBrowseButton(sender:)), for: .touchUpInside)
        saveButton!.addTarget(self, action: #selector(clickSaveButton(sender:)), for: .touchUpInside)
        loadButton!.addTarget(self, action: #selector(clickLoadButton(sender:)), for: .touchUpInside)
        spatialContextSegmentedControl.addTarget(self, action: #selector(selectSpatialContext), for: UIControl.Event.valueChanged)
        manipulationTypeSegmentedControl.addTarget(self, action: #selector(selectManipulation), for: UIControl.Event.valueChanged)
        isRTreeLeavesShowSwitch.addTarget(self, action: #selector(isRTreeLeavesShowSwitchStateChanged), for: .valueChanged)
        intersectBrushSizeSlider.addTarget(self, action: #selector(intersectBrushSizeSliderChanged), for: .valueChanged)
        isRTreeWholeStrokeSwitch.addTarget(self, action: #selector(isWholeStrokeSwitchStateChanged), for: .valueChanged)
        selectionButton!.addTarget(self, action: #selector(clickSelectionButton(sender:)), for: .touchUpInside)
        manipulatorCollectionTypeSegmentedControl.addTarget(self, action: #selector(selectCollectionType), for: UIControl.Event.valueChanged)
        transformationTypeSegmentedControl.addTarget(self, action: #selector(selectManipulationAction), for: UIControl.Event.valueChanged)
        selectionOverlapModeSegmentedControl.addTarget(self, action: #selector(selectOverlap), for: .valueChanged)
        isErasingSwitch.addTarget(self, action: #selector(isErasingChanged), for: .valueChanged)
        
        serializationModel = SerializationQuartz2DModel(isCached: isCached)
        saveModel = UIDocumentPickerSaveModel()
        
        rTreeLayer = view.layer.bounds.createCanvas()
        rTreeLayer?.fillColor = UIColor(red: 0.8, green: 0, blue: 0.1, alpha: 1).cgColor
        
        serializationModel!.backgroundColor = UIColor.white
        view.layer.backgroundColor = serializationModel!.backgroundColor.cgColor
        view.layer.addSublayer(rTreeLayer!)
        
        selectSpatialContextHandler()
        selectManipulationHandler()
        isRTreeLeavesShowHandler()
        intersectBrushSizeSliderHandler()
        selectCollectionTypeHandler()
        selectTransformationHandler()
        
        view.addSubview(fileNameLabel)
        view.addSubview(fileNameTextField)
        view.addSubview(browseButton)
        view.addSubview(absolutePathLabel)
        view.addSubview(saveButton)
        view.addSubview(loadButton)
        view.addSubview(spatialContextLabel)
        view.addSubview(spatialContextSegmentedControl)
        view.addSubview(manipulationTypeLabel)
        view.addSubview(manipulationTypeSegmentedControl)
        view.addSubview(isRTreeLeavesShowLabel)
        view.addSubview(isRTreeLeavesShowSwitch)
        view.addSubview(isRTreeWholeStrokeLabel)
        view.addSubview(isRTreeWholeStrokeSwitch)
        view.addSubview(manipulatorCollectionTypeSegmentedControl)
        view.addSubview(intersectBrushSizeLabel)
        view.addSubview(intersectBrushSizeSlider)
        view.addSubview(isErasingLabel)
        view.addSubview(isErasingSwitch)
        view.addSubview(selectionButton)
        view.addSubview(selectionOverlapModeSegmentedControl)
        
        rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotatedView(_:)))
        
        view.addSubview(transformationTypeSegmentedControl)
    }
    
    @objc func rotatedView(_ sender: UIRotationGestureRecognizer) {
        if serializationModel?.selectedManipulationType == ManipulationType.select {
            
            if serializationModel!.hasSelection && serializationModel!.selectedManipulationAction == ManipulationAction.rotate {
                if sender.state == .began {
                    serializationModel!.rotateBegan(sender)
                } else if sender.state == .changed {
                    serializationModel!.rotateMoved(sender)
                    
                } else if sender.state == .ended {
                    serializationModel!.rotateEnded(sender)
                    isRTreeLeavesShowHandler()
                    
                }
            }
        }
    }
    
    func showRtreeNodes(isToShow: Bool, numberOfNodes: inout Int) {
        rTreeBezierPath = UIBezierPath()
        
        if isToShow {
            let rects = serializationModel!.getAllNodes(bounds:view.layer.bounds)
            numberOfNodes = rects.count
            for rect in rects {
                rTreeBezierPath!.append(UIBezierPath(rect: rect))
            }
        }
        rTreeLayer!.path = rTreeBezierPath!.cgPath
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        serializationModel!.touchesBegan(touches, with: event, view: view)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        serializationModel!.touchesMoved(touches, with: event, view: view)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        serializationModel!.touchesEnded(touches, with: event, view: view)
        isRTreeLeavesShowHandler()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        saveModel!.selectedFileName = textField.text
        absolutePathLabel.text = saveModel!.validateMessage
    }
    
    @objc func clickBrowseButton(sender: UIButton) {
        clickBrowseButtonHandler()
    }
    
    @objc func clickSaveButton(sender: UIButton) {
        clickSaveButtonHandler()
    }
    
    @objc func clickLoadButton(sender: UIButton) {
        clickLoadButtonHandler()
    }
    
    @objc func selectSpatialContext(control: UISegmentedControl) {
        selectSpatialContextHandler()
    }
    
    @objc func selectManipulation(control: UISegmentedControl) {
        selectManipulationHandler()
    }
    
    @objc func selectCollectionType(control: UISegmentedControl) {
        selectCollectionTypeHandler()
    }
    
    @objc func selectManipulationAction(control: UISegmentedControl) {
        selectTransformationHandler()
    }
    
    @objc func intersectBrushSizeSliderChanged(sliderChanged: UISlider) {
        intersectBrushSizeSliderHandler()
    }
    
    @objc func isRTreeLeavesShowSwitchStateChanged(switchState: UISwitch) {
        isRTreeLeavesShowHandler()
    }
    
    @objc func isWholeStrokeSwitchStateChanged(switchState: UISwitch) {
        isRTreeWholeStrokeSwitchHandler()
    }
    
    @objc func selectOverlap(control: UISegmentedControl) {
        selectOverlapModeHandler()
    }
    
    @objc func isErasingChanged(switchState: UISwitch) {
        isErasingHandler()
    }
    
    @objc func clickSelectionButton(sender: UIButton) {
        clickSelectionButtonHandler()
    }
  
    private func setSelectionButton() {
        if serializationModel!.hasSelection {
            selectionButton.setTitle("Clear", for: .normal)
            selectionButton!.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 0.9)
            transformationTypeSegmentedControl.isHidden = false
            view.addGestureRecognizer(rotateGestureRecognizer!)
            isRTreeLeavesShowHandler()
        }
        else {
            selectionButton.setTitle("Select", for: .normal)
            selectionButton!.backgroundColor = UIColor(red: 0.1, green: 0.9, blue: 0.2, alpha: 0.9)
            transformationTypeSegmentedControl.isHidden = true
            
            view.removeGestureRecognizer(rotateGestureRecognizer!)
        }
    }
    
    private func clickSelectionButtonHandler() {
        if serializationModel!.onSelectButton(view: view) {
            setSelectionButton()
        } else {
            let alertController = UIAlertController(title: "Insufficient data", message:
                "You need to draw selecting area.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func selectSpatialContextHandler() {
        serializationModel!.set(spatialContextType: DemosSpatialContextType(rawValue: spatialContextSegmentedControl!.selectedSegmentIndex)!)
        isRTreeLeavesShowHandler()
    }
    
    private func selectManipulationHandler() {
        serializationModel!.set(manipulationType: ManipulationType(rawValue: manipulationTypeSegmentedControl!.selectedSegmentIndex)!)
        if serializationModel!.selectedManipulationType == ManipulationType.draw {
            intersectBrushSizeLabel.isHidden = true
            intersectBrushSizeSlider.isHidden = true
            isErasingLabel.isHidden = true
            isErasingSwitch.isHidden = true
            isRTreeWholeStrokeLabel.isHidden = true
            isRTreeWholeStrokeSwitch.isHidden = true
            manipulatorCollectionTypeSegmentedControl.isHidden = true
            selectionButton.isHidden = true
            selectionOverlapModeSegmentedControl.isHidden = true
            transformationTypeSegmentedControl.isHidden = true
            
        } else if serializationModel!.selectedManipulationType == ManipulationType.intersect {
            intersectBrushSizeLabel.isHidden = false
            intersectBrushSizeSlider.isHidden = false
            isErasingLabel.isHidden = false
            isErasingSwitch.isHidden = false
            isRTreeWholeStrokeLabel.isHidden = false
            isRTreeWholeStrokeSwitch.isHidden = false
            manipulatorCollectionTypeSegmentedControl.isHidden = false//isRTreeWholeStrokeSwitch.isOn
            selectionButton.isHidden = true
            transformationTypeSegmentedControl.isHidden = true
            selectionOverlapModeSegmentedControl.isHidden = true
        } else if serializationModel!.selectedManipulationType == ManipulationType.select {
            intersectBrushSizeLabel.isHidden = true
            intersectBrushSizeSlider.isHidden = true
            isErasingLabel.isHidden = true
            isErasingSwitch.isHidden = true
            isRTreeWholeStrokeLabel.isHidden = false
            isRTreeWholeStrokeSwitch.isHidden = false
            manipulatorCollectionTypeSegmentedControl.isHidden = false
            selectionButton.isHidden = false
            selectionOverlapModeSegmentedControl.isHidden = isRTreeWholeStrokeSwitch.isOn
            setSelectionButton()
        }
        
        //setTitle()
    }
    
    private func selectCollectionTypeHandler() {
        serializationModel!.set(manipulatorCollectionType: ManipulatorCollectionType(rawValue: manipulatorCollectionTypeSegmentedControl.selectedSegmentIndex)!)
    }
    
    private func selectTransformationHandler() {
        serializationModel!.set(transformationType: ManipulationAction(rawValue: transformationTypeSegmentedControl!.selectedSegmentIndex)!)
    }
    
    public func isRTreeLeavesShowHandler() {
        countNodes = 0
        showRtreeNodes(isToShow: isRTreeLeavesShowSwitch.isOn, numberOfNodes: &countNodes)
        //setTitle()
    }
    
    private func intersectBrushSizeSliderHandler() {
        //setTitle()
        //serializationModel!.setDefault(size: intersectBrushSizeSlider.value)
    }
    
    private func isRTreeWholeStrokeSwitchHandler() {
        selectionOverlapModeSegmentedControl.isHidden = !(serializationModel!.selectedManipulationType == ManipulationType.select) || isRTreeWholeStrokeSwitch.isOn
        serializationModel!.toggleWholeStroke()
    }
    
    private func selectOverlapModeHandler() {
        serializationModel!.set(selectOverlapMode: Manipulator.OverlapMode(rawValue: UInt32(selectionOverlapModeSegmentedControl.selectedSegmentIndex))!)
    }

    private func isErasingHandler() {
        serializationModel!.toggleIsErasing()
    }
    
    private func setTitle() {
        if serializationModel!.selectedManipulationType == ManipulationType.draw {
            title = "\(isRTreeLeavesShowSwitch.isOn ? " (leaves# \(countNodes))" : "")"
        } else if serializationModel!.selectedManipulationType == ManipulationType.intersect {
            title = "size \(intersectBrushSizeSlider.value) \(isRTreeLeavesShowSwitch.isOn ? " (leaves# \(countNodes))" : "")"
        } else {
            title = "\(isRTreeLeavesShowSwitch.isOn ? " (leaves# \(countNodes))" : "")"
        }
    }
}


