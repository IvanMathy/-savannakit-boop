//
//  TextViewWrapperView.swift
//  SavannaKit
//
//  Created by Louis D'hauwe on 17/02/2018.
//  Copyright © 2018 Silver Fox. All rights reserved.
//

import Foundation

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

#if os(macOS)
	
	class TextViewWrapperView: View {
		
		var textView: InnerTextView?
		
		override public func draw(_ rect: CGRect) {
			
			guard let textView = textView else {
				return
			}
			
			let contentHeight = textView.enclosingScrollView!.documentView!.bounds.height
			
			let yOffset = self.bounds.height - contentHeight
			
			var paragraphs: [Paragraph]
			
			if let cached = textView.cachedParagraphs {
				
				paragraphs = cached
				
			} else {
				
				paragraphs = generateParagraphs(for: textView, flipRects: true)
				textView.cachedParagraphs = paragraphs
				
			}
			
			paragraphs = offsetParagrahps(paragraphs, for: textView, yOffset: yOffset)
			
			let components = textView.text.components(separatedBy: .newlines)
			
			let count = components.count
			
			let maxNumberOfDigits = "\(count)".count
			
			textView.updateGutterWidth(for: maxNumberOfDigits)
			
			Color.black.setFill()
			
			let gutterRect = CGRect(x: 0, y: 0, width: textView.gutterWidth, height: rect.height)
			let path = BezierPath(rect: gutterRect)
			path.fill()
			
			
			drawLineNumbers(paragraphs, in: self.bounds, for: textView)
			
		}
		
	}
	
#endif