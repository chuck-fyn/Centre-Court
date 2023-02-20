//
//  PlayerOneScore.swift
//  MatchPoint
//
//  Created by Charles Prutting on 8/21/22.
//

import Foundation
import UIKit
import CoreData

class MatchBrain {
    
    private init() {}
    static let shared = MatchBrain()
    
    //match variables and player structs for scoring logic
    var set = 1
    var gameOver = false
    var isPaused = false
    var buttonsLocked = true
    
    var tieBreak = false
    var breakPoint = false
    var gamePoint = false
    var setPoint = false
    var matchPoint = false
    
    var playerOne = PlayerModel()
    var playerTwo = PlayerModel()
        
    //Core Data Variables
    var match: Match?
    var undoMatchArray = [Match]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let undoContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
    
    
    // MARK: -  Scoring Logic
    
    func playerOneScored() {
        //logic for adding point for player one based on game state
        if !tieBreak {
            if playerOne.points <= 2 {
                playerOne.points = playerOne.points + 1
            } else if playerOne.points == playerTwo.points {
                playerOne.points = playerOne.points + 1
            } else if playerOne.points == 3 && playerTwo.points == 4 {
                playerTwo.points = playerTwo.points - 1
            } else {
                if playerOne.games <= 4 {
                    playerOne.games = playerOne.games + 1
                    self.switchServer()
                    self.updatePlayerOneGames(currentSet: self.set)
                } else if playerOne.games == playerTwo.games {
                    playerOne.games = playerOne.games + 1
                    self.switchServer()
                    self.updatePlayerOneGames(currentSet: self.set)
                } else if playerOne.games < playerTwo.games {
                    playerOne.games = playerOne.games + 1
                    self.switchServer()
                    self.updatePlayerOneGames(currentSet: self.set)
                    tieBreak = true
                } else if abs(playerOne.games - playerTwo.games) >= 1 {
                    playerOne.sets = playerOne.sets + 1
                    playerOne.games = playerOne.games + 1
                    self.switchServer()
                    self.updatePlayerOneGames(currentSet: self.set)
                    set = set + 1
                    playerOne.games = 0
                    playerTwo.games = 0
                }
                playerOne.points = 0
                playerTwo.points = 0
            }
        } else if tieBreak {
            if playerOne.points <= 5 {
                playerOne.points = playerOne.points + 1
            } else if playerOne.points == playerTwo.points {
                playerOne.points = playerOne.points + 1
            } else if playerOne.points < playerTwo.points {
                playerOne.points = playerOne.points + 1
            } else if abs(playerOne.points - playerTwo.points) >= 1 {
                playerOne.points = playerOne.points + 1
                playerOne.games = playerOne.games + 1
                playerOne.sets = playerOne.sets + 1
                
                self.switchServer()
                self.updatePlayerOneGames(currentSet: self.set)
                appendTieBreakScore(currentSet: self.set)
                
                set = set + 1
                playerOne.games = 0
                playerTwo.games = 0
                playerOne.points = 0
                playerTwo.points = 0
                tieBreak = false
            }
            if tieBreak {
                if (playerOne.points + playerTwo.points) % 2 == 0 {
                } else {
                    self.switchServer()
                }
            }
        }
        convertTennisScores()
        checkForGameSetMatchPoint()
    }
    
