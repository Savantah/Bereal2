import UIKit
import Alamofire
import AlamofireImage
import ParseSwift

class PostCell: UITableViewCell {
    
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    
    private let headerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    private let profileStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
  
    private lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        
        
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: "bubble.left.fill", withConfiguration: config)
        
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.baseBackgroundColor = UIColor(white: 0.2, alpha: 1.0)
        buttonConfig.baseForegroundColor = .white
        buttonConfig.image = image
        buttonConfig.title = "Comment"
        buttonConfig.imagePadding = 8
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        buttonConfig.cornerStyle = .capsule
        
        button.configuration = buttonConfig
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onCommentButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    private var imageDataRequest: DataRequest?
    var post: Post?
    var commentButtonTapped: ((Post) -> Void)?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        
        contentView.addSubview(headerContainerView)
        headerContainerView.addSubview(profileStackView)
        contentView.addSubview(postImageView)
        contentView.addSubview(commentButton)
        contentView.addSubview(captionLabel)
        
       
        configureUI()
        
       
        setupConstraints()
    }
    
    private func configureUI() {
       
        contentView.backgroundColor = .black
        backgroundColor = .black
        selectionStyle = .none
        
       
        usernameLabel.font = .boldSystemFont(ofSize: 18)
        usernameLabel.textColor = .white
        
       
        dateLabel.font = .systemFont(ofSize: 14)
        dateLabel.textColor = .lightGray
        
        
        captionLabel.font = .systemFont(ofSize: 16)
        captionLabel.textColor = .white
        captionLabel.numberOfLines = 0
        
        
        postImageView.contentMode = .scaleAspectFill
        postImageView.backgroundColor = .black
        postImageView.clipsToBounds = true
        
        
        profileStackView.addArrangedSubview(usernameLabel)
        profileStackView.addArrangedSubview(dateLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            headerContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
           
            profileStackView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            profileStackView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            profileStackView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            
            
            postImageView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: 12),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor), // Make it square
            
            
            commentButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            commentButton.bottomAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: -16),
            commentButton.heightAnchor.constraint(equalToConstant: 44),
            commentButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 140),
            
            
            captionLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 16),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            captionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetContent()
    }
    
    private func resetContent() {
        postImageView.image = nil
        imageDataRequest?.cancel()
        usernameLabel.text = nil
        captionLabel.text = nil
        dateLabel.text = nil
    }
    
    func configure(with post: Post) {
        self.post = post
        
      
        usernameLabel.text = post.user?.username
        
       
        if let caption = post.caption, !caption.isEmpty {
            captionLabel.text = caption
            captionLabel.isHidden = false
        } else {
            captionLabel.isHidden = true
        }
        
        // Format and set date
        if let date = post.createdAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            dateLabel.text = formatter.string(from: date)
        }
        
        
        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {
            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                switch response.result {
                case .success(let image):
                    DispatchQueue.main.async {
                        UIView.transition(with: self?.postImageView ?? UIImageView(),
                                        duration: 0.3,
                                        options: .transitionCrossDissolve) {
                            self?.postImageView.image = image
                        }
                    }
                case .failure(let error):
                    print("❌ Error loading image: \(error)")
                }
            }
        }
        
        
        if let currentUser = User.current {
            blurView.isHidden = post.user?.objectId == currentUser.objectId || currentUser.hasPostedWithin24Hours
        } else {
            blurView.isHidden = false
        }
    }
    
   
    @objc private func onCommentButtonTapped() {
        if let post = post {
            commentButtonTapped?(post)
        }
    }
}
