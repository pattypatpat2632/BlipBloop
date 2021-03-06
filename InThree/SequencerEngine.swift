//
//  SequencerEngine.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/16/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import Foundation
import AudioKit

struct SequencerEngine {
    
    
    let oscBank = AKOscillatorBank()
    let sequencer = AKSequencer()
    let midi = AKMIDI()
    var verb: AKReverb?
    var mode: SequencerMode = .solo
    
    
    init() {}
    
    mutating func setUpSequencer() {
        
        
        let midiNode = AKMIDINode(node: oscBank)
        
        oscBank.attackDuration = 0.1
        oscBank.decayDuration = 0.1
        oscBank.sustainLevel = 0.1
        oscBank.releaseDuration = 0.5
        verb = AKReverb(midiNode)
        
        _ = sequencer.newTrack()
        _ = sequencer.newTrack()
        _ = sequencer.newTrack()
        _ = sequencer.newTrack()
        
        AudioKit.output = verb
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .defaultToSpeaker)
        } catch {
            
        }
        AKSettings.playbackWhileMuted = true
        AudioKit.start()
        midiNode.enableMIDI(midi.client, name: "midiNode midi in")
        sequencer.setTempo(120.0)
        sequencer.setLength(AKDuration(beats: 4.0))
        sequencer.enableLooping()
        sequencer.play()
        NotificationCenter.default.post(name: .playbackStarted, object: nil)
        
    }
    
    func changeTempo(_ newTempo: Double) {
        sequencer.setTempo(newTempo)
    }
    
    func generateSequence(fromScore score: Score, forUserNumber userNum: Int = 0) {
        print("*****Generate Sequence*****")
        sequencer.tracks[userNum].clear()
        print("sequencer length: \(score.beats.count)")
        var beatPostion = AKDuration(beats: 0)
        for beat in score.beats {
            var notePosition = AKDuration(beats: 0)
            let noteDuration = AKDuration(beats: (1/(beat.rhythm.rawValue + 0.01)))
            for note in beat.notes{
                if note.noteOn {
                    sequencer.tracks[userNum].add(noteNumber: note.noteNumber, velocity: note.velocity, position: notePosition + beatPostion, duration: noteDuration)
                }
                notePosition = notePosition + AKDuration(beats: 1/beat.rhythm.rawValue)
            }
            beatPostion = beatPostion + AKDuration(beats: 1.0)
        }
        if userNum == 0 {
            send(score: score)
        }
    }
    
    func send(score: Score) {
        switch mode {
        case .party:
            if let partyID = PartyManager.sharedInstance.party.id {
                print("valid party iD for upload: \(partyID)")
                PartyManager.sharedInstance.send(score: score, toPartyID: partyID)
            }
        case .neighborhood(let neighborString):
            print(neighborString) //TODO: implement when location mode functions
        case .solo:
            print("solo mode, no data sent")
        }
    }
    
    func stopAll() {
        for track in sequencer.tracks {
            track.clear()
        }
        self.sequencer.stop()
        AudioKit.output = nil
        sequencer.stop()
        AudioKit.stop()
        NotificationCenter.default.post(name: .playbackStopped, object: nil)
    }
}




















