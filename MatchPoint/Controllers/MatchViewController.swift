//
//  ViewController.swift
//  MatchPoint
//
//  Created by Charles Prutting on 8/11/22.
//

import SwiftUI
import MediaPlayer
import CoreData

class MatchViewController: UIViewController, AVAudioPlayerDelegate, HomeViewControllerDelegate, MatchSettingsViewControllerDelegate {
    
    @IBOutlet weak var player1Button: UIButton!
    @IBOutlet weak var player2Button: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    
    @IBOutlet weak var player1Name: UILabel!
    @IBOutlet weak var player2Name: UILabel!
    @IBOutlet weak var tennisCourtImage: UIImageView!
    @IBOutlet weak var gameSetMatchPointImage: UIImageView!
    @IBOutlet weak var bestOfStamp: UIImageView!
    
    @IBOutlet weak var allSetsStackView: UIStackView!
    @IBOutlet weak var set1Stack: UIStackView!
    @IBOutlet weak var set2Stack: UIStackView!
    @IBOutlet weak var set3Stack: UIStackView!
    @IBOutlet weak var set4Stack: UIStackView!
    @IBOutlet weak var set5Stack: UIStackView!
    
    @IBOutlet weak var set1GamesPlayer1: UILabel!
    @IBOutlet weak var set1GamesPlayer2: UILabel!
    @IBOutlet weak var set2GamesPlayer1: UILabel!
    @IBOutlet weak var set2GamesPlayer2: UILabel!
    @IBOutlet weak var set3GamesPlayer1: UILabel!
    @IBOutlet weak var set3GamesPlayer2: UILabel!
    @IBOutlet weak var set4GamesPlayer1: UILabel!
    @IBOutlet weak var set4GamesPlayer2: UILabel!
    @IBOutlet weak var set5GamesPlayer1: UILabel!
    @IBOutlet weak var set5GamesPlayer2: UILabel!
    
    var lastPointWinner = ""
    var randomKey = ""
    var undoPrompt = false
    var podsLocked = false
    var instructionsOpen = false
    var courtColorRGB: UIColor?
    var announcerBooth = AnnouncerBooth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize onscreen display and prepare app to recieve remote commands
        initializeDisplay()
        setupRemoteCommandCenter()
        
