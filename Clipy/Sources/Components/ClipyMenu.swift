// 
//  ClipyMenu.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
// 
//  Created by Ronny Fenrich on 2020-05-14.
// 
//  Copyright © 2015-2020 Clipy Project.
//

import Foundation
import AppKit

// Custom NSMenu class for Clipy
// Supports search/filter and highlighting items
class ClipyMenu: NSMenu, NSMenuDelegate {

    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override init(title: String) {
        super.init(title: title)
        self.delegate = self
        self.minimumWidth = 300
        addSearchInputMenuItem()
    }

    func menuWillOpen(_ menu: NSMenu) {
        if AppEnvironment.current.autoHighlightSecondHistoryItem {
            var targetItem = 2
            if AppEnvironment.current.enableSearchInHistoryMenu {
                targetItem += 1
            }
            if AppEnvironment.current.indicatePasteAsPlainTextModifier {
                targetItem += 1
            }

            // highlight second item by default when showing menu
            if let menuItem = self.item(at: targetItem) {
                highlight(menuItem)
            }
        }
    }

    private func highlight(_ itemToHighlight: NSMenuItem?) {
        guard itemToHighlight != nil else {
            return
        }

        let highlightItemSelector = NSSelectorFromString("highlightItem:")
        perform(highlightItemSelector, with: itemToHighlight)
    }

    func addSearchInputMenuItem() {
        guard AppEnvironment.current.enableSearchInHistoryMenu else { return }

        let searchInputMenuItemView = ClipyMenuSearchTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 29))

        let searchInputMenuItem = NSMenuItem()
        searchInputMenuItem.title = L10n.search
        searchInputMenuItem.view = searchInputMenuItemView
        searchInputMenuItem.isEnabled = false
        self.addItem(searchInputMenuItem)

        self.addItem(NSMenuItem.separator())
    }

    func select() {
        if let item = self.highlightedItem {
            performActionForItem(at: index(of: item))
            cancelTracking()
        }
    }
}
