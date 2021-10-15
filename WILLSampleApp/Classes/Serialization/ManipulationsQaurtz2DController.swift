//
//  EraseManipulationQaurtz2DController.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 3.10.19.
//  Copyright © 2019 Nikolay Atanasov. All rights reserved.
//

import UIKit
import WacomInk
import MobileCoreServices

class ManipulationsQaurtz2DController : UIViewController, UIDocumentPickerDelegate {
    public var serializationModel: SerializationQuartz2DModel?
    private var rTreeLayer: CAShapeLayer?
    private var rTreeBezierPath: UIBezierPath?
    private var countNodes = 0
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
    private var manipulatorCollectionTypeSegmentedControl: UISegmentedControl!
    private var selectionButton: UIButton!
    private var rotateGestureRecognizer: UIRotationGestureRecognizer?
    private var selectionOverlapModeSegmentedControl: UISegmentedControl!
    private var saveModel: UIDocumentPickerSaveModel?
    private var fileName = "Test"
    private var lastToolColor = UIColor.red
    private var isDrawingStroke = false
    private var queuedOperation: (() -> ())?
    private var fileExtension = ""
   
    //var isCached: Bool = false
    
    var isSelectingTool = false
    var isSelectingInk = false
    var wholeStrokeErasingFlag = false
    var isWholeStrokeOn = false
    var isLoad: Bool = false
    var interactionEnabled = true
    
    
    @IBOutlet weak var toolSelectionButton: UIButton!
    @IBOutlet weak var transformationTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var penButton: UIButton!
    @IBOutlet weak var feltButton: UIButton!
    @IBOutlet weak var brushButton: UIButton!
    @IBOutlet weak var partialStrokeEraserButton: UIButton!
    @IBOutlet weak var wholeStrokeEraserButton: UIButton!
    @IBOutlet weak var partialStrokeSelectorButton: UIButton!
    @IBOutlet weak var wholeStrokeSelectorButton: UIButton!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var selectInkButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationSize = navigationController?.navigationBar.frame.size
        
        spatialContextLabel = UILabel(frame: CGRect(x: 10, y: 1.6 * navigationSize!.height, width: 120, height: 30))
        spatialContextLabel!.text = "Spatial context: "

        spatialContextSegmentedControl = UISegmentedControl(items: DemosSpatialContextType.allValues())
        spatialContextSegmentedControl.frame = CGRect(x: 10 + spatialContextLabel.frame.maxX, y: 1.6 * navigationSize!.height, width: 250, height: 30)
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
        
        transformationTypeSegmentedControl.selectedSegmentIndex = 0
        transformationTypeSegmentedControl.tintColor = UIColor.black
        
