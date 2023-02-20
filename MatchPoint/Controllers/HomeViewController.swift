//
//  HomeViewController.swift
//  MatchPoint
//
//  Created by Charles Prutting on 8/31/22.
//

import UIKit
import AVFAudio

protocol HomeViewControllerDelegate {
    func newMatch()
    func resumeMatch(date: Date)
    func setCourtColor()
}

class HomeViewController: UIViewController, MatchHistoryViewControllerDelegate, MatchSettingsViewControllerDelegate {
    
    var delegate: HomeViewControllerDelegate?
    var announcerBooth = AnnouncerBooth()
    
    @IBOutlet weak var player1TextField: UITextField!
    @IBOutlet weak var player2TextField: UITextField!
    @IBOutlet weak var numberOfSets: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player1TextField.delegate = self
        player2TextField.delegate = self
        initializeSetsSliderColor()
        
        //makes it so you can't close viewController by swiping down
        self.isModalInPresentation = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        //checks if app should trigger segue to MatchHistory
        if MatchBrain.shared.isPaused {
            performSegue(withIdentifier: "MatchHistory", sender: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //checks if we should auto open istructions based on first time using the app.
        if !MatchSettings.hasOpenedAppBefore {
            self.goToInstructions()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //closes keyboard if user touches screen outside keyboard
        view.endEditing(true)
    }
    
    func initializeSetsSliderColor() {
        //sets the color of the set slider. These changes could not be made in storyboard
        let segmentNormalTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let segmentSelectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red: 48/255, green: 84/255, blue: 53/255, alpha: 1)]
        numberOfSets.setTitleTextAttributes(segmentNormalTextAttributes, for: .normal)
        numberOfSets.setTitleTextAttributes(segmentSelectedTextAttributes, for: .selected)
    }
    
    // MARK: -  Start New Match
    
    @IBAction func startNewMatchPressed(_ sender: UIButton) {
        //checks if both player names have been entered and makes sure names are not exactly the same
        if player1TextField.text == "" || player2TextField.text == "" {
            let dialogMessage = UIAlertController(title: "Enter Player Names", message: "One or both player names are empty", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
        } else if player1TextField.text?.trimmingCharacters(in: .whitespaces).lowercased() == player2TextField.text?.trimmingCharacters(in: .whitespaces).lowercased() {
            let dialogMessage = UIAlertController(title: "Duplicate Player Names", message: "Player names can not be identical", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
        } else {
            self.startMatch()
        }
    }
    
    func startMatch() {
        //sets player names and length of match and starts the match
        let trimmedP1String = player1TextField.text!.trimmingCharacters(in: .whitespaces).capitalized
        let trimmedP2String = player2TextField.text!.trimmingCharacters(in: .whitespaces).capitalized
        MatchSettings.player1Name = trimmedP1String
        MatchSettings.player2Name = trimmedP2String
        MatchSettings.numberOfSets = numberOfSets.selectedSegmentIndex + 1
        
        delegate?.newMatch()
        dismiss(animated: true)
    }
    
    
    //MARK: - Navigation
    
    func goToInstructions() {
        performSegue(withIdentifier: "homeToInstructions", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MatchHistory" {
            let destinationVC = segue.destination as! MatchHistoryViewController
            destinationVC.delegate = self
        }
        if segue.identifier == "homeToSettings" {
            let destinationVC = segue.destination as! MatchSettingsViewController
            destinationVC.delegate = self
        }
        if segue.identifier == "homeToInstructions" {
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
    
    //MARK: - Delegate Protol Methods
    
    func resumeMatch(date: Date) {
        //triggers resume match function when triggered from MatchHistory
        dismiss(animated: true)
        delegate?.resumeMatch(date: date)
    }
    
    func setCourtColor() {
        //sets court coller on MatchViewController when changed in MatchSettings
        delegate?.setCourtColor()
    }
    
    //unused relic protocol methods needed to make HomeViewController a delegate of MatchSettingsViewContoller
    func goToMatchHistory(pauseAnnouncement: String) {
    }
    func setBestOfSetsStamp() {
    }
}

//MARK: - UITextFieldDelegate Extension

extension HomeViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
}

