//
//  BeatView.swift
//  InThree
//
//  Created by Patrick O'Leary on 4/15/17.
//  Copyright © 2017 Patrick O'Leary. All rights reserved.
//

import UIKit

class BeatView: UIView {
    
    let pad1 = PadView()
    let pad2 = PadView()
    let pad3 = PadView()
    let pad4 = PadView()
    let pad5 = PadView()
    let stackView = UIStackView()
    let sliderView = UIView()
    var displayedViewCount: Int = 4
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        self.backgroundColor = UIColor.night
        
        self.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.6666).isActive = true
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.addArrangedSubview(pad1)
        stackView.addArrangedSubview(pad2)
        stackView.addArrangedSubview(pad3)
        stackView.addArrangedSubview(pad4)
        stackView.addArrangedSubview(pad5)
        pad5.isHidden = true
        //pad5.transform = CGAffineTransform(translationX: 200, y: 0)
        
        self.addSubview(sliderView)
        sliderView.translatesAutoresizingMaskIntoConstraints = false
        sliderView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        sliderView.topAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
        sliderView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        sliderView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        sliderView.backgroundColor = UIColor.phoneBoothRed
        
        let addPadGesture = UISwipeGestureRecognizer(target: self, action: #selector(addPad))
        addPadGesture.direction = .left
        sliderView.addGestureRecognizer(addPadGesture)
        
        let subtractPadGesture = UISwipeGestureRecognizer(target: self, action: #selector(subtractPad))
        subtractPadGesture.direction = .right
        sliderView.addGestureRecognizer(subtractPadGesture)
    }

    func addPad() {
        guard displayedViewCount < 5 else {return}
        let pad = stackView.arrangedSubviews[displayedViewCount]
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                pad.isHidden = false
            })
//            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25, animations: {
//                pad.transform = CGAffineTransform(translationX: -200, y: 0)
//            })
        }, completion: nil)
        displayedViewCount += 1
    }
    
    func subtractPad() {
        guard displayedViewCount > 1 else {return}
        let pad = stackView.arrangedSubviews[displayedViewCount - 1]
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: [], animations: {
//            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25, animations: {
//                pad.transform = CGAffineTransform(translationX: 200.0, y: 0)
//            })
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                pad.isHidden = true
            })
        }, completion: nil)
        displayedViewCount -= 1
    }
    
    func reportBeat() {
        let rhythm = Rhythm(rawValue: displayedViewCount)
    }
}

protocol BeatViewDelegate {
    
}
