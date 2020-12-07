//
//  CoreTestDataManager.swift
//  musicSharing
//
//  Created by Varghese Thomas on 26/11/2020.
//  Copyright © 2020 Varghese Thomas. All rights reserved.
//

import Foundation
import UIKit
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
    
    // COREDATA RETRIEVAL
    
    func isUserFriendsWithMainUser(id: UUID) -> Bool {
        let personsFriends = self.getUsersFriends(id.uuidString)
        guard personsFriends != nil else {
            print("person has no friends")
            return false
        }
        return (personsFriends?.filter { $0.userID == self.fetchMainUser()!.userID} != nil) ? true : false
    }
    
//    func getUsersFriends(_ id: String = MainUser.idMainUser) -> [UserEntity]? {
//        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
//        request.predicate = NSPredicate(format: "ANY is_friends_with.userID = %@", id as CVarArg)
//        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
//        do {
//            let userEntities = try self.context?.fetch(request)
//            return userEntities
//        } catch {
//            print("Couldn't return main user's friends")
//            return nil
//        }
//    }
    
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
    
    func fetchMainUser() -> UserEntity? {
        let mainUserRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        mainUserRequest.predicate = NSPredicate(format: "%K == %@", "userID", MainUser.idMainUser as CVarArg)
        do {
            print("CONTEXT: \(self.context!)")
            let mainUser = try self.context!.fetch(mainUserRequest).first!
            return mainUser
        } catch {
            print("Could not initialize main user \(error.localizedDescription)")
        }
        return nil
    }
    
    // get main user's songs from their STASH
    
    func getStashFromUser(_ id: String = MainUser.idMainUser)->[SongInstanceEntity]? {
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
    
    // get main user's friends
    
    func getUsersFriends(_ id: String = MainUser.idMainUser) -> [UserEntity]? {
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
    
    // get people who requested to follow main user
    
    func getReceivedFollowRequestsForUser(_ id: String = MainUser.idMainUser) -> [UserEntity]? {
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
    
    // get follow requests sent by main users
    
    func getFollowRequestsSentByUser(_ id: String = MainUser.idMainUser) -> [UserEntity]? {
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
            let instances = songs.map({
                SongInstance(instanceEntity: $0)}
            )
            return instances
        }
        print("No song listens for user")
        return nil
    }
    
            // SAVE TEST DATA
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
    
    // INITIAL RELATIONSHIPS
    func assignAllInitialRelationships() -> Bool {
        _ = self.assignInitialFollowRequestsForMainUser()
        _ = self.assignMainUsersSentFollowRequests()
        _ = self.assignInitialFriendshipsToUser()
        // need to assign stash relationships
        return true
    }
    
    func assignInitialFriendshipsToUser() -> Bool{
        let sarahFriendRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        sarahFriendRequest.predicate = NSPredicate(format: "name == %@", "Sarah Connor")
        let bobFriendRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        bobFriendRequest.predicate = NSPredicate(format: "name == %@", "Bob LobLaw")
        do {
            let sarah = try self.context!.fetch(sarahFriendRequest).first!
            self.userIsFriends(user: self.fetchMainUser()!, friend: sarah)
            let bob = try self.context!.fetch(bobFriendRequest).first!
            self.userIsFriends(user: self.fetchMainUser()!, friend: bob)
            try self.context?.save()
            return true
        } catch {
            print("Could no assign friendship between test users and main user \(error.localizedDescription)")
            return false
        }
    }
    
    func assignInitialFollowRequestsForMainUser() -> Bool{
        let sarahFriendRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        sarahFriendRequest.predicate = NSPredicate(format: "name == %@", "Sarah Connor")
        let peterRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        peterRequest.predicate = NSPredicate(format: "name == %@", "Peter Parker")
        do {
            let peter = try self.context!.fetch(peterRequest).first!
            self.userSentFollowRequest(from: peter, to: self.fetchMainUser()!)
            try self.context?.save()
            return true
        } catch {
            print("Could not assign follow requests sent by test users to main user \(error.localizedDescription)")
            return false
        }
    }
    
    func assignMainUsersSentFollowRequests() -> Bool {
        let sarahFriendRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        sarahFriendRequest.predicate = NSPredicate(format: "name == %@", "Sarah Connor")
        let cousinVinnyRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        cousinVinnyRequest.predicate = NSPredicate(format: "name == %@", "Vinny Gambini")
        do {
            let myCousinVinny = try self.context!.fetch(cousinVinnyRequest).first!
            self.userSentFollowRequest(from: self.fetchMainUser()!, to: myCousinVinny)
            try self.context?.save()
            return true
        } catch {
            print("Could not assign follow requests sent to test users by main user \(error.localizedDescription)")
            return false
        }
    }
    
    // CLEARING METHODS
    func emptyDB() -> Bool {
        print("EMPTYING DB")
        _ = self.deleteAllSongs()
        _ = self.deleteAllUsers()
        return true
    }
    
    func deleteAllSongs() -> Bool {
        let songFetchRequest: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
        do {
            let songs = try self.context?.fetch(songFetchRequest)
            songs?.forEach{ self.context?.delete($0)}
            return true
        } catch {
            print("Error deleting Songs: \(error.localizedDescription)")
            return false
        }
    }
    
    func deleteAllUsers() -> Bool {
        let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        do {
            let users = try self.context?.fetch(userFetchRequest)
            users?.forEach{ self.context?.delete($0)}
            return true
        } catch {
            print("Error deleting Users: \(error.localizedDescription)")
            return false
        }
    }
    
            // CORE DATA RELATIONSHIPS
    
    func userStashesSong(user: UserEntity, songInstance: SongInstanceEntity) {
         print("\n\nUSER BEFORE ADDING \(user)")
         user.addToStashes_this(songInstance)
         print("\n\nUSER AFTER ADDING \(user)")
         do {
             try self.context!.save()
         } catch {
             print("Error adding stashed song relationship for user")
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
     
     func userCommentsOnSong(user: UserEntity, songInstance: SongInstanceEntity) {
         user.addToCommented_on(songInstance)
         do {
             try self.context!.save()
         } catch {
             print("Error adding commented song relationship for user")
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
     
     func userSentFollowRequest(from: UserEntity, to: UserEntity) {
         from.addToSent_follow_request(to)
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

     func userUncommentsSong(user: UserEntity, songInstance: SongInstanceEntity) {
            user.removeFromCommented_on(songInstance)
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
}

struct JSONTestData {
    var users: [User]?
    var songs: [Song]?
    var songInstances: [SongInstance]?
    
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
    }
}