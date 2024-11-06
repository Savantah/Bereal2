import Foundation
import ParseSwift

struct Comment: ParseObject {
    
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    
    var text: String?
    var user: User?
    var post: Post?
}


extension Comment: Codable {
    enum CodingKeys: String, CodingKey {
        case objectId
        case createdAt
        case updatedAt
        case ACL
        case originalData
        case text
        case user
        case post
    }
}

extension Comment: Equatable {
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.objectId == rhs.objectId
    }
}