    func playerTwoScored() {
        //logic for adding point for player two based on game state
        if !tieBreak {
            if playerTwo.points <= 2 {
                playerTwo.points = playerTwo.points + 1
            } else if playerTwo.points == playerOne.points {
                playerTwo.points = playerTwo.points + 1
            } else if playerTwo.points == 3 && playerOne.points == 4 {
                playerOne.points = playerOne.points - 1
            } else {
                if playerTwo.games <= 4 {
                    playerTwo.games = playerTwo.games + 1
                    self.switchServer()
                    self.updatePlayerTwoGames(currentSet: self.set)
                } else if playerTwo.games == playerOne.games {
                    playerTwo.games = playerTwo.games + 1
                    self.switchServer()
                    self.updatePlayerTwoGames(currentSet: self.set)
                } else if playerTwo.games < playerOne.games {
                    playerTwo.games = playerTwo.games + 1
                    self.switchServer()
                    self.updatePlayerTwoGames(currentSet: self.set)
                    tieBreak = true
                } else if abs(playerOne.games - playerTwo.games) >= 1 {
                    playerTwo.sets = playerTwo.sets + 1
                    playerTwo.games = playerTwo.games + 1
                    self.switchServer()
                    self.updatePlayerTwoGames(currentSet: self.set)
                    set = set + 1
                    playerTwo.games = 0
                    playerOne.games = 0
                }
                playerTwo.points = 0
                playerOne.points = 0
            }
        } else if tieBreak {
            if playerTwo.points <= 5 {
                playerTwo.points = playerTwo.points + 1
            } else if playerTwo.points == playerOne.points {
                playerTwo.points = playerTwo.points + 1
            } else if playerTwo.points < playerOne.points {
                playerTwo.points = playerTwo.points + 1
            } else if abs(playerTwo.points - playerOne.points) >= 1 {
                playerTwo.points = playerTwo.points + 1
                playerTwo.games = playerTwo.games + 1
                playerTwo.sets = playerTwo.sets + 1
                
                self.switchServer()
                self.updatePlayerTwoGames(currentSet: self.set)
                appendTieBreakScore(currentSet: self.set)
                
                set = set + 1
                playerOne.games = 0
                playerTwo.games = 0
                playerOne.points = 0
                playerTwo.points = 0
                tieBreak = false
            }
            if tieBreak {
                if (playerOne.points + playerTwo.points) % 2 == 0 {
                } else {
                    self.switchServer()
                }
            }
        }
        convertTennisScores()
        checkForGameSetMatchPoint()
    }
    
    func checkForGameSetMatchPoint() {
        //checks for game, set, and match points and sets flag for each
        breakPoint = false
        gamePoint = false
        setPoint = false
        matchPoint = false
        
        if tieBreak {
            //Check for Player 1 Game Point
            if ((playerOne.points >= 6) && (playerTwo.points <= (playerOne.points - 1))) {
                if (playerOne.sets == (MatchSettings.numberOfSets - 1)) {
                    matchPoint = true
                }
                setPoint = true
            }
            
            //Check for Player 2 Game Point
            if ((playerTwo.points >= 6) && (playerOne.points <= (playerTwo.points - 1))) {
                if (playerTwo.sets == (MatchSettings.numberOfSets - 1)) {
                    matchPoint = true
                }
                setPoint = true
            }
        } else {
            //Check for Player 1 Game Point
            if (playerOne.points == 3 && (playerTwo.points < playerOne.points)) || playerOne.points == 4 {
                if (playerOne.games == 5 && (playerTwo.games < playerOne.games)) || (playerOne.games == 6 && playerTwo.games == 5) {
                    if (playerOne.sets == (MatchSettings.numberOfSets - 1)) {
                        matchPoint = true
                    }
                    setPoint = true
                }
                gamePoint = true
                if playerTwo.isServing {
                    breakPoint = true
                }
            }
            
            //Check for Player 2 Game Point
            if (playerTwo.points == 3 && (playerOne.points < playerTwo.points)) || playerTwo.points == 4 {
                if (playerTwo.games == 5 && (playerOne.games < playerTwo.games)) || (playerTwo.games == 6 && playerOne.games == 5) {
                    if (playerTwo.sets == (MatchSettings.numberOfSets - 1)) {
                        matchPoint = true
                    }
                    setPoint = true
                }
                gamePoint = true
                if playerOne.isServing {
                    breakPoint = true
                }
            }
        }
    }
    
