//
//  RasterBrushController.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 14.03.19.
//  Copyright © 2019 nikolay.atanasov. All rights reserved.
//

import WacomInk

class RasterBrushController: RedrawController
{
    @IBOutlet weak var configButton: UIButton!
    @IBOutlet weak var pencilButton: UIButton!
    @IBOutlet weak var waterBrushButton: UIButton!
    @IBOutlet weak var crayonButton: UIButton!
    @IBOutlet weak var eraserButton: UIButton!
    @IBOutlet weak var stackViewContainer: UIView!
    
    private var lastToolColor: UIColor = .black
    private var queuedOperation: (() -> ())?
    private var isDrawingStroke = false
    
    var isSelecting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let particleBrush = Pencil().particleBrush(graphics: graphics)
        renderingModel = RasterBrushModel(RasterInkBuilder(), .max, particleBrush: particleBrush)
        (renderingModel as! RasterBrushModel).selectPencil(inputType: .direct, graphics: graphics)
        
        pencilButton.layer.cornerRadius = pencilButton.frame.width / 3
        pencilButton.backgroundColor = .lightGray
        
        stackViewContainer.layer.cornerRadius = 10
        
        let colorPicker = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        colorPicker.layer.cornerRadius = 15
        colorPicker.layer.masksToBounds = true
        colorPicker.backgroundColor = .red
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapColorPicker))
        colorPicker.addGestureRecognizer(tapGestureRecognizer)
        
        let barButtonItem = UIBarButtonItem(customView: colorPicker)
        self.navigationItem.rightBarButtonItem = barButtonItem
        
        renderingModel?.inkColor = .red
        lastToolColor = .red
    }
    
    override func drawableSizeDependableFieldsBody() {
        super.drawableSizeDependableFieldsBody()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawingStroke = true
        stackViewContainer.isUserInteractionEnabled = false
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawingStroke = false
        stackViewContainer.isUserInteractionEnabled = true
        super.touchesCancelled(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawingStroke = false
        stackViewContainer.isUserInteractionEnabled = true
        super.touchesEnded(touches, with: event)
        
        queuedOperation?()
        queuedOperation = nil
    }
    
    @IBAction func didTapToolSelectionButton(_ sender: UIButton) {
        if !isSelecting {
            UIView.animate(withDuration: 0.3) {
                self.pencilButton.alpha = 1
                self.waterBrushButton.alpha = 1
                self.crayonButton.alpha = 1
                self.eraserButton.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.pencilButton.alpha = 0
                self.waterBrushButton.alpha = 0
                self.crayonButton.alpha = 0
                self.eraserButton.alpha = 0
            }
        }
        
        isSelecting = !isSelecting
    }
    
    @IBAction func didTapDismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapToolButton(_ sender: UIButton) {
        switch sender.tag {
        case 0: // Pencil
            if isDrawingStroke {
                queuedOperation = {
                    (self.renderingModel as? RasterBrushModel)?.selectPencil(inputType: .direct, graphics: self.graphics)
                    self.renderingModel?.inkColor = self.lastToolColor
                }
            } else {
                (renderingModel as? RasterBrushModel)?.selectPencil(inputType: .direct, graphics: graphics)
                renderingModel?.inkColor = lastToolColor
            }
            
            pencilButton.layer.cornerRadius = pencilButton.frame.width / 3
            pencilButton.backgroundColor = .lightGray
            waterBrushButton.layer.cornerRadius = 0
            waterBrushButton.backgroundColor = .white
            crayonButton.layer.cornerRadius = 0
            crayonButton.backgroundColor = .white
            eraserButton.layer.cornerRadius = 0
            eraserButton.backgroundColor = .white
        case 1: // Water Brush
            if isDrawingStroke {
                queuedOperation = {
                    (self.renderingModel as? RasterBrushModel)?.selectWaterBrush(inputType: .direct, graphics: self.graphics)
                    self.renderingModel?.inkColor = self.lastToolColor
                }
            } else {
                (renderingModel as? RasterBrushModel)?.selectWaterBrush(inputType: .direct, graphics: graphics)
                renderingModel?.inkColor = lastToolColor
            }
            
            pencilButton.layer.cornerRadius = 0
            pencilButton.backgroundColor = .white
            waterBrushButton.layer.cornerRadius = pencilButton.frame.width / 3
            waterBrushButton.backgroundColor = .lightGray
            crayonButton.layer.cornerRadius = 0
            crayonButton.backgroundColor = .white
            eraserButton.layer.cornerRadius = 0
            eraserButton.backgroundColor = .white
        case 2: // Crayon
            if isDrawingStroke {
                queuedOperation = {
                    (self.renderingModel as? RasterBrushModel)?.selectCrayon(inputType: .direct, graphics: self.graphics)
                    self.renderingModel?.inkColor = self.lastToolColor
                }
            } else {
                (renderingModel as? RasterBrushModel)?.selectCrayon(inputType: .direct, graphics: graphics)
                renderingModel?.inkColor = lastToolColor
            }
            
            pencilButton.layer.cornerRadius = 0
            pencilButton.backgroundColor = .white
            waterBrushButton.layer.cornerRadius = 0
            waterBrushButton.backgroundColor = .white
            crayonButton.layer.cornerRadius = pencilButton.frame.width / 3
            crayonButton.backgroundColor = .lightGray
            eraserButton.layer.cornerRadius = 0
            eraserButton.backgroundColor = .white
        case 3: // Eraser
            if isDrawingStroke {
                queuedOperation = {
                    (self.renderingModel as? RasterBrushModel)?.selectEraser(inputType: .direct, graphics: self.graphics)
                    self.renderingModel?.inkColor = self.view.backgroundColor ?? .white
                }
            } else {
                (renderingModel as? RasterBrushModel)?.selectEraser(inputType: .direct, graphics: graphics)
                renderingModel?.inkColor = view.backgroundColor ?? .white
            }
            
            pencilButton.layer.cornerRadius = 0
            pencilButton.backgroundColor = .white
            waterBrushButton.layer.cornerRadius = 0
            waterBrushButton.backgroundColor = .white
            crayonButton.layer.cornerRadius = 0
            crayonButton.backgroundColor = .white
            eraserButton.layer.cornerRadius = eraserButton.frame.width / 3
            eraserButton.backgroundColor = .lightGray
        default:
            print("Unknown tool")
        }
    }
    
    @IBAction func didTapClearAll(_ sender: UIButton) {
        initLayers()
        
        resetRedraw()
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
    
    @objc func didTapRedColor() {
        if !(ToolPalette.shared.selectedRasterTool is RasterEraser) {
            renderingModel?.inkColor = .red
        }
        
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .red
        lastToolColor = .red
    }
    
    @objc func didTapBlueColor() {
        if !(ToolPalette.shared.selectedRasterTool is RasterEraser) {
            renderingModel?.inkColor = .blue
        }
        
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .blue
        lastToolColor = .blue
    }
    
    @objc func didTapYellowColor() {
        if !(ToolPalette.shared.selectedRasterTool is RasterEraser) {
            renderingModel?.inkColor = .yellow
        }
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .yellow
        lastToolColor = .yellow
    }
    
    @objc func didTapPurpleColor() {
        if !(ToolPalette.shared.selectedRasterTool is RasterEraser) {
            renderingModel?.inkColor = .purple
        }
        
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .purple
        lastToolColor = .purple
    }
    
    @objc func didTapGreenColor() {
        if !(ToolPalette.shared.selectedRasterTool is RasterEraser) {
            renderingModel?.inkColor = .green
        }
        
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .green
        lastToolColor = .green
    }
    
    @objc func didTapOrangeColor() {
        if !(ToolPalette.shared.selectedRasterTool is RasterEraser) {
            renderingModel?.inkColor = .orange
        }
        
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .orange
        lastToolColor = .orange
    }
    
    @objc func didTapBlackColor() {
        if !(ToolPalette.shared.selectedRasterTool is RasterEraser) {
            renderingModel?.inkColor = .black
        }
        
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .black
        lastToolColor = .black
    }
    
    @objc func didTapBrownColor() {
        if !(ToolPalette.shared.selectedRasterTool is RasterEraser) {
            renderingModel?.inkColor = .brown
        }
        
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .brown
        lastToolColor = .brown
    }
    
    @objc func didTapGrayColor() {
        if !(ToolPalette.shared.selectedRasterTool is RasterEraser) {
            renderingModel?.inkColor = .gray
        }
        
        self.navigationItem.rightBarButtonItem?.customView?.backgroundColor = .gray
        lastToolColor = .gray
    }
}
