//
//  MatchHistoryViewController.swift
//  MatchPoint
//
//  Created by Charles Prutting on 10/1/22.
//

import UIKit
import CoreData

protocol MatchHistoryViewControllerDelegate {
    func resumeMatch(date: Date)
}

class MatchHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var savedMatches = false
    var delegate: MatchHistoryViewControllerDelegate?
    var matchArray = [Match]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize table view settings, searchbBar functions, and load match data
        initializeTableView()
        initializeSearchClearButton()
        loadMatchHistory()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    
    // MARK: - Table View Methods
    
    func initializeTableView() {
        //set tableView settings
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "MatchHistoryCell", bundle: nil), forCellReuseIdentifier: "ReusableCell")
        tableView.contentOffset = CGPointMake(0, searchBar.bounds.height)
        tableView.keyboardDismissMode = .onDrag
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //set a minimum of one tableView rows
        if matchArray.count == 0 {
            return 1
        } else {
            return matchArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if matchArray.count == 0 {
            //First check if there are no saved matches, or matches returned from search query, and if so return placeholder cell
            
            let noMatchCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var text = String()
            if !savedMatches {
                //sets placeholder cell for no saved matches
                tableView.rowHeight = 240
                tableView.contentSize.height = 240
                text = """
    YOU HAVE NO MATCHES SAVED!
    
    After you have started at least one match from the home screen, you will have a detailed history of all matches played. From here, you will also be able to open and continue any in-progress match you had previously paused.
         
    -Enjoy!
    """
            } else {
                //sets placeholder cell for no matches meeting search query
                tableView.rowHeight = 180
                tableView.contentSize.height = 180
                text = """
    NO MATCHES PLAYED AGAINST "\(searchBar.text!.uppercased())"!
    
    We can't find any matches you've played against \(searchBar.text!), but you should invite them to play! Who would win between you two? Only time will tell!
         
    -Enjoy!
    """
            }
            
            if #available(iOS 14.0, *) {
                var content = noMatchCell.defaultContentConfiguration()
                content.text = text
                content.textProperties.color = .systemGray
                content.textProperties.font = UIFont(name: "Arial Rounded MT Bold", size: 16)!
                noMatchCell.contentConfiguration = content
                
            } else {
                tableView.rowHeight = 80
                noMatchCell.textLabel?.text = text
                noMatchCell.textLabel?.font = UIFont(name: "Arial Rounded MT Bold", size: 16)!
                noMatchCell.textLabel?.textColor = .systemGray
            }
            return noMatchCell
        } else {
            //Begin stylizing match history cell for finalized and in-progress matches
            tableView.rowHeight = 130
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReusableCell", for: indexPath) as! MatchHistoryCellController
            cell.backgroundColor = indexPath.row % 2 == 0 ? UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1) : .white
            
            //converts and sets date data
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            let formattedDate = formatter.string(from: matchArray[indexPath.row].date!)
            cell.date.text = "Date: \(formattedDate)"
            //comverts and sets match duration data
            let (h,m,_) = secondsToHoursMinutesSeconds(Int(matchArray[indexPath.row].duration))
            if m < 10 {
                cell.matchDuration.text = "Duration: \(h):0\(m)"
            } else {
                cell.matchDuration.text = "Duration: \(h):\(m)"
            }
            
            //sets player names and pulls player objects from match object
            cell.player1Name.text = matchArray[indexPath.row].player1Name?.uppercased()
            cell.player2Name.text = matchArray[indexPath.row].player2Name?.uppercased()
            let playerOne = matchArray[indexPath.row].players?.object(at: 0) as! Player
            let playerTwo = matchArray[indexPath.row].players?.object(at: 1) as! Player
            
            //Adds highlited border to paused match - will stop being displayed after any navigation away from screen
            if indexPath.row == 0 {
                if MatchBrain.shared.isPaused {
                    cell.contentView.layer.cornerRadius = 12
                    cell.contentView.layer.borderWidth = 3
                    cell.contentView.layer.borderColor = UIColor(red: 79/255, green: 154/255, blue: 81/255, alpha: 0.97).cgColor
                    cell.contentView.clipsToBounds = true
                }
            } else {
                cell.contentView.layer.borderWidth = 0
                cell.contentView.layer.cornerRadius = 0
            }
            
            //Begin by blank-ing all sets but first, and then fill in subsequent set scores as needed
            if matchArray[indexPath.row].numberOfSets >= 1 {
                cell.player1Set1.attributedText = unAtttributedStringConverter(unAtrbString: ((playerOne.set1Games)!))
                cell.player2Set1.attributedText = unAtttributedStringConverter(unAtrbString: ((playerTwo.set1Games)!))
                cell.player1Set2.text = ""
                cell.player1Set3.text = ""
                cell.player1Set4.text = ""
                cell.player1Set5.text = ""
                cell.player2Set2.text = ""
                cell.player2Set3.text = ""
                cell.player2Set4.text = ""
                cell.player2Set5.text = ""
            }
            if matchArray[indexPath.row].numberOfSets >= 2 {
                cell.player1Set2.attributedText = unAtttributedStringConverter(unAtrbString: ((playerOne.set2Games)!))
                cell.player1Set3.attributedText = unAtttributedStringConverter(unAtrbString: ((playerOne.set3Games)!))
                cell.player2Set2.attributedText = unAtttributedStringConverter(unAtrbString: ((playerTwo.set2Games)!))
                cell.player2Set3.attributedText = unAtttributedStringConverter(unAtrbString: ((playerTwo.set3Games)!))
            }
            if matchArray[indexPath.row].numberOfSets >= 3 {
                cell.player1Set4.attributedText = unAtttributedStringConverter(unAtrbString: ((playerOne.set4Games)!))
                cell.player1Set5.attributedText = unAtttributedStringConverter(unAtrbString: ((playerOne.set5Games)!))
                cell.player2Set4.attributedText = unAtttributedStringConverter(unAtrbString: ((playerTwo.set4Games)!))
                cell.player2Set5.attributedText = unAtttributedStringConverter(unAtrbString: ((playerTwo.set5Games)!))
            }
            //Add dashes to remaining unplayed possible sets in match
            if matchArray[indexPath.row].numberOfSets >= 2 {
                if (Int(playerOne.sets) + Int(playerTwo.sets)) < 1 {
                    cell.player1Set2.text = "-"
                    cell.player2Set2.text = "-"
                }
                if (Int(playerOne.sets) + Int(playerTwo.sets)) < 2 {
                    cell.player1Set3.text = "-"
                    cell.player2Set3.text = "-"
                }
            }
            if matchArray[indexPath.row].numberOfSets == 3 {
                if (Int(playerOne.sets) + Int(playerTwo.sets)) < 3 {
                    cell.player1Set4.text = "-"
                    cell.player2Set4.text = "-"
                }
                if (Int(playerOne.sets) + Int(playerTwo.sets)) < 4 {
                    cell.player1Set5.text = "-"
                    cell.player2Set5.text = "-"
                }
            }
            
            //Change stylizing for gameOver dependant elements
            if matchArray[indexPath.row].gameOver {
                cell.resumeMatch.text = "FINAL"
                cell.resumeMatch.backgroundColor = UIColor.black
                cell.player1Points.isHiddenInStackView = true
                cell.player2Points.isHiddenInStackView = true
                cell.player1Serving.image = nil
                cell.player2Serving.image = nil
                
                if !playerOne.resigned && !playerTwo.resigned {
                    if matchArray[indexPath.row].numberOfSets == 2 {
                        if (Int(playerOne.sets) + Int(playerTwo.sets)) < 3 {
                            cell.player1Set3.text = ""
                            cell.player2Set3.text = ""
                        }
                    }
                    if matchArray[indexPath.row].numberOfSets == 3 {
                        if (Int(playerOne.sets) + Int(playerTwo.sets)) < 4 {
                            cell.player1Set4.text = ""
                            cell.player2Set4.text = ""
                        }
                        if (Int(playerOne.sets) + Int(playerTwo.sets)) < 5 {
                            cell.player1Set5.text = ""
                            cell.player2Set5.text = ""
                        }
                    }
                }
                
                if playerOne.isWinner {
                    cell.player1Name.textColor = UIColor(red: 79/255, green: 154/255, blue: 81/255, alpha: 1)
                    cell.player2Name.textColor = UIColor.black
                    cell.player1Wins.isHiddenInStackView = false
                    cell.player2Wins.isHiddenInStackView = true
                    cell.player1Wins.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
                } else {
                    cell.player2Name.textColor = UIColor(red: 79/255, green: 154/255, blue: 81/255, alpha: 1)
                    cell.player1Name.textColor = UIColor.black
                    cell.player2Wins.isHiddenInStackView = false
                    cell.player1Wins.isHiddenInStackView = true
                    cell.player2Wins.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
                }
                if playerOne.resigned {
                    cell.player1Name.attributedText = resignedPlayerNameAttrStringConverter(playerName: (matchArray[indexPath.row].player1Name?.uppercased())!)
                } else if playerTwo.resigned {
                    cell.player2Name.attributedText = resignedPlayerNameAttrStringConverter(playerName: (matchArray[indexPath.row].player2Name?.uppercased())!)
                }
            } else {
                //final stylizing for game-not-over matches
                if playerOne.isServing {
                    cell.player1Serving.image = UIImage(systemName: "tennisball.fill")
                    cell.player2Serving.image = nil
                } else if playerTwo.isServing {
                    cell.player1Serving.image = nil
                    cell.player2Serving.image = UIImage(systemName: "tennisball.fill")
                }
                cell.player1Name.textColor = UIColor.black
                cell.player2Name.textColor = UIColor.black
                cell.player1Points.isHiddenInStackView = false
                cell.player2Points.isHiddenInStackView = false
                cell.player1Points.text = playerOne.scoreString
                cell.player2Points.text = playerTwo.scoreString
                cell.player1Wins.isHiddenInStackView = true
                cell.player2Wins.isHiddenInStackView = true
                cell.resumeMatch.text = "RESUME"
                cell.resumeMatch.backgroundColor = UIColor(red: 79/255, green: 154/255, blue: 81/255, alpha: 1)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //close keyboard if open
        self.searchBar.resignFirstResponder()
        if matchArray.count == 0 {
            //can't turn select placeholder cell
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            if let date = matchArray[indexPath.row].date {
                if matchArray[indexPath.row].gameOver {
                    //can't select gameOver matches
                    tableView.deselectRow(at: indexPath, animated: true)
                } else {
                    //open confirmation message before resuming match
                    let resumeMatch = UIAlertController(title: "Resume Match?", message: nil, preferredStyle: .actionSheet)
                    resumeMatch.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        if MatchBrain.shared.isPaused {
                            MatchBrain.shared.isPaused = false
                        }
                        self.dismiss(animated: false)
                        self.delegate?.resumeMatch(date: date)
                    }))
                    resumeMatch.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
                        tableView.deselectRow(at: indexPath, animated: true)
                    }))
                    self.present(resumeMatch, animated: true, completion: nil)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        //close keyboard if open
        dismissKeyboard()
        if matchArray.count != 0 {
            //create swipe to delete action if not placeholder cell
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
                let deleteMatch = UIAlertController(title: "Delete Match?", message: nil, preferredStyle: .actionSheet)
                deleteMatch.addAction(UIAlertAction(title: "DELETE", style: .destructive, handler: { (action) -> Void in
                    self.context.delete(self.matchArray[indexPath.row])
                    self.matchArray.remove(at: indexPath.row)
                    self.saveCoreData()
                    
                    //checks if the deleted match was the last saved match, and if so, reloadsTableView to display placeholder cell
                    if self.matchArray.count == 0 {
                        tableView.reloadData()
                    } else {
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                    
                    //checks if the deleted match was currently higlighted and makes it so the new match at the top of the list doesn't get highlighted
                    if indexPath.row == 0 {
                        if MatchBrain.shared.isPaused {
                            MatchBrain.shared.isPaused = false
                        }
                    }
                    
                    completionHandler(true)
                }))
                deleteMatch.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
                    completionHandler(true)
                }))
                self.present(deleteMatch, animated: true, completion: nil)
            }
            //set image and color of delete button
            deleteAction.image = UIImage(systemName: "trash")
            deleteAction.backgroundColor = .systemRed
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
        } else {
            return nil
        }
    }
    
    
    // MARK: - Search Bar Methods
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //a search is triggered while the user is typing, so the search button is just used to clear the keyboard
        dismissKeyboard()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //peform new match data search after every letter typed
        //start by loading all matches back into matchArray each time
        loadMatchHistory()
        if searchBar.text!.count == 0 {
            //if nothing yped in search bar, display entire matchArray
            self.tableView.reloadData()
        } else {
            //sort matchArray to remove any matches that don't contain the searched for player name
            let searchText = searchBar.text!.lowercased()
            matchArray = matchArray.filter({ $0.player1Name!.lowercased().contains(searchText) || $0.player2Name!.lowercased().contains(searchText) })
            
            //turns off highlighting of top listed match
            if MatchBrain.shared.isPaused {
                MatchBrain.shared.isPaused = false
            }
            
            self.tableView.reloadData()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //clears keyboard when user touches outside keyboard or searchbar
        view.endEditing(true)
    }
    
    func initializeSearchClearButton() {
        if let searchTextField = self.searchBar.value(forKey: "searchField") as? UITextField , let clearButton = searchTextField.value(forKey: "_clearButton")as? UIButton {
            clearButton.addTarget(self, action: #selector(self.dismissKeyboard), for: .touchUpInside)
        }
    }
    
    @objc func dismissKeyboard() {
        DispatchQueue.main.async {
            self.searchBar.resignFirstResponder()
        }
    }
    
    
    // MARK: - Navigation
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        //turns off highlighting of top listed match for the next time matchHistory is navigated to
        if MatchBrain.shared.isPaused {
            MatchBrain.shared.isPaused = false
        }
        
        dismiss(animated: true)
    }
    
    
    //MARK: - Data Manipulation Methods
    
    func loadMatchHistory() {
        //fill matchArray with all saved matches starting with the most recently played match
        let matchRequest: NSFetchRequest<Match> = Match.fetchRequest()
        matchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        do {
            matchArray =  try context.fetch(matchRequest)
            if matchArray.count == 0 {
                savedMatches = false
            } else {
                savedMatches = true
            }
        } catch {
            print("Error fetching data from context \(error)")
        }
        tableView.reloadData()
    }
    
    func saveCoreData() {
        do {
            try context.save()
        } catch {
            print("Error saving Core Data, \(error)")
        }
    }
    
    func resignedPlayerNameAttrStringConverter(playerName: String) -> NSAttributedString {
        //adds a red 'R' to the end of a player's name to signify if they resigned a match
        let attrNameString: NSMutableAttributedString = NSMutableAttributedString(string: playerName)
        let resignSymbol = NSAttributedString(string: "  (R)", attributes: [.foregroundColor: UIColor.red])
        attrNameString.append(resignSymbol)
        return attrNameString
    }
    
    func unAtttributedStringConverter(unAtrbString: String) -> NSAttributedString {
        //creates an attributed string for a players set score if the set went to a tie break and the tie score needs to be displayed as an exponent
        let newString: NSMutableAttributedString = NSMutableAttributedString(string: String(unAtrbString.prefix(1)))
        
        if unAtrbString.count >= 2 {
            if unAtrbString.count == 2 {
                let newAttribute = NSAttributedString(string: String(unAtrbString.suffix(1)),
                                                      attributes: [
                                                        .baselineOffset: 8,
                                                        .font: UIFont.systemFont(ofSize: 8),
                                                      ])
                newString.append(newAttribute)
            }
            if unAtrbString.count == 3 {
                let newAttribute = NSAttributedString(string: String(unAtrbString.suffix(2)),
                                                      attributes: [
                                                        .baselineOffset: 8,
                                                        .font: UIFont.systemFont(ofSize: 7),
                                                      ])
                newString.append(newAttribute)
            }
            if unAtrbString.count == 4 {
                let newAttribute = NSAttributedString(string: String(unAtrbString.suffix(3)),
                                                      attributes: [
                                                        .baselineOffset: 8,
                                                        .font: UIFont.systemFont(ofSize: 7),
                                                      ])
                newString.append(newAttribute)
            }
            return newString
        } else {
            return newString
        }
        
    }
    
    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
}
