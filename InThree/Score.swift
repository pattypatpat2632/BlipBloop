//
//  Score.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/16/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import Foundation
import AudioKit

//Model for an individual user's score
struct Score {
    
    var beats = [Beat]()
    
    mutating func add(beat: Beat) {
        var newBeat = beat
        let beatNumber = AKDuration(beats: Double(beats.count))
        newBeat.setBeatNumber(to: beatNumber)
        beats.append(newBeat)
    }
    
}

extension Score {
    init?(dictionary: [String: Any]) { //Init from database
        guard let beats = dictionary["beats"] as? [[String: Any]] else {return nil}
        for beat in beats {
            guard let newBeat = Beat(dictionary: beat) else { return nil }
            self.beats.append(newBeat)
        }
    }
    
    init(rhythm: Rhythm) { //Initialize score with four beats
        self.add(beat: Beat(rhythm: rhythm))
        self.add(beat: Beat(rhythm: rhythm))
        self.add(beat: Beat(rhythm: rhythm))
        self.add(beat: Beat(rhythm: rhythm))
    }
}
//MARK: database functions
extension Score {
    
    func asDictionary() -> [String: Any] {
        
        var beatArray = [[String: Any]]()
        for beat in beats {
            beatArray.append(beat.asDictionary())
        }
        let scoreDict = [
            "beats": beatArray
        ]
        return scoreDict
    }
    
    func asData() -> Data? {
        let scoreDict = self.asDictionary()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: scoreDict, options: [])
            return jsonData
        } catch {
            print("Could not convert dictionary to JSON Data")
            return nil
        }
    }
    
    //MARK: mutating functions
    mutating func addStep(toBeatNum beatNum: Int, newRhythm: Rhythm) {
        let note = Note(noteOn: false, noteNumber: 0, velocity: 127)
        beats[beatNum].add(note: note, forNewRhythm: newRhythm)
    }
    
    mutating func removeStep(fromBeatNum beatNum: Int, newRhythm: Rhythm) {
        beats[beatNum].removeLastNote(forNewRhythm: newRhythm)
    }
}

extension Score{
    static let empty = Score(rhythm: .four) //Static constant representing an empty score
    
    static func random() -> Score { //Static constant representing a random score
        let beat0 = Beat.randomBeat()
        let beat1 = Beat.randomBeat(position: 1)
        let beat2 = Beat.randomBeat(position: 2)
        let beat3 = Beat.randomBeat(position: 3)
        return Score(beats: [beat0, beat1, beat2, beat3])
    }
}
