//
//  DashboardVC.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/26/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.


import UIKit
import Foundation


class DashboardVC: UIViewController, DashboardViewDelegate {
    
    let dashboardView = DashboardView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkForLogin()
    }
    
    func goToPartyMode() {
        let partySequencerVC = PartySequencerVC()
        self.navigationController?.pushViewController(partySequencerVC, animated: true)
    }
    
    func goToSoloMode() {
        let sequencerVC = SequencerVC()
        self.navigationController?.pushViewController(sequencerVC, animated: true)
    }
    
    func goToNeighborhoodMode() {
        let sequencerVC = SequencerVC()
        sequencerVC.sequencerEngine.mode = .neighborhood("No Neighborhood")
        self.navigationController?.pushViewController(sequencerVC, animated: true)//TODO: update if I decide to put a view in between dashboard and neighborhood sequencer
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
                MultipeerManager.sharedInstance.partyDelegate = self
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

extension DashboardVC: PartyInviteDelegate {
    func askIfAttending(fromInvitee invitee: BlipUser, completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "\(invitee.name) has started a party!", message: "Would you like to join?", preferredStyle: .alert)
        
        let noAction = UIAlertAction(title: "No", style: .cancel) { (action) in
            completion(false)
        }
        alertController.addAction(noAction)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            completion(true)
            let partyVC = PartySequencerVC()
            self.navigationController?.pushViewController(partyVC, animated: true)
        }
        alertController.addAction(yesAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func availablePeersChanged() {
    }
}