        spatialContextSegmentedControl.addTarget(self, action: #selector(selectSpatialContext), for: UIControl.Event.valueChanged)
        manipulationTypeSegmentedControl.addTarget(self, action: #selector(selectManipulation), for: UIControl.Event.valueChanged)
        isRTreeLeavesShowSwitch.addTarget(self, action: #selector(isRTreeLeavesShowSwitchStateChanged), for: .valueChanged)
        intersectBrushSizeSlider.addTarget(self, action: #selector(intersectBrushSizeSliderChanged), for: .valueChanged)
        isRTreeWholeStrokeSwitch.addTarget(self, action: #selector(isWholeStrokeSwitchStateChanged), for: .valueChanged)
        selectionButton!.addTarget(self, action: #selector(clickSelectionButton(sender:)), for: .touchUpInside)
        manipulatorCollectionTypeSegmentedControl.addTarget(self, action: #selector(selectCollectionType), for: UIControl.Event.valueChanged)
        transformationTypeSegmentedControl.addTarget(self, action: #selector(selectTransformaion), for: UIControl.Event.valueChanged)
        selectionOverlapModeSegmentedControl.addTarget(self, action: #selector(selectOverlap), for: .valueChanged)
        isErasingSwitch.addTarget(self, action: #selector(isErasingChanged), for: .valueChanged)
        
        serializationModel = SerializationQuartz2DModel(isCached: true)
        serializationModel?.selectPen(inputType: .direct)
        serializationModel?.inkColor = .red
        
        penButton.backgroundColor = .lightGray
        penButton.layer.cornerRadius = penButton.frame.width / 3
        feltButton.backgroundColor = .white
        feltButton.layer.cornerRadius = 0
        brushButton.backgroundColor = .white
        brushButton.layer.cornerRadius = 0
        partialStrokeEraserButton.backgroundColor = .white
        partialStrokeEraserButton.layer.cornerRadius = 0
        wholeStrokeEraserButton.backgroundColor = .white
        wholeStrokeEraserButton.layer.cornerRadius = 0
        partialStrokeSelectorButton.backgroundColor = .white
        partialStrokeSelectorButton.layer.cornerRadius = 0
        wholeStrokeSelectorButton.backgroundColor = .white
        wholeStrokeSelectorButton.layer.cornerRadius = 0
        
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
        
        saveModel = UIDocumentPickerSaveModel()
        
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        customView.layer.cornerRadius = 15
        customView.layer.masksToBounds = true
        customView.backgroundColor = .red
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapColorPicker))
        customView.addGestureRecognizer(tapGestureRecognizer)
        
        let barButtonItem = UIBarButtonItem(customView: customView)
        self.navigationItem.rightBarButtonItem = barButtonItem
        
//        view.addSubview(spatialContextLabel)
//        view.addSubview(spatialContextSegmentedControl)
//        view.addSubview(manipulationTypeLabel)
//        view.addSubview(manipulationTypeSegmentedControl)
//        view.addSubview(isRTreeLeavesShowLabel)
//        view.addSubview(isRTreeLeavesShowSwitch)
//        view.addSubview(isRTreeWholeStrokeLabel)
//        view.addSubview(isRTreeWholeStrokeSwitch)
//        view.addSubview(manipulatorCollectionTypeSegmentedControl)
//        view.addSubview(intersectBrushSizeLabel)
//        view.addSubview(intersectBrushSizeSlider)
//        view.addSubview(isErasingLabel)
//        view.addSubview(isErasingSwitch)
        //view.addSubview(selectionButton)
//        view.addSubview(selectionOverlapModeSegmentedControl)
//        view.addSubview(includeInnerContourLabel)
//        view.addSubview(includeInnerContourSwitch)
//        view.addSubview(includeOuterContourLabel)
//        view.addSubview(includeOuterContourSwitch)
        rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotatedView(_:)))
    }
    
    @objc func rotatedView(_ sender: UIRotationGestureRecognizer) {
        if serializationModel!.selectedManipulationType == ManipulationType.select {
            
            if serializationModel!.hasSelection && serializationModel!.selectedManipulationAction == ManipulationAction.rotate {
                if sender.state == .began {
                    serializationModel!.rotateBegan(sender)
                } else if sender.state == .changed {
                    serializationModel!.rotateMoved(sender)
                    
                } else if sender.state == .ended {
                    serializationModel!.rotateEnded(sender)
                    //isRTreeLeavesShowHandler()
                    
                }
            }
        }
    }
    
    @objc func didTapRedColor() {
        serializationModel?.inkColor = .red
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .red
        lastToolColor = .red
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapBlueColor() {
        serializationModel?.inkColor = .blue
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .blue
        lastToolColor = .blue
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapYellowColor() {
        serializationModel?.inkColor = .yellow
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .yellow
        lastToolColor = .yellow
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapPurpleColor() {
        serializationModel?.inkColor = .purple
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .purple
        lastToolColor = .purple
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapGreenColor() {
        serializationModel?.inkColor = .green
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .green
        lastToolColor = .green
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapOrangeColor() {
        serializationModel?.inkColor = .orange
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .orange
        lastToolColor = .orange
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapBlackColor() {
        serializationModel?.inkColor = .black
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .black
        lastToolColor = .black
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapBrownColor() {
        serializationModel?.inkColor = .brown
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .brown
        lastToolColor = .brown
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapGrayColor() {
        serializationModel?.inkColor = .gray
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .gray
        lastToolColor = .gray
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapColorPicker() {
        let redColorView = UIView()
        redColorView.backgroundColor = .red
        redColorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        redColorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        redColorView.layer.cornerRadius = 25
        let redGR = UITapGestureRecognizer(target: self, action: #selector(didTapRedColor))
        redColorView.addGestureRecognizer(redGR)
        
        let blueColorView = UIView()
        blueColorView.backgroundColor = .blue
        blueColorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        blueColorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        blueColorView.layer.cornerRadius = 25
        let blueGR = UITapGestureRecognizer(target: self, action: #selector(didTapBlueColor))
        blueColorView.addGestureRecognizer(blueGR)
    
        let yellowColorView = UIView()
        yellowColorView.backgroundColor = .yellow
        yellowColorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        yellowColorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        yellowColorView.layer.cornerRadius = 25
        let yellowGR = UITapGestureRecognizer(target: self, action: #selector(didTapYellowColor))
        yellowColorView.addGestureRecognizer(yellowGR)
        
        let purpleColorView = UIView()
        purpleColorView.backgroundColor = .purple
        purpleColorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        purpleColorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        purpleColorView.layer.cornerRadius = 25
        let purpleGR = UITapGestureRecognizer(target: self, action: #selector(didTapPurpleColor))
        purpleColorView.addGestureRecognizer(purpleGR)
        
        let greenColorView = UIView()
        greenColorView.backgroundColor = .green
        greenColorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        greenColorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        greenColorView.layer.cornerRadius = 25
        let greenGR = UITapGestureRecognizer(target: self, action: #selector(didTapGreenColor))
        greenColorView.addGestureRecognizer(greenGR)
        
        let orangeColorView = UIView()
        orangeColorView.backgroundColor = .orange
        orangeColorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        orangeColorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        orangeColorView.layer.cornerRadius = 25
        let orangeGR = UITapGestureRecognizer(target: self, action: #selector(didTapOrangeColor))
        orangeColorView.addGestureRecognizer(orangeGR)
        
        let blackColorView = UIView()
        blackColorView.backgroundColor = .black
        blackColorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        blackColorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        blackColorView.layer.cornerRadius = 25
        let blackGR = UITapGestureRecognizer(target: self, action: #selector(didTapBlackColor))
        blackColorView.addGestureRecognizer(blackGR)
        
        let brownColorView = UIView()
        brownColorView.backgroundColor = .brown
        brownColorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        brownColorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        brownColorView.layer.cornerRadius = 25
        let brownGR = UITapGestureRecognizer(target: self, action: #selector(didTapBrownColor))
        brownColorView.addGestureRecognizer(brownGR)
        
        let grayColorView = UIView()
        grayColorView.backgroundColor = .gray
        grayColorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        grayColorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        grayColorView.layer.cornerRadius = 25
        let grayGR = UITapGestureRecognizer(target: self, action: #selector(didTapGrayColor))
        grayColorView.addGestureRecognizer(grayGR)

        let popover = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        popover.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        let mainStackView = UIStackView()
        mainStackView.axis = NSLayoutConstraint.Axis.vertical
        mainStackView.distribution = UIStackView.Distribution.fillProportionally
        mainStackView.alignment = UIStackView.Alignment.center
        mainStackView.spacing = 3
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let topStackView = UIStackView()
        topStackView.axis = NSLayoutConstraint.Axis.horizontal
        topStackView.distribution = UIStackView.Distribution.equalSpacing
        topStackView.alignment = UIStackView.Alignment.center
        topStackView.spacing = 10

        topStackView.addArrangedSubview(redColorView)
        topStackView.addArrangedSubview(blueColorView)
        topStackView.addArrangedSubview(yellowColorView)
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let midStackView = UIStackView()
        midStackView.axis = NSLayoutConstraint.Axis.horizontal
        midStackView.distribution = UIStackView.Distribution.equalSpacing
        midStackView.alignment = UIStackView.Alignment.center
        midStackView.spacing = 10

        midStackView.addArrangedSubview(purpleColorView)
        midStackView.addArrangedSubview(greenColorView)
        midStackView.addArrangedSubview(orangeColorView)
        midStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let bottomStackView = UIStackView()
        bottomStackView.axis = NSLayoutConstraint.Axis.horizontal
        bottomStackView.distribution = UIStackView.Distribution.equalSpacing
        bottomStackView.alignment = UIStackView.Alignment.center
        bottomStackView.spacing = 10

        bottomStackView.addArrangedSubview(blackColorView)
        bottomStackView.addArrangedSubview(brownColorView)
        bottomStackView.addArrangedSubview(grayColorView)
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false

        mainStackView.addArrangedSubview(topStackView)
        mainStackView.addArrangedSubview(midStackView)
        mainStackView.addArrangedSubview(bottomStackView)
                
        let leadingConstraint = NSLayoutConstraint(item: mainStackView, attribute: .leading, relatedBy: .equal, toItem: popover.view, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: mainStackView, attribute: .trailing, relatedBy: .equal, toItem: popover.view, attribute: .trailing, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: mainStackView, attribute: .top, relatedBy: .equal, toItem: popover.view, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: mainStackView, attribute: .bottom, relatedBy: .equal, toItem: popover.view, attribute: .bottom, multiplier: 1, constant: 0)
        
        popover.view.addSubview(mainStackView)
        
        popover.view.addConstraints([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
        
        present(popover, animated: true, completion: nil)
    }
    
    @IBAction func didTapResetAll(_ sender: UIButton) {
        serializationModel?.removeAll(view: view)
    }
    
    @IBAction func didTapSelect(_ sender: UIButton) {
        if isSelectingInk {
            if serializationModel!.onSelectButton(view: view) {
                setSelectionButton()
            } else {
                let alertController = UIAlertController(title: "Insufficient data", message:
                                                            "You need to draw selecting area.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                
                self.present(alertController, animated: true, completion: nil)
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
        if interactionEnabled {
            isDrawingStroke = true
            serializationModel!.touchesBegan(touches, with: event, view: view)
            buttonsStackView.isUserInteractionEnabled = false
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if interactionEnabled {
            if touches.first!.force != 0.3333333333333333 {
                serializationModel!.touchesMoved(touches, with: event, view: view)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawingStroke = false
        buttonsStackView.isUserInteractionEnabled = true
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        enableToolsButtons()
        if interactionEnabled {
            isDrawingStroke = false
            buttonsStackView.isUserInteractionEnabled = true
            serializationModel!.touchesEnded(touches, with: event, view: view)
        }
        
        queuedOperation?()
        queuedOperation = nil
    }
    
    @IBAction func didTapDismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapToolSelectionButton(_ sender: UIButton) {
        if !isSelectingTool {
            UIView.animate(withDuration: 0.3) {
                self.penButton.alpha = 1
                self.feltButton.alpha = 1
                self.brushButton.alpha = 1
                self.partialStrokeEraserButton.alpha = 1
                self.wholeStrokeEraserButton.alpha = 1
                self.partialStrokeSelectorButton.alpha = 1
                self.wholeStrokeSelectorButton.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.penButton.alpha = 0
                self.feltButton.alpha = 0
                self.brushButton.alpha = 0
                self.partialStrokeEraserButton.alpha = 0
                self.wholeStrokeEraserButton.alpha = 0
                self.partialStrokeSelectorButton.alpha = 0
                self.wholeStrokeSelectorButton.alpha = 0
            }
        }
        
        isSelectingTool = !isSelectingTool
    }
    
    @IBAction func didTapPenButton(_ sender: UIButton) {
        if isDrawingStroke {
            queuedOperation = {
                self.serializationModel?.selectPen(inputType: .direct)
                self.selectInkButton.isHidden = true
                self.transformationTypeSegmentedControl.isHidden = true
                self.serializationModel?.set(manipulationType: .draw)
                self.isSelectingInk = false
                self.serializationModel?.inkColor = self.lastToolColor
            }
        } else {
            selectInkButton.isHidden = true
            transformationTypeSegmentedControl.isHidden = true
            serializationModel?.set(manipulationType: .draw)
            isSelectingInk = false
            serializationModel?.inkColor = lastToolColor
            serializationModel?.selectPen(inputType: .direct)
        }
        
        penButton.backgroundColor = .lightGray
        penButton.layer.cornerRadius = penButton.frame.width / 3
        feltButton.backgroundColor = .white
        feltButton.layer.cornerRadius = 0
        brushButton.backgroundColor = .white
        brushButton.layer.cornerRadius = 0
        partialStrokeEraserButton.backgroundColor = .white
        partialStrokeEraserButton.layer.cornerRadius = 0
        wholeStrokeEraserButton.backgroundColor = .white
        wholeStrokeEraserButton.layer.cornerRadius = 0
        partialStrokeSelectorButton.backgroundColor = .white
        partialStrokeSelectorButton.layer.cornerRadius = 0
        wholeStrokeSelectorButton.backgroundColor = .white
        wholeStrokeSelectorButton.layer.cornerRadius = 0
    }
    
    @IBAction func didTapFeltButton(_ sender: UIButton) {
        if isDrawingStroke {
            queuedOperation = {
                self.serializationModel?.selectFelt(inputType: .direct)
            }
        } else {
            serializationModel?.selectFelt(inputType: .direct)
        }
        
        selectInkButton.isHidden = true
        transformationTypeSegmentedControl.isHidden = true
        serializationModel?.set(manipulationType: .draw)
        isSelectingInk = false
        serializationModel?.inkColor = lastToolColor

        penButton.backgroundColor = .white
        penButton.layer.cornerRadius = 0
        feltButton.backgroundColor = .lightGray
        feltButton.layer.cornerRadius = feltButton.frame.width / 3
        brushButton.backgroundColor = .white
        brushButton.layer.cornerRadius = 0
        partialStrokeEraserButton.backgroundColor = .white
        partialStrokeEraserButton.layer.cornerRadius = 0
        wholeStrokeEraserButton.backgroundColor = .white
        wholeStrokeEraserButton.layer.cornerRadius = 0
        partialStrokeSelectorButton.backgroundColor = .white
        partialStrokeSelectorButton.layer.cornerRadius = 0
        wholeStrokeSelectorButton.backgroundColor = .white
        wholeStrokeSelectorButton.layer.cornerRadius = 0
    }
    
    @IBAction func didTapBrushButton(_ sender: UIButton) {
        if isDrawingStroke {
            queuedOperation = {
                self.serializationModel?.selectBrush(inputType: .direct)
            }
        } else {
            serializationModel?.selectBrush(inputType: .direct)
        }
        
        selectInkButton.isHidden = true
        transformationTypeSegmentedControl.isHidden = true
        serializationModel?.set(manipulationType: .draw)
        isSelectingInk = false
        serializationModel?.inkColor = lastToolColor
        
        penButton.backgroundColor = .white
        penButton.layer.cornerRadius = 0
        feltButton.backgroundColor = .white
        feltButton.layer.cornerRadius = 0
        brushButton.backgroundColor = .lightGray
        brushButton.layer.cornerRadius = brushButton.frame.width / 3
        partialStrokeEraserButton.backgroundColor = .white
        partialStrokeEraserButton.layer.cornerRadius = 0
        wholeStrokeEraserButton.backgroundColor = .white
        wholeStrokeEraserButton.layer.cornerRadius = 0
        partialStrokeSelectorButton.backgroundColor = .white
        partialStrokeSelectorButton.layer.cornerRadius = 0
        wholeStrokeSelectorButton.backgroundColor = .white
        wholeStrokeSelectorButton.layer.cornerRadius = 0
    }
    
    @IBAction func didTapPartialStrokeEraser(_ sender: UIButton) {
        if isDrawingStroke {
            queuedOperation = {
                self.serializationModel!.set(manipulationType: .intersect)
                self.serializationModel?.inkColor = .white
                
                if self.isWholeStrokeOn {
                    self.serializationModel?.toggleWholeStroke()
                    self.isWholeStrokeOn = false
                }
                
                self.selectInkButton.isHidden = true
                self.transformationTypeSegmentedControl.isHidden = true
                
                self.isSelectingInk = false
            }
        } else {
            serializationModel!.set(manipulationType: .intersect)
            serializationModel?.inkColor = .white
            
            if isWholeStrokeOn {
                serializationModel?.toggleWholeStroke()
                isWholeStrokeOn = false
            }
            
            selectInkButton.isHidden = true
            transformationTypeSegmentedControl.isHidden = true
            
            isSelectingInk = false
        }
        
        penButton.backgroundColor = .white
        penButton.layer.cornerRadius = 0
        feltButton.backgroundColor = .white
        feltButton.layer.cornerRadius = 0
        brushButton.backgroundColor = .white
        brushButton.layer.cornerRadius = 0
        partialStrokeEraserButton.backgroundColor = .lightGray
        partialStrokeEraserButton.layer.cornerRadius = partialStrokeEraserButton.frame.width / 3
        wholeStrokeEraserButton.backgroundColor = .white
        wholeStrokeEraserButton.layer.cornerRadius = 0
        partialStrokeSelectorButton.backgroundColor = .white
        partialStrokeSelectorButton.layer.cornerRadius = 0
        wholeStrokeSelectorButton.backgroundColor = .white
        wholeStrokeSelectorButton.layer.cornerRadius = 0
    }
    
    @IBAction func didTapWholeStrokeEraser(_ sender: UIButton) {
        if isDrawingStroke {
            queuedOperation = {
                self.serializationModel?.set(manipulationType: .intersect)
                self.serializationModel?.inkColor = .white
                
                if !self.isWholeStrokeOn {
                    self.serializationModel?.toggleWholeStroke()
                    self.isWholeStrokeOn = true
                }
                
                self.selectInkButton.isHidden = true
                self.transformationTypeSegmentedControl.isHidden = true
                
                self.isSelectingInk = false
            }
        } else {
            serializationModel?.set(manipulationType: .intersect)
            serializationModel?.inkColor = .white
            
            if !isWholeStrokeOn {
                serializationModel?.toggleWholeStroke()
                isWholeStrokeOn = true
            }
            
            selectInkButton.isHidden = true
            transformationTypeSegmentedControl.isHidden = true
            
            isSelectingInk = false
        }
        
        penButton.backgroundColor = .white
        penButton.layer.cornerRadius = 0
        feltButton.backgroundColor = .white
        feltButton.layer.cornerRadius = 0
        brushButton.backgroundColor = .white
        brushButton.layer.cornerRadius = 0
        partialStrokeEraserButton.backgroundColor = .white
        partialStrokeEraserButton.layer.cornerRadius = 0
        wholeStrokeEraserButton.backgroundColor = .lightGray
        wholeStrokeEraserButton.layer.cornerRadius = wholeStrokeEraserButton.frame.width / 3
        partialStrokeSelectorButton.backgroundColor = .white
        partialStrokeSelectorButton.layer.cornerRadius = 0
        wholeStrokeSelectorButton.backgroundColor = .white
        wholeStrokeSelectorButton.layer.cornerRadius = 0
    }
    
    @IBAction func didTapPartialStrokeSelector(_ sender: UIButton) {
        if isDrawingStroke {
            queuedOperation = {
                self.serializationModel?.set(manipulationType: .select)
                self.selectInkButton.isHidden = false
                self.selectInkButton.setTitle("Select", for: .normal)
                
                if self.isWholeStrokeOn {
                    self.serializationModel?.toggleWholeStroke()
                    self.isWholeStrokeOn = false
                }
                
                self.isSelectingInk = true
            }
        } else {
            serializationModel?.set(manipulationType: .select)
            selectInkButton.isHidden = false
            selectInkButton.setTitle("Select", for: .normal)
            
            if isWholeStrokeOn {
                serializationModel?.toggleWholeStroke()
                isWholeStrokeOn = false
            }
            
            isSelectingInk = true
        }
        
        penButton.backgroundColor = .white
        penButton.layer.cornerRadius = 0
        feltButton.backgroundColor = .white
        feltButton.layer.cornerRadius = 0
        brushButton.backgroundColor = .white
        brushButton.layer.cornerRadius = 0
        partialStrokeEraserButton.backgroundColor = .white
        partialStrokeEraserButton.layer.cornerRadius = 0
        wholeStrokeEraserButton.backgroundColor = .white
        wholeStrokeEraserButton.layer.cornerRadius = 0
        partialStrokeSelectorButton.backgroundColor = .lightGray
        partialStrokeSelectorButton.layer.cornerRadius = partialStrokeSelectorButton.frame.width / 3
        wholeStrokeSelectorButton.backgroundColor = .white
        wholeStrokeSelectorButton.layer.cornerRadius = 0
    }
    
    @IBAction func didTapWholeStrokeSelector(_ sender: UIButton) {
        if isDrawingStroke {
            queuedOperation = {
                self.serializationModel?.set(manipulationType: .select)
                self.selectInkButton.isHidden = false
                self.selectInkButton.setTitle("Select", for: .normal)
                
                if !self.isWholeStrokeOn {
                    self.serializationModel?.toggleWholeStroke()
                    self.isWholeStrokeOn = true
                }
                
                self.isSelectingInk = true
            }
        } else {
            serializationModel?.set(manipulationType: .select)
            selectInkButton.isHidden = false
            selectInkButton.setTitle("Select", for: .normal)
            
            if !isWholeStrokeOn {
                serializationModel?.toggleWholeStroke()
                isWholeStrokeOn = true
            }
            
            isSelectingInk = true
        }
        
        penButton.backgroundColor = .white
        penButton.layer.cornerRadius = 0
        feltButton.backgroundColor = .white
        feltButton.layer.cornerRadius = 0
        brushButton.backgroundColor = .white
        brushButton.layer.cornerRadius = 0
        partialStrokeEraserButton.backgroundColor = .white
        partialStrokeEraserButton.layer.cornerRadius = 0
        wholeStrokeEraserButton.backgroundColor = .white
        wholeStrokeEraserButton.layer.cornerRadius = 0
        partialStrokeSelectorButton.backgroundColor = .white
        partialStrokeSelectorButton.layer.cornerRadius = 0
        wholeStrokeSelectorButton.backgroundColor = .lightGray
        wholeStrokeSelectorButton.layer.cornerRadius = wholeStrokeSelectorButton.frame.width / 3
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let url = urls.first!
        if isLoad {
            guard url.startAccessingSecurityScopedResource() else {
                // Handle the failure here.
                assert(false, "Could not access security scoped resources")
                return
            }
            
            // Make sure you release the security-scoped resource when you are done.
            defer { url.stopAccessingSecurityScopedResource() }
            
            if url.pathExtension == "uim" {
                if serializationModel?.hasRasterInk(url: url) ?? false {
                    let alertController = UIAlertController(title: "Raster ink in vector canvas", message: "The ink model you are trying to load contains raster ink. Ink manipulation is disabled.", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(alertAction)
                    toolSelectionButton.isEnabled = false
                    try! serializationModel!.load(url: url, viewLayer: view.layer)
                    isRTreeLeavesShowHandler()
                    interactionEnabled = false
                    
                    if isSelectingTool {
                        UIView.animate(withDuration: 0.3) {
                            self.penButton.alpha = 0
                            self.feltButton.alpha = 0
                            self.brushButton.alpha = 0
                            self.partialStrokeEraserButton.alpha = 0
                            self.wholeStrokeEraserButton.alpha = 0
                            self.partialStrokeSelectorButton.alpha = 0
                            self.wholeStrokeSelectorButton.alpha = 0
                        }
                    }
                    
                    present(alertController, animated: true, completion: nil)
                } else {
                    try! serializationModel!.load(url: url, viewLayer: view.layer)
                    isRTreeLeavesShowHandler()
                    toolSelectionButton.isEnabled = true
                    interactionEnabled = true
                }
            } else {
                let alertView = UIAlertController(title: "Wrong file extension", message: "The selected file is not a .uim file", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertView.addAction(alertAction)
                present(alertView, animated: true, completion: nil)
            }
        } else {
            saveModel!.selectedFolderURL = url
           
            //let result = saveModel!.validate()
            
            let alertController = UIAlertController(title: "Name", message: "Choose a name", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) in
            }
            
            let okAction = UIAlertAction(title: "Ok", style: .default) { (alertAction) in
                if let textField = alertController.textFields?.first {
                    if let text = textField.text, !text.isEmpty {
                        self.fileName = text
                    }
                }
                
                self.saveModel!.selectedFileName = self.fileName
                
                if self.saveModel!.isValid {
                    var urlToSave = self.saveModel!.selectedFolderURL!.appendingPathComponent("\(self.saveModel!.selectedFileName!).\(self.fileExtension)")
                    if urlToSave.checkFileExist() {
                        let date = Date()
                        let format = DateFormatter()
                        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let formattedDate = format.string(from: date)
                        urlToSave = self.saveModel!.selectedFolderURL!.appendingPathComponent("\(self.saveModel!.selectedFileName!)_\(formattedDate).\(self.fileExtension)")
                    }
                    
                    guard self.saveModel!.selectedFolderURL!.startAccessingSecurityScopedResource() else {
                        assert(false, "Could not access security scoped context")
                        return
                    }
                    
                    defer { self.saveModel!.selectedFolderURL!.stopAccessingSecurityScopedResource() }
                    
                    do {
                        switch self.fileExtension {
                        case "uim":
                            try self.serializationModel!.save(urlToSave)//, name: saveNameFile)
                            print("Saved successfully in \(urlToSave.path)")
                        case "pdf":
                            try self.serializationModel?.savePDF(urlToSave)
                            print("Saved successfully in \(urlToSave.path)")
                        default:
                            print("unknown file extension")
                        }
                    } catch let error {
                        print("ERROR: \(error)")
                    }
                } else {
                    print("saveModel!.validateMessage -> \(self.saveModel!.validateMessage)")
                }
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            
            alertController.addTextField { (textField) in
                textField.placeholder = "File Name"
            }
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapSaveAsPDF(_ sender: UIButton) {
        fileExtension = "pdf"
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
        
        isLoad = false
        documentPicker.delegate = self
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func didTapSave(_ sender: UIButton) {
        fileExtension = "uim"
        
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
        
        isLoad = false
        documentPicker.delegate = self
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func didTapLoad(_ sender: UIButton) {
        let documentPicker: UIDocumentPickerViewController!
        
        documentPicker =  UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
        isLoad = true
        documentPicker.delegate = self
        
        present(documentPicker, animated: true, completion: nil)
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

    @objc func selectTransformaion(control: UISegmentedControl) {
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
    
    private func disableToolsButtons() {
        toolSelectionButton.isEnabled = false
        penButton.isEnabled = false
        feltButton.isEnabled = false
        brushButton.isEnabled = false
        partialStrokeEraserButton.isEnabled = false
        wholeStrokeEraserButton.isEnabled = false
        partialStrokeSelectorButton.isEnabled = false
        wholeStrokeSelectorButton.isEnabled = false
    }
    
    private func enableToolsButtons() {
        toolSelectionButton.isEnabled = true
        penButton.isEnabled = true
        feltButton.isEnabled = true
        brushButton.isEnabled = true
        partialStrokeEraserButton.isEnabled = true
        wholeStrokeEraserButton.isEnabled = true
        partialStrokeSelectorButton.isEnabled = true
        wholeStrokeSelectorButton.isEnabled = true
    }
    
    private func setSelectionButton() {
        if serializationModel!.hasSelection {
            transformationTypeSegmentedControl.isHidden = false
            selectInkButton.isHidden = false
            selectInkButton.setTitle("Deselect", for: .normal)
            
            view.addGestureRecognizer(rotateGestureRecognizer!)
            isRTreeLeavesShowHandler()
        }
        else {
            selectInkButton.setTitle("Select", for: .normal)
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

        setTitle()
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
        setTitle()
    }
    
    private func intersectBrushSizeSliderHandler() {
        setTitle()
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