        //adds didBecomeActive observer
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //this only gets called when the app first opens and after the instuctions screen is closed when opened from this viewcController. It is only used to trigger the segue to HomeViewController at first open, so we restrict that if coming from instructions and set the instructions open flag to false.
        if !instructionsOpen {
            performSegue(withIdentifier: "goHome", sender: self)
        } else {
            instructionsOpen = false
        }
    }
    
    @objc func didBecomeActive() {
        //this gets called every time the app is first opened or navigated to from another app while already open. It is used to turn on the match audio(and pause audio from other apps) if a match is currently open because these commands normally only get called when a match is created or resumed. If a match is not open, we do not take over the phone's audio
        if !MatchBrain.shared.buttonsLocked {
            announcerBooth.initMatchAudio()
            announcerBooth.beginMatchAudio(time: MatchBrain.shared.match!.duration)
        }
    }
    
    @objc func handleRouteChange(_ notification: Notification) {
        //cancel last point scored if triggered by airpods being put in or taken off, but check if match is loaded first
        if !MatchBrain.shared.buttonsLocked && MatchBrain.shared.undoMatchArray.count != 0 {
//            announcerBooth.cancelPoint()
//            undoPoint()
        }
    }
    
    // MARK: - Match Display and Updates
    
    func initializeDisplay() {
        //Sets initial attributes of all onscreen items
        setCourtColor()
        set1Stack.layer.cornerRadius = 30
        set2Stack.layer.cornerRadius = 30
        set3Stack.layer.cornerRadius = 30
        set4Stack.layer.cornerRadius = 30
        set5Stack.layer.cornerRadius = 30
        set2Stack.isHiddenInStackView = true
        set3Stack.isHiddenInStackView = true
        set4Stack.isHiddenInStackView = true
        set5Stack.isHiddenInStackView = true
        gameSetMatchPointImage.image = nil
        
        bestOfStamp.image = nil
        bestOfStamp.layer.shadowColor = UIColor.black.cgColor
        bestOfStamp.layer.shadowRadius = 6
        bestOfStamp.layer.shadowOffset = .zero
        bestOfStamp.layer.shadowOpacity = 0.5
        
        player1Name.text = ""
        player2Name.text = ""
        player1Name.layer.cornerRadius = 12
        player2Name.layer.cornerRadius = 12
        
        player1Button.layer.shadowColor = UIColor.black.cgColor
        player1Button.layer.shadowOffset = CGSize(width: -3, height: 3)
        player1Button.layer.shadowRadius = 3
        player1Button.layer.shadowOpacity = 0.15
        player2Button.layer.shadowColor = UIColor.black.cgColor
        player2Button.layer.shadowOffset = CGSize(width: -3, height: 3)
        player2Button.layer.shadowRadius = 3
        player2Button.layer.shadowOpacity = 0.15
    }
    
    func newMatch() {
        //Reset PlayerScores Struct
        MatchBrain.shared.newMatch()
        
        //Update display with new match data
        updateDisplayWithLoadedMatchData()
        setBestOfSetsStamp()
        
        //Start AVAudioSession and Check for connected BT headphones. Once connected, announcerBooth reads current game state
        announcerBooth.initMatchAudio()
        announcerBooth.beginMatchAudio(time: MatchBrain.shared.match!.duration)
        areAirPodsConnected(sender: "newGame")
    }
    func resumeMatch(date: Date) {
        //Load saved match from core data and copy to MatchBrain.shared struct
        MatchBrain.shared.loadCoreData(date: date)
        MatchBrain.shared.copyMatchCoreDataToStruct()
        
        //Update display with saved match data
        updateDisplayWithLoadedMatchData()
        setBestOfSetsStamp()
        
        //Start AVAudioSession and Check for connected BT headphones. Once connected, announcerBooth reads current game state
        announcerBooth.initMatchAudio()
        announcerBooth.beginMatchAudio(time: MatchBrain.shared.match!.duration)
        areAirPodsConnected(sender: "resumeMatch")
    }
    func updateDisplayWithLoadedMatchData() {
        //Update display with current match data
        updateGameCounts()
        updateButtonDisplays()
        player1Button.setTitle(MatchBrain.shared.playerOne.scoreString, for: .normal)
        player2Button.setTitle(MatchBrain.shared.playerTwo.scoreString, for: .normal)
        player1Button.isEnabled = true
        player2Button.isEnabled = true
        
        //cool animation of player names appearing onscreen
        UIView.animate(withDuration: 0.8, animations: {
            self.player1Name.isHiddenInStackView = false
            self.player2Name.isHiddenInStackView = false
            self.player1Name.text = "\(MatchSettings.player1Name)    "
            self.player2Name.text = "\(MatchSettings.player2Name)    "
            MatchBrain.shared.playerOne.isServing ? self.player1Name.addTennisBall() : self.player2Name.addTennisBall()
        })
        
        //cool animation of appropriate number of sets appearing on screen
        UIView.animate(withDuration: 1.2, animations: {
            if MatchBrain.shared.set >= 2 {
                self.set2Stack.isHiddenInStackView = false
            }
            if MatchBrain.shared.set >= 3 {
                self.set3Stack.isHiddenInStackView = false
            }
            if MatchBrain.shared.set >= 4 {
                self.set4Stack.isHiddenInStackView = false
            }
            if MatchBrain.shared.set == 5 {
                self.set5Stack.isHiddenInStackView = false
            }
        })
    }
    
    func updatePlayer1() {
        //Player one scored, updata match data and display
        MatchBrain.shared.playerOneScored()
        lastPointWinner = "playerOne"
        
        if MatchBrain.shared.gameOver {
            MatchBrain.shared.playerOne.isWinner = true
            player1Button.setTitle("Winner!", for: .normal)
            player2Button.setTitle("-", for: .normal)
        }
        
        updateGameCounts()
        updateButtonDisplays()
        MatchBrain.shared.copyMatchDataToUndoArray()
        MatchBrain.shared.updateMatchCoreData()
        
//        print("player 1: \(MatchBrain.shared.playerOne.points), \(MatchBrain.shared.playerOne.games), \(MatchBrain.shared.playerOne.sets)")
//        print("player 2: \(MatchBrain.shared.playerTwo.points), \(MatchBrain.shared.playerTwo.games), \(MatchBrain.shared.playerTwo.sets)")
//        print("set: \(MatchBrain.shared.set)")
    }
    func updatePlayer2() {
        //Player two scored, updata match data and display
        MatchBrain.shared.playerTwoScored()
        lastPointWinner = "playerTwo"
        
        if MatchBrain.shared.gameOver {
            MatchBrain.shared.playerTwo.isWinner = true
            player1Button.setTitle("-", for: .normal)
            player2Button.setTitle("Winner!", for: .normal)
        }
        
        updateGameCounts()
        updateButtonDisplays()
        MatchBrain.shared.copyMatchDataToUndoArray()
        MatchBrain.shared.updateMatchCoreData()
        
//        print("player 1: \(MatchBrain.shared.playerOne.points), \(MatchBrain.shared.playerOne.games), \(MatchBrain.shared.playerOne.sets)")
//        print("player 2: \(MatchBrain.shared.playerTwo.points), \(MatchBrain.shared.playerTwo.games), \(MatchBrain.shared.playerTwo.sets)")
//        print("set: \(MatchBrain.shared.set)")
    }
    
    func updateGameCounts() {
        //Updates 'Sets' and 'Games' displays after a game is won
        
        //Set game counts to current match data
        set1GamesPlayer1.attributedText = MatchBrain.shared.playerOne.set1Games
        set1GamesPlayer2.attributedText = MatchBrain.shared.playerTwo.set1Games
        set2GamesPlayer1.attributedText = MatchBrain.shared.playerOne.set2Games
        set2GamesPlayer2.attributedText = MatchBrain.shared.playerTwo.set2Games
        set3GamesPlayer1.attributedText = MatchBrain.shared.playerOne.set3Games
        set3GamesPlayer2.attributedText = MatchBrain.shared.playerTwo.set3Games
        set4GamesPlayer1.attributedText = MatchBrain.shared.playerOne.set4Games
        set4GamesPlayer2.attributedText = MatchBrain.shared.playerTwo.set4Games
        set5GamesPlayer1.attributedText = MatchBrain.shared.playerOne.set5Games
        set5GamesPlayer2.attributedText = MatchBrain.shared.playerTwo.set5Games
        setGameSetMatchPointImages()
        
        //Add tennis ball to the player serving
        self.player1Name.text = "\(MatchSettings.player1Name)    "
        self.player2Name.text = "\(MatchSettings.player2Name)    "
        MatchBrain.shared.playerOne.isServing ? player1Name.addTennisBall() : player2Name.addTennisBall()
        
        //Animates next set displaying on screen
        if !MatchBrain.shared.gameOver {
            switch MatchBrain.shared.set {
            case 1:
                if MatchBrain.shared.playerOne.games == 0 && MatchBrain.shared.playerTwo.games == 0 && MatchBrain.shared.playerOne.points == 0 && MatchBrain.shared.playerTwo.points == 0 {
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 1.2, animations: {
                            self.set2Stack.isHiddenInStackView = true
                            self.set3Stack.isHiddenInStackView = true
                            self.set4Stack.isHiddenInStackView = true
                            self.set5Stack.isHiddenInStackView = true
                        })
                    }
                }
            case 2:
                if MatchBrain.shared.playerOne.games == 0 && MatchBrain.shared.playerTwo.games == 0 && MatchBrain.shared.playerOne.points == 0 && MatchBrain.shared.playerTwo.points == 0 {
                    self.allSetsStackView.removeArrangedSubview(self.set2Stack)
                    self.allSetsStackView.insertArrangedSubview(self.set2Stack, at: 4)
                    DispatchQueue.main.async {
                        self.set3Stack.isHiddenInStackView = true
                        self.set4Stack.isHiddenInStackView = true
                        self.set5Stack.isHiddenInStackView = true
                        self.set2GamesPlayer1.alpha = 0
                        self.set2GamesPlayer2.alpha = 0
                        UIView.animate(withDuration: 1.2, animations: {
                            self.set2GamesPlayer1.alpha = 1
                            self.set2GamesPlayer2.alpha = 1
                            
                            self.allSetsStackView.removeArrangedSubview(self.set2Stack)
                            self.allSetsStackView.insertArrangedSubview(self.set2Stack, at: 1)
                            
                            self.set2Stack.isHiddenInStackView = false
                        })
                    }
                }
            case 3:
                if MatchBrain.shared.playerOne.games == 0 && MatchBrain.shared.playerTwo.games == 0 && MatchBrain.shared.playerOne.points == 0 && MatchBrain.shared.playerTwo.points == 0 {
                    DispatchQueue.main.async {
                        self.set4Stack.isHiddenInStackView = true
                        self.set5Stack.isHiddenInStackView = true
                        self.set3GamesPlayer1.alpha = 0
                        self.set3GamesPlayer2.alpha = 0
                        UIView.animate(withDuration: 1.2, animations: {
                            self.set3Stack.isHiddenInStackView = false
                            self.set3GamesPlayer1.alpha = 1
                            self.set3GamesPlayer2.alpha = 1
                        })
                    }
                }
            case 4:
                if MatchBrain.shared.playerOne.games == 0 && MatchBrain.shared.playerTwo.games == 0 && MatchBrain.shared.playerOne.points == 0 && MatchBrain.shared.playerTwo.points == 0 {
                    DispatchQueue.main.async {
                        self.set5Stack.isHiddenInStackView = true
                        self.set4GamesPlayer1.alpha = 0
                        self.set4GamesPlayer2.alpha = 0
                        UIView.animate(withDuration: 1.2, animations: {
                            self.set4Stack.isHiddenInStackView = false
                            self.set4GamesPlayer1.alpha = 1
                            self.set4GamesPlayer2.alpha = 1
                        })
                    }
                }
            case 5:
                if MatchBrain.shared.playerOne.games == 0 && MatchBrain.shared.playerTwo.games == 0 && MatchBrain.shared.playerOne.points == 0 && MatchBrain.shared.playerTwo.points == 0 {
                    DispatchQueue.main.async {
                        self.set5GamesPlayer1.alpha = 0
                        self.set5GamesPlayer2.alpha = 0
                        UIView.animate(withDuration: 1.2, animations: {
                            self.set5Stack.isHiddenInStackView = false
                            self.set5GamesPlayer1.alpha = 1
                            self.set5GamesPlayer2.alpha = 1
                        })
                    }
                }
            default:
                print("Error - MatchBrain set not between 1 and 5")
            }
        }
    }
    
    func undoPoint() {
        //Undo point in match data
        MatchBrain.shared.undoPoint()
        MatchBrain.shared.saveCoreData()
        
        //Update display with updated match data
        updateDisplayWithLoadedMatchData()
        hideSetsOnUndoPoint()
    }
    func hideSetsOnUndoPoint() {
        //Hides new set via animation if the point that was undone was the end of a set and triggered a new set
        UIView.animate(withDuration: 1.2, animations: {
            if MatchBrain.shared.set <= 4 {
                self.set5Stack.isHiddenInStackView = true
            }
            if MatchBrain.shared.set <= 3 {
                self.set4Stack.isHiddenInStackView = true
            }
            if MatchBrain.shared.set <= 2 {
                self.set3Stack.isHiddenInStackView = true
            }
            if MatchBrain.shared.set == 1 {
                self.set2Stack.isHiddenInStackView = true
            }
        })
    }
    
    func updateButtonDisplays() {
        //Used to update the player1 and player 2 button with their current point score and at Game Over
        //Also used for updating the Settings, Center, and Undo button with the current court color and at Game Over
        if MatchBrain.shared.gameOver {
            setCenterButton(buttonName: "checkmark.rectangle.fill")
            player1Button.isEnabled = false
            player2Button.isEnabled = false
            self.player1Name.text = "\(MatchSettings.player1Name)    "
            self.player2Name.text = "\(MatchSettings.player2Name)    "
        } else {
            setCenterButton(buttonName: "pause.rectangle.fill")
            player1Button.setTitle(MatchBrain.shared.playerOne.scoreString, for: .normal)
            player2Button.setTitle(MatchBrain.shared.playerTwo.scoreString, for: .normal)
        }
        setSettingsAndUndoButton()
    }
    func setCenterButton(buttonName: String) {
        //Sets Center Button color based on court color, and symbol based on Game Over
        var centerConfig = UIButton.Configuration.plain()
        centerConfig.image = UIImage(systemName: buttonName)
        var config = UIImage.SymbolConfiguration(paletteColors: [courtColorRGB!, .white])
        config = config.applying(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 38.0)))
        config = config.applying(UIImage.SymbolConfiguration(weight: .heavy))
        centerConfig.preferredSymbolConfigurationForImage = config
        centerButton.configuration = centerConfig
    }
    func setSettingsAndUndoButton() {
        //Sets Settings and Undo Buttons color based on court color
        var settingsAndUndoConfig = UIImage.SymbolConfiguration(paletteColors: [courtColorRGB!, .white])
        settingsAndUndoConfig = settingsAndUndoConfig.applying(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 33.0)))
        settingsAndUndoConfig = settingsAndUndoConfig.applying(UIImage.SymbolConfiguration(weight: .semibold))
        var settingsConfig = UIButton.Configuration.plain()
        settingsConfig.image = UIImage(systemName: "gearshape.circle.fill")
        settingsConfig.preferredSymbolConfigurationForImage = settingsAndUndoConfig
        settingsButton.configuration = settingsConfig
        var undoConfig = UIButton.Configuration.plain()
        undoConfig.image = UIImage(systemName: "arrow.uturn.backward.circle.fill")
        undoConfig.preferredSymbolConfigurationForImage = settingsAndUndoConfig
        undoButton.configuration = undoConfig
    }
    
    func setGameSetMatchPointImages() {
        //Self explanatory
        if MatchBrain.shared.breakPoint {
            self.gameSetMatchPointImage.setImage(UIImage(named: "\(MatchSettings.courtColor)BreakPoint"))
        }
        if MatchBrain.shared.tieBreak {
            self.gameSetMatchPointImage.setImage(UIImage(named: "\(MatchSettings.courtColor)TieBreaker"))
        }
        if MatchBrain.shared.setPoint {
            self.gameSetMatchPointImage.setImage(UIImage(named: "\(MatchSettings.courtColor)SetPoint"))
        }
        if MatchBrain.shared.matchPoint {
            self.gameSetMatchPointImage.setImage(UIImage(named: "\(MatchSettings.courtColor)MatchPoint"))
        }
        if MatchBrain.shared.gameOver {
            self.gameSetMatchPointImage.setImage(UIImage(named: "\(MatchSettings.courtColor)Final"))
        }
        
        if !MatchBrain.shared.breakPoint && !MatchBrain.shared.tieBreak && !MatchBrain.shared.setPoint && !MatchBrain.shared.matchPoint && !MatchBrain.shared.gameOver || MatchBrain.shared.buttonsLocked {
            self.gameSetMatchPointImage.setImage(nil)
        }
    }
    
    func setCourtColor() {
        tennisCourtImage.setImage(UIImage(named: "\(MatchSettings.courtColor)TennisCourt"))
        
        //Set RGB values based on color choice
        if MatchSettings.courtColor == "green" {
            courtColorRGB = UIColor(red: 67/255, green: 105/255, blue: 62/255, alpha: 1)
        } else if MatchSettings.courtColor == "purple" {
            courtColorRGB = UIColor(red: 188/255, green: 150/255, blue: 193/255, alpha: 1)
        } else if MatchSettings.courtColor == "blue" {
            courtColorRGB = UIColor(red: 26/255, green: 143/255, blue: 154/255, alpha: 1)
        } else if MatchSettings.courtColor == "pink" {
            courtColorRGB = UIColor(red: 229/255, green: 112/255, blue: 101/255, alpha: 1)
        } else {
            courtColorRGB = UIColor(red: 67/255, green: 105/255, blue: 62/255, alpha: 1)
        }
        
        //Decided to change the purple text color to not exactly match the purple court color. PUrely a design choice
        if MatchSettings.courtColor == "purple" {
            player1Name.textColor = UIColor(red: 147/255, green: 108/255, blue: 163/255, alpha: 1)
            player2Name.textColor = UIColor(red: 147/255, green: 108/255, blue: 163/255, alpha: 1)
        } else {
            player1Name.textColor = courtColorRGB!
            player2Name.textColor = courtColorRGB!
        }
        
        //This stops these displays from updating when settings menu is opened from the home screen. Purely a design choice to keep the court clean when a match isn't in session
        setSettingsAndUndoButton()
        if !MatchBrain.shared.buttonsLocked {
            updateButtonDisplays()
            setGameSetMatchPointImages()
        }
    }
    
    func setBestOfSetsStamp() {
        //Sets a "stamp" in the top left of the screen to indicate the length of the match being played
        bestOfStamp.setImage(UIImage(named: "bestOf\(MatchSettings.numberOfSets)White"))
    }
    
    
    // MARK: -  Onscreen Button Presses
    
    @IBAction func player1Scored(_ sender: UIButton) {
        if !MatchBrain.shared.buttonsLocked {
            updatePlayer1()
            //This if statent checks the user settings for whether or not the crowd cheer should play
            if MatchSettings.crowdCheers {
                announcerBooth.pointScored(winner: "playerOne")
            } else {
                announcerBooth.readScores(event: "playerOne", keepPoint: false)
            }
        }
    }
    
    @IBAction func player2Scored(_ sender: UIButton) {
        if !MatchBrain.shared.buttonsLocked {
            updatePlayer2()
            if MatchSettings.crowdCheers {
                //This if statent checks the user settings for whether or not the crowd cheer should play
                announcerBooth.pointScored(winner: "playerTwo")
            } else {
                announcerBooth.readScores(event: "playerTwo", keepPoint: false)
            }
        }
    }
    
    @IBAction func settingsButtonPressedDown(_ sender: UIButton) {
        //Custom button animation on press down
        settingsButton.alpha = 0.1
    }
    @IBAction func settingsButtonPressExit(_ sender: UIButton) {
        //Custom button animation on press exit
        UIView.animate(withDuration: 0.2, animations: {
            self.settingsButton.alpha = 1
        })
    }
    @IBAction func settingsButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "matchToSettings", sender: self)
        UIView.animate(withDuration: 0.2, animations: {
            self.settingsButton.alpha = 1
        })
    }
    
    @IBAction func centerButtonPressedDown(_ sender: UIButton) {
        //Custom button animation on press down
        centerButton.alpha = 0.1
    }
    @IBAction func centerButtonPressExit(_ sender: UIButton) {
        //Custom button animation on press exit
        UIView.animate(withDuration: 0.2, animations: {
            self.centerButton.alpha = 1
        })
    }
    @IBAction func centerButtonPressed(_ sender: UIButton) {
        centerButton.alpha = 1
        
        //Check if button is pausing or ending match based on game over state and display pop-up appropraitely
        var pauseTitle = String()
        var pauseMessage = String()
        var pauseAnnouncement = String()
        
        if !MatchBrain.shared.gameOver {
            pauseTitle = "Pause and Save Match?"
            pauseMessage = "This match will be saved to your Match History and can be resumed at any time"
            pauseAnnouncement = "Match Paused."
        } else {
            pauseTitle = "End and Save Match?"
            pauseMessage = "A new matcn can be started from the home screen at any time"
            pauseAnnouncement = ""
        }
        
        let pauseMatch = UIAlertController(title: pauseTitle, message: (MatchBrain.shared.gameOver ? nil : pauseMessage), preferredStyle: .actionSheet)
        pauseMatch.addAction(UIAlertAction(title: "OK", style: .default, handler: { [self] (action) -> Void in
            goToMatchHistory(pauseAnnouncement: pauseAnnouncement)
        }))
        pauseMatch.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
        }))
        
        self.present(pauseMatch, animated: true, completion: nil)
    }
    
    @IBAction func undoButtonPressedDown(_ sender: UIButton) {
        //Custom button animation on press down
        undoButton.alpha = 0.1
    }
    @IBAction func undoButtonPressExit(_ sender: UIButton) {
        //Custom button animation on press exit
        UIView.animate(withDuration: 0.2, animations: {
            self.undoButton.alpha = 1
        })
    }
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, animations: {
            self.undoButton.alpha = 1
        })
        
        //Check if there are any previous points saved and if undo is possible and display pop-up accordingly
        if MatchBrain.shared.undoMatchArray.count == 0 {
            let dialogMessage = UIAlertController(title: "Can't Undo!", message: "No previous points available.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
        } else {
            let undoPoint = UIAlertController(title: "Undo Point?", message: nil, preferredStyle: .actionSheet)
            undoPoint.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                self.undoPoint()
                self.announcerBooth.readScores(event: "undoPoint", keepPoint: false)
            }))
            undoPoint.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            }))
            self.present(undoPoint, animated: true, completion: nil)
        }
        
    }
    
    
    // MARK: -  AirPod functions
    
    func setupRemoteCommandCenter() {
        //enable app for remotecommandcenter to receive play/pause/next/previous commands from outside the app
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.playCommand.addTarget(self, action: #selector(playButtonPressed))
        commandCenter.pauseCommand.addTarget(self, action: #selector(pauseButtonPressed))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(nextTrackPressed))
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(previousTrackPressed))
        commandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(pauseButtonPressed))
    }
    
    @objc func playButtonPressed() -> MPRemoteCommandHandlerStatus {
        //This if statement prevents headphone clicks from triggering this method when a game is not in session
        if !MatchBrain.shared.buttonsLocked && !podsLocked {
            self.airPodPressed(command: "onePress")
        }
        return .success
    }
    
    @objc func pauseButtonPressed() -> MPRemoteCommandHandlerStatus {
        //This if statement prevents headphone clicks from triggering this method when a game is not in session
        if !MatchBrain.shared.buttonsLocked && !podsLocked {
            self.airPodPressed(command: "onePress")
        }
        return .commandFailed
    }
    
    @objc func nextTrackPressed() -> MPRemoteCommandHandlerStatus {
        //This if statement prevents headphone clicks from triggering this method when a game is not in session
        if !MatchBrain.shared.buttonsLocked && !podsLocked {
            self.airPodPressed(command: "twoPress")
        }
        return .success
    }
    
    @objc func previousTrackPressed() -> MPRemoteCommandHandlerStatus {
        //This if statement prevents headphone clicks from triggering this method when a game is not in session
        if !MatchBrain.shared.buttonsLocked && !podsLocked {
            self.airPodPressed(command: "threePress")
        }
        return .success
    }
    
    func airPodPressed(command: String) {
        //First check if user is navigating through the undoPrompt
        if undoPrompt {
            if command == "onePress" {
                self.undoPoint()
                announcerBooth.readScores(event: "undoPoint", keepPoint: false)
                undoPrompt = false
            } else {
                announcerBooth.readScores(event: lastPointWinner, keepPoint: true)
                undoPrompt = false
            }
        } else {
            if command == "onePress" {
                //If not currently game over, give point to player 1
                if !MatchBrain.shared.gameOver {
                    updatePlayer1()
                }
                
                //This triggers the sore to be read regardless if it is gameover or not. If it is gameover, the same score will continue to be read each time this is pressed
                if MatchSettings.crowdCheers {
                    announcerBooth.pointScored(winner: "playerOne")
                } else {
                    announcerBooth.readScores(event: "playerOne", keepPoint: false)
                }
                
                //lock AirPods scoring for ~4 seconds to prevent accidental scoring by both players
                self.podsLockedTimer()
                
                //this call is to update the playback time in the event the pause/play button on the lock screen was used. Ok to delete if lock screen buttons are disabled
                //announcerBooth.beginMatchAudio(time: MatchBrain.shared.match!.duration)
            } else if command == "twoPress" {
                //If not currently game over, give point to player 2
                if !MatchBrain.shared.gameOver {
                    updatePlayer2()
                }
                
                //This triggers the sore to be read regardless if it is gameover or not. If it is gameover, the same score will continue to be read each time this is pressed
                if MatchSettings.crowdCheers {
                    announcerBooth.pointScored(winner: "playerTwo")
                } else {
                    announcerBooth.readScores(event: "playerTwo", keepPoint: false)
                }
                
                //lock AirPods scoring for ~4 seconds to prevent accidental scoring by both players
                self.podsLockedTimer()
            } else if command == "threePress" {
                //User is entering into undoPromt and can trigger the last point to be undone
                if MatchBrain.shared.undoMatchArray.count == 0 {
                    let prompt = "No previous points available."
                    announcerBooth.speak(script: prompt)
                } else {
                    let prompt = "Re-Play last point? Press once to Confirm, and twice to Cancel."
                    announcerBooth.speak(script: prompt)
                    undoPrompt = true
                    
                    randomKey = randomString(length: 5)
                    self.undoPromptTimer(key: randomKey)
                }
            } else {}
        }
    }
    
    func podsLockedTimer() {
        //This pauses AirPod functionality for 4 seconds after a point was scored. Since both players can trigger a point scored, this prevents two points from being accidentally scored in quick succession if both players attempt to log the previous point at the same time.
        podsLocked = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.podsLocked = false
        }
    }
    
    func undoPromptTimer(key: String) {
        //This exits the user from the undoPrompt if they don't make a decision within 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if key == self.randomKey{
                if self.undoPrompt {
                    self.announcerBooth.readScores(event: self.lastPointWinner, keepPoint: true)
                    self.undoPrompt = false
                }
            }
        }
    }
    func randomString(length: Int) -> String {
        //creates a random key that is set to prevent the above undoPromptTimer from being triggered once the user makes their choice
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func areAirPodsConnected(sender: String) {
        //check if AirPods are connected before starting match. Match can still be played without them, but this triggers a message to the user reminding them that the app is designed to be used with headphones
        let availableOutputs = AVAudioSession.sharedInstance().currentRoute.outputs
        for portDescription in availableOutputs {
            if portDescription.portType == AVAudioSession.Port.bluetoothA2DP || portDescription.portType == AVAudioSession.Port.bluetoothHFP || portDescription.portType == AVAudioSession.Port.bluetoothLE {
                MatchBrain.shared.buttonsLocked = false
                setGameSetMatchPointImages()
                announcerBooth.readScores(event: sender, keepPoint: false)
            } else {
                let dialogMessage = UIAlertController(title: "No Headphones Detected!", message: "Center Court is designed to be used with AirPods for effortless in-game scorekeeping. Please connect bluetooth headphones now, and refer to the instructions in the Settings menu for more detail", preferredStyle: .alert)
                let ok = UIAlertAction(title: "Start Match", style: .default, handler: { (action) -> Void in
                    MatchBrain.shared.buttonsLocked = false
                    self.setGameSetMatchPointImages()
                    self.announcerBooth.readScores(event: sender, keepPoint: false)
                })
                dialogMessage.addAction(ok)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.present(dialogMessage, animated: true, completion: nil)
                }
                self.announcerBooth.speak(script: "No Headphones Detected! Please connect bluetooth headphones now.")
            }
        }
    }
    
    
    // MARK: -  Navigation
    
    func goToMatchHistory(pauseAnnouncement: String) {
        //gets called when a match is paused mid-game and when a gameOver match is ended
        
        //reset all onscreen match displays first as this screen is still visible behind the home and match history screen
        UIView.animate(withDuration: 0.6, animations: {
            self.bestOfStamp.setImage(nil)
            self.gameSetMatchPointImage.setImage(nil)
            self.set2Stack.isHiddenInStackView = true
            self.set3Stack.isHiddenInStackView = true
            self.set4Stack.isHiddenInStackView = true
            self.set5Stack.isHiddenInStackView = true
            self.player1Button.setTitle("0", for: .normal)
            self.player2Button.setTitle("0", for: .normal)
            self.set1GamesPlayer1.attributedText = NSMutableAttributedString(string: "0")
            self.set1GamesPlayer2.attributedText = NSMutableAttributedString(string: "0")
            self.player1Name.isHiddenInStackView = true
            self.player2Name.isHiddenInStackView = true
        })
        //Save match data and update MatchBrain settings
        MatchBrain.shared.saveCoreData()
        MatchBrain.shared.undoMatchArray.removeAll()
        MatchBrain.shared.buttonsLocked = true
        MatchBrain.shared.isPaused = true
        
        //annoucne end or pause of match, stop match audio to clear NowPlayingInfoCenter
        announcerBooth.speak(script: pauseAnnouncement)
        announcerBooth.stopMatchAudio()
        
        //open HomeViewController which will then handle the transition to the MatchSettingsViewController
        performSegue(withIdentifier: "goHome", sender: self)
    }
    
    func goToInstructions() {
        //opens InstructionsViewController but first sets a flag to prevent another sugue to the HomeViewController when InstructionsViewController is closed
        instructionsOpen = true
        performSegue(withIdentifier: "matchToInstructions", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goHome" {
            //sets MatchViewController as delegate of HomeViewController
            let destinationVC = segue.destination as! HomeViewController
            destinationVC.delegate = self
        }
        if segue.identifier == "matchToSettings" {
            //sets MatchViewController as delegate of MatchSettingsViewController
            let destinationVC = segue.destination as! MatchSettingsViewController
            destinationVC.delegate = self
        }
        if segue.identifier == "matchToInstructions" {
            //take screenshot of current screen
            //This below warning can be ignored as the app does not supportt multiple screens
            let layer = UIApplication.shared.keyWindow!.layer
            let scale = UIScreen.main.scale
            UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale)
            layer.render(in: UIGraphicsGetCurrentContext()!)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            //sets above screenshot as background of InstructionsViewController. Very sneaky sneaky
            let destinationVC = segue.destination as! InstructionsViewController
            destinationVC.screenShot = screenshot
        }
    }
    
}

