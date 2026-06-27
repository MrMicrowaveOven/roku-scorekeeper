' ********** Copyright 2026  All Rights Reserved. **********
' HomeScene.brs — scene only delegates focus, no game logic lives here.

sub init()
    m.scoreboard = m.top.findNode("Scoreboard")
    m.scoreboard.setFocus(true)
end sub
