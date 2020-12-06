
/* in addition to the member-wise initializers, providing additional initializer using an Entity instance to create the following structs.
 
    Each struct instance can also create an entity instance as well with a ".convertToManagedObject()" method
 */
import Foundation
import SwiftUI
import CoreData

struct User: Codable, Identifiable, Hashable {
    public var id: UUID = UUID()
    let name: String
    let user_bio: String?
    let avatar: String?
    
    func convertToManagedObject(_ context: NSManagedObjectContext? = CoreDataStoreContainer.shared?.backgroundContext) -> UserEntity {
//        let userEntity = UserEntity(context: context!)
        
        // reconfigure to avoid mismatching when testing. Core Data gets confused when it thinks multiple NSEntityDescriptions claim NSManagedObject subclasses
        let userEntity = NSEntityDescription.insertNewObject(forEntityName: "UserEntity", into: context!) as! UserEntity
        userEntity.userID = self.id
        userEntity.name = self.name
        userEntity.bio = self.user_bio
        userEntity.avatar = self.avatar
//        userEntity.listened_to = NSSet()
        return userEntity
    }
}


extension User {
    init(userEntity: UserEntity) {
        self.id = userEntity.userID!
        self.name = userEntity.name ?? "Unknown"
        self.user_bio = userEntity.bio ?? "prefers to keep an air of mystery"
        self.avatar = userEntity.avatar ?? "northern-lights"
    }
}

struct Song: Codable, Identifiable, Hashable {
    
    public var id: UUID
    let name: String
    let artist: String?
    let genre: String?
    let image: String
    let songLength: Decimal?
    
    init(songId: UUID = UUID(), name: String, artist: String? = nil, genre: String? = nil, image: String = "northern_lights", songLength: Decimal?) {
        self.id = songId
        self.name = name
        self.artist = artist
        self.genre = genre
        self.image = image
        self.songLength = songLength
    }
    
    func convertToManagedObject(_ context: NSManagedObjectContext? = CoreDataStoreContainer.shared?.backgroundContext) -> SongEntity {
//        let songEntity = SongEntity(context: context!)
        let songEntity = NSEntityDescription.insertNewObject(forEntityName: "SongEntity", into: context!) as! SongEntity
        songEntity.song_id = self.id
        songEntity.song_name = self.name
        songEntity.artist_name = self.artist
        songEntity.genre = self.genre
        songEntity.song_image = self.image
        songEntity.song_length = self.songLength as NSDecimalNumber?
        return songEntity
    }
}

//
extension Song {
    init(songEntity: SongEntity) {
        self.id = songEntity.song_id!
        self.name = songEntity.song_name!
        self.artist = songEntity.artist_name ?? "Unknown"
        self.genre = songEntity.genre ?? "Unknown"
        self.image = songEntity.song_image ?? "northern-lights"
        self.songLength = songEntity.song_length?.decimalValue ?? 0.00
    }
}

struct SongInstance: Codable, Identifiable, Hashable {
    
    public var id: UUID = UUID()
    let songName: String  // need additional attribute so can use NSSortDescriptor--using the id leads to an Obj-C thread exception
    let dateListened: Date
    var instanceOf: Song
    var playedBy: User
    
    var likers = [User]()
    var commenters = [User]()
    var stashers = [User]()
    
    // add convo property
    // add stash relationship
    
//    var numLikes: Int {
//        return likers.count
//    }
    
    func convertToManagedObject(_ context: NSManagedObjectContext? = CoreDataStoreContainer.shared?.backgroundContext) -> SongInstanceEntity {
//        let instanceEntity = SongInstanceEntity(context: context!)
        let instanceEntity = NSEntityDescription.insertNewObject(forEntityName: "SongInstanceEntity", into: context!) as! SongInstanceEntity
        instanceEntity.instance_id = self.id
        instanceEntity.date_listened = self.dateListened
        instanceEntity.song_name = self.songName
        instanceEntity.instance_of = self.instanceOf.convertToManagedObject(context)
        instanceEntity.liked_by = NSSet()
        instanceEntity.commented_by = NSSet()
        instanceEntity.stashed_by = NSSet()
        instanceEntity.played_by = self.playedBy.convertToManagedObject(context)
        
        return instanceEntity
    }
}



extension SongInstance {
    init(instanceEntity: SongInstanceEntity) {
        self.id = instanceEntity.instance_id!
        self.songName = instanceEntity.song_name!
        self.dateListened = instanceEntity.date_listened!
        self.instanceOf = Song(songEntity: instanceEntity.instance_of!)
        self.playedBy = User(userEntity: instanceEntity.played_by!)
        self.likers = self.getPeopleLikes(instanceEntity: instanceEntity)
        self.commenters = self.getCommenters(instanceEntity: instanceEntity)
        self.stashers = self.getStashers(instanceEntity: instanceEntity)
    }
    
    func getPeopleLikes(instanceEntity: SongInstanceEntity) -> [User] {
        // for each SongInstanceEntity, get all the people who liked the song
        var likers = [User]()
        if instanceEntity.liked_by?.allObjects as? [UserEntity] == nil {
            return likers
        }
        for liker in instanceEntity.liked_by!.allObjects as! [UserEntity]{
            let user = User(userEntity: liker)
            likers.append(user)
        }
        return likers
    }
    
    func getCommenters(instanceEntity: SongInstanceEntity) -> [User] {
        var commenters = [User]()
        if instanceEntity.commented_by?.allObjects as? [UserEntity] == nil {
            return commenters
        }
        for commenter in instanceEntity.commented_by!.allObjects as! [UserEntity] {
            let user = User(userEntity: commenter)
            commenters.append(user)
        }
        return commenters
    }
    
    func getStashers(instanceEntity: SongInstanceEntity) -> [User] {
        var stashers = [User]()
        if instanceEntity.stashed_by?.allObjects as? [UserEntity] == nil {
            return stashers
        }
        for stasher in instanceEntity.stashed_by!.allObjects as! [UserEntity] {
            let user = User(userEntity: stasher)
            stashers.append(user)
        }
        return stashers
    }
}


