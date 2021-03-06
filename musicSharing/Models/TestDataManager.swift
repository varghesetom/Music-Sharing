//
//  CoreTestDataManager.swift
//  musicSharing
//
//  Created by Varghese Thomas on 26/11/2020.
//  Copyright © 2020 Varghese Thomas. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import CoreData


class TestDataManager {
    /*
      Class is responsible only for injecting test data into Core Data.
     */
    let memoryType: StorageType
    let context: NSManagedObjectContext?
    
    init(_ memoryType: StorageType = .persistent, backgroundContext: NSManagedObjectContext? = CoreDataStoreContainer.shared?.backgroundContext) {
        self.memoryType = memoryType
        self.context = backgroundContext
    }
    
    public func addUserEntity(user: User) -> UserEntity? {
        let userEnt = user.convertToManagedObject(self.context!)
        self.context!.perform {
            do {
                try self.context!.save()
            } catch {
                print("couldn't save user entity")
            }
        }
        return userEnt
    }
    public func addSongInstanceEntity(songInstance: SongInstance) -> SongInstanceEntity? {
        let songInstEnt = songInstance.convertToManagedObject(self.context!)
        self.context!.perform {
            do {
                try self.context!.save()
            } catch {
                print("couldn't save song instance entity")
            }
        }
        return songInstEnt
    }
    
    func addSongEntity(song: Song) -> SongEntity? {
        let songEnt = song.convertToManagedObject(self.context!)
        self.context!.perform {
            do {
                try self.context!.save()
            } catch {
                print("couldn't save song entity")
            }
        }
        return songEnt
    }
    
    func addCommentEntity(commentType: CommentType, songInstEnt: SongInstanceEntity, userEnt: UserEntity) {
        let comment = Comment(user: User(userEntity: userEnt), comment: commentType, timeCommented: Date(), forSongInst: SongInstance(instanceEntity: songInstEnt))
        let commentEnt = comment.convertToManagedObject(self.context)
        self.userCommentsOnSong(user: userEnt, comment: commentEnt)
        self.commentForSongInst(songInstEnt: songInstEnt, comment: commentEnt)
        self.context!.perform {
            do {
                try self.context?.save()
            } catch {
                print("couldn't save comment entity")
            }
        }
    }
    
    // MARK: COREDATA RETRIEVAL
    
