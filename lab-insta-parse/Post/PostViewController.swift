import UIKit
import PhotosUI
import ParseSwift
import AVFoundation

class PostViewController: UIViewController {
    
    
    @IBOutlet private weak var shareButton: UIBarButtonItem!
    @IBOutlet private weak var captionTextField: UITextField!
    @IBOutlet private weak var previewImageView: UIImageView!
    
    
    private var pickedImage: UIImage?
    
    
    private enum Constants {
        static let compressionQuality: CGFloat = 0.1
        static let loadingIndicatorTag = 100
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    
    private func setupUI() {
        
        view.backgroundColor = .black
        
        
        captionTextField.textColor = .white
        captionTextField.backgroundColor = .darkGray
        
        
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
    }
    
    
    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Choose Photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                self?.presentCamera()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        
        present(alertController, animated: true)
    }
    
    private func presentCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @IBAction func onShareTapped(_ sender: Any) {
        guard let image = pickedImage,
              let imageData = image.jpegData(compressionQuality: Constants.compressionQuality) else {
            showAlert(message: "Please select an image first")
            return
        }
        
        showLoadingIndicator()
        
        let imageFile = ParseFile(name: "image.jpg", data: imageData)
        var post = Post()
        post.imageFile = imageFile
        post.caption = captionTextField.text
        post.user = User.current
        
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            post.save { [weak self] result in
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    
                    switch result {
                    case .success(_):
                        if var currentUser = User.current {
                            currentUser.lastPostedDate = Date()
                            
                            DispatchQueue.global(qos: .userInitiated).async {
                                currentUser.save { [weak self] result in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success(_):
                                            NotificationCenter.default.post(name: Notification.Name("refresh_feed"), object: nil)
                                            self?.showSuccessAndDismiss()
                                        case .failure(let error):
                                            self?.showAlert(message: error.localizedDescription)
                                        }
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        self?.showAlert(message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    
    private func showSuccessAndDismiss() {
        let alert = UIAlertController(
            title: "Success!",
            message: "Your photo has been posted.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showLoadingIndicator() {
        shareButton.isEnabled = false
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.tag = Constants.loadingIndicatorTag
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
    
    private func hideLoadingIndicator() {
        shareButton.isEnabled = true
        view.viewWithTag(Constants.loadingIndicatorTag)?.removeFromSuperview()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


extension PostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(message: error.localizedDescription)
                }
                return
            }
            
            guard let image = object as? UIImage else { return }
            
            DispatchQueue.main.async {
                self?.pickedImage = image
                self?.previewImageView.image = image
            }
        }
    }
}


extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            pickedImage = image
            previewImageView.image = image
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
