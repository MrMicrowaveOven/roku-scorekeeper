' ********** Copyright 2026  All Rights Reserved. **********
' NumberEntry.brs — display only. Scoreboard.brs owns all key handling
' and drives this component entirely via its two public fields.

sub init()
    m.promptLabel = m.top.findNode("promptLabel")
    m.digitsLabel = m.top.findNode("digitsLabel")

    m.top.observeField("promptText", "onPromptTextChange")
    m.top.observeField("digits", "onDigitsChange")
end sub

sub onPromptTextChange()
    m.promptLabel.text = m.top.promptText
end sub

sub onDigitsChange()
    m.digitsLabel.text = m.top.digits
end sub
