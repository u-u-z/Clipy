//
//  ClipyMenuSearchTextField.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
// 
//  Created by Ronny Fenrich on 2020-05-14.
// 
//  Copyright © 2015-2020 Clipy Project.
//

class ClipyMenuSearchTextField: NSView, NSTextFieldDelegate {

    var searchQueryField: NSTextField?

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.autoresizingMask = .width
        self.setupUI()
    }

    func setupUI() {
        let searchTitleField = NSTextField(frame: NSRect.zero)
        searchTitleField.translatesAutoresizingMaskIntoConstraints = false
        searchTitleField.stringValue = L10n.search
        searchTitleField.isBordered = false
        searchTitleField.isEditable = false
        searchTitleField.isEnabled = false
        searchTitleField.drawsBackground = false
        searchTitleField.font = NSFont.menuFont(ofSize: 0)
        searchTitleField.textColor = NSColor.controlTextColor
        self.addSubview(searchTitleField)

        let searchQueryField = NSTextField(frame: NSRect.zero)
        searchQueryField.translatesAutoresizingMaskIntoConstraints = false
        searchQueryField.stringValue = ""
        searchQueryField.isBordered = true
        searchQueryField.isEditable = true
        searchQueryField.isEnabled = true
        searchQueryField.isBezeled = true
        searchQueryField.isHidden = false
        searchQueryField.bezelStyle = NSTextField.BezelStyle.roundedBezel
        searchQueryField.delegate = self
        searchQueryField.font = NSFont.menuFont(ofSize: 0)
        searchQueryField.textColor = NSColor.controlTextColor
        searchQueryField.usesSingleLineMode = true // cell!.usesSingleLineMode = true
        searchQueryField.lineBreakMode = NSLineBreakMode.byTruncatingHead
        self.addSubview(searchQueryField)
        self.searchQueryField = searchQueryField

        let views = ["searchTitleField": searchTitleField, "searchQueryField": searchQueryField]
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[searchTitleField]-[searchQueryField]-(==10)-|", options: [], metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(==6)-[searchTitleField]", options: [], metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[searchQueryField]-(==0)-|", options: [], metrics: nil, views: views))
    }

    func controlTextDidChange(_ obj: Notification) {
        AppEnvironment.current.menuService.searchQuery = self.searchQueryField?.stringValue ?? ""
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.searchQueryUpdated), object: nil)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            window?.makeFirstResponder(window)
            return true
        } else if commandSelector == #selector(NSResponder.insertTab(_:)) {
            window?.makeFirstResponder(window)
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            window?.makeFirstResponder(window)
            return true
        } else if commandSelector == #selector(NSResponder.moveUp(_:)) {
            window?.makeFirstResponder(window)
            return true
        } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
            window?.makeFirstResponder(window)
            return true
        }

        return false
    }
}
