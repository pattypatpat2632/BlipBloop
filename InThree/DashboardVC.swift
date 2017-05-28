
//  DashboardVC.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/26/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.


import UIKit
import Foundation


class DashboardVC: UIViewController, DashboardViewDelegate, UserAlert {
    
    let dashboardView = DashboardView()
    var invitesEnabled: Bool = false
    var inviteablePeers = [BlipUser]()
    var selectedPeers = [BlipUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkForLogin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        makeAvailableForParties()
        dashboardView.peerTable.reloadData()
    }
    
    func goToPartyMode() {
        guard let currentUser = FirebaseManager.sharedInstance.currentBlipUser else {
            let message = "Connection lost, could not create party."
            alertUser(with: message, viewController: self, completion: nil)
            return
        }
        PartyManager.sharedInstance.newParty(byUser: currentUser) { (partyID) in
            MultipeerManager.sharedInstance.invite(blipUsers: self.selectedPeers, toParty: PartyManager.sharedInstance.party)
            let partySequencerVC = PartySequencerVC()
            DispatchQueue.main.async {
                self.present(partySequencerVC, animated: true, completion: nil)
                partySequencerVC.partyID = partyID
            }
        }
    }
    
    func goToSoloMode() {
        let sequencerVC = SequencerVC()
        self.present(sequencerVC, animated: true, completion: nil)
    }
    
    func goToInstructions() {
        let instructionsVC = InstructionsVC()
        navigationController?.pushViewController(instructionsVC, animated: true)
    }
    
    func inviteSwitchPressed(newState: Bool) {
        self.invitesEnabled = newState
        guard let currentUser = FirebaseManager.sharedInstance.currentBlipUser else {return}
        FirebaseManager.sharedInstance.updateInviteable(user: currentUser, with: newState)
        UserDefaults.standard.set(newState, forKey: "enable-invites")
    }
    
    func logout() {
        FirebaseManager.sharedInstance.logoutUser { (response) in
            switch response {
            case .success(let logoutString):
                print(logoutString)
                NotificationCenter.default.post(name: .closeDashboardVC, object: nil)
            case .failure(let failString):
                print(failString)
            }
        }
    }
    
    func makeAvailableForParties(){
        if let currentUser = FirebaseManager.sharedInstance.currentBlipUser {
            FirebaseManager.sharedInstance.updateIsInParty(user: currentUser, with: false)
        }
    }
    
    func checkForLogin() {
        FirebaseManager.sharedInstance.checkForCurrentUser { (userExists) in
            if userExists {
                self.view = self.dashboardView
                self.dashboardView.delegate = self
                self.observeAllUsers()
                self.setTableView()
                self.setMultipeer()
                self.makeAvailableForParties()
            } else {
                NotificationCenter.default.post(name: .closeDashboardVC, object: nil)
            }
        }
    }
    
    func observeAllUsers() {
        FirebaseManager.sharedInstance.observeAllBlipUsers { (response) in
            //            switch response {
            //            case .success(let successString):
            //                print(successString)
            //            case .failure(let failString):
            //                print(failString)
            //            }
        }
    }
    
}
