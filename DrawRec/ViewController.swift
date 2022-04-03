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
import CoreML

class ViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver {
    
    @IBOutlet weak var pencilFingerButton: UIBarButtonItem!
    @IBOutlet weak var canvasView: PKCanvasView!
    
    @IBOutlet weak var recNum: UILabel!
    
    let canvasWidth: CGFloat = 414
    let context = CIContext()
    var pixelBuffer: CVPixelBuffer?
    var requests = [VNRequest]() // holds Image Classification Request
    
    var drawing = PKDrawing()
    let toolPicker = PKToolPicker.init()

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        canvasView.delegate = self
        canvasView.drawing = drawing
        
        canvasView.alwaysBounceVertical = true
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .black
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.isRulerActive = false
        toolPicker.selectedTool = PKInkingTool(.marker, color: .white, width: 30)
        
        canvasView.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVision()
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
    
    func setupVision() {
        // load MNIST model for the use with the Vision framework
        guard let visionModel = try? VNCoreMLModel(for: MNISTClassifier(configuration: MLModelConfiguration()).model) else {fatalError("can not load Vision ML model")}
        
        // create a classification request and tell it to call handleClassification once its done
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.handleClassification)
        
        self.requests = [classificationRequest] // assigns the classificationRequest to the global requests array
        
    }
    
    func handleClassification (request:VNRequest, error:Error?) {
        guard let observations = request.results else {print("no results"); return}
        
        // process the ovservations
        let classifications = observations
            .compactMap({$0 as? VNClassificationObservation}) // cast all elements to VNClassificationObservation objects
            .filter({$0.confidence > 0.8}) // only choose observations with a confidence of more than 80%
            .map({$0.identifier}) // only choose the identifier string to be placed into the classifications array
        
        DispatchQueue.main.async {
            self.recNum.text = classifications.first // update the UI with the classification
        }
        
    }
    
    @IBAction func saveDrawingToCameraRoll(_ sender: Any) {
        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, UIScreen.main.scale)
        
        
        canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext() //salviamo il disegno in image
        UIGraphicsEndImageContext() //termina l'attività di disegno
        
        
        if image != nil {
            let scaledImage = scaleImage(image: image!, toSize: CGSize(width: 28, height: 28))
            
            let imageRequestHandler = VNImageRequestHandler(cgImage: scaledImage.cgImage!, options: [:]) // create a handler that should perform the vision request
            
            do {
                try imageRequestHandler.perform(self.requests)
            }catch{
                print(error)
            }
        }
    }
    
    // scales any UIImage to a desired target size
    func scaleImage (image:UIImage, toSize size:CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
}