    func switchServer() {
        //sweitches server from one player to the next
        playerOne.isServing = !playerOne.isServing
        playerTwo.isServing = !playerTwo.isServing
    }
    
    func convertTennisScores() {
        //converts player's points to corresponding 'tennis score' (0,15,30,40)
        let tennisScores = [0,15,30,40]

        if !tieBreak {
            if playerOne.points <= 3 && playerTwo.points <= 3 {
                playerOne.scoreString = String(tennisScores[playerOne.points])
                playerTwo.scoreString = String(tennisScores[playerTwo.points])
            } else if playerOne.points == 4 {
                playerOne.scoreString = "AD"
                playerTwo.scoreString = "-"
            } else if playerTwo.points == 4 {
                playerOne.scoreString = "-"
                playerTwo.scoreString = "AD"
            }
        } else if tieBreak {
            playerOne.scoreString = String(playerOne.points)
            playerTwo.scoreString = String(playerTwo.points)
        }
        
        //sets game over flag
        if playerOne.sets == MatchSettings.numberOfSets || playerTwo.sets == MatchSettings.numberOfSets {
            gameOver = true
        }
    }
    
    func updatePlayerOneGames(currentSet: Int) {
        //converts general game counter to individual sets for player one
        switch currentSet {
        case 1:
            playerOne.set1Games = NSMutableAttributedString(string: String(playerOne.games))
        case 2:
            playerOne.set2Games = NSMutableAttributedString(string: String(playerOne.games))
        case 3:
            playerOne.set3Games = NSMutableAttributedString(string: String(playerOne.games))
        case 4:
            playerOne.set4Games = NSMutableAttributedString(string: String(playerOne.games))
        case 5:
            playerOne.set5Games = NSMutableAttributedString(string: String(playerOne.games))
        default:
            print("Error - updatePlayerOneGames")
        }
    }
    
    func updatePlayerTwoGames(currentSet: Int) {
        //converts general game counter to individual sets for player two
        switch currentSet {
        case 1:
            playerTwo.set1Games = NSMutableAttributedString(string: String(playerTwo.games))
        case 2:
            playerTwo.set2Games = NSMutableAttributedString(string: String(playerTwo.games))
        case 3:
            playerTwo.set3Games = NSMutableAttributedString(string: String(playerTwo.games))
        case 4:
            playerTwo.set4Games = NSMutableAttributedString(string: String(playerTwo.games))
        case 5:
            playerTwo.set5Games = NSMutableAttributedString(string: String(playerTwo.games))
        default:
            print("Error - updatePlayerTwoGames")
        }
    }
    
    func appendTieBreakScore(currentSet: Int) {
        //adds current tie break score to each player's game counter for the current set
        let playerOneTieBreakString = NSAttributedString(string: String(playerOne.points),
                                                         attributes: [
                                                            .baselineOffset: 16,
                                                            .font: UIFont.systemFont(ofSize: 23),
                                                         ])
        let playerTwoTieBreakString = NSAttributedString(string: String(playerTwo.points),
                                                         attributes: [
                                                            .baselineOffset: 16,
                                                            .font: UIFont.systemFont(ofSize: 23),
                                                         ])
        switch currentSet {
        case 1:
            playerOne.set1Games.append(playerOneTieBreakString)
            playerTwo.set1Games.append(playerTwoTieBreakString)
        case 2:
            playerOne.set2Games.append(playerOneTieBreakString)
            playerTwo.set2Games.append(playerTwoTieBreakString)
        case 3:
            playerOne.set3Games.append(playerOneTieBreakString)
            playerTwo.set3Games.append(playerTwoTieBreakString)
        case 4:
            playerOne.set4Games.append(playerOneTieBreakString)
            playerTwo.set4Games.append(playerTwoTieBreakString)
        case 5:
            playerOne.set5Games.append(playerOneTieBreakString)
            playerTwo.set5Games.append(playerTwoTieBreakString)
        default:
            print("Error - appendTieBreakScore")
        }
    }
    
    
    // MARK: -  Core Data Manipulation

    
    func newMatch(){
        //reset MatchBrain variables and player structs
        resetMatchStruct()
        
        //initialize new match Core Data Object
        match = Match(context: context)
        let playerOne = Player(context: context)
        let playerTwo = Player(context: context)
        playerOne.parentMatch = match
        playerTwo.parentMatch = match
        match!.date = NSDate.now
        match!.player1Name = MatchSettings.player1Name
        match!.player2Name = MatchSettings.player2Name
        match!.numberOfSets = Int16(MatchSettings.numberOfSets)
        updateMatchCoreData()
    }
    
