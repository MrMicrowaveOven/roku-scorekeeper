' ********** Copyright 2026  All Rights Reserved. **********
' TeamPanel.brs — purely presentational. Renders whatever Scoreboard sets.

sub init()
    m.nameLabel   = m.top.findNode("nameLabel")
    m.roundsGroup = m.top.findNode("roundsGroup")
    m.totalLabel  = m.top.findNode("totalLabel")
    m.focusRing   = m.top.findNode("focusRing")
    m.divider1    = m.top.findNode("divider1")
    m.divider2    = m.top.findNode("divider2")
    applyLayout()
end sub

' ---- layout --------------------------------------------------------------

sub onPanelWidthChange()
    applyLayout()
    rebuildRounds()
end sub

function layoutMargin(pw as integer) as integer
    if pw >= 400 then return 40
    if pw >= 250 then return 20
    return 10
end function

sub applyLayout()
    pw     = m.top.panelWidth
    margin = layoutMargin(pw)
    cw     = pw - 2 * margin
    if cw < 30 then cw = 30

    if pw >= 250
        m.nameLabel.font = "font:LargeBoldSystemFont"
    else if pw >= 180
        m.nameLabel.font = "font:MediumBoldSystemFont"
    else
        m.nameLabel.font = "font:SmallBoldSystemFont"
    end if

    m.focusRing.width = pw

    m.nameLabel.translation = [margin, 20]
    m.nameLabel.width       = cw

    m.divider1.translation = [margin, 76]
    m.divider1.width       = cw

    m.roundsGroup.translation = [margin, 102]

    m.divider2.translation = [margin, 752]
    m.divider2.width       = cw

    m.totalLabel.translation = [margin, 760]
    m.totalLabel.width       = cw
end sub

' ---- field observers -----------------------------------------------------

sub onTeamNameChange()
    m.nameLabel.text = m.top.teamName
end sub

sub onScoreChange()
    m.totalLabel.text = m.top.score.toStr()
end sub

sub onRoundScoresChange()
    rebuildRounds()
end sub

sub onCursorIndexChange()
    if m.top.cursorIndex = -2
        m.nameLabel.color = "0x000000FF"   ' black on gold = name selected
    else
        m.nameLabel.color = "0xFFFFFFFF"
    end if
    rebuildRounds()
end sub

sub onEditModeChange()
    rebuildRounds()
end sub

sub onFocusedChange()
    if m.top.focused
        m.focusRing.color = "0xD4AF37FF"
    else
        m.focusRing.color = "0x00000000"
    end if
end sub

' ---- round rendering -----------------------------------------------------

