' ********** Copyright 2026  All Rights Reserved. **********
' Scoreboard.brs — single source of truth for all game state and input.
' TeamPanel is a dumb renderer driven entirely by this file.

sub init()
    m.leftPanel = m.top.findNode("leftPanel")
    m.rightPanel = m.top.findNode("rightPanel")
    m.hintLabel = m.top.findNode("hintLabel")

    m.leftScores = []
    m.rightScores = []
    m.leftName = "PLAYER 1"
    m.rightName = "PLAYER 2"

    ' "left" or "right" — which team is focused.
    m.focusedTeam = "left"
    m.keyboardDialog = invalid

    ' Cursor index into the scores array. count() = "append new round" slot.
    m.leftCursor = 0
    m.rightCursor = 0
    ' Cached scroll offsets so moveCursor can compare without reading child fields.
    m.leftOffset = 0
    m.rightOffset = 0
    m.editMode = false

    m.repeatDirection = ""
    m.repeatFast = false
    m.repeatDelayTimer = m.top.findNode("repeatDelayTimer")
    m.repeatDelayTimer.observeField("fire", "onRepeatDelayTimerFire")
    m.repeatTimer = m.top.findNode("repeatTimer")
    m.repeatTimer.observeField("fire", "onRepeatTimerFire")
    m.repeatAccelTimer = m.top.findNode("repeatAccelTimer")
    m.repeatAccelTimer.observeField("fire", "onRepeatAccelTimerFire")

    m.leftPanel.cursorIndex = m.leftCursor
    m.rightPanel.cursorIndex = -1

    refreshFocusRings()
    refreshHint()
end sub

' ---- score helpers -------------------------------------------------------

function computeTotal(scores as object) as integer
    total = 0
    for each s in scores
        total = total + s
    next
    return total
end function

' Returns the first visible array index, scrolled to keep cursorIdx in view.
function computeOffset(scores as object, cursorIdx as integer) as integer
    startIdx = scores.count() - 6
    if startIdx < 0 then startIdx = 0
    if cursorIdx >= 0 and cursorIdx < scores.count()
        if cursorIdx < startIdx then startIdx = cursorIdx
        if cursorIdx > startIdx + 5 then startIdx = cursorIdx - 5
    end if
    return startIdx
end function

function formatRoundScores(scores as object, startIdx as integer) as string
    if scores.count() = 0 then return ""
    text = ""
    endIdx = startIdx + 5
    if endIdx >= scores.count() then endIdx = scores.count() - 1
    for i = startIdx to endIdx
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

sub refreshHint()
    if m.editMode
        m.hintLabel.text = "Up/Down: adjust score   OK / Back: done"
    else
        m.hintLabel.text = "Up/Down: select round   OK: edit / add   Left/Right: switch   *: rename"
    end if
end sub

' Push score totals and visible round history to both panels.
sub pushScores()
    m.leftOffset = computeOffset(m.leftScores, m.leftCursor)
    m.leftPanel.score = computeTotal(m.leftScores)
    m.leftPanel.roundOffset = m.leftOffset
    m.leftPanel.roundScores = formatRoundScores(m.leftScores, m.leftOffset)

    m.rightOffset = computeOffset(m.rightScores, m.rightCursor)
    m.rightPanel.score = computeTotal(m.rightScores)
    m.rightPanel.roundOffset = m.rightOffset
    m.rightPanel.roundScores = formatRoundScores(m.rightScores, m.rightOffset)
end sub

' ---- navigate helpers ----------------------------------------------------

sub moveCursor(direction as string)
    if m.focusedTeam = "left"
        maxIdx = m.leftScores.count()
        if direction = "up"
            if m.leftCursor > 0 then m.leftCursor = m.leftCursor - 1
        else
            if m.leftCursor < maxIdx then m.leftCursor = m.leftCursor + 1
        end if
        newOffset = computeOffset(m.leftScores, m.leftCursor)
        if newOffset <> m.leftOffset
            m.leftOffset = newOffset
            m.leftPanel.roundOffset = newOffset
            m.leftPanel.roundScores = formatRoundScores(m.leftScores, newOffset)
        end if
        m.leftPanel.cursorIndex = m.leftCursor
    else
        maxIdx = m.rightScores.count()
        if direction = "up"
            if m.rightCursor > 0 then m.rightCursor = m.rightCursor - 1
        else
            if m.rightCursor < maxIdx then m.rightCursor = m.rightCursor + 1
        end if
        newOffset = computeOffset(m.rightScores, m.rightCursor)
        if newOffset <> m.rightOffset
            m.rightOffset = newOffset
            m.rightPanel.roundOffset = newOffset
            m.rightPanel.roundScores = formatRoundScores(m.rightScores, newOffset)
        end if
        m.rightPanel.cursorIndex = m.rightCursor
    end if
end sub

