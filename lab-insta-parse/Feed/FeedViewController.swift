import UIKit
import ParseSwift

class FeedViewController: UIViewController {
    
 
    @IBOutlet weak var tableView: UITableView!
    
    
    private let noPostsView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let noPostsLabel: UILabel = {
        let label = UILabel()
        label.text = "Post a BeReal to see your friends' BeReal!"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Take Photo", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handlePostPhoto), for: .touchUpInside)
        return button
    }()
    
    
    private let refreshControl = UIRefreshControl()
    private var posts = [Post]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkUserPostStatus()
    }
    
    
    private func setupUI() {
       
        view.backgroundColor = .black
        
       
        view.addSubview(noPostsView)
        noPostsView.addSubview(noPostsLabel)
        noPostsView.addSubview(cameraButton)
        
       
        NSLayoutConstraint.activate([
            noPostsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            noPostsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noPostsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noPostsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            noPostsLabel.centerXAnchor.constraint(equalTo: noPostsView.centerXAnchor),
            noPostsLabel.centerYAnchor.constraint(equalTo: noPostsView.centerYAnchor, constant: -50),
            noPostsLabel.leadingAnchor.constraint(equalTo: noPostsView.leadingAnchor, constant: 40),
            noPostsLabel.trailingAnchor.constraint(equalTo: noPostsView.trailingAnchor, constant: -40),
            
            cameraButton.topAnchor.constraint(equalTo: noPostsLabel.bottomAnchor, constant: 30),
            cameraButton.centerXAnchor.constraint(equalTo: noPostsView.centerXAnchor),
            cameraButton.widthAnchor.constraint(equalToConstant: 200),
            cameraButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        
        navigationItem.title = "BeReal"
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 20)
            ]
            navigationBar.barStyle = .black
            navigationBar.tintColor = .white
        }
        
        // TableView Setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UIScreen.main.bounds.width + 100
        
        // Refresh Control Setup
        refreshControl.tintColor = .white
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
    }
    
    private func checkUserPostStatus() {
        guard let currentUser = User.current else { return }
        
        if currentUser.hasPostedWithin24Hours {
            noPostsView.isHidden = true
            tableView.isHidden = false
            queryPosts()
        } else {
            noPostsView.isHidden = false
            tableView.isHidden = true
            posts = []
        }
    }
    
    private func queryPosts() {
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .limit(50)
        
        query.find { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                switch result {
                case .success(let posts):
                    self?.posts = posts
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }
    
    
    @objc private func handlePostPhoto() {
        if let postVC = storyboard?.instantiateViewController(withIdentifier: "PostViewController") as? PostViewController {
            navigationController?.pushViewController(postVC, animated: true)
        }
    }
    
    @objc private func onPullToRefresh() {
        checkUserPostStatus()
    }
    
    @IBAction func onLogOutTapped(_ sender: Any) {
        let alertController = UIAlertController(
            title: "Log out of BeReal?",
            message: nil,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            User.logout { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
                    case .failure(let error):
                        self?.showAlert(description: error.localizedDescription)
                    }
                }
            }
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func showCommentAlert(for post: Post) {
        let alert = UIAlertController(
            title: "Add Comment",
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Write a comment..."
        }
        
        let postAction = UIAlertAction(title: "Post", style: .default) { [weak self, weak alert] _ in
            guard let commentText = alert?.textFields?.first?.text,
                  !commentText.isEmpty else { return }
            
            var comment = Comment()
            comment.text = commentText
            comment.user = User.current
           
            
            comment.save { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Refresh the specific cell
                        if let index = self?.posts.firstIndex(where: { $0.objectId == post.objectId }),
                           let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PostCell {
                            cell.configure(with: post)
                        }
                    case .failure(let error):
                        self?.showAlert(description: error.localizedDescription)
                    }
                }
            }
        }
        
        alert.addAction(postAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showAlert(description: String) {
        let alertController = UIAlertController(
            title: "Error",
            message: description,
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}


extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        
        let post = posts[indexPath.row]
        cell.configure(with: post)
        cell.commentButtonTapped = { [weak self] post in
            self?.showCommentAlert(for: post)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.width + 100
    }
}