    func updateMatchCoreData() {
        //copy MatchBrain variables and player structs to CoreData object. Used to regularly save match state to core data
        
        let playerOneCoreData = match?.players?.object(at: 0) as! Player
        let playerTwoCoreData = match?.players?.object(at: 1) as! Player
        
        playerOneCoreData.points = Int16(MatchBrain.shared.playerOne.points)
        playerOneCoreData.games = Int16(MatchBrain.shared.playerOne.games)
        playerOneCoreData.sets = Int16(MatchBrain.shared.playerOne.sets)
        playerOneCoreData.scoreString = MatchBrain.shared.playerOne.scoreString
        playerOneCoreData.set1Games = MatchBrain.shared.playerOne.set1Games.string
        playerOneCoreData.set2Games = MatchBrain.shared.playerOne.set2Games.string
        playerOneCoreData.set3Games = MatchBrain.shared.playerOne.set3Games.string
        playerOneCoreData.set4Games = MatchBrain.shared.playerOne.set4Games.string
        playerOneCoreData.set5Games = MatchBrain.shared.playerOne.set5Games.string
        playerOneCoreData.isWinner = MatchBrain.shared.playerOne.isWinner
        playerOneCoreData.resigned = MatchBrain.shared.playerOne.resigned
        playerOneCoreData.isServing = MatchBrain.shared.playerOne.isServing
        
        playerTwoCoreData.points = Int16(MatchBrain.shared.playerTwo.points)
        playerTwoCoreData.games = Int16(MatchBrain.shared.playerTwo.games)
        playerTwoCoreData.sets = Int16(MatchBrain.shared.playerTwo.sets)
        playerTwoCoreData.scoreString = MatchBrain.shared.playerTwo.scoreString
        playerTwoCoreData.set1Games = MatchBrain.shared.playerTwo.set1Games.string
        playerTwoCoreData.set2Games = MatchBrain.shared.playerTwo.set2Games.string
        playerTwoCoreData.set3Games = MatchBrain.shared.playerTwo.set3Games.string
        playerTwoCoreData.set4Games = MatchBrain.shared.playerTwo.set4Games.string
        playerTwoCoreData.set5Games = MatchBrain.shared.playerTwo.set5Games.string
        playerTwoCoreData.isWinner = MatchBrain.shared.playerTwo.isWinner
        playerTwoCoreData.resigned = MatchBrain.shared.playerTwo.resigned
        playerTwoCoreData.isServing = MatchBrain.shared.playerTwo.isServing
        
        match?.set = Int16(MatchBrain.shared.set)
        match?.tieBreak = MatchBrain.shared.tieBreak
        match?.gameOver = MatchBrain.shared.gameOver
        match?.numberOfSets = Int16(MatchSettings.numberOfSets)
        
        saveCoreData()
    }
    
