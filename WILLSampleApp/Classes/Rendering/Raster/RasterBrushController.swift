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
    @IBOutlet weak var stackViewContainer: UIView!
    
    var isSelecting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let particleBrush = Pencil().particleBrush(graphics: graphics)
        renderingModel = RasterBrushModel(RasterInkBuilder(), .max, particleBrush: particleBrush)
        (renderingModel as! RasterBrushModel).selectPencil(inputType: .direct, graphics: graphics)
        
        pencilButton.layer.cornerRadius = pencilButton.frame.width / 3
        pencilButton.backgroundColor = .lightGray
        
        stackViewContainer.layer.cornerRadius = 10
    }
    
    override func drawableSizeDependableFieldsBody() {
        super.drawableSizeDependableFieldsBody()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        stackViewContainer.isUserInteractionEnabled = false
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        stackViewContainer.isUserInteractionEnabled = true
        super.touchesCancelled(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stackViewContainer.isUserInteractionEnabled = true
        super.touchesEnded(touches, with: event)
    }
    
    @IBAction func didTapToolSelectionButton(_ sender: UIButton) {
        if !isSelecting {
            UIView.animate(withDuration: 0.3) {
                self.pencilButton.alpha = 1
                self.waterBrushButton.alpha = 1
                self.crayonButton.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.pencilButton.alpha = 0
                self.waterBrushButton.alpha = 0
                self.crayonButton.alpha = 0
            }
        }
        
        isSelecting = !isSelecting
    }
    
    @IBAction func didTapDismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapToolButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            (renderingModel as? RasterBrushModel)?.selectPencil(inputType: .direct, graphics: graphics)
            renderingModel?.color = .gray
            
            pencilButton.layer.cornerRadius = pencilButton.frame.width / 3
            pencilButton.backgroundColor = .lightGray
            waterBrushButton.layer.cornerRadius = 0
            waterBrushButton.backgroundColor = .white
            crayonButton.layer.cornerRadius = 0
            crayonButton.backgroundColor = .white
        case 1:
            (renderingModel as? RasterBrushModel)?.selectWaterBrush(inputType: .direct, graphics: graphics)
            renderingModel?.color = UIColor.gray
            
            pencilButton.layer.cornerRadius = 0
            pencilButton.backgroundColor = .white
            waterBrushButton.layer.cornerRadius = pencilButton.frame.width / 3
            waterBrushButton.backgroundColor = .lightGray
            crayonButton.layer.cornerRadius = 0
            crayonButton.backgroundColor = .white
        case 2:
            (renderingModel as? RasterBrushModel)?.selectCrayon(inputType: .direct, graphics: graphics)
            renderingModel?.color = .green
            
            pencilButton.layer.cornerRadius = 0
            pencilButton.backgroundColor = .white
            waterBrushButton.layer.cornerRadius = 0
            waterBrushButton.backgroundColor = .white
            crayonButton.layer.cornerRadius = pencilButton.frame.width / 3
            crayonButton.backgroundColor = .lightGray
        default:
            print("Unknown tool")
        }
    }
}
