//
//  InnerTextView+MultilineEditing.swift
//  SavannaKit macOS
//
//  Created by Ivan on 12/29/21.
//  Copyright © 2021 OKatBest. All rights reserved.
//

import Foundation
import AppKit

enum MoveDirection {
    case up
    case down
    case left
    case right
}

extension InnerTextView {
    
    func characterIndex(for event: NSEvent) -> Int? {
        
        guard
            let layoutManager = layoutManager,
            let textStorage   = textStorage,
            let textContainer = textContainer
        else {
            return nil
        }
        
        let point = self.convert(event.locationInWindow, from: nil)
        var fraction: CGFloat = 0

        var index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: &fraction)

        if (fraction > 0.5 && index < textStorage.length &&
            (textStorage.string as NSString).character(at: index) != 10)
        {
          index += 1;
        }

        return index
    }
    
    override func mouseDown(with event: NSEvent) {
        guard event.modifierFlags.contains(.option) else {
            
            self.cursorBlinkTimer?.invalidate()
            self.cursorBlinkTimer = nil
            
            self.shouldDrawInsertionPoints = false
            self.refreshInsertionRects()
            self.selectionRanges = nil
            
            return super.mouseDown(with: event)
            
        }
        
        if selectionRanges != nil {
            self.shouldDrawInsertionPoints = false
            self.refreshInsertionRects()
        }
        
        startIndex = characterIndex(for: event)
        selectionRanges = []
        
        if let index = startIndex {
            selectionRanges?.append(NSRange(location: index,length: 0))
        }
        
        self.shouldDrawInsertionPoints = true
        self.refreshInsertionRects()
        
        
        
    }
    
    override func mouseDragged(with event: NSEvent) {
//        let index = characterIndex(for: event)!
//        let glyphIndex = (layoutManager?.glyphIndexForCharacter(at: index))!
//
        //(string as NSString).lineRange(for: <#T##NSRange#>)
        
        //layoutManager?.enumerateLineFragments(forGlyphRange: <#T##NSRange#>, using: <#T##(NSRect, NSRect, NSTextContainer, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void#>)
        
        // 1 find first char in line by setting X to 0
        // 2 save rect of char (maybe)
        // 3 if mouse moves out of rect, find 1st char of new line
        // 4 offset first char by original offset
        
        
        // if move more than 1/2 char on x, switch to box selection
        //layoutManager!.glyphRange(forBoundingRect: <#T##NSRect#>, in: <#T##NSTextContainer#>)
        // find smallest range
        
//        layoutManager!.enumerateLineFragments(forGlyphRange: NSRange(location: glyphIndex, length: 100)) { (rect, usedRect, textContainer, glyphRange, stop) in
//
//            print(rect, usedRect, textContainer, glyphRange, stop)
//        }
//
        
        self.autoscroll(with: event)
        
        guard
            let index = self.characterIndex(for: event),
            let selectionRanges = self.selectionRanges,
            !selectionRanges.contains(where: { range in
                range.location == index
            })
        else {
            return
        }
        
        self.selectionRanges?.append(NSRange(location: index, length: 0))
        
        self.cursorBlinkTimer?.invalidate()
        self.cursorBlinkTimer = nil
        self.shouldDrawInsertionPoints = true
        self.refreshInsertionRects()
        self.cursorBlinkTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateInsertionPoints), userInfo: nil, repeats: true)
        
        
        
        
        //print(layoutManager!.truncatedGlyphRange(inLineFragmentForGlyphAt: glyphIndex!))
    }

    
    @objc func updateInsertionPoints() {
        self.refreshInsertionRects()
        self.shouldDrawInsertionPoints.toggle()
    }
        
    func refreshInsertionRects() {
        
        guard let selectionRanges = selectionRanges else {
            return
        }
        
        for range in selectionRanges {
            guard range.length == 0 else {
                continue
            }
            // todo move to func but i need sleep
            // also round to nearest half pixel
            var location = range.location
            var isLastChar = false
            
            if location >= textStorage!.length {
                location -= 1
                isLastChar = true
            }
            
            var rect = layoutManager!.boundingRect(forGlyphRange: NSRange(location: location, length: 1), in: textContainer!)
            var origin = rect.origin
            
            if(isLastChar) {
                origin = NSPoint(x: origin.x + rect.width, y: origin.y)
            }
            
            rect = NSRect(origin: origin, size: NSSize(width: 1, height: rect.height))
            super.setNeedsDisplay(rect)
        }
    }
    
    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        guard self.selectionRanges == nil else {
            // No thanks I make my own
            return
        }
        super.drawInsertionPoint(in: rect, color: color, turnedOn: flag)
    }
    
    