    func resetMatchStruct() {
        //reset MatchBrain variables and player structs for new match
        set = 1
        gameOver = false
        tieBreak = false
        breakPoint = false
        gamePoint = false
        setPoint = false
        matchPoint = false
        
        playerOne.points = 0
        playerOne.scoreString = "0"
        playerOne.set1Games = NSMutableAttributedString(string: "0")
        playerOne.set2Games = NSMutableAttributedString(string: "0")
        playerOne.set3Games = NSMutableAttributedString(string: "0")
        playerOne.set4Games = NSMutableAttributedString(string: "0")
        playerOne.set5Games = NSMutableAttributedString(string: "0")
        playerOne.games = 0
        playerOne.sets = 0
        playerOne.isServing = true
        playerOne.resigned = false
        playerOne.isWinner = false
        
        playerTwo.points = 0
        playerTwo.scoreString = "0"
        playerTwo.set1Games = NSMutableAttributedString(string: "0")
        playerTwo.set2Games = NSMutableAttributedString(string: "0")
        playerTwo.set3Games = NSMutableAttributedString(string: "0")
        playerTwo.set4Games = NSMutableAttributedString(string: "0")
        playerTwo.set5Games = NSMutableAttributedString(string: "0")
        playerTwo.games = 0
        playerTwo.sets = 0
        playerTwo.isServing = false
        playerTwo.resigned = false
        playerTwo.isWinner = false
    }
    
    func copyMatchCoreDataToStruct() {
        //copy match CoreData object to MatchBrain variables and player structs. Used when loading a saved match or undoing a point
        
        let playerOneCoreData = match?.players?.object(at: 0) as! Player
        let playerTwoCoreData = match?.players?.object(at: 1) as! Player
        
        MatchBrain.shared.playerOne.points = Int(playerOneCoreData.points)
        MatchBrain.shared.playerOne.games = Int(playerOneCoreData.games)
        MatchBrain.shared.playerOne.sets = Int(playerOneCoreData.sets)
        MatchBrain.shared.playerOne.scoreString = (playerOneCoreData.scoreString)!
        MatchBrain.shared.playerOne.set1Games = unAtttributedStringConverter(unAtrbString: (playerOneCoreData.set1Games)!)
        MatchBrain.shared.playerOne.set2Games = unAtttributedStringConverter(unAtrbString: (playerOneCoreData.set2Games)!)
        MatchBrain.shared.playerOne.set3Games = unAtttributedStringConverter(unAtrbString: (playerOneCoreData.set3Games)!)
        MatchBrain.shared.playerOne.set4Games = unAtttributedStringConverter(unAtrbString: (playerOneCoreData.set4Games)!)
        MatchBrain.shared.playerOne.set5Games = unAtttributedStringConverter(unAtrbString: (playerOneCoreData.set5Games)!)
        MatchBrain.shared.playerOne.isWinner = playerOneCoreData.isWinner
        MatchBrain.shared.playerOne.resigned = playerOneCoreData.resigned
        MatchBrain.shared.playerOne.isServing = playerOneCoreData.isServing
        
        MatchBrain.shared.playerTwo.points = Int(playerTwoCoreData.points)
        MatchBrain.shared.playerTwo.games = Int(playerTwoCoreData.games)
        MatchBrain.shared.playerTwo.sets = Int(playerTwoCoreData.sets)
        MatchBrain.shared.playerTwo.scoreString = (playerTwoCoreData.scoreString)!
        MatchBrain.shared.playerTwo.set1Games = unAtttributedStringConverter(unAtrbString: (playerTwoCoreData.set1Games)!)
        MatchBrain.shared.playerTwo.set2Games = unAtttributedStringConverter(unAtrbString: (playerTwoCoreData.set2Games)!)
        MatchBrain.shared.playerTwo.set3Games = unAtttributedStringConverter(unAtrbString: (playerTwoCoreData.set3Games)!)
        MatchBrain.shared.playerTwo.set4Games = unAtttributedStringConverter(unAtrbString: (playerTwoCoreData.set4Games)!)
        MatchBrain.shared.playerTwo.set5Games = unAtttributedStringConverter(unAtrbString: (playerTwoCoreData.set5Games)!)
        MatchBrain.shared.playerTwo.isWinner = playerTwoCoreData.isWinner
        MatchBrain.shared.playerTwo.resigned = playerTwoCoreData.resigned
        MatchBrain.shared.playerTwo.isServing = playerTwoCoreData.isServing
        
        MatchBrain.shared.set = Int(match!.set)
        MatchBrain.shared.tieBreak = match!.tieBreak
        MatchBrain.shared.gameOver = match!.gameOver
        MatchSettings.player1Name = match!.player1Name!
        MatchSettings.player2Name = match!.player2Name!
        MatchSettings.numberOfSets = Int(match!.numberOfSets)
        
        checkForGameSetMatchPoint()
    }
    
