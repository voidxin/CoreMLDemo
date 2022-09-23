//
//  ViewController.swift
//  CoreMLDemo
//
//  Created by zhangxin on 2020/11/18.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
   
    @IBOutlet weak var tipsTextField: UITextField!
    @IBOutlet weak var content: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    lazy var detectorRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: targetFind().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.detectionResult(request: request, error: error)
            })
            request.imageCropAndScaleOption = .scaleFit
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    @IBAction func choosePic(_ sender: Any) {
        choosePic()
    }
    //检测结果
    func detectionResult(request:VNRequest,error:Error?) -> Void {
        DispatchQueue.main.async {
            guard let resutls = request.results else {
                print("什么都没有")
                self.tipsTextField.text = "未检测到目标物体-吉利汽车"
                return
            }
            let detections = resutls as! [VNRecognizedObjectObservation]
            self.drawMaskRect(detections: detections)
        }
    }
    //画出检测到的目标区域以及返回的参数
    func drawMaskRect(detections:[VNRecognizedObjectObservation]) -> Void {
        guard let image = self.content.image else {
            return
        }
        
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        
        image.draw(at: CGPoint.zero)
        if detections.count == 0 {
            self.tipsTextField.text = "未检测到目标物体特征"
        }
        for detection in detections {
            let title = "目标物体："+detection.labels.first!.identifier
            let boundingBox = detection.boundingBox
            let rectangle = CGRect(x: boundingBox.minX*image.size.width, y: (1-boundingBox.minY-boundingBox.height)*image.size.height, width: boundingBox.width*image.size.width, height: boundingBox.height*image.size.height)
            UIColor(red: 0, green: 1, blue: 0, alpha: 0.4).setFill()
            UIRectFillUsingBlendMode(rectangle, CGBlendMode.normal)
            
            self.tipsTextField.text = title + "\n" + "目标检测区域：\n"+detection.labels.first!.description
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.content?.image = newImage
    }
    
    
    //检测图片
    func detectImage(image:UIImage) -> Void {
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation!)
            do {
                //检测
                try handler.perform([self.detectorRequest])
            } catch {
                print("Failed to perform detection.\n\(error.localizedDescription)")
            }
        }
    }
    //选择图片
    func choosePic() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let camera = UIAlertAction(title: "相机", style: .default) { (action) in
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)){
                let pickerVC = UIImagePickerController()
                pickerVC.delegate = self
                pickerVC.allowsEditing = true
                pickerVC.sourceType = .camera
                self .present(pickerVC, animated: true, completion: nil)
            }
        }
        
        let album = UIAlertAction(title: "相册", style: .default) { (action) in
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)){
                let pickerVC = UIImagePickerController()
                pickerVC.delegate = self
                pickerVC.allowsEditing = true
                pickerVC.sourceType = .photoLibrary
                self .present(pickerVC, animated: true, completion: nil)
            }
        }
        
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alert.addAction(camera)
        alert.addAction(album)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }


}
extension ViewController : UIImagePickerControllerDelegate ,UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
         guard let image = info[.originalImage] as? UIImage else {
                   return
               }
        self.content.image = image
        self.detectImage(image: image)
        
    }
}