sub rebuildRounds()
    for i = m.roundsGroup.getChildCount() - 1 to 0 step -1
        m.roundsGroup.removeChildIndex(i)
    next

    rounds = []
    if m.top.roundScores <> ""
        rounds = splitOnNewline(m.top.roundScores)
    end if

    pw     = m.top.panelWidth
    margin = layoutMargin(pw)
    cw     = pw - 2 * margin
    if cw < 30 then cw = 30

    lineHeight       = 60
    cursorDisplayIdx = m.top.cursorIndex - m.top.roundOffset
    isEditMode       = m.top.editMode

    twoCol   = (rounds.count() >= 10)
    colGap   = 10
    col1W    = int((cw - colGap) / 2)
    col2X    = col1W + colGap
    col2W    = cw - col2X

    ' Divider and total always span the full content width
    m.divider2.width   = cw
    m.totalLabel.width = cw

    if twoCol
        ' Left column: rounds 0-9
        lastLeft = 9
        if lastLeft > rounds.count() - 1 then lastLeft = rounds.count() - 1
        for i = 0 to lastLeft
            lbl = CreateObject("roSGNode", "Label")
            lbl.text        = rounds[i]
            lbl.width       = col1W
            lbl.height      = lineHeight
            lbl.horizAlign  = "center"
            lbl.translation = [0, i * lineHeight]
            lbl.font        = "font:LargeBoldSystemFont"
            if i = cursorDisplayIdx
                if isEditMode
                    lbl.color = "0x00FFFFFF"
                else
                    lbl.color = "0x000000FF"
                end if
            else
                lbl.color = "0xFFFFFFFF"
            end if
            m.roundsGroup.appendChild(lbl)
        next

        ' Right column: rounds 10+
        for i = 10 to rounds.count() - 1
            lbl = CreateObject("roSGNode", "Label")
            lbl.text        = rounds[i]
            lbl.width       = col2W
            lbl.height      = lineHeight
            lbl.horizAlign  = "center"
            lbl.translation = [col2X, (i - 10) * lineHeight]
            lbl.font        = "font:LargeBoldSystemFont"
            if i = cursorDisplayIdx
                if isEditMode
                    lbl.color = "0x00FFFFFF"
                else
                    lbl.color = "0x000000FF"
                end if
            else
                lbl.color = "0xFFFFFFFF"
            end if
            m.roundsGroup.appendChild(lbl)
        next

        ' Append slot in right column
        if cursorDisplayIdx >= 0 and cursorDisplayIdx = rounds.count()
            yPos       = (rounds.count() - 10) * lineHeight
            squareSize = 40
            squareX    = col2X + (col2W - squareSize) / 2

            outer = CreateObject("roSGNode", "Rectangle")
            outer.width       = squareSize
            outer.height      = squareSize
            outer.color       = "0x000000C0"
            outer.translation = [squareX, yPos]
            m.roundsGroup.appendChild(outer)

            inner = CreateObject("roSGNode", "Rectangle")
            inner.width       = squareSize - 6
            inner.height      = squareSize - 6
            inner.color       = "0xD4AF37FF"
            inner.translation = [squareX + 3, yPos + 3]
            m.roundsGroup.appendChild(inner)

            plusLbl = CreateObject("roSGNode", "Label")
            plusLbl.text        = "+"
            plusLbl.width       = col2W
            plusLbl.height      = lineHeight
            plusLbl.horizAlign  = "center"
            plusLbl.vertAlign   = "center"
            plusLbl.font        = "font:LargeBoldSystemFont"
            plusLbl.color       = "0x000000FF"
            plusLbl.translation = [col2X, yPos - (lineHeight - squareSize) / 2]
            m.roundsGroup.appendChild(plusLbl)
        end if
    else
        ' Single column
        for i = 0 to rounds.count() - 1
            lbl = CreateObject("roSGNode", "Label")
            lbl.text        = rounds[i]
            lbl.width       = cw
            lbl.height      = lineHeight
            lbl.horizAlign  = "center"
            lbl.translation = [0, i * lineHeight]
            lbl.font        = "font:LargeBoldSystemFont"
            if i = cursorDisplayIdx
                if isEditMode
                    lbl.color = "0x00FFFFFF"
                else
                    lbl.color = "0x000000FF"
                end if
            else
                lbl.color = "0xFFFFFFFF"
            end if
            m.roundsGroup.appendChild(lbl)
        next

        ' Append slot
        if cursorDisplayIdx >= 0 and cursorDisplayIdx = rounds.count()
            yPos       = cursorDisplayIdx * lineHeight
            squareSize = 40
            squareX    = (cw - squareSize) / 2

            outer = CreateObject("roSGNode", "Rectangle")
            outer.width       = squareSize
            outer.height      = squareSize
            outer.color       = "0x000000C0"
            outer.translation = [squareX, yPos]
            m.roundsGroup.appendChild(outer)

            inner = CreateObject("roSGNode", "Rectangle")
            inner.width       = squareSize - 6
            inner.height      = squareSize - 6
            inner.color       = "0xD4AF37FF"
            inner.translation = [squareX + 3, yPos + 3]
            m.roundsGroup.appendChild(inner)

            plusLbl = CreateObject("roSGNode", "Label")
            plusLbl.text        = "+"
            plusLbl.width       = cw
            plusLbl.height      = lineHeight
            plusLbl.horizAlign  = "center"
            plusLbl.vertAlign   = "center"
            plusLbl.font        = "font:LargeBoldSystemFont"
            plusLbl.color       = "0x000000FF"
            plusLbl.translation = [0, yPos - (lineHeight - squareSize) / 2]
            m.roundsGroup.appendChild(plusLbl)
        end if
    end if
end sub

function splitOnNewline(inputStr as string) as object
    parts    = []
    lineStart = 1
    strLen   = Len(inputStr)
    for charIdx = 1 to strLen
        if Asc(Mid(inputStr, charIdx, 1)) = 10
            parts.push(Mid(inputStr, lineStart, charIdx - lineStart))
            lineStart = charIdx + 1
        end if
    next
    parts.push(Mid(inputStr, lineStart))
    return parts
end function