    func undoPoint() {
        //Undo'sthe last point but keeps the current match duration, date, and length
        
        calculateDuration()
        let date = self.match?.date
        let duration = self.match?.duration
        let numberOfSets = self.match?.numberOfSets
        let lastPoint = self.undoMatchArray.popLast()
        context.delete(self.match!)
        match = lastPoint!.copyEntireObjectGraph(context: self.context) as? Match
        match?.date = date
        match?.duration = duration!
        match?.numberOfSets = numberOfSets!
        
        copyMatchCoreDataToStruct()
    }
    func copyMatchDataToUndoArray() {
        //saves each point as new match object to be used in case of point being undone
        let matchCopy = match!.copyEntireObjectGraph(context: undoContext) as! Match
        undoMatchArray.append(matchCopy)
    }
    
    func loadCoreData(date: Date) {
        //loads previousy played match ito memory
        let matchPredicate = NSPredicate(format: "date == %@", date as CVarArg)
        let request : NSFetchRequest<Match> = Match.fetchRequest()
        request.predicate = matchPredicate
        do {
            var matchArray = [Match]()
            matchArray =  try context.fetch(request)
            match = matchArray[0]
            match!.date = NSDate.now
        } catch {
            print("Error fetching resumeMatch data from context \(error)")
        }
    }
    
    func saveCoreData() {
        calculateDuration()
        do {
            try context.save()
        } catch {
            print("Error saving Core Data, \(error)")
        }
    }
    
    func calculateDuration(){
        //calculates match duration and updates the latest date of match
        let now = NSDate.now
        let duration = (now.timeIntervalSinceReferenceDate - (match?.date!.timeIntervalSinceReferenceDate)!)
        match?.duration = (((match?.duration) ?? 0) + Double(duration))
        match?.date = NSDate.now
    }
    
    func unAtttributedStringConverter(unAtrbString: String) -> NSMutableAttributedString {
        //raises the tie break score to an exponent for each sets game counts. Used when copying the unattricuted game score string saved in core data to the MatchBrain variables and player structs.
        let newString: NSMutableAttributedString = NSMutableAttributedString(string: String(unAtrbString.prefix(1)))
        
        if unAtrbString.count >= 2 {
            if unAtrbString.count == 2 {
                let newAttribute = NSAttributedString(string: String(unAtrbString.suffix(1)),
                                                      attributes: [
                                                        .baselineOffset: 16,
                                                        .font: UIFont.systemFont(ofSize: 23),
                                                      ])
                
                newString.append(newAttribute)
            }
            if unAtrbString.count == 3 {
                let newAttribute = NSAttributedString(string: String(unAtrbString.suffix(2)),
                                                      attributes: [
                                                        .baselineOffset: 16,
                                                        .font: UIFont.systemFont(ofSize: 23),
                                                      ])
                newString.append(newAttribute)
            }
            if unAtrbString.count == 4 {
                let newAttribute = NSAttributedString(string: String(unAtrbString.suffix(3)),
                                                      attributes: [
                                                        .baselineOffset: 16,
                                                        .font: UIFont.systemFont(ofSize: 23),
                                                      ])
                newString.append(newAttribute)
            }
            return newString
        } else {
            return newString
        }
        
    }
    
}
