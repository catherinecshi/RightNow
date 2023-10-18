import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth
import SDWebImage

class PhotoTakenViewController: UIViewController {
    
    // MARK: variables
    //storage
    lazy var storage = Storage.storage()
    //var db: Firestore!
    
    var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray
        return imageView
    }()
    
    lazy var saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Save", for: .normal)
        btn.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    /*
    lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cancel", for: .normal)
        btn.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return btn
    }()
     */
    
    //MARK: Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        //firestore
        //db = Firestore.firestore()
        
        //title
        title = "RightNow"
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        //add image into view
        view.addSubview(previewImageView)
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        setupConstraintsForPreviewImageView()
        
        //add save button
        view.addSubview(saveButton)
        setupSaveButton()
        setupConstraintsForSaveButton()
    }
    
    // MARK: Preview Image View
    
    private func setupConstraintsForPreviewImageView() {
        NSLayoutConstraint.activate([
            //sets height
            previewImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            previewImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            
            //align imageview horizontally to center of main view
            previewImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            //encompasses whole screen
            previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
        ])
        
        //round corners
        let cornerRadius: CGFloat = 15.0
        previewImageView.layer.cornerRadius = cornerRadius
        previewImageView.clipsToBounds = true
    }
    
    //MARK: Button Methods
    
    private func setupSaveButton() {
        //appearance
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        saveButton.backgroundColor = .black
        
        //add target to handle
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraintsForSaveButton() {
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 70),
            saveButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    @objc func saveButtonTapped(_ sender: Any) {
        //UIImageWriteToSavedPhotosAlbum(previewImageView.image!, nil, nil, nil)
        
        saveImageToFirebase(image: previewImageView.image!) { downloadURL in
            if let downloadURL = downloadURL {
                print("Image uploaded and available at: \(downloadURL)")
            } else {
                print("Image upload failed")
            }
        }
    }
    
    /*
    @objc func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
     */
    
    //MARK: Storage
    /*
     this was for firebase cloud firestore, instead of just firebase storage
    func savePhotoData(imageURL: String) {
        var ref: DocumentReference? = nil
        ref = db.collection("photos").addDocument(data: [
            "url": imageUrl,
            "uploaded_by": Auth.auth().currentUser?.uid ?? "",
            "timestamp": Timestamp(date: Date())
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    */
    
    func saveImageToFirebase(image: UIImage, completion: @escaping (String?) -> Void) {
        //upload image (imagedata) to firebase
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let imagePath = Auth.auth().currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        let metadata = StorageMetadata()
        let storageRef = storage.reference(withPath: imagePath)
        storageRef.putData(imageData, metadata: metadata) { result in
            switch result {
            case .success:
                self.uploadSuccess(storageRef, storagePath: imagePath)
            case let .failure(error):
                print("Error uploading: \(error)")
            }
        }
    }
    
    func uploadSuccess(_ storageRef: StorageReference, storagePath: String) {
        print("Upload Succeeded!")
        storageRef.downloadURL { result in
            switch result {
            case .success:
                UserDefaults.standard.set(storagePath, forKey: "storagePath")
                UserDefaults.standard.synchronize()
            case let .failure(error):
                print("Error getting download URL: \(error)")
            }
        }
    }
    
    // MARK: Retrieval
    
    func retrieveImage(imageUrl: String, imageView: UIImageView) {
        let imageRef = Storage.storage().reference(forURL: imageUrl)
        imageRef.downloadURL { url, error in
            guard let downloadURL = url else {
                print("An error occurred while retrieving the download URL")
                return
            }
            imageView.sd_setImage(with: downloadURL, completed: nil) //using sdweb
        }
    }
}
