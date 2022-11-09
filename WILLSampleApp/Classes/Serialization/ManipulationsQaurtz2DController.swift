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
    public var manipulationsModel: ManipulationsModel?
    private var rTreeLayer: CAShapeLayer?
    private var rTreeBezierPath: UIBezierPath?
    private var rotateGestureRecognizer: UIRotationGestureRecognizer?
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
    
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var transformationTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var penButton: UIButton!
    @IBOutlet weak var feltButton: UIButton!
    @IBOutlet weak var brushButton: UIButton!
    @IBOutlet weak var partialStrokeEraserButton: UIButton!
    @IBOutlet weak var wholeStrokeEraserButton: UIButton!
    @IBOutlet weak var partialStrokeSelectorButton: UIButton!
    @IBOutlet weak var wholeStrokeSelectorButton: UIButton!
    @IBOutlet weak var colorPickerButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var selectInkButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manipulationsModel = try! ManipulationsModel()
        manipulationsModel?.selectPen(inputType: .direct)
        manipulationsModel?.inkColor = .red
        
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
        
        manipulationsModel!.backgroundColor = UIColor.white
        view.layer.backgroundColor = manipulationsModel!.backgroundColor.cgColor
        view.layer.addSublayer(rTreeLayer!)
        
        saveModel = UIDocumentPickerSaveModel()
        
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        customView.layer.cornerRadius = 15
        customView.layer.masksToBounds = true
        customView.backgroundColor = .red
        
        manipulationsModel?.set(manipulationType: .draw)
        
        transformationTypeSegmentedControl.selectedSegmentIndex = 0
        transformationTypeSegmentedControl.tintColor = UIColor.black
        transformationTypeSegmentedControl.addTarget(self, action: #selector(selectTransformaion), for: UIControl.Event.valueChanged)
        transformationTypeSegmentedControl.isHidden = true
        selectTransformaion()
        
        rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotatedView(_:)))
    }
    
    @objc func rotatedView(_ sender: UIRotationGestureRecognizer) {
        if manipulationsModel!.selectedManipulationType == ManipulationType.select {
            if manipulationsModel!.hasSelection && manipulationsModel!.selectedTransformationType == TransformationType.rotate {
                if sender.state == .began {
                    manipulationsModel!.rotateBegan(sender)
                } else if sender.state == .changed {
                    manipulationsModel!.rotateMoved(sender)
                    
                } else if sender.state == .ended {
                    do {
                        try manipulationsModel!.rotateEnded(sender)
                    } catch {
                        NSException(name:NSExceptionName(rawValue: "ManipulationsQaurtz2DController.rotatedView"), reason:"\(error)", userInfo:nil).raise()
                    }
                }
            }
        }
    }
    
    @objc func didTapRedColor() {
        manipulationsModel?.inkColor = .red
        self.colorPickerButton.backgroundColor = .red
        lastToolColor = .red
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapBlueColor() {
        manipulationsModel?.inkColor = .blue
        self.colorPickerButton.backgroundColor = .blue
        lastToolColor = .blue
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapYellowColor() {
        manipulationsModel?.inkColor = .yellow
        self.colorPickerButton.backgroundColor = .yellow
        lastToolColor = .yellow
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapPurpleColor() {
        manipulationsModel?.inkColor = .purple
        self.colorPickerButton.backgroundColor = .purple
        lastToolColor = .purple
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapGreenColor() {
        manipulationsModel?.inkColor = .green
        self.colorPickerButton.backgroundColor = .green
        lastToolColor = .green
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapOrangeColor() {
        manipulationsModel?.inkColor = .orange
        self.colorPickerButton.backgroundColor = .orange
        lastToolColor = .orange
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapBlackColor() {
        manipulationsModel?.inkColor = .black
        self.colorPickerButton.backgroundColor = .black
        lastToolColor = .black
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapBrownColor() {
        manipulationsModel?.inkColor = .brown
        self.colorPickerButton.backgroundColor = .brown
        lastToolColor = .brown
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapGrayColor() {
        manipulationsModel?.inkColor = .gray
        self.colorPickerButton.backgroundColor = .gray
        lastToolColor = .gray
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapFileBrowser(_ sender: UIButton) {
        let documentPicker: UIDocumentPickerViewController!
        
        documentPicker =  UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
        isLoad = true
        documentPicker.delegate = self
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func didTapShareButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "Save as...", message: "Please Select File Format", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: ".uim", style: .default , handler:{ (UIAlertAction)in
            alert.dismiss(animated: true) {
                self.fileExtension = "uim"
                
                let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
                
                self.isLoad = false
                documentPicker.delegate = self
                
                self.present(documentPicker, animated: true, completion: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: ".pdf", style: .default , handler:{ (UIAlertAction)in
            alert.dismiss(animated: true) {
                self.fileExtension = "pdf"
                
                let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
                
                self.isLoad = false
                documentPicker.delegate = self
                
                self.present(documentPicker, animated: true, completion: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: ".svg", style: .default , handler:{ (UIAlertAction)in
            alert.dismiss(animated: true) {
                self.fileExtension = "svg"
                
                let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
                
                self.isLoad = false
                documentPicker.delegate = self
                
                self.present(documentPicker, animated: true, completion: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: ".png", style: .default , handler:{ (UIAlertAction)in
            alert.dismiss(animated: true) {
                self.fileExtension = "png"
                
                let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
                
                self.isLoad = false
                documentPicker.delegate = self
                
                self.present(documentPicker, animated: true, completion: nil)
            }
        }))
        
        alert.popoverPresentationController?.sourceView = shareButton

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didTapBackButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapColorPicker(_ sender: UIButton) {
        let colorViewSize: CGFloat = 44
        
        let redColorView = UIView()
        redColorView.backgroundColor = .red
        redColorView.heightAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        redColorView.widthAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        redColorView.layer.cornerRadius = colorViewSize / 2
        let redGR = UITapGestureRecognizer(target: self, action: #selector(didTapRedColor))
        redColorView.addGestureRecognizer(redGR)
        
        let blueColorView = UIView()
        blueColorView.backgroundColor = .blue
        blueColorView.heightAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        blueColorView.widthAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        blueColorView.layer.cornerRadius = colorViewSize / 2
        let blueGR = UITapGestureRecognizer(target: self, action: #selector(didTapBlueColor))
        blueColorView.addGestureRecognizer(blueGR)
    
        let yellowColorView = UIView()
        yellowColorView.backgroundColor = .yellow
        yellowColorView.heightAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        yellowColorView.widthAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        yellowColorView.layer.cornerRadius = colorViewSize / 2
        let yellowGR = UITapGestureRecognizer(target: self, action: #selector(didTapYellowColor))
        yellowColorView.addGestureRecognizer(yellowGR)
        
        let purpleColorView = UIView()
        purpleColorView.backgroundColor = .purple
        purpleColorView.heightAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        purpleColorView.widthAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        purpleColorView.layer.cornerRadius = colorViewSize / 2
        let purpleGR = UITapGestureRecognizer(target: self, action: #selector(didTapPurpleColor))
        purpleColorView.addGestureRecognizer(purpleGR)
        
        let greenColorView = UIView()
        greenColorView.backgroundColor = .green
        greenColorView.heightAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        greenColorView.widthAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        greenColorView.layer.cornerRadius = colorViewSize / 2
        let greenGR = UITapGestureRecognizer(target: self, action: #selector(didTapGreenColor))
        greenColorView.addGestureRecognizer(greenGR)
        
        let orangeColorView = UIView()
        orangeColorView.backgroundColor = .orange
        orangeColorView.heightAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        orangeColorView.widthAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        orangeColorView.layer.cornerRadius = colorViewSize / 2
        let orangeGR = UITapGestureRecognizer(target: self, action: #selector(didTapOrangeColor))
        orangeColorView.addGestureRecognizer(orangeGR)
        
        let blackColorView = UIView()
        blackColorView.backgroundColor = .black
        blackColorView.heightAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        blackColorView.widthAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        blackColorView.layer.cornerRadius = colorViewSize / 2
        let blackGR = UITapGestureRecognizer(target: self, action: #selector(didTapBlackColor))
        blackColorView.addGestureRecognizer(blackGR)
        
        let brownColorView = UIView()
        brownColorView.backgroundColor = .brown
        brownColorView.heightAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        brownColorView.widthAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        brownColorView.layer.cornerRadius = colorViewSize / 2
        let brownGR = UITapGestureRecognizer(target: self, action: #selector(didTapBrownColor))
        brownColorView.addGestureRecognizer(brownGR)
        
        let grayColorView = UIView()
        grayColorView.backgroundColor = .gray
        grayColorView.heightAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        grayColorView.widthAnchor.constraint(equalToConstant: colorViewSize).isActive = true
        grayColorView.layer.cornerRadius = colorViewSize / 2
        let grayGR = UITapGestureRecognizer(target: self, action: #selector(didTapGrayColor))
        grayColorView.addGestureRecognizer(grayGR)

        let popover = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        popover.popoverPresentationController?.sourceView = colorPickerButton
        
        let mainStackView = UIStackView()
        mainStackView.axis = NSLayoutConstraint.Axis.vertical
        mainStackView.distribution = UIStackView.Distribution.equalSpacing
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
          
        popover.view.addSubview(mainStackView)
        
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.topAnchor.constraint(equalTo: popover.view.topAnchor, constant: 10).isActive = true
        mainStackView.rightAnchor.constraint(equalTo: popover.view.rightAnchor, constant: 10).isActive = true
        mainStackView.leftAnchor.constraint(equalTo: popover.view.leftAnchor, constant: 10).isActive = true
        mainStackView.heightAnchor.constraint(equalToConstant: 170).isActive = true
        
        popover.view.translatesAutoresizingMaskIntoConstraints = false
        popover.view.heightAnchor.constraint(equalToConstant: 190).isActive = true
        
        present(popover, animated: true, completion: nil)
    }
    
    @IBAction func didTapClearAll(_ sender: UIButton) {
        if isSelectingInk {
            if try! manipulationsModel!.onSelectButton(view: view) {
                selectInkButton.setTitle("Select", for: .normal)
                
                view.removeGestureRecognizer(rotateGestureRecognizer!)
                self.transformationTypeSegmentedControl.isHidden = true
            }
        }
        
        manipulationsModel?.removeAll(view: view)
        manipulationsModel?.m_spatialModel.clear()
    }
    
    @IBAction func didTapSelect(_ sender: UIButton) {
        if isSelectingInk {
            if try! manipulationsModel!.onSelectButton(view: view) {
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
            let rects = manipulationsModel!.getAllNodes(bounds:view.layer.bounds)
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
            manipulationsModel!.touchesBegan(touches, with: event, view: view)
            buttonsView.isUserInteractionEnabled = false
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if interactionEnabled {
            if touches.first!.force != 0.3333333333333333 {
                manipulationsModel!.touchesMoved(touches, with: event, view: view)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawingStroke = false
        buttonsView.isUserInteractionEnabled = true
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        enableToolsButtons()
        if interactionEnabled {
            isDrawingStroke = false
            buttonsView.isUserInteractionEnabled = true
            manipulationsModel!.touchesEnded(touches, with: event, view: view)
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
                self.manipulationsModel?.selectPen(inputType: .direct)
                self.manipulationsModel?.set(manipulationType: .draw)
                self.manipulationsModel?.inkColor = self.lastToolColor
            }
        } else {
            manipulationsModel?.selectPen(inputType: .direct)
            manipulationsModel?.set(manipulationType: .draw)
            manipulationsModel?.inkColor = lastToolColor
        }
        
        isSelectingInk = false
        self.transformationTypeSegmentedControl.isHidden = true
        selectInkButton.isHidden = true
        
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
                self.manipulationsModel?.selectFelt(inputType: .direct)
                self.manipulationsModel?.set(manipulationType: .draw)
                self.manipulationsModel?.inkColor = self.lastToolColor
            }
        } else {
            manipulationsModel?.selectFelt(inputType: .direct)
            manipulationsModel?.set(manipulationType: .draw)
            manipulationsModel?.inkColor = lastToolColor
        }
        
        self.transformationTypeSegmentedControl.isHidden = true
        selectInkButton.isHidden = true
        isSelectingInk = false

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
                self.manipulationsModel?.selectBrush(inputType: .direct)
                self.manipulationsModel?.set(manipulationType: .draw)
                self.manipulationsModel?.inkColor = self.lastToolColor
            }
        } else {
            manipulationsModel?.selectBrush(inputType: .direct)
            manipulationsModel?.set(manipulationType: .draw)
            manipulationsModel?.inkColor = lastToolColor
        }
        
        selectInkButton.isHidden = true
        isSelectingInk = false
        self.transformationTypeSegmentedControl.isHidden = true
        
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
                self.manipulationsModel?.selectPartialStrokeEraser(inputType: .direct)
                self.manipulationsModel!.set(manipulationType: .intersect)
                self.manipulationsModel?.inkColor = .white
            }
        } else {
            self.manipulationsModel?.selectPartialStrokeEraser(inputType: .direct)
            manipulationsModel!.set(manipulationType: .intersect)
            manipulationsModel?.inkColor = .white
        }
        
        if self.isWholeStrokeOn {
            self.manipulationsModel?.toggleWholeStroke()
            self.isWholeStrokeOn = false
        }
        
        self.isSelectingInk = false
        self.selectInkButton.isHidden = true
        self.transformationTypeSegmentedControl.isHidden = true
        
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
                self.manipulationsModel?.selectWholeStrokeEraser(inputType: .direct)
                self.manipulationsModel?.set(manipulationType: .intersect)
                self.manipulationsModel?.inkColor = .white
            }
        } else {
            manipulationsModel?.selectWholeStrokeEraser(inputType: .direct)
            manipulationsModel?.set(manipulationType: .intersect)
            manipulationsModel?.inkColor = .white
        }
        
        if !isWholeStrokeOn {
            manipulationsModel?.toggleWholeStroke()
            isWholeStrokeOn = true
        }

        isSelectingInk = false
        selectInkButton.isHidden = true
        self.transformationTypeSegmentedControl.isHidden = true
        
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
                self.manipulationsModel?.selectPartialStrokeSelector(inputType: .direct)
                self.manipulationsModel?.set(manipulationType: .select)
                self.manipulationsModel?.inkColor = .black
                
            }
        } else {
            manipulationsModel?.selectPartialStrokeSelector(inputType: .direct)
            manipulationsModel?.set(manipulationType: .select)
            manipulationsModel?.inkColor = .black
        }
        
        if !self.isSelectingInk {
            self.selectInkButton.setTitle("Select", for: .normal)
        }
        
        self.selectInkButton.isHidden = false
        
        if self.isWholeStrokeOn {
            self.manipulationsModel?.toggleWholeStroke()
            self.isWholeStrokeOn = false
        }
        
        self.isSelectingInk = true
        
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
                self.manipulationsModel?.selectWholeStrokeSelector(inputType: .direct)
                self.manipulationsModel?.set(manipulationType: .select)
            }
        } else {
            manipulationsModel?.selectWholeStrokeSelector(inputType: .direct)
            manipulationsModel?.set(manipulationType: .select)
        }
        
        if !self.isSelectingInk {
            self.selectInkButton.setTitle("Select", for: .normal)
        }
        
        self.selectInkButton.isHidden = false
        
        if !self.isWholeStrokeOn {
            self.manipulationsModel?.toggleWholeStroke()
            self.isWholeStrokeOn = true
        }
        
        self.isSelectingInk = true
        
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
                if manipulationsModel?.hasRasterInk(url: url) ?? false {
                    let alertController = UIAlertController(title: "Raster ink in vector canvas", message: "The ink model you are trying to load contains raster ink. Ink manipulation is disabled.", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(alertAction)
                    try! manipulationsModel!.load(url: url, viewLayer: view.layer)
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
                    try! manipulationsModel!.load(url: url, viewLayer: view.layer)
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
            
            let alertController = UIAlertController(title: "Name", message: "", preferredStyle: .alert)
            
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
                    let fileExt = (self.saveModel?.selectedFileName ?? "").hasSuffix(".\(self.fileExtension)") ? "" : ".\(self.fileExtension)"
                    var urlToSave = self.saveModel!.selectedFolderURL!.appendingPathComponent("\(self.saveModel!.selectedFileName!.appending(fileExt))")
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
                            try self.manipulationsModel!.save(urlToSave)//, name: saveNameFile)
                            print("Saved successfully in \(urlToSave.path)")
                        case "pdf":
                            try self.manipulationsModel?.savePDF(urlToSave)
                            print("Saved successfully in \(urlToSave.path)")
                        case "svg":
                            try self.manipulationsModel?.saveSVG(urlToSave)
                            print("Saved successfully in \(urlToSave.path)")
                        case "png":
                            try self.manipulationsModel?.savePNG(urlToSave)
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
    
    func clickSaveButtonHandler() throws {
        //let validate = saveModel!.validate()
        if saveModel!.isValid {//, fileName = fileNameTextField.text {
            
            var urlToSave = saveModel!.selectedFolderURL!.appendingPathComponent("\(saveModel!.selectedFileName!).uim")
            if urlToSave.checkFileExist() {
                let date = Date()
                let format = DateFormatter()
                format.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let formattedDate = format.string(from: date)
                urlToSave = saveModel!.selectedFolderURL!.appendingPathComponent("\(saveModel!.selectedFileName!)_\(formattedDate).uim")
            }
            
            guard saveModel!.selectedFolderURL!.startAccessingSecurityScopedResource() else {
                // Handle the failure here.
                assert(false, "Could not access security scoped context")
                return
            }
            
            defer { saveModel!.selectedFolderURL!.stopAccessingSecurityScopedResource() }
            
            try manipulationsModel!.save(urlToSave)//, name: saveNameFile)
            print("Saved successfully")
        } else {
            print("saveModel?.validateMessage -> \(saveModel?.validateMessage)")
        }
    }
    
    func clickLoadButtonHandler() {
        let documentPicker: UIDocumentPickerViewController!
        
        documentPicker =  UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
        isLoad = true
        documentPicker.delegate = self
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    @objc func selectTransformaion() {
        manipulationsModel?.set(transformationType: TransformationType(rawValue: transformationTypeSegmentedControl.selectedSegmentIndex)!)
    }
    
    @objc func clickSelectionButton(sender: UIButton) {
        clickSelectionButtonHandler()
    }
    
    private func disableToolsButtons() {
        penButton.isEnabled = false
        feltButton.isEnabled = false
        brushButton.isEnabled = false
        partialStrokeEraserButton.isEnabled = false
        wholeStrokeEraserButton.isEnabled = false
        partialStrokeSelectorButton.isEnabled = false
        wholeStrokeSelectorButton.isEnabled = false
    }
    
    private func enableToolsButtons() {
        penButton.isEnabled = true
        feltButton.isEnabled = true
        brushButton.isEnabled = true
        partialStrokeEraserButton.isEnabled = true
        wholeStrokeEraserButton.isEnabled = true
        partialStrokeSelectorButton.isEnabled = true
        wholeStrokeSelectorButton.isEnabled = true
    }
    
    private func setSelectionButton() {
        if manipulationsModel!.hasSelection {
            selectInkButton.isHidden = false
            selectInkButton.setTitle("Deselect", for: .normal)
            
            view.addGestureRecognizer(rotateGestureRecognizer!)
            self.transformationTypeSegmentedControl.isHidden = false
        } else {
            selectInkButton.setTitle("Select", for: .normal)
            
            view.removeGestureRecognizer(rotateGestureRecognizer!)
            self.transformationTypeSegmentedControl.isHidden = true
        }
    }
    
    private func clickSelectionButtonHandler() {
        if try! manipulationsModel!.onSelectButton(view: view) {
            setSelectionButton()
        } else {
            let alertController = UIAlertController(title: "Insufficient data", message:
                "You need to draw selecting area.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