sub exitEditMode()
    m.editMode = false
    m.leftPanel.editMode = false
    m.rightPanel.editMode = false
    ' Move cursor to the append slot so the next OK adds a new round.
    if m.focusedTeam = "left"
        m.leftCursor = m.leftScores.count()
        newOffset = computeOffset(m.leftScores, m.leftCursor)
        if newOffset <> m.leftOffset
            m.leftOffset = newOffset
            m.leftPanel.roundOffset = newOffset
            m.leftPanel.roundScores = formatRoundScores(m.leftScores, newOffset)
        end if
        m.leftPanel.cursorIndex = m.leftCursor
    else
        m.rightCursor = m.rightScores.count()
        newOffset = computeOffset(m.rightScores, m.rightCursor)
        if newOffset <> m.rightOffset
            m.rightOffset = newOffset
            m.rightPanel.roundOffset = newOffset
            m.rightPanel.roundScores = formatRoundScores(m.rightScores, newOffset)
        end if
        m.rightPanel.cursorIndex = m.rightCursor
    end if
    stopRepeatTimers()
    refreshHint()
end sub

sub stopRepeatTimers()
    m.repeatDelayTimer.control = "stop"
    m.repeatTimer.control = "stop"
    m.repeatAccelTimer.control = "stop"
    m.repeatDirection = ""
    m.repeatFast = false
end sub

' ---- up/down logic (shared by key press and hold timer) -----------------

sub applyUpDown(direction as string)
    delta = 1
    if m.repeatFast then delta = 10

    if m.focusedTeam = "left"
        if m.leftScores.count() = 0 then return
        idx = m.leftCursor
        if idx < 0 or idx >= m.leftScores.count() then return
        if direction = "up"
            m.leftScores[idx] = m.leftScores[idx] + delta
        else
            newVal = m.leftScores[idx] - delta
            if newVal < 0 then newVal = 0
            m.leftScores[idx] = newVal
        end if
    else
        if m.rightScores.count() = 0 then return
        idx = m.rightCursor
        if idx < 0 or idx >= m.rightScores.count() then return
        if direction = "up"
            m.rightScores[idx] = m.rightScores[idx] + delta
        else
            newVal = m.rightScores[idx] - delta
            if newVal < 0 then newVal = 0
            m.rightScores[idx] = newVal
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

    if m.focusedTeam = "left"
        if m.leftScores.count() = 0 then return
        idx = m.leftCursor
        if idx < 0 or idx >= m.leftScores.count() then return
        val = m.leftScores[idx]
        if m.repeatDirection = "up"
            m.leftScores[idx] = (val \ 10 + 1) * 10
        else
            if val mod 10 = 0
                snapped = val - 10
            else
                snapped = (val \ 10) * 10
            end if
            if snapped < 0 then snapped = 0
            m.leftScores[idx] = snapped
        end if
    else
        if m.rightScores.count() = 0 then return
        idx = m.rightCursor
        if idx < 0 or idx >= m.rightScores.count() then return
        val = m.rightScores[idx]
        if m.repeatDirection = "up"
            m.rightScores[idx] = (val \ 10 + 1) * 10
        else
            if val mod 10 = 0
                snapped = val - 10
            else
                snapped = (val \ 10) * 10
            end if
            if snapped < 0 then snapped = 0
            m.rightScores[idx] = snapped
        end if
    end if
    pushScores()
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

function onKeyEvent(key as string, press as boolean) as boolean
    ' Up/Down handled on both press and release (timers need the release event).
    if key = "up" or key = "down"
        if m.editMode
            if press
                m.repeatDirection = key
                m.repeatFast = false
                applyUpDown(key)
                m.repeatDelayTimer.control = "start"
                m.repeatAccelTimer.control = "start"
            else
                stopRepeatTimers()
            end if
        else
            if press then moveCursor(key)
        end if
        return true
    end if

    if not press then return false

    handled = true

    if key = "left" or key = "right"
        if m.editMode then exitEditMode()
        m.focusedTeam = key
        if m.focusedTeam = "left"
            m.leftPanel.cursorIndex = m.leftCursor
            m.rightPanel.cursorIndex = -1
        else
            m.rightPanel.cursorIndex = m.rightCursor
            m.leftPanel.cursorIndex = -1
        end if
        refreshFocusRings()

    else if key = "OK"
        if m.editMode
            exitEditMode()
        else
            if m.focusedTeam = "left"
                if m.leftCursor >= m.leftScores.count()
                    m.leftScores.push(0)
                    m.leftCursor = m.leftScores.count() - 1
                    pushScores()
                end if
                m.editMode = true
                m.leftPanel.cursorIndex = m.leftCursor
                m.leftPanel.editMode = true
            else
                if m.rightCursor >= m.rightScores.count()
                    m.rightScores.push(0)
                    m.rightCursor = m.rightScores.count() - 1
                    pushScores()
                end if
                m.editMode = true
                m.rightPanel.cursorIndex = m.rightCursor
                m.rightPanel.editMode = true
            end if
            refreshHint()
        end if

    else if key = "back"
        if m.editMode
            exitEditMode()
        else
            handled = false
        end if

    else if key = "options"
        openNameEntryForFocusedTeam()

    else
        handled = false
    end if

    return handled
end function