//    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
//        guard let selectionRanges = selectionRanges else {
//            return super.drawInsertionPoint(in: rect, color: color, turnedOn: flag)
//        }
//
//        var selections = [NSRange]()
//
//        for range in selectionRanges {
//            guard range.length == 0 else {
//                selections.append(range)
//                continue
//            }
//            var rect = layoutManager!.boundingRect(forGlyphRange: NSRange(location: range.location, length: 1), in: textContainer!)
//            rect = NSRect(origin: rect.origin, size: NSSize(width: 1, height: rect.height))
//            super.drawInsertionPoint(in: rect, color: color, turnedOn: flag)
//
//        }
//
//        if !selections.isEmpty {
//            self.setSelectionRanges(selections)
//        }
//
//
//
//    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let selectionRanges = selectionRanges, shouldDrawInsertionPoints else {
            return
        }
        
        var selections = [NSRange]()
        
        for range in selectionRanges {
            guard range.length == 0 else {
                selections.append(range)
                continue
            }
            
            var location = range.location
            var isLastChar = false
            
            if location >= textStorage!.length {
                location -= 1
                isLastChar = true
            }
            
            var rect = layoutManager!.boundingRect(forGlyphRange: NSRange(location: location, length: 1), in: textContainer!)
            var origin = rect.origin
            
            if(isLastChar) {
                origin = NSPoint(x: origin.x + rect.width, y: origin.y)
            }
            
            rect = NSRect(origin: origin, size: NSSize(width: 1, height: rect.height))
            
            super.drawInsertionPoint(in: rect, color: .textColor, turnedOn: true)
            
        }
    }
    
//    override func insertText(_ insertString: Any) {
//        guard let insertionPoints = insertionPoints else {
//            return super.insertText(insertString)
//        }
//
//        insertionPoints.forEach { point in
//            self.setSelectedRange(NSRange(location: point, length: 0))
//            super.insertText(insertString)
//        }
//    }
    
    override func mouseUp(with event: NSEvent) {
        
        startIndex = nil
    }
    
//    override func keyDown(with event: NSEvent) {
//        guard let insertionPoints = insertionPoints else {
//            return super.keyDown(with: event)
//        }
//
//        insertionPoints.forEach { point in
//            self.setSelectedRange(NSRange(location: point, length: 0))
//            super.keyDown(with: event)
//        }
//    }
    
    override func insertText(_ insertString: Any) {

        guard let insertionRanges = selectionRanges, let insertString = insertString as? String else {
            return super.insertText(insertString)
        }
        
        self.selectionRanges = self.insert(stringInRanges: insertionRanges.map { (insertString, $0)})
        
    }
    
    
    func insert(stringInRanges pairs: [(String, NSRange)]) -> [NSRange]? {
        
        guard
            shouldChangeText(inRanges: pairs.map { NSValue.init(range: $0.1) }, replacementStrings: pairs.map { $0.0 }),
            let textStorage = self.textStorage
        else {
            return nil
        }
        
        textStorage.beginEditing()
        
        var offset = 0
        
        let newPairs = pairs.sorted(by: { $0.1.location < $1.1.location  }).map {
            pair -> NSRange in
            let range = NSRange(location: pair.1.location + offset, length: pair.1.length)
            textStorage.replaceCharacters(in: range, with: pair.0)
            offset += pair.0.count - pair.1.length
            
            return NSRange(location: pair.1.location + offset, length: 0)
        }
        
        textStorage.endEditing()
        
        self.didChangeText()
        
        return newPairs
    }
    
    func setSelectionRanges(_ ranges: [NSRange]) {
        self.selectionRanges = ranges
        
        self.selectedRanges = ranges.filter { $0.length > 0 } as [NSValue]
    }
    
    func moveInsertionPoints(_ direction: MoveDirection) {
        self.shouldDrawInsertionPoints = false
        self.refreshInsertionRects()
        selectionRanges = selectionRanges?.map { $0.upperBound }.compactMap {
            self.move(index:$0, direction, by: 1)
        }.map { NSRange(location: $0, length: 0) }
        
        self.shouldDrawInsertionPoints = true
        self.refreshInsertionRects()
    }
    
    // this is peak function signature fight me
    func move(index: Int, _ direction: MoveDirection, by: Int) -> Int? {
        guard
            let layoutManager = layoutManager,
            let textStorage = self.textStorage
        else {
            return nil
        }
        
        let lineRange = self.getLineRange(for: index)
        let characterPosition = index - lineRange.location
        
        
        switch direction {
        case .up:
            let previousLine = lineRange.location - 1
            guard previousLine >= 0 else {
                // out of bounds
                return nil
            }
            
            let previousLineRange = self.getLineRange(for: previousLine)
            
            return previousLineRange.lowerBound + min(previousLineRange.length, characterPosition)
            
        case .down:
            let nextLine = lineRange.upperBound + 1
            guard nextLine < textStorage.length else {
                // out of bounds
                return nil
            }
            
            let nextLineRange = self.getLineRange(for: nextLine)
            
            return nextLineRange.lowerBound + min(nextLineRange.length, characterPosition)
            
        case .left:
            
                return nil
        case .right:
            
                return nil
        }
        
        return nil
    }
    
    func getLineRange(for glyphIndex: Int) -> NSRange {
        
        guard let layoutManager = layoutManager else {
            fatalError("Missing Layout Manager. How did we get so far without it??")
        }
        
        var lineRange:NSRange? = nil
        layoutManager.enumerateLineFragments(forGlyphRange: NSRange(location: glyphIndex, length: 1)) { (rect, usedRect, textContainer, glyphRange, stop) in
            print(rect, usedRect, textContainer, glyphRange, stop)
            lineRange = glyphRange
        }
        print("after")
        return lineRange ?? NSRange()
    }
    
    override func keyDown(with event: NSEvent) {
        guard self.selectionRanges != nil else {
            return super.keyDown(with: event)
        }
        
        let character = Int(event.keyCode)
        switch character {
        case 126:
            self.moveInsertionPoints(.up)
        case 127:
            self.moveInsertionPoints(.down)
        default:
            super.keyDown(with: event)
        }
    }
    
}