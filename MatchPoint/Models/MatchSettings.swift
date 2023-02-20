//
//  Settings.swift
//  MatchPoint
//
//  Created by Charles Prutting on 8/31/22.
//

import Foundation
import SwiftUI

struct MatchSettings {
    
    //these are specific to the current math being played and do not need to persist after app is closed
    static var player1Name = "Charlie"
    static var player2Name = "Joey"
    static var numberOfSets = 2
    
    //these are user set preferences that persist after app is closed
    @AppStorage("announcePointWinner") static var announcePointWinnerEachPoint = true
    @AppStorage("crowdCheers") static var crowdCheers = true
    @AppStorage("courtColor") static var courtColor = "green"
    
    //this is only used for knowing if the app has ever been opened before
    @AppStorage("hasOpenedAppBefore") static var hasOpenedAppBefore = false
}
