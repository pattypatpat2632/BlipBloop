//
//  MultipeerSequencerVC.swift
//  InThree

//  Created by Patrick O'Leary on 5/8/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.


import UIKit
import AudioKit

class PartySequencerVC: SequencerVC {
    
    let allBlipUsers = FirebaseManager.sharedInstance.allBlipUsers
    var connectedPeers = PartyManager.sharedInstance.party.members
    var partyID: String = ""{
        didSet {
            print("SET PARTYID, CALLING OBSERVE FUNCTION")
            PartyManager.sharedInstance.observe(partyWithID: partyID)
            PartyManager.sharedInstance.observeAllScoresIn(partyID: partyID)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PartyManager.sharedInstance.delegate = self
        self.sequencerEngine.mode = .party
    }
    
    override func respondTo(noteNumber: MIDINoteNumber, scoreIndex: ScoreIndex) {
        super.respondTo(noteNumber: noteNumber, scoreIndex: scoreIndex)
    }
    
    override func returnToDashboard() {
        guard let currentUser = currentUser else {return}
        FirebaseManager.sharedInstance.updateIsInParty(user: currentUser, with: false)
        sequencerEngine.generateSequence(fromScore: Score.empty)
        sequencerEngine.stopAll()
        self.dismiss(animated: true, completion: nil)
        PartyManager.sharedInstance.remove(member: currentUser, fromPartyID: partyID) {}
    }
}

extension PartySequencerVC: PartyDelegate {
    
    func scoreChange(forUID uid: String, score: Score) {
        for (index, blipUser) in connectedPeers.enumerated() {
            if blipUser.uid == uid {
                sequencerEngine.generateSequence(fromScore: score, forUserNumber: index + 1)
            }
        }
    }
    
    func partyChange() {
        self.connectedPeers = PartyManager.sharedInstance.party.members
    }
}

