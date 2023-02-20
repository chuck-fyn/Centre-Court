//
//  PlayerModel.swift
//  CenterCourt
//
//  Created by Charles Prutting on 1/22/23.
//

import Foundation

struct PlayerModel {
    var points = 0
    var scoreString = "0"
    var set1Games: NSMutableAttributedString = NSMutableAttributedString(string: "0")
    var set2Games: NSMutableAttributedString = NSMutableAttributedString(string: "0")
    var set3Games: NSMutableAttributedString = NSMutableAttributedString(string: "0")
    var set4Games: NSMutableAttributedString = NSMutableAttributedString(string: "0")
    var set5Games: NSMutableAttributedString = NSMutableAttributedString(string: "0")
    var games = 0
    var sets = 0
    var isWinner = false
    var resigned = false
    var isServing = true
}
