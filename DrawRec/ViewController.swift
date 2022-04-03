//
//  ViewController.swift
//  DrawRec
//
//  Created by Abigail De Micco on 22/03/22.
//

import UIKit
import PencilKit
import Vision

class ViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver {
    
    @IBOutlet weak var pencilFingerButton: UIBarButtonItem! //pencil o dito
    @IBOutlet weak var canvasView: PKCanvasView! //lavagna
    
    @IBOutlet weak var recNum: UILabel! //risultato
    
    var requests = [VNRequest]() // holds Image Classification Request
    
    var drawing = PKDrawing() //contiene il disegno
    let toolPicker = PKToolPicker.init() //barra dei pennelli

    
    override func viewDidAppear(_ animated: Bool) { //funzione triggerata quando appare la pagina
        super.viewDidAppear(animated)
        
        canvasView.delegate = self
        canvasView.drawing = drawing //colleghiamo il disegno di PK alla lavagna
        
        canvasView.drawingPolicy = .anyInput //possiamo disegnare sia con la pencil che con il dito
        canvasView.backgroundColor = .black //imposto il colore della lavagna a nero
        
        toolPicker.setVisible(true, forFirstResponder: canvasView) //il toolPicker è visibile solo in presenza della canvasView
        toolPicker.addObserver(canvasView) //il toolPicker controlla se c'è la canvasView
        toolPicker.selectedTool = PKInkingTool(.marker, color: .white, width: 30) //impostiamo il pennello di default
        
        canvasView.becomeFirstResponder() //la canvasView comunica al toolPicker di essere attiva
    }
    
    override func viewDidLoad() { //funzione triggerata quando si carica la pagina
        super.viewDidLoad()
        setupVision() //configura vision
    }
    
    @IBAction func toggleFingerOrPencil (_ sender: Any) { //cambia il mezzo con cui disegnare
        if canvasView.drawingPolicy == .anyInput {
            canvasView.drawingPolicy = .pencilOnly
            pencilFingerButton.title = "Pencil"
        }
        else {
            canvasView.drawingPolicy = .anyInput
            pencilFingerButton.title = "Finger"
        }
    }
    
    func setupVision() {
        
        guard let visionModel = try? VNCoreMLModel(for: MNISTClassifier(configuration: MLModelConfiguration()).model) else {fatalError("can not load Vision ML model")}  //assegniamo il modello di riconoscimento numeri al visionModel
        
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.handleClassification) //impostiamo una richiesta per il visionModel affinché, quando gli passiamo il disegno, esso richiami la funzione "handleClassification"
        
        self.requests = [classificationRequest] //assegna la richiesta a requests in forma di array
        
    }
    
    func handleClassification (request:VNRequest, error:Error?) {
        guard let observations = request.results else {print("no results"); return} //recupero i risultati della richiesta fatta al visionModel
        
        // process the ovservations
        let classifications = observations
            .compactMap({$0 as? VNClassificationObservation}) // cast all elements to VNClassificationObservation objects
            .filter({$0.confidence > 0.8}) // only choose observations with a confidence of more than 80%
            .map({$0.identifier}) // only choose the identifier string to be placed into the classifications array
        
        DispatchQueue.main.async {
            self.recNum.text = classifications.first // update the UI results with the classification
        }
        
    }
    
    @IBAction func recognizeNumber(_ sender: Any) {
        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, UIScreen.main.scale)
        
        canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext() //salviamo il disegno in image
        UIGraphicsEndImageContext() //termina l'attività di disegno
        
        
        if image != nil {
            let scaledImage = scaleImage(image: image!, toSize: CGSize(width: 28, height: 28)) //ridimensioniamo il disegno
            
            let imageRequestHandler = VNImageRequestHandler(cgImage: scaledImage.cgImage!, options: [:]) // creiamo il gestore della richiesta, passandogli il disegno ridimensionato
            
            do {
                try imageRequestHandler.perform(self.requests) //attiviamo il gestore della richiesta affinché passi l'immagine al visionModel
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

