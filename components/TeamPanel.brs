' ********** Copyright 2026  All Rights Reserved. **********
' TeamPanel.brs — purely presentational. It renders whatever score/name
' it's given and reports its own focus state visually. All game rules
' (when to increment, win conditions, etc.) live in Scoreboard.brs.

sub init()
    m.nameLabel = m.top.findNode("nameLabel")
    m.scoreLabel = m.top.findNode("scoreLabel")
    m.focusRing = m.top.findNode("focusRing")
end sub

sub onTeamNameChange()
    m.nameLabel.text = m.top.teamName
end sub

sub onScoreChange()
    m.scoreLabel.text = m.top.score.toStr()
end sub

sub onFocusedChange()
    if m.top.focused
        m.focusRing.color = "0xD4AF37FF"
    else
        m.focusRing.color = "0x00000000"
    end if
end sub
