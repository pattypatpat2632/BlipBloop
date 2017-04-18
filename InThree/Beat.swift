//
//  Beat.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/16/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import Foundation
import AudioKit

struct Beat {
    
    var rhythm: Rhythm
    var notes = [Note]()
    var beatNumber: AKDuration = AKDuration(beats: 0)
    
}

extension Beat {
    
    init(rhythm: Rhythm) {
        self.rhythm = rhythm
        for i in 1...rhythm.rawValue {
            let position = AKDuration(beats: Double(i - 1) / rhythm.rawValue)
            let duration = AKDuration(beats: 1.0/Double(i))
            let note = Note(noteOn: false, noteNumber: 0, velocity: 0, duration: duration, position: position)
            self.notes.append(note)
        }
    }
}
