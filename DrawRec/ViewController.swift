//
//  ViewController.swift
//  DrawRec
//
//  Created by Abigail De Micco on 22/03/22.
//

import UIKit
import PencilKit
import PhotosUI
import Vision

class ViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver {
    
    @IBOutlet weak var pencilFingerButton: UIBarButtonItem!
    @IBOutlet weak var canvasView: PKCanvasView!
    
    @IBOutlet weak var recNum: UILabel!
    
    let canvasWidth: CGFloat = 414
    let context = CIContext()
    var pixelBuffer: CVPixelBuffer?
    
    var drawing = PKDrawing()
    let toolPicker = PKToolPicker.init()

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        canvasView.delegate = self
        canvasView.drawing = drawing
        
        canvasView.alwaysBounceVertical = true
        canvasView.drawingPolicy = .anyInput
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.isRulerActive = false
        
        canvasView.becomeFirstResponder()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let canvasScale = canvasView.bounds.width / canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }
    
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    @IBAction func toggleFingerOrPencil (_ sender: Any) {
        if canvasView.drawingPolicy == .anyInput {
            canvasView.drawingPolicy = .pencilOnly
        }
        else {
            canvasView.drawingPolicy = .anyInput
        }
        pencilFingerButton.title = canvasView.drawingPolicy == .anyInput ? "Finger" : "Pencil"
    }
    
    @IBAction func saveDrawingToCameraRoll(_ sender: Any) {
        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, UIScreen.main.scale)
        
        
        canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext() //salviamo il disegno in image
        UIGraphicsEndImageContext() //termina l'attività di disegno
        
        
        if image != nil {
                        // load our CoreML Pokedex model
           guard let model = try? MNISTClassifier(configuration: MLModelConfiguration()) else {fatalError("can not load Vision ML model")}
            
                        let ciImage = CIImage(image: image!) //converto UIimage in CIImage
                        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                                             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
                                CVPixelBufferCreate(kCFAllocatorDefault,
                                                    28,
                                                    28,
                                                    kCVPixelFormatType_OneComponent8,
                                                    attrs,
                                                    &pixelBuffer)
                        context.render(ciImage!, to: pixelBuffer!) //converto CIImage in CVPixelBuffer
                        guard let output = try? model.prediction(image: pixelBuffer!) else { //avviene il confronto tra il disegno e il dataset
                            fatalError("Unexpected runtime error.")
                        }
            
                        let recognizedNumb = output.classLabel
                self.recNum.text = "\(recognizedNumb)"
        }
    }
}

