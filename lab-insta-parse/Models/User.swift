import Foundation
import ParseSwift

struct User: ParseUser {
    
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

   
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    
    var lastPostedDate: Date?
}


extension User {
    
    var hasPostedWithin24Hours: Bool {
        guard let lastPostedDate = lastPostedDate else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        let twentyFourHoursAgo = calendar.date(byAdding: .hour, value: -24, to: now)!
        
        return lastPostedDate > twentyFourHoursAgo
    }
}
