' ********** Copyright 2026  All Rights Reserved. **********
' TeamPanel.brs — purely presentational. It renders whatever score/name
' it's given and reports its own focus state visually. All game rules
' (when to increment, win conditions, etc.) live in Scoreboard.brs.

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

' One Label node per round — avoids depending on chr(10) line-break
' support in the Label component.
sub onRoundScoresChange()
    for i = m.roundsGroup.getChildCount() - 1 to 0 step -1
        m.roundsGroup.removeChildIndex(i)
    next

    if m.top.roundScores = "" then return

    rounds = splitOnNewline(m.top.roundScores)
    lineHeight = 80

    for i = 0 to rounds.count() - 1
        lbl = CreateObject("roSGNode", "Label")
        lbl.text = rounds[i]
        lbl.width = 340
        lbl.height = lineHeight
        lbl.horizAlign = "center"
        lbl.translation = [0, i * lineHeight]
        lbl.font = "font:LargeBoldSystemFont"
        m.roundsGroup.appendChild(lbl)
    next
end sub

sub onFocusedChange()
    if m.top.focused
        m.focusRing.color = "0xD4AF37FF"
    else
        m.focusRing.color = "0x00000000"
    end if
end sub

' Split a string on chr(10) into an array of substrings.
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
