import Foundation
import ParseSwift
import UIKit

struct Post: ParseObject {
  
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    
    var caption: String?
    var user: User?
    var imageFile: ParseFile?
}


extension Post: Codable {
    enum CodingKeys: String, CodingKey {
        case objectId
        case createdAt
        case updatedAt
        case ACL
        case originalData
        case caption
        case user
        case imageFile
    }
}


extension Post {
    
    func updateUserLastPostedDate() {
        guard var currentUser = User.current else { return }
        currentUser.lastPostedDate = Date()
        
        do {
            try currentUser.save { result in
                switch result {
                case .success(let user):
                    print("✅ User's lastPostedDate updated: \(String(describing: user.lastPostedDate))")
                case .failure(let error):
                    print("❌ Error updating user's lastPostedDate: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Error saving user: \(error.localizedDescription)")
        }
    }
    
    
    func fetchComments(completion: @escaping ([Comment]) -> Void) {
        guard let postId = objectId else {
            completion([])
            return
        }
        
        do {
            let query = try Comment.query("post" == self)
                .include("user")
                .order([.ascending("createdAt")])
            
            query.find { result in
                switch result {
                case .success(let comments):
                    completion(comments)
                case .failure(let error):
                    print("Error fetching comments: \(error)")
                    completion([])
                }
            }
        } catch {
            print("Error creating query: \(error)")
            completion([])
        }
    }
}


extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.objectId == rhs.objectId
    }
}


extension Post {
    
    static func create(with image: UIImage, caption: String?, completion: @escaping (Result<Post, ParseError>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ParseError(code: .unknownError, message: "Failed to process image")))
            return
        }
        
        guard let user = User.current else {
            completion(.failure(ParseError(code: .unknownError, message: "User not logged in")))
            return
        }
        
        let imageFile = ParseFile(name: "post_image.jpg", data: imageData)
        
        var post = Post()
        post.imageFile = imageFile
        post.caption = caption
        post.user = user
        
        do {
            try post.save { result in
                switch result {
                case .success(let savedPost):
                    savedPost.updateUserLastPostedDate()
                    completion(.success(savedPost))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
        }
    }
    
   
    var formattedDate: String {
        guard let date = createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
   
    var username: String {
        return user?.username ?? "Unknown User"
    }
}

// MARK: - Query Extensions
extension Post {
   
    static func fetchAllPosts(completion: @escaping (Result<[Post], ParseError>) -> Void) {
        do {
            let query = try Post.query()
                .include("user")
                .order([.descending("createdAt")])
                .limit(50)
            
            query.find { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        } catch {
            completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
        }
    }
    
    
    static func fetchUserPosts(for user: User, completion: @escaping (Result<[Post], ParseError>) -> Void) {
        do {
            let query = try Post.query("user" == user)
                .include("user")
                .order([.descending("createdAt")])
            
            query.find { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        } catch {
            completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
        }
    }
}
