' ********** Copyright 2026  All Rights Reserved. **********
' TeamPanel.brs — purely presentational. Renders whatever Scoreboard sets.

sub init()
    m.nameLabel = m.top.findNode("nameLabel")
    m.roundsGroup = m.top.findNode("roundsGroup")
    m.totalLabel = m.top.findNode("totalLabel")
    m.focusRing = m.top.findNode("focusRing")
end sub

sub onTeamNameChange()
    m.nameLabel.text = m.top.teamName
end sub

sub onScoreChange()
    m.totalLabel.text = "Total: " + m.top.score.toStr()
end sub

sub onRoundScoresChange()
    rebuildRounds()
end sub

sub onCursorIndexChange()
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

sub rebuildRounds()
    for i = m.roundsGroup.getChildCount() - 1 to 0 step -1
        m.roundsGroup.removeChildIndex(i)
    next

    rounds = []
    if m.top.roundScores <> ""
        rounds = splitOnNewline(m.top.roundScores)
    end if

    lineHeight = 80
    cursorDisplayIdx = m.top.cursorIndex - m.top.roundOffset
    isEditMode = m.top.editMode

    for i = 0 to rounds.count() - 1
        lbl = CreateObject("roSGNode", "Label")
        lbl.text = rounds[i]
        lbl.width = 340
        lbl.height = lineHeight
        lbl.horizAlign = "center"
        lbl.translation = [0, i * lineHeight]
        lbl.font = "font:LargeBoldSystemFont"
        if i = cursorDisplayIdx
            if isEditMode
                lbl.color = "0x00FFFFFF"  ' cyan = editing this round
            else
                lbl.color = "0x000000FF"  ' black = selected, not yet editing
            end if
        else
            lbl.color = "0xFFFFFFFF"
        end if
        m.roundsGroup.appendChild(lbl)
    next

    ' Plus-square at the append slot — cursor is one past the last displayed row.
    if cursorDisplayIdx >= 0 and cursorDisplayIdx = rounds.count()
        yPos = cursorDisplayIdx * lineHeight
        squareSize = 40
        squareX = (340 - squareSize) / 2

        outer = CreateObject("roSGNode", "Rectangle")
        outer.width = squareSize
        outer.height = squareSize
        outer.color = "0x000000C0"
        outer.translation = [squareX, yPos]
        m.roundsGroup.appendChild(outer)

        inner = CreateObject("roSGNode", "Rectangle")
        inner.width = squareSize - 6
        inner.height = squareSize - 6
        inner.color = "0xD4AF37FF"
        inner.translation = [squareX + 3, yPos + 3]
        m.roundsGroup.appendChild(inner)

        plusLbl = CreateObject("roSGNode", "Label")
        plusLbl.text = "+"
        plusLbl.width = 340
        plusLbl.height = squareSize
        plusLbl.horizAlign = "center"
        plusLbl.vertAlign = "center"
        plusLbl.font = "font:LargeBoldSystemFont"
        plusLbl.color = "0x000000FF"
        plusLbl.translation = [0, yPos]
        m.roundsGroup.appendChild(plusLbl)
    end if
end sub

function splitOnNewline(inputStr as string) as object
    parts = []
    lineStart = 1
    strLen = Len(inputStr)
    for charIdx = 1 to strLen
        if Asc(Mid(inputStr, charIdx, 1)) = 10
            parts.push(Mid(inputStr, lineStart, charIdx - lineStart))
            lineStart = charIdx + 1
        end if
    next
    parts.push(Mid(inputStr, lineStart))
    return parts
end function
