' ********** Copyright 2026  All Rights Reserved. **********
' HomeScene.brs — shows player-count dialog on launch, then hands focus to Scoreboard.

sub init()
    m.scoreboard = m.top.findNode("Scoreboard")
    m.playerCountHandled = false
    showPlayerCountDialog()
end sub

sub showPlayerCountDialog()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "How many players?"
    dialog.message = " "
    dialog.buttons = ["1", "2", "3", "4", "5", "6", "7", "8"]
    dialog.buttonFocused = 1  ' default: index 1 = "2"
    m.top.appendChild(dialog)
    m.playerCountDialog = dialog
    dialog.observeField("buttonSelected", "onPlayerCountSelected")
    dialog.setFocus(true)
end sub

sub onPlayerCountSelected()
    if m.playerCountHandled then return
    m.playerCountHandled = true
    bs = m.playerCountDialog.buttonSelected
    if bs < 0
        n = 2
    else
        n = bs + 1
    end if
    m.top.removeChild(m.playerCountDialog)
    m.playerCountDialog = invalid
    m.scoreboard.playerCount = n
    m.scoreboard.setFocus(true)
end sub
