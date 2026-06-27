' ********** Copyright 2026  All Rights Reserved. **********
' NumberEntry.brs — owns key handling only while it is the active
' focus target. Scoreboard is responsible for giving/taking focus.

sub init()
    m.promptLabel = m.top.findNode("promptLabel")
    m.digitsLabel = m.top.findNode("digitsLabel")
    m.digits = ""

    m.top.observeField("promptText", "onPromptTextChange")
end sub

sub onPromptTextChange()
    m.promptLabel.text = m.top.promptText
end sub

' Call this right before showing the overlay to reset typed digits.
sub reset()
    m.digits = ""
    m.digitsLabel.text = "0"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    handled = true

    if key >= "0" and key <= "9"
        ' Cap at 3 digits — plenty for any real score, avoids overflow nonsense.
        if Len(m.digits) < 3
            m.digits = m.digits + key
            m.digitsLabel.text = m.digits
        end if

    else if key = "OK"
        if m.digits = ""
            m.digits = "0"
        end if
        m.top.confirmedValue = m.digits.toInt()

    else if key = "back"
        if Len(m.digits) > 0
            m.digits = Left(m.digits, Len(m.digits) - 1)
            if m.digits = ""
                m.digitsLabel.text = "0"
            else
                m.digitsLabel.text = m.digits
            end if
        else
            m.top.cancelled = true
        end if

    else
        handled = false
    end if

    return handled
end function