    func getLikesForSongInstID(songInstID: UUID) -> Int {
        let request: NSFetchRequest<SongInstanceEntity> = SongInstanceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "instance_id == %@", songInstID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "song_name", ascending: true)]
        do {
            let songInstEnt = try self.context!.fetch(request).first!
            var numLikes = 0
            if songInstEnt.liked_by?.allObjects as? [UserEntity] == nil {
                return numLikes
            }
            numLikes = (songInstEnt.liked_by!.allObjects as! [UserEntity]).count
            return numLikes
        } catch {
            print("Couldn't load song instances for getting likes")
            return 0
        }
    }

    func getCommentsForSongInstID(songInstID: UUID) -> [Comment]? {
        let request: NSFetchRequest<CommentEntity> = CommentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "comment_for.instance_id == %@", songInstID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "time_commented", ascending: true)]
        do {
            let commentEnts = try self.context!.fetch(request)
            if commentEnts.count == 0 { return [Comment]() }
            let comments = commentEnts.map{
                Comment(commentEntity: $0)
            }
            return comments
            
        } catch {
            print("Couldn't load all comments for song instance entity")
            return nil
        }
    }
    
    func getGenreEntity(genre: Genre) -> GenreEntity? {
        let request: NSFetchRequest<GenreEntity> = GenreEntity.fetchRequest()
        request.predicate = NSPredicate(format: "genre_name == %@", genre.genre)
        request.sortDescriptors = [NSSortDescriptor(key: "genre_name", ascending: true)]
        do {
            let genreEntity = try self.context!.fetch(request).first
            return genreEntity
        } catch {
            print("Couldn't get matching genre entity for genre")
            return nil
        }
    }
    
    func getSongInstanceEntity(songInst: SongInstance) ->SongInstanceEntity? {
        let request: NSFetchRequest<SongInstanceEntity> = SongInstanceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "instance_id == %@", songInst.id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "song_name", ascending: true)]
        do {
            let songInstEnt = try self.context!.fetch(request).first
            return songInstEnt
        } catch {
            print("Couldn't get song instance entity for song inst")
            return nil
        }
    }
    
    func getAllGenreForUser(id: UUID, genreName: String) -> [Genre] {
        let genreEnts = self.getGenresForUser(id: id)
        var toggledGenres = [Genre]()
        if let unwrappedEnts = genreEnts {
          toggledGenres = unwrappedEnts.map {
              Genre(genreEntity: $0)
          }
        }
        return toggledGenres
    }
    
    func getGenresForUser(id: UUID) -> [GenreEntity]? {
        // get user's toggled genres
        let request: NSFetchRequest<GenreEntity> = GenreEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ANY toggled_by.userID = %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "genre_name", ascending: true)]
        do {
            let genreEntities = try self.context?.fetch(request)
            return genreEntities
        } catch {
            print("Couldn't return user's genres")
            return nil
        }
    }
    
    func isUserFriendsWithMainUser(id: UUID) -> Bool {
        let personsFriends = self.getUsersFriends(id.uuidString)
        guard personsFriends != nil else {
            print("person has no friends")
            return false
        }
        if personsFriends!.count == 0 {
            print("person has no friends")
            return false
        }

        for per in personsFriends! {
            print(User(userEntity: per).name)
        }
        let main = User(userEntity: self.fetchMainUser()!)
        return (personsFriends!.filter { $0.userID == main.id}).count == 1 ? true : false
    }
    
    func getUsersFriends(_ id: String = MainUser.idMainUser) -> [UserEntity]? {
        // get main user's friends
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ANY is_friends_with.userID = %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            let userEntities = try self.context?.fetch(request)
            return userEntities
        } catch {
            print("Couldn't return main user's friends")
            return nil
        }
    }
    
    func fetchMainUser() -> UserEntity? {
        let mainUserRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        mainUserRequest.predicate = NSPredicate(format: "%K == %@", "userID", MainUser.idMainUser as CVarArg)
        do {
            let mainUser = try self.context!.fetch(mainUserRequest).first!
            return mainUser
        } catch {
            print("Could not initialize main user \(error.localizedDescription)")
        }
        return nil
    }
    
    func getAllUsers() -> [User]? {
        // used for the Search Bar functionality
        let userEntReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        var users = [User]()
        var seen = Set<UUID>()
        do {
            let userEnts = try self.context!.fetch(userEntReq)
            if (userEnts.count > 0) {
                for userEnt in userEnts {
                    if userEnt.name != nil && !seen.contains(userEnt.userID!) {
                        seen.insert(userEnt.userID!)
                        users.append(User(userEntity: userEnt))
                    }
                }
                return users
            }
         } catch {
             return nil
         }
         return nil
     }
    
    func getSong(_ name: String) -> SongEntity? {
        let songRequest: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
        songRequest.predicate = NSPredicate(format: "song_name == %@", name)
        do {
            let song = try self.context!.fetch(songRequest).first
            print("For context \(self.context!) -- Fetched song: \(String(describing: song))")
            return song
        } catch {
            print("Song fetch failed")
            return nil
        }
    }
    
    func checkIfSongExists(_ songName: String) -> Bool {
        let request: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
        let regularMatchPredicate = NSPredicate(format: "song_name = %@", songName)
        let lowerCaseMatchPredicate = NSPredicate(format: "song_name = %@", songName.lowercased())
        let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [regularMatchPredicate, lowerCaseMatchPredicate])
        request.predicate = orPredicate
        do {
            let match = try  self.context!.fetch(request).first
            guard match != nil else {
                print("Song does not exist")
                return false
            }
            return true
        } catch {
            print("Couldn't perform songName predicate match request.")
            return false
        }
    }
    
    func getUser(_ id: String) -> UserEntity? {
        let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        userFetchRequest.predicate = NSPredicate(format: "userID == %@", id as CVarArg)
        do {
            let user = try self.context!.fetch(userFetchRequest).first
            return user
        } catch {
            print("User fetch failed")
            return nil
        }
    }
    
    func getStashFromUser(_ id: String = MainUser.idMainUser)->[SongInstanceEntity]? {
        // get main user's songs from their STASH
        let request: NSFetchRequest<SongInstanceEntity> = SongInstanceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ANY stashed_by.userID = %@", id as CVarArg) // comparing a collection of results(?) to a scalar value so need ANY
        request.sortDescriptors = [NSSortDescriptor(key: "song_name", ascending: true)]
        do {
            let stashSongs = try self.context?.fetch(request)
            return stashSongs
        } catch {
            print("Couldn't return stashed songs for Main User")
            return nil
        }
    }
    
    func getReceivedFollowRequestsForUser(_ id: String = MainUser.idMainUser) -> [UserEntity]? {
        // get people who requested to follow main user
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
               request.predicate = NSPredicate(format: "ANY received_follow_request.userID = %@", id as CVarArg)
               request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            let userEntities = try self.context?.fetch(request)
            
            return userEntities
        } catch {
            print("Couldn't return main user's follower requests")
            return nil
        }
    }
    
    func getFollowRequestsSentByUser(_ id: String = MainUser.idMainUser) -> [UserEntity]? {
        // get follow requests sent by main users
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ANY sent_follow_request.userID = %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            let userEntities = try self.context?.fetch(request)
            return userEntities
        } catch {
            print("Could not get requests sent BY main user")
            return nil
        }
    }
    
    func getRecentlyListenedSongFromUser(_ id: String = MainUser.idMainUser) -> [SongInstanceEntity]? {
        let request: NSFetchRequest<SongInstanceEntity> = SongInstanceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "played_by.userID = %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date_listened", ascending: false)]
        do {
            let songInstEnt = try self.context?.fetch(request)
            return songInstEnt
        } catch {
            print("Couldn't get the most recently listened to song for Main User")
            return nil
        }
    }
    
    func getSongInstancesFromUser(_ user: UserEntity) -> [SongInstance]? {
        if let songs:[SongInstanceEntity] = user.listened_to?.allObjects as? [SongInstanceEntity] {
            songs.forEach({ print("User 1 listens to -> \($0.instance_of!.song_name ?? "Unknown") by \($0.instance_of!.artist_name ?? "")")})
            let instances = songs.map({ si in
                SongInstance(instanceEntity: si)}
            )
            return instances
        }
        print("No song listens for user")
        return nil
    }
    
    
    
    // MARK: SAVE TEST DATA
    
    lazy var testData = JSONTestData()
    
    func saveFakeData() {
        print("SAVING FAKE DATA")
        _ = self.loadUsersFromJSON()
        _ = self.loadSongsFromJSON()
        _ = self.loadSongInstancesFromJSON()
        _ = self.assignAllInitialRelationships()
    }
    
    func loadUsersFromJSON() -> Bool {
        guard let users = testData.users else {
            print("Could not load users data")
            return false
        }
        users.forEach({ user in _ =
            user.convertToManagedObject(self.context!)
        })
        do {
            try self.context?.save()
            return true
        } catch {
            print("Error saving users to CoreData store \(error.localizedDescription)")
            return false
        }
    }

    func loadSongsFromJSON() -> Bool{
        guard let songs = testData.songs else {
            print("Could not load songs data")
            return false
        }
         songs.forEach({ song in _ =
            song.convertToManagedObject(self.context!)
         })
         do {
            try self.context?.save()
            return true
         } catch {
             print("Error saving songs to CoreData store \(error.localizedDescription)")
            return false
         }
    }
    
    func loadSongInstancesFromJSON() -> Bool{
        guard let songInstances = testData.songInstances else {
            print("Could not load song instances data")
            return false
        }
         songInstances.forEach({ songInstance in _ =
            songInstance.convertToManagedObject(self.context!)
         })
         do {
            try self.context?.save()
            return true
         } catch {
             print("Error saving song instances to CoreData store \(error.localizedDescription)")
            return false
         }
    }
    
    func loadCommentsFromJSON() -> Bool {
        guard let comments = testData.comments else {
            print("Could not load song instances data")
            return false
        }
         comments.forEach({ comment in _ =
            comment.convertToManagedObject(self.context!)
         })
         do {
            try self.context?.save()
            return true
         } catch {
             print("Error saving comments to CoreData store \(error.localizedDescription)")
            return false
         }
    }
    
    // MARK: ASSIGN INITIAL RELATIONSHIPS
    
    func assignAllInitialRelationships() -> Bool {
        _ = self.assignInitialFriendships()
        _ = self.assignInitialFollowRequestsSentByMainUser()
        _ = self.assignInitialFollowRequestsSentToMainUser()
        _ = self.assignInitialComments()
        print("assigned all relationships")
        // need to assign stash relationships
        return true
    }
    
    func assignInitialComments() -> Bool {
        let bobAdagioRequest: NSFetchRequest<SongInstanceEntity> = SongInstanceEntity.fetchRequest()
        bobAdagioRequest.predicate = NSPredicate(format: "instance_id == %@", "d362db4f-a6ac-46c9-809b-a6137f43c4da" as CVarArg)
        let sarahFriendRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        sarahFriendRequest.predicate = NSPredicate(format: "name == %@", "Sarah Connor")
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            let sarah = try self.context!.fetch(sarahFriendRequest).first!
            let bobAdagio = try self.context!.fetch(bobAdagioRequest).first!
            let sarahCommentDate = dateFormatter.date(from: "2020-12-01T10:01")!
            let sarahComment = Comment(user: User(userEntity: sarah), comment: CommentType.great, timeCommented: sarahCommentDate, forSongInst: SongInstance(instanceEntity: bobAdagio))
            let sarahCommentEntity = sarahComment.convertToManagedObject(self.context)
            self.userCommentsOnSong(user: sarah, comment: sarahCommentEntity)
            self.commentForSongInst(songInstEnt: bobAdagio, comment: sarahCommentEntity)
            try self.context?.save()
            return true
        } catch {
            print("Couldn't assign initial comments")
        }
        return false
    }
    
    func assignInitialFriendships() -> Bool{
        let sarahFriendRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        sarahFriendRequest.predicate = NSPredicate(format: "name == %@", "Sarah Connor")
        let bobFriendRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        bobFriendRequest.predicate = NSPredicate(format: "name == %@", "Bob LobLaw")
        let peterFriendRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        peterFriendRequest.predicate = NSPredicate(format: "name == %@", "Peter Parker")
        do {
            let sarah = try self.context!.fetch(sarahFriendRequest).first!
            let bob = try self.context!.fetch(bobFriendRequest).first!
            let peter = try self.context!.fetch(peterFriendRequest).first!
            self.userIsFriends(user: self.fetchMainUser()!, friend: sarah) // I'm friends with Sarah
            self.userIsFriends(user: self.fetchMainUser()!, friend: bob)   // I'm friends with Bob
            self.userIsFriends(user: bob, friend: sarah)                   // Bob is friends with Sarah
            self.userIsFriends(user: peter, friend: sarah)                 // Peter is friends with Sarah
            try self.context?.save()
            return true
        } catch {
            print("Could no assign friendship between test users and main user \(error.localizedDescription)")
            return false
        }
    }
    
    func assignInitialFollowRequestsSentByMainUser() -> Bool{
        let peterRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        peterRequest.predicate = NSPredicate(format: "name == %@", "Peter Parker")
        do {
            let peter = try self.context!.fetch(peterRequest).first!
            self.userSentFollowRequest(to: peter, from: self.fetchMainUser()!)
            try self.context?.save()
            return true
        } catch {
            print("Could not assign follow requests sent by test users to main user \(error.localizedDescription)")
            return false
        }
    }
    
    func assignInitialFollowRequestsSentToMainUser() -> Bool {
        let cousinVinnyRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        cousinVinnyRequest.predicate = NSPredicate(format: "name == %@", "Vinny Gambini")
        do {
            let myCousinVinny = try self.context!.fetch(cousinVinnyRequest).first!
            self.userSentFollowRequest(to: self.fetchMainUser()!, from: myCousinVinny)
            try self.context?.save()
            return true
        } catch {
            print("Could not assign follow requests sent to test users by main user \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: DELETE METHODS
    
    func emptyDB() -> Bool {
        print("EMPTYING DB")
        _ = self.deleteAllSongs()
        _ = self.deleteAllUsers()
        _ = self.deleteAllSongInstances()
        print("Deleted all data")
        return true
    }
    
    func deleteAllSongs() -> Bool {
        let songFetchRequest: NSFetchRequest<NSFetchRequestResult> = SongEntity.fetchRequest()
        let deleteAllSongsRequest = NSBatchDeleteRequest(fetchRequest: songFetchRequest)
        do {
            try self.context!.execute(deleteAllSongsRequest)
            return true
        } catch {
            print("Error deleting Songs: \(error.localizedDescription)")
            return false
        }
    }
    
    func deleteAllUsers() -> Bool {
        let userFetchRequest: NSFetchRequest<NSFetchRequestResult> = UserEntity.fetchRequest()
        let deleteAllUsersRequest = NSBatchDeleteRequest(fetchRequest: userFetchRequest)
        do {
            try self.context!.execute(deleteAllUsersRequest)
            return true
        } catch {
            print("Error deleting Users: \(error.localizedDescription)")
            return false
        }
    }
    
 
    
    func deleteAllSongInstances() -> Bool {
        let songInstFetchRequest: NSFetchRequest<NSFetchRequestResult> = SongInstanceEntity.fetchRequest()
        let deleteAllSongInstRequest = NSBatchDeleteRequest(fetchRequest: songInstFetchRequest)
        do {
            try self.context!.execute(deleteAllSongInstRequest)
            return true
        } catch {
            print("Error deleting Song Instances: \(error.localizedDescription)")
            return false
        }
    }
    
    func deleteSongInstance(songInstID: UUID) -> Bool {
        let request: NSFetchRequest<SongInstanceEntity> = SongInstanceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "instance_id == %@", songInstID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "song_name", ascending: true)]
        do {
            let songInsts = try self.context!.fetch(request)
            songInsts.forEach { self.context!.delete($0) }
            do {
                try self.context!.save()   // persist the deletion to the data store
            } catch {
                print("Cannot save deletion of song instance")
                return false
            }
            return true
        } catch {
            print("Error deleting specific song instance \(songInstID). Error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: RELATIONSHIP HELPERS
    
     func userCommentsOnSong(user: UserEntity, comment: CommentEntity) {
         user.addToCommented_on(comment)
         do {
             try self.context!.save()
         } catch {
             print("Error adding commented song relationship for user")
         }
     }
    
    func commentForSongInst(songInstEnt: SongInstanceEntity, comment: CommentEntity) {
        songInstEnt.addToHas_comments(comment)
        do {
            try self.context!.save()
        } catch {
            print("Error adding commented song relationship for user")
        }
    }
    
    func userToggleGenre(user: UserEntity, genreEntity: GenreEntity) {
        user.addToToggled_genre(genreEntity)
        do {
            try self.context!.save()
        } catch {
            print("Error assigning genre to user")
        }
    }
    
    func userStashesSong(user: UserEntity, songInstEnt: SongInstanceEntity) {
         user.addToStashes_this(songInstEnt)
         do {
             try self.context!.save()
         } catch {
             print("Error adding stashed song relationship for user")
         }
     }
    
    func userRemovesStashedSong(userEnt: UserEntity, songInstEnt: SongInstanceEntity) {
        userEnt.removeFromStashes_this(songInstEnt)
        do {
            try self.context!.save()
            print("removed!")
        } catch {
            print("Error removing stashed song for user")
        }
    }
     
     func userListenedToSong(user: UserEntity, songInstance: SongInstanceEntity) {
         user.addToListened_to(songInstance)
         do {
             try self.context!.save()
         } catch {
             print("Error adding listened song relationship for user")
         }
     }
     
     func userLikesSong(user: UserEntity, songInstance: SongInstanceEntity) {
         user.addToLikes_this(songInstance)
         do {
             try self.context!.save()
         } catch {
             print("Error adding liked song relationship for user")
         }
     }
    
     func userIsFriends(user: UserEntity, friend: UserEntity) {
         user.addToIs_friends_with(friend)
         do {
             try self.context!.save()
         } catch {
             print("Error adding friendship for user")
         }
     }
     
     func userSentFollowRequest(to: UserEntity, from: UserEntity) {
         to.addToSent_follow_request(from)
         do {
             try self.context!.save()
         } catch {
             print("Error adding follow sent request for user")
         }
     }
     
     /* Deleting Database relationships */
     
     func userUnlikesSong(user: UserEntity, songInstance: SongInstanceEntity) {
         user.removeFromLikes_this(songInstance)
         do {
             try self.context!.save()
         } catch {
             print("Error removing liked song relationship for user")
         }
     }

     func userUncommentsSong(user: UserEntity, commentEnt: CommentEntity) {
            user.removeFromCommented_on(commentEnt)
         do {
             try self.context!.save()
         } catch {
             print("Error removing comment relationship for user")
         }
    }
     
     func userUnstashesSong(user: UserEntity, songInstance: SongInstanceEntity) {
         user.removeFromStashes_this(songInstance)
         do {
             try self.context!.save()
         } catch {
             print("Error removing stashed song relationship for user")
         }
     }
    
    func userRemovesFollowRequst(to: UserEntity, from: UserEntity) {
        to.removeFromSent_follow_request(from)
        do {
            try self.context!.save()
        } catch {
            print("Error removing friend request")
        }
    }
    
    func userUntogglesGenre(user: UserEntity, genreEntity: GenreEntity) {
        user.removeFromToggled_genre(genreEntity)
        do {
            try self.context!.save()
        } catch {
            print("Error unassigning genre to user")
        }
    }
}

// MARK: JSON DATA STRUCT

struct JSONTestData {
    var users: [User]?
    var songs: [Song]?
    var songInstances: [SongInstance]?
    var genres: [Genre]?
    var comments: [Comment]?
    
    init() {
        guard let usersPath = Bundle.main.path(forResource: "users", ofType: "json") else {
            print("Yo! no users Path!")
            return
        }
        do {
            if let jsonData = try String(contentsOfFile: usersPath).data(using: .utf8) {
                let decoder = JSONDecoder()
                users = try decoder.decode([User].self, from: jsonData)
                print("USERS -> \(users ?? [User]())")
            }
        } catch {
               print("Error occurred for users decoding process \(error.localizedDescription)")
        }
        
        guard let songsPath = Bundle.main.path(forResource: "songs", ofType: "json") else {
            print("Yo! no songs Path!")
            return
        }
        do {
            if let jsonData = try String(contentsOfFile: songsPath).data(using: .utf8) {
                let decoder = JSONDecoder()
                songs = try decoder.decode([Song].self, from: jsonData)
            }
        } catch {
          print("Error occurred for song decoding process \(error.localizedDescription)")
       }
                    
        guard let songInstancesPath = Bundle.main.path(forResource: "song_instances", ofType: "json") else {
                print("Yo! no songInstances Path!")
                return
        }
        do {
            if let jsonData = try String(contentsOfFile: songInstancesPath).data(using: .utf8) {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            songInstances = try decoder.decode([SongInstance].self, from: jsonData)
            }
            print("SONG INSTANCES\(String(describing: songInstances))")
        } catch {
            print("Error occurred for song instances decoding process \(error.localizedDescription)")
        }
        
         guard let genresPath = Bundle.main.path(forResource: "genres", ofType: "json") else {
             print("Yo! no genres Path!")
             return
         }
         do {
             if let jsonData = try String(contentsOfFile: genresPath).data(using: .utf8) {
                let decoder = JSONDecoder()
                genres = try decoder.decode([Genre].self, from: jsonData)
                print("GENRES -> \(genres ?? [Genre]())")
             }
         } catch {
           print("Error occurred for genre decoding process \(error.localizedDescription)")
        }
    }
}
