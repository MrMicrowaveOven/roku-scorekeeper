' ********** Copyright 2026  All Rights Reserved. **********
' Scoreboard.brs — single source of truth for game state. TeamPanel
' and NumberEntry are dumb renderers; this file is the only place
' that decides what the score *means*.

sub init()
    m.leftPanel = m.top.findNode("leftPanel")
    m.rightPanel = m.top.findNode("rightPanel")
    m.numberEntry = m.top.findNode("numberEntry")

    m.leftScore = 0
    m.rightScore = 0

    ' "left" or "right" — which team currently responds to up/down.
    m.focusedTeam = "left"

    ' Listen for the overlay telling us it has a confirmed value or was cancelled.
    m.numberEntry.observeField("confirmedValue", "onNumberEntryConfirmed")
    m.numberEntry.observeField("cancelled", "onNumberEntryCancelled")

    refreshFocusRings()
end sub

' ---- rendering helpers -----------------------------------------------

sub refreshFocusRings()
    m.leftPanel.focused = (m.focusedTeam = "left")
    m.rightPanel.focused = (m.focusedTeam = "right")
end sub

sub pushScores()
    m.leftPanel.score = m.leftScore
    m.rightPanel.score = m.rightScore
end sub

' ---- overlay lifecycle -------------------------------------------------

sub openNumberEntryForFocusedTeam()
    m.numberEntry.callFunc("reset")

    if m.focusedTeam = "left"
        m.numberEntry.promptText = "Set HOME score"
    else
        m.numberEntry.promptText = "Set AWAY score"
    end if

    m.numberEntry.visible = true
    m.numberEntry.setFocus(true)
end sub

sub closeNumberEntry()
    m.numberEntry.visible = false
    m.top.setFocus(true)
end sub

sub onNumberEntryConfirmed()
    newValue = m.numberEntry.confirmedValue

    if m.focusedTeam = "left"
        m.leftScore = newValue
    else
        m.rightScore = newValue
    end if

    pushScores()
    closeNumberEntry()
end sub

sub onNumberEntryCancelled()
    closeNumberEntry()
end sub

' ---- remote input -------------------------------------------------------
' Scoreboard only receives key events while it holds focus, which is
' exactly the time the overlay should NOT be receiving them — and vice
' versa. We hand focus to numberEntry explicitly when it opens, so this
' handler never has to check "is the overlay up" itself.

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    handled = true

    if key = "left" or key = "right"
        m.focusedTeam = key
        refreshFocusRings()

    else if key = "up"
        if m.focusedTeam = "left"
            m.leftScore = m.leftScore + 1
        else
            m.rightScore = m.rightScore + 1
        end if
        pushScores()

    else if key = "down"
        if m.focusedTeam = "left"
            if m.leftScore > 0 then m.leftScore = m.leftScore - 1
        else
            if m.rightScore > 0 then m.rightScore = m.rightScore - 1
        end if
        pushScores()

    else if key = "OK"
        openNumberEntryForFocusedTeam()

    else
        handled = false
    end if

    return handled
end function
