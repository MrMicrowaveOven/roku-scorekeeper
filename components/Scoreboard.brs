' ********** Copyright 2026  All Rights Reserved. **********
' Scoreboard.brs — single source of truth for all game state and input.
' TeamPanel is a dumb renderer driven entirely by this file.

sub init()
    m.leftPanel = m.top.findNode("leftPanel")
    m.rightPanel = m.top.findNode("rightPanel")

    m.leftScores = []
    m.rightScores = []
    m.leftName = "PLAYER 1"
    m.rightName = "PLAYER 2"

    ' "left" or "right" — which team currently responds to up/down.
    m.focusedTeam = "left"
    m.keyboardDialog = invalid

    m.repeatDirection = ""
    m.repeatFast = false
    m.repeatDelayTimer = m.top.findNode("repeatDelayTimer")
    m.repeatDelayTimer.observeField("fire", "onRepeatDelayTimerFire")
    m.repeatTimer = m.top.findNode("repeatTimer")
    m.repeatTimer.observeField("fire", "onRepeatTimerFire")
    m.repeatAccelTimer = m.top.findNode("repeatAccelTimer")
    m.repeatAccelTimer.observeField("fire", "onRepeatAccelTimerFire")

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

' ---- up/down logic (shared by key press and hold timer) -----------------

sub applyUpDown(direction as string)
    delta = 1
    if m.repeatFast then delta = 10

    if direction = "up"
        if m.focusedTeam = "left"
            if m.leftScores.count() = 0
                m.leftScores.push(delta)
            else
                lastIdx = m.leftScores.count() - 1
                m.leftScores[lastIdx] = m.leftScores[lastIdx] + delta
            end if
        else
            if m.rightScores.count() = 0
                m.rightScores.push(delta)
            else
                lastIdx = m.rightScores.count() - 1
                m.rightScores[lastIdx] = m.rightScores[lastIdx] + delta
            end if
        end if
    else if direction = "down"
        if m.focusedTeam = "left"
            if m.leftScores.count() > 0
                lastIdx = m.leftScores.count() - 1
                newVal = m.leftScores[lastIdx] - delta
                if newVal < 0 then newVal = 0
                m.leftScores[lastIdx] = newVal
            end if
        else
            if m.rightScores.count() > 0
                lastIdx = m.rightScores.count() - 1
                newVal = m.rightScores[lastIdx] - delta
                if newVal < 0 then newVal = 0
                m.rightScores[lastIdx] = newVal
            end if
        end if
    end if
    pushScores()
end sub

sub onRepeatDelayTimerFire()
    if m.repeatDirection <> ""
        m.repeatTimer.control = "start"
    end if
end sub

sub onRepeatTimerFire()
    if m.repeatDirection <> ""
        applyUpDown(m.repeatDirection)
    end if
end sub

sub onRepeatAccelTimerFire()
    if m.repeatDirection = "" then return
    m.repeatFast = true
    ' Snap the last score to the nearest 10 boundary in the direction of travel.
    if m.focusedTeam = "left"
        if m.leftScores.count() = 0 then return
        lastIdx = m.leftScores.count() - 1
        val = m.leftScores[lastIdx]
        if m.repeatDirection = "up"
            m.leftScores[lastIdx] = (val \ 10 + 1) * 10
        else
            if val mod 10 = 0
                snapped = val - 10
            else
                snapped = (val \ 10) * 10
            end if
            if snapped < 0 then snapped = 0
            m.leftScores[lastIdx] = snapped
        end if
    else
        if m.rightScores.count() = 0 then return
        lastIdx = m.rightScores.count() - 1
        val = m.rightScores[lastIdx]
        if m.repeatDirection = "up"
            m.rightScores[lastIdx] = (val \ 10 + 1) * 10
        else
            if val mod 10 = 0
                snapped = val - 10
            else
                snapped = (val \ 10) * 10
            end if
            if snapped < 0 then snapped = 0
            m.rightScores[lastIdx] = snapped
        end if
    end if
    pushScores()
end sub

' ---- remote input --------------------------------------------------------

function onKeyEvent(key as string, press as boolean) as boolean
    ' Handle up/down on both press and release so the hold timer stays in sync.
    if key = "up" or key = "down"
        if press
            m.repeatDirection = key
            m.repeatFast = false
            applyUpDown(key)
            m.repeatDelayTimer.control = "start"
            m.repeatAccelTimer.control = "start"
        else
            m.repeatDelayTimer.control = "stop"
            m.repeatTimer.control = "stop"
            m.repeatAccelTimer.control = "stop"
            m.repeatDirection = ""
            m.repeatFast = false
        end if
        return true
    end if

    if not press then return false

    handled = true

    if key = "left" or key = "right"
        m.focusedTeam = key
        refreshFocusRings()

    else if key = "OK"
        if m.focusedTeam = "left"
            m.leftScores.push(0)
        else
            m.rightScores.push(0)
        end if
        pushScores()

    else if key = "options"
        openNameEntryForFocusedTeam()

    else
        handled = false
    end if

    return handled
end function
