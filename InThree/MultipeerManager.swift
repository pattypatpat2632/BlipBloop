//
//  MultipeerManager.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/27/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import Foundation
import MultipeerConnectivity

final class MultipeerManager: NSObject {
    
    static let sharedInstance = MultipeerManager()
    let service = "blipbloop-2632"
    var currentUser = FirebaseManager.sharedInstance.currentBlipUser
    let myPeerID = MCPeerID(displayName: (FirebaseManager.sharedInstance.currentBlipUser?.uid)!)
    var availablePeers = [BlipUser]()
    
    var serviceAdvertiser: MCNearbyServiceAdvertiser?
    var serviceBrowser: MCNearbyServiceBrowser?

    var delegate: MultipeerDelegate?
    
    lazy var session: MCSession = {
        
        let session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .optional)
        session.delegate = self
        return session
        
    }()
    
    private override init() {
        super.init()
    }
    
    func startBrowsing() {
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: service)
        serviceBrowser?.delegate = self
        serviceBrowser?.startBrowsingForPeers()
    }
    
    func startAdvertising() {
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: service)
        serviceAdvertiser?.delegate = self
        serviceAdvertiser?.startAdvertisingPeer()
    }
    
    deinit {
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceBrowser?.stopBrowsingForPeers()
    }
    
    func updateAvailablePeers() {
        print("UPDATING AVAILABLE PEERS")
        availablePeers.removeAll()
        var allPeers = [BlipUser]()
        for peer in session.connectedPeers {
            for user in FirebaseManager.sharedInstance.allBlipUsers {
                if user.uid == peer.displayName {
                    allPeers.append(user)
                }
            }
        }
        let usersNotInParty: [BlipUser] = allPeers.filter{!$0.isInParty}
        availablePeers = usersNotInParty.filter{$0.invitesEnabled}
        delegate?.availablePeersUpdate()
    }
    
    func invite(blipUsers: [BlipUser], toParty party: Party) {
        if let partyID = party.id {
            print("Inviting users with valid party ID")
            do {
                let json = try JSONSerialization.data(withJSONObject:["partyid": partyID] , options: [])
                let selectedUIDs = blipUsers.map{$0.uid}
                let peers = session.connectedPeers.filter{selectedUIDs.contains($0.displayName)}
                try session.send(json, toPeers: peers, with: .reliable)
            } catch {
                print("could not convert party ID into JSON and send to connected peers")
            }
        }
    }
    
}

//MARK: Advertiser Delegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        delegate?.didNotConnect(withMessage: "Unable to connect to network for party mode. Please check your Wi-Fi connection.")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        for user in FirebaseManager.sharedInstance.allBlipUsers {
            if user.uid == peerID.displayName {
                delegate?.askPermission(fromInvitee: user, completion: { (permission) in
                    if permission {
                        invitationHandler(true, self.session)
                    }
                })
                break
            }
        }
    }
}

//MARK: Browser Delegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        self.updateAvailablePeers()
    }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        delegate?.didNotConnect(withMessage: "Unable to connect to network to find other BlipBloop users. Please check your Wi-Fi connection.")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {

        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 30.0)
        
    }
}

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let partyDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] ?? [:]
            for user in FirebaseManager.sharedInstance.allBlipUsers {
                if user.uid == peerID.displayName {
                    guard let partyID = partyDict["partyid"] else {return}
                    delegate?.respondToInvite(fromUser: user, withPartyID: partyID)
                    break
                }
            }
        } catch {
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            self.updateAvailablePeers()
        case .connecting:
            print("connecting")
        case .connected:
            //add(peerID: peerID.displayName)
            print("connected")
            self.updateAvailablePeers()
        }
    }
    
    // Unused required delegate functions
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
    }
    
    
}

protocol MultipeerDelegate {
    func askPermission(fromInvitee invitee: BlipUser, completion: @escaping (Bool) -> Void)
    func respondToInvite(fromUser blipUser: BlipUser, withPartyID partyID: String)
    func didNotConnect(withMessage: String)
    func availablePeersUpdate()
}