// MARK: - UIView, UIImageView, and UILabel Extensions

//This solves a known bug where hiding and showing views in a stack view is cumulative. Use new isHiddenInStackView variable instead of isHidden
extension UIView {
    var isHiddenInStackView: Bool {
        get {
            return isHidden
        }
        set {
            if isHidden != newValue {
                isHidden = newValue
            }
        }
    }
}

//Creates animated fade transition when setting new image in imageview
extension UIImageView{
    func setImage(_ image: UIImage?, animated: Bool = true) {
        let duration = animated ? 0.5 : 0.0
        UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve, animations: {
            self.image = image
        }, completion: nil)
    }
}

//Adds Tennis Ball to label text to indicate which player is serving
extension UILabel {
    func addTennisBall() {
        let titleFont = UIFont(name: "Arial Rounded MT Bold", size: 25)
        let tennisBall = UIImage(systemName: "tennisball.fill")
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: (titleFont!.capHeight - tennisBall!.size.height).rounded() / 2, width: tennisBall!.size.width, height: tennisBall!.size.height)
        attachment.image = tennisBall?.withTintColor(UIColor(red: 160/255, green: 195/255, blue: 0/255, alpha: 1))
        let attachmentString = NSAttributedString(attachment: attachment)
        let string = NSMutableAttributedString(string: self.text!.trimmingCharacters(in: .whitespaces), attributes: [:])
        let oneSpaceString = NSAttributedString(string: " ")
        let threeSpaceString = NSAttributedString(string: "   ")
        string.append(oneSpaceString)
        string.append(attachmentString)
        string.append(threeSpaceString)
        self.attributedText = string
    }
}
