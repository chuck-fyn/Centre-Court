//
//  MatchHistoryCell.swift
//  MatchPoint
//
//  Created by Charles Prutting on 10/2/22.
//

import UIKit

class MatchHistoryCellController: UITableViewCell {
    
    @IBOutlet weak var player1Name: UILabel!
    @IBOutlet weak var player2Name: UILabel!
    
    @IBOutlet weak var player1Set1: UILabel!
    @IBOutlet weak var player1Set2: UILabel!
    @IBOutlet weak var player1Set3: UILabel!
    @IBOutlet weak var player1Set4: UILabel!
    @IBOutlet weak var player1Set5: UILabel!
    @IBOutlet weak var player1Points: UILabel!
    @IBOutlet weak var player1Serving: UIImageView!
    @IBOutlet weak var player1Wins: UIImageView!
    
    @IBOutlet weak var player2Set1: UILabel!
    @IBOutlet weak var player2Set2: UILabel!
    @IBOutlet weak var player2Set3: UILabel!
    @IBOutlet weak var player2Set4: UILabel!
    @IBOutlet weak var player2Set5: UILabel!
    @IBOutlet weak var player2Points: UILabel!
    @IBOutlet weak var player2Serving: UIImageView!
    @IBOutlet weak var player2Wins: UIImageView!
    
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var matchDuration: UILabel!
    @IBOutlet weak var resumeMatch: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
