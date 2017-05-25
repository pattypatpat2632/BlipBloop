
//  DashboardVC.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/26/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.


import UIKit
import Foundation


class DashboardVC: UIViewController, DashboardViewDelegate {
    
    let dashboardView = DashboardView()
    var invitesEnabled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkForLogin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        FirebaseManager.sharedInstance.currentBlipUser?.isInParty = false
    }
    
    func goToPartyMode() {
        let partyVC = LocalPeerVC()
        MultipeerManager.sharedInstance.startBrowsing()
        self.present(partyVC, animated: true, completion: nil)
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
    
    func checkForLogin() {
        FirebaseManager.sharedInstance.checkForCurrentUser { (userExists) in
            if userExists {
                self.view = self.dashboardView
                self.dashboardView.delegate = self
                MultipeerManager.sharedInstance.startAdvertising()
                MultipeerManager.sharedInstance.multipeerDelegate = self
                self.observeAllUsers()
            } else {
                NotificationCenter.default.post(name: .closeDashboardVC, object: nil)
            }
        }
    }
    
    func observeAllUsers() {
        FirebaseManager.sharedInstance.observeAllBlipUsers { (response) in
            switch response {
            case .success(let successString):
                print(successString)
            case .failure(let failString):
                print(failString)
            }
        }
    }
    
}

extension DashboardVC: MultipeerDelegate {
    func askPermission(fromInvitee invitee: BlipUser, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func respondToInvite(fromUser blipUser: BlipUser, withPartyID partyID: String) {
        guard let currentUser = FirebaseManager.sharedInstance.currentBlipUser else {return}
        if currentUser.isInParty == false && self.invitesEnabled {
            print("asked to join party: \(partyID)")
            let alertController = UIAlertController(title: "\(blipUser.name) has invited you to party!", message: "Would you like to join?", preferredStyle: .alert)
            
            let noAction = UIAlertAction(title: "No", style: .cancel) { (action) in
                print("User did not join party :(")
            }
            alertController.addAction(noAction)
            
            let yesAction = UIAlertAction(title: "Yes", style: .default) { (action) in
                FirebaseManager.sharedInstance.currentBlipUser?.isInParty = true
                PartyManager.sharedInstance.join(partyWithID: partyID) {
                    let partyVC = PartySequencerVC()
                    partyVC.partyID = partyID
                    DispatchQueue.main.async {
                        self.present(partyVC, animated: true, completion: nil)
                    }
                    
                }
            }
            alertController.addAction(yesAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
