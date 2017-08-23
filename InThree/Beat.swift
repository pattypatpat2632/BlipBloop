//
//  Beat.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/16/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.


import Foundation
import AudioKit

//Model for each beat
struct Beat {
    
    var rhythm: Rhythm
    var notes = [Note]()
    var beatNumber: AKDuration = AKDuration(beats: 0) //Index for beat within score
    
    mutating func setBeatNumber(to beatNumber: AKDuration) {
        self.beatNumber = beatNumber
    }
    
}

extension Beat {
    
    init(rhythm: Rhythm) { //Initialize a new beat, with blank notes
        self.rhythm = rhythm
        for _ in 1...rhythm.rawValue {
            let note = Note(noteOn: false, noteNumber: 0, velocity: 127)//, duration: duration, position: position)
            self.notes.append(note)
        }
    }
    
    init?(dictionary: [String: Any]) {
        guard let rhythmRawValue = dictionary["rhythm"] as? Int else { return nil }
        guard let rhythm = Rhythm(rawValue: rhythmRawValue) else { return nil }
        self.rhythm = rhythm
        guard let notes = dictionary["notes"] as? [[String: Any]] else { return nil }
        for note in notes {
            let newNote = Note(dictionary: note)
            self.notes.append(newNote)
        }
        guard let beatNumber = dictionary["beatNumber"] as? Double else { return nil }
        self.beatNumber = AKDuration(beats: beatNumber)
    }
}

extension Beat {
    
    mutating func add(note: Note, forNewRhythm rhythm: Rhythm) {
        self.notes.append(note)
        self.rhythm = rhythm
    }
    
    mutating func removeLastNote(forNewRhythm rhythm: Rhythm) {
        self.notes.removeLast()
        self.rhythm = rhythm
    }
    
    func asDictionary() -> [String: Any] {
        var notesDict = [[String: Any]]()
        for note in notes {
            notesDict.append(note.asDictionary())
        }
        
        let beatDict: [String: Any] = [
            "rhythm": rhythm.rawValue,
            "notes": notesDict,
            "beatNumber": self.beatNumber.beats
        ]
        
        return beatDict
    }
    
    static func randomBeat(position: Double = 0) -> Beat {
        let rhythm: Rhythm = .four
        let notes = [Note.random(), Note.random(), Note.random(), Note.random()]
        return Beat(rhythm: rhythm, notes: notes, beatNumber: AKDuration(beats: position))
    }
}


