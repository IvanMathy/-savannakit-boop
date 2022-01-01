//
//  InnerTextView+MultilineEditing.swift
//  SavannaKit macOS
//
//  Created by Ivan on 12/29/21.
//  Copyright © 2021 Silver Fox. All rights reserved.
//

import Foundation
import AppKit

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
            (textStorage.string as NSString).character(at: index) != 0)
        {
          index += 1;
        }

        return index
    }
    
    override func mouseDown(with event: NSEvent) {
        guard event.modifierFlags.contains(.option) else {
            self.setNeedsDisplay(NSRect.zero, avoidAdditionalLayout: true)
            self.selectionRanges = nil
            return super.mouseDown(with: event)
        }
        
        startIndex = characterIndex(for: event)
        selectionRanges = [NSRange(location: 0,length: 0), NSRange(location: 5, length: 0), NSRange(location: 10, length: 3)]
        
    }
    
    override func mouseDragged(with event: NSEvent) {
        let index = characterIndex(for: event)!
        let glyphIndex = (layoutManager?.glyphIndexForCharacter(at: index))!
        
        //(string as NSString).lineRange(for: <#T##NSRange#>)
        
        //layoutManager?.enumerateLineFragments(forGlyphRange: <#T##NSRange#>, using: <#T##(NSRect, NSRect, NSTextContainer, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void#>)
        
        // 1 find first char in line by setting X to 0
        // 2 save rect of char (maybe)
        // 3 if mouse moves out of rect, find 1st char of new line
        // 4 offset first char by original offset
        
        
        // if move more than 1/2 char on x, switch to box selection
        //layoutManager!.glyphRange(forBoundingRect: <#T##NSRect#>, in: <#T##NSTextContainer#>)
        // find smallest range
        
        layoutManager!.enumerateLineFragments(forGlyphRange: NSRange(location: glyphIndex, length: 100)) { (rect, usedRect, textContainer, glyphRange, stop) in

            print(rect, usedRect, textContainer, glyphRange, stop)
        }
        
        print("--")
        
        
        //print(layoutManager!.truncatedGlyphRange(inLineFragmentForGlyphAt: glyphIndex!))
    }
    
    
    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        guard let selectionRanges = selectionRanges else {
            return super.drawInsertionPoint(in: rect, color: color, turnedOn: flag)
        }
        
        var selections = [NSRange]()
        
        for range in selectionRanges {
            guard range.length == 0 else {
                selections.append(range)
                continue
            }
            var rect = layoutManager!.boundingRect(forGlyphRange: NSRange(location: range.location, length: 1), in: textContainer!)
            rect = NSRect(origin: rect.origin, size: NSSize(width: 1, height: rect.height))
            super.drawInsertionPoint(in: rect, color: color, turnedOn: flag)
            
        }
        
        if !selections.isEmpty {
            self.setSelectionRanges(selections)
        }
        
        
        
    }
    
    override func setNeedsDisplay(_ rect: NSRect, avoidAdditionalLayout flag: Bool) {
        super.setNeedsDisplay(rect, avoidAdditionalLayout: flag)
        
        guard let selectionRanges = selectionRanges else {
            return
        }
        
        for range in selectionRanges {
            guard range.length == 0 else {
                continue
            }
            let rect = layoutManager!.boundingRect(forGlyphRange: NSRange(location: range.location, length: 1), in: textContainer!)
            super.setNeedsDisplay(rect, avoidAdditionalLayout: flag)
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
        
        self.insert(stringInRanges: insertionRanges.map { (insertString, $0)})
        
    }
    
    
    func insert(stringInRanges pairs: [(String, NSRange)]) -> Bool {
        
        guard
            shouldChangeText(inRanges: pairs.map { NSValue.init(range: $0.1) }, replacementStrings: pairs.map { $0.0 }),
            let textStorage = self.textStorage
        else {
            return false
        }
        
        textStorage.beginEditing()
        
        var offset = 0
        
        for pair in pairs.sorted(by: { $0.1.location < $1.1.location  }) {
            let range = NSRange(location: pair.1.location + offset, length: pair.1.length)
            textStorage.replaceCharacters(in: range, with: pair.0)
            offset += pair.0.count - pair.1.length
        }
        
        textStorage.endEditing()
        
        self.didChangeText()
        
        return true
    }
    
    func setSelectionRanges(_ ranges: [NSRange]) {
        self.selectionRanges = ranges
        
        self.selectedRanges = ranges.filter { $0.length > 0 } as [NSValue]
    }
}
