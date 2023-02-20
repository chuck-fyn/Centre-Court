//
//  AnnouncerBooth.swift
//  MatchPoint
//
//  Created by Charles Prutting on 10/22/22.
//

import Foundation
import AVFAudio
import MediaPlayer

class AnnouncerBooth: NSObject, AVAudioPlayerDelegate {
    
    public var myPlayer: AVAudioPlayer?
    public var crowdPlayer: AVAudioPlayer?
    let synth = AVSpeechSynthesizer()
    var randomKey = ""
    
    
    // MARK: - loading, starting, and stopping main match audio
    
    func initMatchAudio() {
        //load match audio into avaudioplayer to prepare for match to begin
        guard let loadSound = loadSound(filename: "silence") else {
            print("Not able to load the sound")
            return
        }
        loadSound.delegate = self
        loadSound.volume = 1
        loadSound.numberOfLoops = -1
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSessionError: \(error)")
        }
        myPlayer = loadSound
        myPlayer?.rate = 1.0
    }
    
    func beginMatchAudio(time: Double) {
        //set match data and 'albun artwork' for NowPlayingInfoCenter
        let image = UIImage(named: "AlbumArtwork")!
        let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
            return image
        })
        let audioInfo = MPNowPlayingInfoCenter.default()
        audioInfo.nowPlayingInfo = [MPMediaItemPropertyTitle: "\(MatchSettings.player1Name) vs. \(MatchSettings.player2Name)", MPMediaItemPropertyArtist: "Centre Court", MPMediaItemPropertyArtwork: artwork, MPMediaItemPropertyPlaybackDuration: Double.infinity, MPNowPlayingInfoPropertyElapsedPlaybackTime: time]
        
        //begin match audio
        myPlayer?.play()
    }
    
    func stopMatchAudio() {
        //clears NowPlayingInfoCenter and stops match audio
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        myPlayer?.stop()
    }
    
    
    // MARK: - Umpire Announcements

    
    func pointScored(winner: String) {
        //plays crowd cheers before score is read. randomKey is set to prevent waitForCrowd triggering readScores more than once if points are scored in quick succession
        crowdGoesWild()
        randomKey = randomString(length: 5)
        waitForCrowd(key: randomKey, winner: winner)
    }
    func crowdGoesWild() {
        //first clears the last message beig read, then plays a random crowd cheer file.
        speak(script: "")
        let crowdCheers = ["crowd1", "crowd2", "crowd3", "crowd4", "crowd5", "crowd6", "crowd7", "crowd8", "crowd9", "crowd10", "crowd11", "crowd12", "crowd13", "crowd14", "crowd15"]
        let randomIndex = Int(arc4random_uniform(UInt32(crowdCheers.count)))
        let selectedFileName = crowdCheers[randomIndex]
        let cheer = Bundle.main.path(forResource: selectedFileName, ofType: "mp3", inDirectory: "Crowd Cheers")
        do{
            crowdPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: cheer!))
        }catch{
            print("crowdPlayer error:\(error)")
        }
        crowdPlayer!.volume = 0.0
        crowdPlayer!.play()
        crowdPlayer!.setVolume(0.07, fadeDuration: 0.5)
    }
    func waitForCrowd(key: String, winner: String) {
        //waits two seconds for crowd cheers and triggers readScores. randomKey is set to prevent readScores being triggered more than once if points are scored in quick succession
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if key == self.randomKey {
                self.readScores(event: winner, keepPoint: false)
            }
        }
    }
    
    func readScores(event: String, keepPoint: Bool) {
        //logic for setting the umpire script for each point scored scenario!
        
        var matchLength: String
        var pointWinnerName: String
        var pointString: String
        var serversScore: String
        var receiversScore: String
        var serverName: String
        var serviceString: String
        var setName: String
        var lastSetName: String
        var playerOneLastSetGames: Int
        var playerTwoLastSetGames: Int
        var lastSetGameScoresString: String
        var resumeMatchGameScoreString: String
        var setScoresString: String
        var allSetsGameScoresP1Wins: String
        var allSetsGameScoresP2Wins: String
        
        var umpire: String
        
        //init game score strings for end of each set
        let set1P1Wins = "\(MatchBrain.shared.playerOne.set1Games.string.first!) \(MatchBrain.shared.playerTwo.set1Games.string.first!)"
        let set2P1Wins = "\(MatchBrain.shared.playerOne.set2Games.string.first!) \(MatchBrain.shared.playerTwo.set2Games.string.first!)"
        let set3P1Wins = "\(MatchBrain.shared.playerOne.set3Games.string.first!) \(MatchBrain.shared.playerTwo.set3Games.string.first!)"
        let set4P1Wins = "\(MatchBrain.shared.playerOne.set4Games.string.first!) \(MatchBrain.shared.playerTwo.set4Games.string.first!)"
        let set5P1Wins = "\(MatchBrain.shared.playerOne.set5Games.string.first!) \(MatchBrain.shared.playerTwo.set5Games.string.first!)"
        let set1P2Wins = "\(MatchBrain.shared.playerTwo.set1Games.string.first!) \(MatchBrain.shared.playerOne.set1Games.string.first!)"
        let set2P2Wins = "\(MatchBrain.shared.playerTwo.set2Games.string.first!) \(MatchBrain.shared.playerOne.set2Games.string.first!)"
        let set3P2Wins = "\(MatchBrain.shared.playerTwo.set3Games.string.first!) \(MatchBrain.shared.playerOne.set3Games.string.first!)"
        let set4P2Wins = "\(MatchBrain.shared.playerTwo.set4Games.string.first!) \(MatchBrain.shared.playerOne.set4Games.string.first!)"
        let set5P2Wins = "\(MatchBrain.shared.playerTwo.set5Games.string.first!) \(MatchBrain.shared.playerOne.set5Games.string.first!)"
        
        //init set name, last set name, and games won last set for each player
        switch MatchBrain.shared.set {
        case 1:
            setName = "First"
            lastSetName = "Never Gonna Happen"
            playerOneLastSetGames = MatchBrain.shared.playerOne.set1Games.string.first!.wholeNumberValue!
            playerTwoLastSetGames = MatchBrain.shared.playerTwo.set1Games.string.first!.wholeNumberValue!
            allSetsGameScoresP1Wins = "Never ever"
            allSetsGameScoresP2Wins = "Never ever ever"
        case 2:
            setName = "Second"
            lastSetName = "First"
            playerOneLastSetGames = MatchBrain.shared.playerOne.set1Games.string.first!.wholeNumberValue!
            playerTwoLastSetGames = MatchBrain.shared.playerTwo.set1Games.string.first!.wholeNumberValue!
            allSetsGameScoresP1Wins = "\(MatchBrain.shared.playerOne.set1Games.string.first!) games to \(MatchBrain.shared.playerTwo.set1Games.string.first!)."
            allSetsGameScoresP2Wins = "\(MatchBrain.shared.playerTwo.set1Games.string.first!) games to \(MatchBrain.shared.playerOne.set1Games.string.first!)."
        case 3:
            setName = "Third"
            lastSetName = "Second"
            playerOneLastSetGames = MatchBrain.shared.playerOne.set2Games.string.first!.wholeNumberValue!
            playerTwoLastSetGames = MatchBrain.shared.playerTwo.set2Games.string.first!.wholeNumberValue!
            allSetsGameScoresP1Wins = "\(MatchBrain.shared.playerOne.sets) sets to \(MatchBrain.shared.playerTwo.sets)!… \(set2P1Wins), \(set1P1Wins)."
            allSetsGameScoresP2Wins = "\(MatchBrain.shared.playerTwo.sets) sets to \(MatchBrain.shared.playerOne.sets)!… \(set2P2Wins), \(set1P2Wins)."
        case 4:
            setName = "Fourth"
            lastSetName = "Third"
            playerOneLastSetGames = MatchBrain.shared.playerOne.set3Games.string.first!.wholeNumberValue!
            playerTwoLastSetGames = MatchBrain.shared.playerTwo.set3Games.string.first!.wholeNumberValue!
            allSetsGameScoresP1Wins = "\(MatchBrain.shared.playerOne.sets) sets to \(MatchBrain.shared.playerTwo.sets)!… \(set3P1Wins), \(set2P1Wins), \(set1P1Wins)."
            allSetsGameScoresP2Wins = "\(MatchBrain.shared.playerTwo.sets) sets to \(MatchBrain.shared.playerOne.sets)!… \(set3P2Wins), \(set2P2Wins), \(set1P2Wins)."
        case 5:
            setName = "Fifth"
            lastSetName = "Fourth"
            playerOneLastSetGames = MatchBrain.shared.playerOne.set4Games.string.first!.wholeNumberValue!
            playerTwoLastSetGames = MatchBrain.shared.playerTwo.set4Games.string.first!.wholeNumberValue!
            allSetsGameScoresP1Wins = "\(MatchBrain.shared.playerOne.sets) sets to \(MatchBrain.shared.playerTwo.sets)!… \(set4P1Wins), \(set3P1Wins), \(set2P1Wins), \(set1P1Wins)."
            allSetsGameScoresP2Wins = "\(MatchBrain.shared.playerTwo.sets) sets to \(MatchBrain.shared.playerOne.sets)!… \(set4P2Wins), \(set3P2Wins), \(set2P2Wins), \(set1P2Wins)."
        default:
            setName = "Also isn't going to happen"
            lastSetName = "Fifth"
            playerOneLastSetGames = MatchBrain.shared.playerOne.set5Games.string.first!.wholeNumberValue!
            playerTwoLastSetGames = MatchBrain.shared.playerTwo.set5Games.string.first!.wholeNumberValue!
            allSetsGameScoresP1Wins = "\(MatchBrain.shared.playerOne.sets) sets to \(MatchBrain.shared.playerTwo.sets)!… \(set5P1Wins), \(set4P1Wins), \(set3P1Wins), \(set2P1Wins), \(set1P1Wins)."
            allSetsGameScoresP2Wins = "\(MatchBrain.shared.playerTwo.sets) sets to \(MatchBrain.shared.playerOne.sets)!… \(set5P2Wins), \(set4P2Wins), \(set3P2Wins), \(set2P2Wins), \(set1P2Wins)."
        }
        
        //init length of match script
        if MatchSettings.numberOfSets == 1 {
            matchLength = "one tie-break set,"
        } else if MatchSettings.numberOfSets == 2 {
            matchLength = "best of three Tie Break Sets"
        } else {
            matchLength = "best of five Tie Break Sets"
        }
        
        //init point score based on who is currently serving
        if MatchBrain.shared.playerOne.isServing {
            serverName = MatchSettings.player1Name
            if MatchBrain.shared.playerOne.points == 0 {
                serversScore = "love"
            } else {
                serversScore = MatchBrain.shared.playerOne.scoreString
            }
            if MatchBrain.shared.playerTwo.points == 0 {
                receiversScore = "love"
            } else {
                receiversScore = MatchBrain.shared.playerTwo.scoreString
            }
        } else {
            serverName = MatchSettings.player2Name
            if MatchBrain.shared.playerOne.points == 0 {
                receiversScore = "love"
            } else {
                receiversScore = MatchBrain.shared.playerOne.scoreString
            }
            if MatchBrain.shared.playerTwo.points == 0 {
                serversScore = "love"
            } else {
                serversScore = MatchBrain.shared.playerTwo.scoreString
            }
        }
        if MatchBrain.shared.tieBreak {
            if MatchBrain.shared.playerOne.points > MatchBrain.shared.playerTwo.points {
                pointString = "\(MatchBrain.shared.playerOne.points). \(MatchBrain.shared.playerTwo.points). \(MatchSettings.player1Name)."
            } else if MatchBrain.shared.playerOne.points < MatchBrain.shared.playerTwo.points {
                pointString = "\(MatchBrain.shared.playerTwo.points). \(MatchBrain.shared.playerOne.points). \(MatchSettings.player2Name)."
            } else {
                pointString = "\(MatchBrain.shared.playerTwo.points). All."
            }
        } else {
            if MatchBrain.shared.playerOne.points == 3 && MatchBrain.shared.playerTwo.points == 3 {
                pointString = "Deuce."
            } else if MatchBrain.shared.playerOne.points == 4 && MatchBrain.shared.playerTwo.points == 3 {
                pointString  = "Advantage. \(MatchSettings.player1Name)."
            } else if MatchBrain.shared.playerOne.points == 3 && MatchBrain.shared.playerTwo.points == 4 {
                pointString  = "Advantage. \(MatchSettings.player2Name)."
            } else {
                if serversScore == receiversScore {
                    pointString = "\(serversScore). All."
                } else {
                    pointString = "...\(serversScore)... \(receiversScore)."
                }
            }
        }
        if MatchBrain.shared.matchPoint {
            let matchPoint = " Match Point."
            pointString.append(matchPoint)
        } else if MatchBrain.shared.setPoint {
            let setPoint = " Set Point."
            pointString.append(setPoint)
        } else if MatchBrain.shared.breakPoint {
            let breakPoint = " Break Point."
            pointString.append(breakPoint)
        }
        
        
        //init name of the player who won the last point, and the game score sentence to read aloud based on who won the set
        if event == "playerOne" {
            pointWinnerName = MatchSettings.player1Name
            lastSetGameScoresString = "At \(playerOneLastSetGames) games to \(playerTwoLastSetGames)."
        } else {
            pointWinnerName = MatchSettings.player2Name
            lastSetGameScoresString = "At \(playerTwoLastSetGames) games to \(playerOneLastSetGames)."
        }
        
        //init if players should change ends and who is serving
        if (MatchBrain.shared.playerOne.games + MatchBrain.shared.playerTwo.games) % 2 == 0 {
            if MatchBrain.shared.playerOne.games + MatchBrain.shared.playerTwo.games == 0 && (playerOneLastSetGames + playerTwoLastSetGames) % 2 != 0 {
                serviceString = "Players, change ends. \(serverName) to serve."
            } else {
                serviceString = "\(serverName) to serve."
            }
        } else {
            serviceString = "Players, change ends. \(serverName) to serve."
        }
        if MatchBrain.shared.tieBreak {
            if (MatchBrain.shared.playerOne.points + MatchBrain.shared.playerTwo.points) % 2 != 0 {
                let tieBreakServiceString = "… \(serverName) to serve."
                pointString.append(tieBreakServiceString)
            }
            if (MatchBrain.shared.playerOne.points + MatchBrain.shared.playerTwo.points) % 6 == 0 {
                if event != "resumeMatch" && event != "undoPoint" {
                    let tieBreakChangeEndsString = "… Players, change ends."
                    pointString.append(tieBreakChangeEndsString)
                }
            }
        }
        
        //init set score sentence based on which player is winning
        if MatchBrain.shared.playerOne.sets > MatchBrain.shared.playerTwo.sets {
            if MatchBrain.shared.playerOne.sets == 1 {
                setScoresString = "\(MatchSettings.player1Name) leads \(String(MatchBrain.shared.playerOne.sets)) set to \(String(MatchBrain.shared.playerTwo.sets))."
            } else {
                setScoresString = "\(MatchSettings.player1Name) leads \(String(MatchBrain.shared.playerOne.sets)) sets to \(String(MatchBrain.shared.playerTwo.sets))."
            }
        } else if MatchBrain.shared.playerOne.sets < MatchBrain.shared.playerTwo.sets {
            if MatchBrain.shared.playerTwo.sets == 1 {
                setScoresString = "\(MatchSettings.player2Name) leads \(String(MatchBrain.shared.playerTwo.sets)) set to \(String(MatchBrain.shared.playerOne.sets))."
            } else{
                setScoresString = "\(MatchSettings.player2Name) leads \(String(MatchBrain.shared.playerTwo.sets)) sets to \(String(MatchBrain.shared.playerOne.sets))."
            }
        } else {
            if MatchBrain.shared.playerOne.sets == 0 {
                setScoresString = ""
            } else if MatchBrain.shared.playerOne.sets == 1 {
                setScoresString = "One Set all."
            } else {
                setScoresString = "\(MatchBrain.shared.playerOne.sets) Sets all."
            }
        }
        
        //init match score to announce when resuming match
        if MatchBrain.shared.playerOne.games > MatchBrain.shared.playerTwo.games {
            if MatchBrain.shared.playerOne.games == 1 {
                resumeMatchGameScoreString = "\(MatchSettings.player1Name) leads \(MatchBrain.shared.playerOne.games) game to \(MatchBrain.shared.playerTwo.games) in the \(setName) set."
            } else {
                resumeMatchGameScoreString = "\(MatchSettings.player1Name) leads \(MatchBrain.shared.playerOne.games) games to \(MatchBrain.shared.playerTwo.games) in the \(setName) set."
            }
        } else if MatchBrain.shared.playerOne.games < MatchBrain.shared.playerTwo.games {
            if MatchBrain.shared.playerTwo.games == 1 {
                resumeMatchGameScoreString = "\(MatchSettings.player2Name) leads \(MatchBrain.shared.playerTwo.games) game to \(MatchBrain.shared.playerOne.games) in the \(setName) set."
            } else {
                resumeMatchGameScoreString = "\(MatchSettings.player2Name) leads \(MatchBrain.shared.playerTwo.games) games to \(MatchBrain.shared.playerOne.games) in the \(setName) set."
            }
        } else {
            if MatchBrain.shared.playerOne.games == 1 {
                resumeMatchGameScoreString = "One game all in the \(setName) set."
            } else if MatchBrain.shared.playerOne.games == 6 {
                resumeMatchGameScoreString = "Six games all in the \(setName) set. Tie-Breaker!"
            } else {
                resumeMatchGameScoreString = "… \(MatchBrain.shared.playerOne.games) games all in the \(setName) set."
            }
        }
        
        
        //Set umpire scripts for point won, game won, set won, and match won
        if event == "resumeMatch" {
            umpire = "Now playing on Center Court... \(MatchSettings.player1Name)! and \(MatchSettings.player2Name)! to resume a match of \(matchLength).... \(setScoresString) \(resumeMatchGameScoreString) \(serverName) to serve… \(pointString)…… And remember, press AirPods once for \(MatchSettings.player1Name)'s point, twice for \(MatchSettings.player2Name)'s point, and three times to undo the last point..... Ready? Play."
        } else {
            if event == "undoPoint" {
                umpire = "The last point will be played over... \(pointString)"
            } else {
                if MatchBrain.shared.playerOne.sets == MatchSettings.numberOfSets || MatchBrain.shared.playerTwo.sets == MatchSettings.numberOfSets {
                    //"Game Set Match" conditional
                    if MatchBrain.shared.playerOne.isWinner {
                        umpire = "Game, Set, and Match, \(MatchSettings.player1Name)!… \(allSetsGameScoresP1Wins)"
                    } else {
                        umpire = "Game, Set, and Match, \(MatchSettings.player2Name)!… \(allSetsGameScoresP2Wins)"
                    }
                } else {
                    if MatchBrain.shared.playerOne.points == 0 && MatchBrain.shared.playerTwo.points == 0 {
                        if MatchBrain.shared.playerOne.games == 0 && MatchBrain.shared.playerTwo.games == 0 {
                            //Conditionals for Set Won OR Match is just beginning
                            if MatchBrain.shared.set == 1 {
                                umpire = "Now playing on Center Court... \(MatchSettings.player1Name)! and \(MatchSettings.player2Name)! to play a match of \(matchLength)… First set. \(MatchSettings.player1Name) to serve…… and remember, press AirPods once for \(MatchSettings.player1Name)'s point, twice for \(MatchSettings.player2Name)'s point, and three times to undo the last point.... Ready? Play."
                            } else if MatchBrain.shared.set == 2 {
                                umpire = "Game and First set, \(pointWinnerName). \(lastSetGameScoresString). \(serviceString)"
                            } else {
                                umpire = "Game and \(lastSetName) set, \(pointWinnerName). \(lastSetGameScoresString) \(setScoresString). \(serviceString)"
                            }
                        } else{
                            //Conditionals for Game Won
                            if MatchBrain.shared.playerOne.games + MatchBrain.shared.playerTwo.games == 1 {
                                if MatchBrain.shared.set == 1 {
                                    umpire = "Game \(pointWinnerName). First Game. \(serviceString)"
                                } else {
                                    umpire = "Game \(pointWinnerName). First Game. \(setName) Set. \(serviceString)"
                                }
                            } else {
                                if MatchBrain.shared.playerOne.games == MatchBrain.shared.playerTwo.games {
                                    if MatchBrain.shared.playerOne.games == 1 {
                                        umpire = "Game \(pointWinnerName). One game all. \(setName) Set. \(serviceString)"
                                    } else {
                                        if MatchBrain.shared.tieBreak {
                                            umpire = "Game \(pointWinnerName). \(String(MatchBrain.shared.playerOne.games)) games all. \(setName) Set. Tie-Breaker! \(serviceString)"
                                        } else {
                                            umpire = "Game \(pointWinnerName). \(String(MatchBrain.shared.playerOne.games)) games all. \(setName) Set. \(serviceString)"
                                        }
                                    }
                                } else if MatchBrain.shared.playerOne.games > MatchBrain.shared.playerTwo.games {
                                    umpire = "Game \(pointWinnerName)... \(MatchSettings.player1Name) leads \(String(MatchBrain.shared.playerOne.games)) games to \(String(MatchBrain.shared.playerTwo.games)). \(setName) Set. \(serviceString)"
                                } else {
                                    umpire = "Game \(pointWinnerName)... \(MatchSettings.player2Name) leads \(String(MatchBrain.shared.playerTwo.games)) games to \(String(MatchBrain.shared.playerOne.games)). \(setName) Set. \(serviceString)"
                                }
                            }
                        }
                    } else {
                        if keepPoint {
                            umpire = pointString
                        } else {
                            if MatchSettings.announcePointWinnerEachPoint {
                                umpire = "Point \(pointWinnerName)!… \(pointString)"
                            } else {
                                umpire = pointString
                            }
                        }
                    }
                }
            }
        }
        //changes script for undo point cancelled, and then confirms the latest score
        if keepPoint {
            var keepPointScript = "Undo Cancelled. The point stands..."
            keepPointScript.append(contentsOf: umpire)
            speak(script: keepPointScript)
        } else {
            speak(script: umpire)
        }
    }
    
    func speak(script: String) {
        //starts by clearing latest speach
        synth.stopSpeaking(at: .immediate)
        
        //updates randomKey to stop any pending functions from firing
        randomKey = randomString(length: 5)
        
        //sets voice of umpire as Lee if available in users phone settings. Otherwise defualts to user preferences
        let announcement = AVSpeechUtterance(string: script)
        announcement.rate = 0.4
        announcement.volume = 1.0
        announcement.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.en-AU.Lee")
        
        synth.speak(announcement)
    }
    
    func cancelPoint() {
        speak(script: "")
        if crowdPlayer != nil {
            crowdPlayer!.stop()
        }
    }
    
    
    // MARK: - Supporting functions

    
    func loadSound(filename: NSString) -> AVAudioPlayer? {
        //loads sound from app assets
        let url = Bundle.main.url(forResource: filename as String, withExtension: "mp3")
        do {
            let player = try AVAudioPlayer(contentsOf: url ?? URL(fileURLWithPath: ""))
            player.prepareToPlay()
            return player
        }
        catch {
            print("Error : \(error)")
            return nil
        }
    }
    
    func randomString(length: Int) -> String {
        //random string generator used for randomKey
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
