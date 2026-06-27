' ********** Copyright 2026  All Rights Reserved. **********
' Scoreboard.brs — single source of truth for all game state and input.
' NumberEntry and TeamPanel are dumb renderers driven entirely by this file.

sub init()
    m.leftPanel = m.top.findNode("leftPanel")
    m.rightPanel = m.top.findNode("rightPanel")
    m.numberEntry = m.top.findNode("numberEntry")

    m.leftScores = []
    m.rightScores = []
    m.leftName = "PLAYER 1"
    m.rightName = "PLAYER 2"

    ' Digit buffer for the number-entry overlay.
    m.digits = ""

    ' "left" or "right" — which team currently responds to up/down.
    m.focusedTeam = "left"
    m.keyboardDialog = invalid

    refreshFocusRings()
end sub

' ---- score helpers -------------------------------------------------------

function computeTotal(scores as object) as integer
    total = 0
    for each s in scores
        total = total + s
    next
    return total
end function

function formatRoundScores(scores as object) as string
    if scores.count() = 0 then return ""
    text = ""
    startIdx = scores.count() - 6
    if startIdx < 0 then startIdx = 0
    for i = startIdx to scores.count() - 1
        if text = ""
            text = scores[i].toStr()
        else
            text = text + chr(10) + scores[i].toStr()
        end if
    next
    return text
end function

' ---- rendering helpers ---------------------------------------------------

sub refreshFocusRings()
    m.leftPanel.focused = (m.focusedTeam = "left")
    m.rightPanel.focused = (m.focusedTeam = "right")
end sub

sub pushScores()
    m.leftPanel.score = computeTotal(m.leftScores)
    m.leftPanel.roundScores = formatRoundScores(m.leftScores)
    m.rightPanel.score = computeTotal(m.rightScores)
    m.rightPanel.roundScores = formatRoundScores(m.rightScores)
end sub

' ---- number-entry overlay ------------------------------------------------

sub openNumberEntryForFocusedTeam()
    m.digits = ""
    m.numberEntry.digits = "0"

    if m.focusedTeam = "left"
        m.numberEntry.promptText = "Add round for " + m.leftName
    else
        m.numberEntry.promptText = "Add round for " + m.rightName
    end if

    m.numberEntry.visible = true
end sub

' ---- name entry (keyboard dialog) ----------------------------------------

sub openNameEntryForFocusedTeam()
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = "Rename Player"
    dialog.buttons = ["OK", "Cancel"]
    m.top.getScene().appendChild(dialog)
    m.keyboardDialog = dialog
    dialog.observeField("buttonSelected", "onNameEntryButtonSelected")
    dialog.setFocus(true)
end sub

sub onNameEntryButtonSelected()
    if m.keyboardDialog.buttonSelected = 0  ' OK
        newName = UCase(m.keyboardDialog.keyboard.text.trim())
        if newName <> ""
            if m.focusedTeam = "left"
                m.leftName = newName
                m.leftPanel.teamName = newName
            else
                m.rightName = newName
                m.rightPanel.teamName = newName
            end if
        end if
    end if
    m.top.getScene().removeChild(m.keyboardDialog)
    m.keyboardDialog = invalid
    m.top.setFocus(true)
end sub

' ---- remote input --------------------------------------------------------
' Scoreboard holds focus for the entire lifetime of the scene. When the
' number-entry overlay is visible, onKeyEvent handles digit input directly
' rather than delegating — no callFunc or focus transfers needed.

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    ' ---- number-entry overlay active ------------------------------------
    if m.numberEntry.visible
        if key >= "0" and key <= "9"
            if Len(m.digits) < 3
                m.digits = m.digits + key
                m.numberEntry.digits = m.digits
            end if

        else if key = "OK"
            newScore = 0
            if m.digits <> "" then newScore = m.digits.toInt()
            if m.focusedTeam = "left"
                m.leftScores.push(newScore)
            else
                m.rightScores.push(newScore)
            end if
            pushScores()
            m.numberEntry.visible = false
            m.digits = ""

        else if key = "back"
            if Len(m.digits) > 0
                m.digits = Left(m.digits, Len(m.digits) - 1)
                if m.digits = ""
                    m.numberEntry.digits = "0"
                else
                    m.numberEntry.digits = m.digits
                end if
            else
                m.numberEntry.visible = false
                m.digits = ""
            end if
        end if

        return true ' consume all keys while overlay is open
    end if

    ' ---- normal scoreboard input ----------------------------------------
    handled = true

    if key = "left" or key = "right"
        m.focusedTeam = key
        refreshFocusRings()

    else if key = "up"
        if m.focusedTeam = "left"
            if m.leftScores.count() = 0
                m.leftScores.push(1)
            else
                lastIdx = m.leftScores.count() - 1
                m.leftScores[lastIdx] = m.leftScores[lastIdx] + 1
            end if
        else
            if m.rightScores.count() = 0
                m.rightScores.push(1)
            else
                lastIdx = m.rightScores.count() - 1
                m.rightScores[lastIdx] = m.rightScores[lastIdx] + 1
            end if
        end if
        pushScores()

    else if key = "down"
        if m.focusedTeam = "left"
            if m.leftScores.count() > 0
                lastIdx = m.leftScores.count() - 1
                if m.leftScores[lastIdx] > 0
                    m.leftScores[lastIdx] = m.leftScores[lastIdx] - 1
                end if
            end if
        else
            if m.rightScores.count() > 0
                lastIdx = m.rightScores.count() - 1
                if m.rightScores[lastIdx] > 0
                    m.rightScores[lastIdx] = m.rightScores[lastIdx] - 1
                end if
            end if
        end if
        pushScores()

    else if key = "OK"
        openNumberEntryForFocusedTeam()

    else if key = "options"
        openNameEntryForFocusedTeam()

    else
        handled = false
    end if

    return handled
end function
