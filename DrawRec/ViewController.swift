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
    var requests = [VNRequest]()
    
    let canvasWidth: CGFloat = 414
    let canvasOverscrollHight: CGFloat = 454
    let context = CIContext()
    var pixelBuffer: CVPixelBuffer?
    
    var drawing = PKDrawing()
    let toolPicker = PKToolPicker.init()

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        canvasView.delegate = self
        canvasView.isOpaque = true
        canvasView.drawing = drawing
        
        canvasView.alwaysBounceVertical = true
        canvasView.drawingPolicy = .anyInput
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.isRulerActive = false
        
        canvasView.becomeFirstResponder()
        
        //setupVision()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let canvasScale = canvasView.bounds.width / canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale

        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }
    
//    func setupVision() {
//        // load MNIST model for the use with the Vision framework
//        guard let visionModel = try? VNCoreMLModel(for: MNISTClassifier(configuration: MLModelConfiguration()).model) else {fatalError("can not load Vision ML model")}
//
//        // create a classification request and tell it to call handleClassification once its done
//        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.handleClassification)
//
//        self.requests = [classificationRequest] // assigns the classificationRequest to the global requests array
//
//    }
    
//    func handleClassification (request:VNRequest, error:Error?) {
//        guard let observations = request.results else {print("no results"); return}
//
//        // process the ovservations
//        let classifications = observations
//            .compactMap({$0 as? VNClassificationObservation}) // cast all elements to VNClassificationObservation objects
//            .filter({$0.confidence > 0.8}) // only choose observations with a confidence of more than 80%
//            .map({$0.identifier}) // only choose the identifier string to be placed into the classifications array
//
//        DispatchQueue.main.async {
//            self.recNum.text = classifications.first // update the UI with the classification
//        }
//
//    }
    
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
                        let model = MNISTClassifier()
            
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
                        
            
//            let scaledImage = scaleImage(image: image!, toSize: CGSize(width: 28, height: 28)) // scale the image to the required size of 28x28 for better recognition results
//
//            let imageRequestHandler = VNImageRequestHandler(cgImage: scaledImage.cgImage!, options: [:]) // create a handler that should perform the vision request
//
//            do {
//                try imageRequestHandler.perform(self.requests)
//            }catch{
//                print(error)
//            }
        }
    }
    
    // scales any UIImage to a desired target size
//    func scaleImage (image:UIImage, toSize size:CGSize) -> UIImage {
//        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
//        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return newImage!
//    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateContentSizeForDrawing()
    }
    
    func updateContentSizeForDrawing(){
        let drawing = canvasView.drawing
        let contentHeight: CGFloat
        
        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + self.canvasOverscrollHight) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }
        
        canvasView.contentSize = CGSize (width: canvasWidth * canvasView.zoomScale, height: contentHeight)
    }
    
}

