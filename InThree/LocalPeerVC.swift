//
//  FriendFinderVC.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/27/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import UIKit

class LocalPeerVC: UIViewController {
    
    let localPeerView = LocalPeerView()
    var localPeers = [BlipUser]()
    var selectedPeers = [BlipUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localPeerView.peerTable.delegate = self
        localPeerView.peerTable.dataSource = self
        localPeerView.peerTable.register(BlipUserCell.self, forCellReuseIdentifier: BlipUserCell.identifier)
        
        localPeerView.delegate = self
        
        self.view = localPeerView
        MultipeerTestManager.sharedInstance.generateRandomScores()
        
        NotificationCenter.default.addObserver(forName: .newPeerFound, object: nil, queue: nil) { (notification) in
            DispatchQueue.main.async {
                self.localPeers = MultipeerManager.sharedInstance.peers
                self.localPeerView.peerTable.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.localPeers = MultipeerManager.sharedInstance.peers
        print("Local peers: \(self.localPeers)")
        localPeerView.peerTable.reloadData()
    }
    
}
// MARK: Tableview delegate and data source
extension LocalPeerVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return localPeers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = localPeerView.peerTable.dequeueReusableCell(withIdentifier: BlipUserCell.identifier, for: indexPath) as! BlipUserCell
        cell.blipUser = localPeers[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! BlipUserCell
        if !cell.chosen {
            guard selectedPeers.count <= 3 else {
                print("Selected peer count is already at maximum")
                return
            }
            selectedPeers.append(localPeers[indexPath.row])
            print("Number of selected peers: \(selectedPeers.count)")
            for peer in selectedPeers {
                print("Users listed in selected peers: \(peer.name)")
            }
            cell.backgroundColor = localPeerView.colorScheme.model.highlightColor
            cell.chosen = true
        } else {
            cell.backgroundColor = localPeerView.colorScheme.model.baseColor
            let uidForDeselectedPeer = localPeers[indexPath.row].uid
            for (index, blipUser) in selectedPeers.enumerated() {
                if blipUser.uid == uidForDeselectedPeer {
                    selectedPeers.remove(at: index)
                    for peer in selectedPeers {
                        print("Users listed in selected peers: \(peer.name)")
                    }
                }
            }
            cell.chosen = false
        }
        
    }

}

//MARK: Local Peer View Delegate
extension LocalPeerVC: LocalPeerViewDelegate {
    
    func goToPartySquencer() {
        let partySequencerVC = PartySequencerVC()
        partySequencerVC.selectedPeers = self.selectedPeers
        partySequencerVC.sequencerEngine.mode = .party
        navigationController?.pushViewController(partySequencerVC, animated: true)
    }
    
    func returnToDashboard() {
        navigationController?.popViewController(animated: true)
    }
    
}

