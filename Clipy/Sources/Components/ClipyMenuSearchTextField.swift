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

import AppKit
import Carbon
import Sauce

class ClipyMenuSearchTextField: NSView, NSTextFieldDelegate {

    var searchQueryField: NSTextField?

    private let eventSpecs = [
        EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventRawKeyDown)),
        EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventRawKeyRepeat))
    ]

    private var eventHandler: EventHandlerRef?

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
        searchQueryField.refusesFirstResponder = true
        searchQueryField.translatesAutoresizingMaskIntoConstraints = false
        searchQueryField.stringValue = ""

        let attrPlaceholderString = NSAttributedString(string: "type to search...", attributes: [
            NSAttributedString.Key.foregroundColor: NSColor.lightGray
        ])

        searchQueryField.placeholderAttributedString = attrPlaceholderString

        searchQueryField.isBordered = true
        searchQueryField.isEditable = true
        searchQueryField.isEnabled = false
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

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil {
            if let dispatcher = GetEventDispatcherTarget() {
                // Create pointer to our event processer.
                let eventProcessorPointer = UnsafeMutablePointer<Any>.allocate(capacity: 1)
                eventProcessorPointer.initialize(to: processInterceptedEvent)

                let eventHandlerCallback: EventHandlerUPP = { _, eventRef, userData in
                    guard let event = eventRef else { return noErr }
                    guard let callbackPointer = userData else { return noErr }

                    // Call our event processor from pointer.
                    let eventProcessPointer = UnsafeMutablePointer<(EventRef) -> (Bool)>(OpaquePointer(callbackPointer))
                    let eventProcessed = eventProcessPointer.pointee(event)

                    if eventProcessed {
                        return noErr
                    } else {
                        return OSStatus(Carbon.eventNotHandledErr)
                    }
                }

                InstallEventHandler(dispatcher, eventHandlerCallback, 2, eventSpecs, eventProcessorPointer, &eventHandler)
            }
        } else {
            RemoveEventHandler(eventHandler)
            DispatchQueue.main.async {
                self.setQuery("")
            }
        }
    }

    // Process query when search field was focused (i.e. user clicked on it).
    func controlTextDidChange(_ obj: Notification) {
        fireNotification()
    }

    // Switch to main window if Tab is pressed when search is focused.
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertTab(_:)) {
            window?.makeFirstResponder(window)
            return true
        }
        return false
    }

    private func fireNotification() {
        //      customMenu?.updateFilter(filter: queryField.stringValue)
        AppEnvironment.current.menuService.searchQuery = self.searchQueryField?.stringValue ?? ""
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.searchQueryUpdated), object: nil)
    }

    private func setQuery(_ newQuery: String) {
        guard searchQueryField?.stringValue != newQuery else {
            return
        }

        searchQueryField?.stringValue = newQuery
        fireNotification()
    }

    private func processInterceptedEvent(_ eventRef: EventRef) -> Bool {
        let firstResponder = window?.firstResponder
        if firstResponder == searchQueryField || firstResponder == searchQueryField!.currentEditor() {
            return false
        }

        guard let event = NSEvent(eventRef: UnsafeRawPointer(eventRef)) else {
            return false
        }

        if event.type != NSEvent.EventType.keyDown {
            return false
        }

        return processKeyDownEvent(event)
    }

    private func processKeyDownEvent(_ event: NSEvent) -> Bool {
        guard let key = Key(QWERTYKeyCode: Int(event.keyCode)) else {
            return false
        }
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if Keys.shouldPassThrough(key) {
            return false
        }

        switch key {
        case Key.delete:
            processDeleteKey(key: key, modifierFlags: modifierFlags)
            return true
        case Key.return, Key.keypadEnter, Key.upArrow, Key.downArrow:
            // pass through to native menu
            NSLog("ignoring up/down arrow")
            window?.makeFirstResponder(window)
            return false
        default:
            break
        }

        if modifierFlags.contains(.command) || modifierFlags.contains(.control) || modifierFlags.contains(.option) {
            return false
        }

        if let chars = event.charactersIgnoringModifiers {
            if chars.count == 1 {
                appendSearchField(chars)
                return true
            }
        }

        return false
    }

    private func processDeleteKey(key: Key, modifierFlags: NSEvent.ModifierFlags) {
        if let queryField = searchQueryField {
            if !queryField.stringValue.isEmpty {
                setQuery(String(queryField.stringValue.dropLast()))
            }
        }
    }

    private func processSelectionKey(menu: ClipyMenu?, key: Key, modifierFlags: NSEvent.ModifierFlags) {
        switch key {
        case .return, .keypadEnter:
            AppEnvironment.current.menuService.historyMenu?.select()
        default: ()
        }
    }

    private func appendSearchField(_ chars: String) {
        setQuery("\(searchQueryField?.stringValue ?? "")\(chars)")
    }
}
