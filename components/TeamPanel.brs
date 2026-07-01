' ********** Copyright 2026  All Rights Reserved. **********
' TeamPanel.brs — purely presentational. Renders whatever Scoreboard sets.

sub init()
    m.nameLabel   = m.top.findNode("nameLabel")
    m.penPoster   = m.top.findNode("penPoster")
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
    ' Position pencil at right edge of name row, nudged slightly inward
    m.penPoster.translation = [margin + cw - 48, 20 + (50 - 28) / 2]

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
        m.nameLabel.color  = "0x000000FF"
        m.penPoster.visible = true
    else
        m.nameLabel.color   = "0xFFFFFFFF"
        m.penPoster.visible = false
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

    cursorDisplayIdx = m.top.cursorIndex - m.top.roundOffset
    isEditMode       = m.top.editMode

    twoCol = (rounds.count() >= 10)
    colGap = 10
    col1W  = int((cw - colGap) / 2)
    col2X  = col1W + colGap
    col2W  = cw - col2X

    ' Dynamic split and lineHeight for two-column mode.
    ' splitAt grows so both columns fill together once col2 exceeds 10 rows.
    ' lineHeight shrinks as needed; floor 36px; font drops at 50px.
    lineHeight = 60
    roundFont  = "font:LargeBoldSystemFont"
    squareSize = 40
    splitAt    = 10
    if twoCol
        ' ceil(N/2), but never below 10 — keeps the initial 10/0 split until col2 fills
        splitAt    = int((rounds.count() + 1) / 2)
        if splitAt < 10 then splitAt = 10
        leftSlots  = splitAt
        rightSlots = rounds.count() - splitAt + 1   ' right rounds + append button
        maxSlots   = rightSlots
        if leftSlots > maxSlots then maxSlots = leftSlots
        lineHeight = int(650 / maxSlots)
        if lineHeight > 60 then lineHeight = 60
        if lineHeight < 36 then lineHeight = 36
        if lineHeight < 50 then roundFont = "font:MediumBoldSystemFont"
        squareSize = int(lineHeight * 0.65)
        if squareSize > 40 then squareSize = 40
        if squareSize < 20 then squareSize = 20
    end if

    ' Divider and total always span the full content width
    m.divider2.width   = cw
    m.totalLabel.width = cw

    if twoCol
        ' Left column: rounds 0 to splitAt-1
        lastLeft = splitAt - 1
        if lastLeft > rounds.count() - 1 then lastLeft = rounds.count() - 1
        for i = 0 to lastLeft
            lbl = CreateObject("roSGNode", "Label")
            lbl.text        = rounds[i]
            lbl.width       = col1W
            lbl.height      = lineHeight
            lbl.horizAlign  = "center"
            lbl.translation = [0, i * lineHeight]
            lbl.font        = roundFont
            if i = cursorDisplayIdx
                if isEditMode
                    lbl.color = "0x00FFFFFF"
                else
                    lbl.color = "0x000000FF"
                    addEditHint(0, i * lineHeight, col1W, lineHeight)
                end if
            else
                lbl.color = "0xFFFFFFFF"
            end if
            m.roundsGroup.appendChild(lbl)
        next

        ' Right column: rounds splitAt+
        for i = splitAt to rounds.count() - 1
            lbl = CreateObject("roSGNode", "Label")
            lbl.text        = rounds[i]
            lbl.width       = col2W
            lbl.height      = lineHeight
            lbl.horizAlign  = "center"
            lbl.translation = [col2X, (i - splitAt) * lineHeight]
            lbl.font        = roundFont
            if i = cursorDisplayIdx
                if isEditMode
                    lbl.color = "0x00FFFFFF"
                else
                    lbl.color = "0x000000FF"
                    addEditHint(col2X, (i - splitAt) * lineHeight, col2W, lineHeight)
                end if
            else
                lbl.color = "0xFFFFFFFF"
            end if
            m.roundsGroup.appendChild(lbl)
        next

        ' Append slot or max-rounds notice in right column
        yPos = (rounds.count() - splitAt) * lineHeight
        if rounds.count() >= 36
            maxLbl = CreateObject("roSGNode", "Label")
            maxLbl.text        = "Max rounds"
            maxLbl.width       = col2W
            maxLbl.height      = lineHeight
            maxLbl.horizAlign  = "center"
            maxLbl.vertAlign   = "center"
            maxLbl.font        = "font:SmallBoldSystemFont"
            maxLbl.color       = "0xFFFFFF50"
            maxLbl.translation = [col2X, yPos]
            m.roundsGroup.appendChild(maxLbl)
        else if cursorDisplayIdx >= 0 and cursorDisplayIdx = rounds.count()
            squareX = col2X + (col2W - squareSize) / 2

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
            plusLbl.font        = roundFont
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
                    addEditHint(0, i * lineHeight, cw, lineHeight)
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

sub addEditHint(x as integer, y as integer, w as integer, h as integer)
    ps = 28   ' pencil icon display size (square)
    ' Place pencil just past the score value (centre-aligned text ends ~w/2 + ~35px)
    ' Clamp so it never spills outside the column
    penX = x + w / 2 + 35
    if penX + ps > x + w then penX = x + w - ps
    hint = CreateObject("roSGNode", "Poster")
    hint.uri         = "pkg:/images/pencil.png"
    hint.width       = ps
    hint.height      = ps
    hint.translation = [penX, y + (h - ps) / 2 - 5]
    m.roundsGroup.appendChild(hint)
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
