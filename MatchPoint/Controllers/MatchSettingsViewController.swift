//
//  MatchSettingsViewController.swift
//  MatchPoint
//
//  Created by Charles Prutting on 10/3/22.
//

import UIKit

protocol MatchSettingsViewControllerDelegate {
    func setCourtColor()
    func setBestOfSetsStamp()
    func goToMatchHistory(pauseAnnouncement: String)
    func goToInstructions()
}

class MatchSettingsViewController: UIViewController {
    
    @IBOutlet weak var announcePointWinnerOnOff: UISegmentedControl!
    @IBOutlet weak var crowdCheersOnOff: UISegmentedControl!
    @IBOutlet weak var greenTennisCourtButton: UIButton!
    @IBOutlet weak var purpleTennisCourtButton: UIButton!
    @IBOutlet weak var blueTennisCourtButton: UIButton!
    @IBOutlet weak var pinkTennisCourtButton: UIButton!
    @IBOutlet weak var numberOfSets: UISegmentedControl!
    @IBOutlet weak var player1Resigns: UIButton!
    @IBOutlet weak var player2Resigns: UIButton!
    
    var delegate: MatchSettingsViewControllerDelegate?
    var playerResigning = ""
    var playerWinning = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialDisplaySetup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //resets court color every time settings is closed, and checks if settings was closed to resign a player
        delegate?.setCourtColor()
        if playerResigning != "" {
            delegate?.goToMatchHistory(pauseAnnouncement: "\(playerResigning) resigns!… Game, Set, and Match, \(playerWinning)!")
        }
    }
    
    func initialDisplaySetup() {
        //sets display of settings based on users past set preferences
        if MatchSettings.announcePointWinnerEachPoint {
            announcePointWinnerOnOff.selectedSegmentIndex = 0
        } else {
            announcePointWinnerOnOff.selectedSegmentIndex = 1
        }
        
        if MatchSettings.crowdCheers {
            crowdCheersOnOff.selectedSegmentIndex = 0
        } else {
            crowdCheersOnOff.selectedSegmentIndex = 1
        }
        
        if MatchSettings.courtColor == "green" {
            addCourtBorder(button: greenTennisCourtButton)
        } else if MatchSettings.courtColor == "purple" {
            addCourtBorder(button: purpleTennisCourtButton)
        } else if MatchSettings.courtColor == "blue" {
            addCourtBorder(button: blueTennisCourtButton)
        } else if MatchSettings.courtColor == "pink" {
            addCourtBorder(button: pinkTennisCourtButton)
        }
        
        //turns numberOfsets switch and player resign buttons on or off depending on whether a match is in session or not
        if MatchBrain.shared.buttonsLocked {
            numberOfSets.isEnabled = false
            
            player1Resigns.setTitle("Player 1\("\n")Resigns", for: .normal)
            player2Resigns.setTitle("Player 2\("\n")Resigns", for: .normal)
            player1Resigns.isEnabled = false
            player2Resigns.isEnabled = false
        } else {
            numberOfSets.selectedSegmentIndex = (MatchSettings.numberOfSets - 1)
            if MatchBrain.shared.gameOver {
                numberOfSets.isEnabled = false
                player1Resigns.isEnabled = false
                player2Resigns.isEnabled = false
            } else {
                numberOfSets.isEnabled = true
                player1Resigns.isEnabled = true
                player2Resigns.isEnabled = true
            }
            if MatchBrain.shared.playerOne.sets > 0 || MatchBrain.shared.playerTwo.sets > 0 {
                numberOfSets.setEnabled(false, forSegmentAt: 0)
            }
            if MatchBrain.shared.playerOne.sets > 1 || MatchBrain.shared.playerTwo.sets > 1 {
                numberOfSets.setEnabled(false, forSegmentAt: 1)
            }
            
            player1Resigns.setTitle("\(MatchSettings.player1Name)\("\n")Resigns", for: .normal)
            player2Resigns.setTitle("\(MatchSettings.player2Name)\("\n")Resigns", for: .normal)
        }
        player1Resigns.titleLabel?.textAlignment = .center
        player2Resigns.titleLabel?.textAlignment = .center
    }
    
    func clearCourtBorders() {
        //clears border from all court color selections
        greenTennisCourtButton.layer.borderWidth = 0
        purpleTennisCourtButton.layer.borderWidth = 0
        blueTennisCourtButton.layer.borderWidth = 0
        pinkTennisCourtButton.layer.borderWidth = 0
    }
    func addCourtBorder(button: UIButton) {
        //sets bortder on selected court color
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 4
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 5
        button.layer.shadowOffset = .zero
        button.layer.shadowOpacity = 0.6
    }
    
    //MARK: - IBActions(Settings Toggled!)
    
    @IBAction func announcePointWinnerToggled(_ sender: UISegmentedControl) {
        if announcePointWinnerOnOff.selectedSegmentIndex == 0 {
            MatchSettings.announcePointWinnerEachPoint = true
        } else if announcePointWinnerOnOff.selectedSegmentIndex == 1 {
            MatchSettings.announcePointWinnerEachPoint = false
        }
    }
    
    @IBAction func crowdCheersToggled(_ sender: UISegmentedControl) {
        if crowdCheersOnOff.selectedSegmentIndex == 0 {
            MatchSettings.crowdCheers = true
        } else if crowdCheersOnOff.selectedSegmentIndex == 1 {
            MatchSettings.crowdCheers = false
        }
    }
    
    @IBAction func instructionsSelected(_ sender: UIButton) {
        dismiss(animated: true)
        //delay used to give app time to take screenshot of the below viewController(Match or Home) before displaying instructions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            self.delegate?.goToInstructions()
        }
    }
    
    @IBAction func greenTennisCourtSelected(_ sender: UIButton) {
        clearCourtBorders()
        addCourtBorder(button: greenTennisCourtButton)
        MatchSettings.courtColor = "green"
    }
    
    @IBAction func purpleTennisCourtSelected(_ sender: UIButton) {
        clearCourtBorders()
        addCourtBorder(button: purpleTennisCourtButton)
        MatchSettings.courtColor = "purple"
    }
    
    @IBAction func blueTennisCourtSelected(_ sender: UIButton) {
        clearCourtBorders()
        addCourtBorder(button: blueTennisCourtButton)
        MatchSettings.courtColor = "blue"
    }
    
    @IBAction func pinkTennisCourtSelected(_ sender: UIButton) {
        clearCourtBorders()
        addCourtBorder(button: pinkTennisCourtButton)
        MatchSettings.courtColor = "pink"
    }
    
    @IBAction func changedNumberOfSets(_ sender: UISegmentedControl) {
        //set confirmation message display based on selected number of sets change
        
        var numberOfSetsString: String
        if numberOfSets.selectedSegmentIndex == 0 {
            numberOfSetsString = "SINGLE SET"
        } else if numberOfSets.selectedSegmentIndex == 1 {
            numberOfSetsString = "best of THREE SETS"
        } else {
            numberOfSetsString = "best of FIVE SETS"
        }
        
        let resignMatch = UIAlertController(title: "Change Match Length", message: "Are you sure you want to change this Match to a \(numberOfSetsString)?", preferredStyle: .actionSheet)
        resignMatch.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [self] (action) -> Void in
            MatchSettings.numberOfSets = numberOfSets.selectedSegmentIndex + 1
            MatchBrain.shared.updateMatchCoreData()
            delegate?.setBestOfSetsStamp()
            dismiss(animated: true)
        }))
        resignMatch.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [self] (action) -> Void in
            numberOfSets.selectedSegmentIndex = (MatchSettings.numberOfSets - 1)
        }))
        
        self.present(resignMatch, animated: true, completion: nil)
    }
    
    @IBAction func player1Resigns(_ sender: UIButton) {
        playerResigning = MatchSettings.player1Name
        playerWinning = MatchSettings.player2Name
        resignPlayer(player: "one")
    }
    
    @IBAction func player2Resigns(_ sender: UIButton) {
        playerResigning = MatchSettings.player2Name
        playerWinning = MatchSettings.player1Name
        resignPlayer(player: "two")
    }
    
    func resignPlayer(player: String) {
        //set confirmation message based on who is resigning
        
        let resignMatch = UIAlertController(title: "End Match", message: "Are you sure \(playerResigning.capitalized) wants to resign this Match to \(playerWinning.capitalized)?", preferredStyle: .actionSheet)
        resignMatch.addAction(UIAlertAction(title: "\(playerResigning) Resigns", style: .destructive, handler: { [self] (action) -> Void in
            if player == "one" {
                MatchBrain.shared.playerOne.resigned = true
                MatchBrain.shared.playerTwo.isWinner = true
            } else if player == "two" {
                MatchBrain.shared.playerTwo.resigned = true
                MatchBrain.shared.playerOne.isWinner = true
            }
            MatchBrain.shared.gameOver = true
            MatchBrain.shared.updateMatchCoreData()
            dismiss(animated: true)
        }))
        resignMatch.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [self] (action) -> Void in
            playerResigning = ""
        }))
        
        self.present(resignMatch, animated: true, completion: nil)
    }
    
    //MARK: - Navigation
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
}
