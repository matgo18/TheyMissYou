import Foundation
import FirebaseFirestore

struct Group: Identifiable, Codable {
    let id: String
    let name: String
    let createdAt: Date
    let createdBy: String // User ID of creator
    var memberIds: [String]
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "createdAt": createdAt,
            "createdBy": createdBy,
            "memberIds": memberIds
        ]
    }
    
    init(id: String, name: String, createdBy: String, createdAt: Date = Date(), memberIds: [String] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.memberIds = memberIds
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let createdBy = dictionary["createdBy"] as? String,
              let createdAt = dictionary["createdAt"] as? Timestamp,
              let memberIds = dictionary["memberIds"] as? [String] else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = createdAt.dateValue()
        self.memberIds = memberIds
    }
} 