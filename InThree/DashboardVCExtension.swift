//
//  DashboardVCExtension.swift
//  InThree
//
//  Created by Patrick O'Leary on 5/27/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import UIKit

extension DashboardVC: UITableViewDelegate, UITableViewDataSource {
    
    func setTableView() {
        dashboardView.peerTable.delegate = self
        dashboardView.peerTable.dataSource = self
        dashboardView.peerTable.register(BlipUserCell.self, forCellReuseIdentifier: BlipUserCell.identifier)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inviteablePeers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dashboardView.peerTable.dequeueReusableCell(withIdentifier: BlipUserCell.identifier, for: indexPath) as! BlipUserCell
        cell.blipUser = inviteablePeers[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = dashboardView.peerTable.cellForRow(at: indexPath) as! BlipUserCell
        if !cell.chosen {
            cell.chosen = true
            if let blipUser = cell.blipUser {
                selectedPeers.append(blipUser)
            }
        } else {
            cell.chosen = false
            if let blipUser = cell.blipUser {
                deselect(peer: blipUser)
            }
        }
    }
    
    private func deselect(peer: BlipUser) {
        for (index, selected) in selectedPeers.enumerated() {
            if selected.uid == peer.uid {
                selectedPeers.remove(at: index)
                break
            }
        }
    }
}

extension DashboardVC: MultipeerDelegate {
    
    func setMultipeer() {
        MultipeerManager.sharedInstance.delegate = self
        MultipeerManager.sharedInstance.startAdvertising()
        MultipeerManager.sharedInstance.startBrowsing()
    }
    
    func askPermission(fromInvitee invitee: BlipUser, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func respondToInvite(fromUser blipUser: BlipUser, withPartyID partyID: String) {
        guard let currentUser = FirebaseManager.sharedInstance.currentBlipUser else {return}
        if !currentUser.isInParty {
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
            
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func didNotConnect(withMessage: String) {
        alertUser(with: withMessage, viewController: self, completion: nil)
    }
    
    func availablePeersUpdate() {
        DispatchQueue.main.async {
            self.inviteablePeers = MultipeerManager.sharedInstance.availablePeers
            self.dashboardView.peerTable.reloadData()
        }
    }
}
