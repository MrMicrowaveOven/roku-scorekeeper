' ********** Copyright 2026  All Rights Reserved. **********
' Scoreboard.brs — single source of truth for all game state and input.
' TeamPanel is a dumb renderer driven entirely by this file.

sub init()
    m.hintLabel = m.top.findNode("hintLabel")

    ' Per-player state (arrays indexed 0..N-1)
    m.panels  = []
    m.scores  = []   ' array of roArray (one per player)
    m.names   = []
    m.cursors = []   ' cursor index per player: -2=name, 0..count-1=round, count=append
    m.offsets = []   ' scroll offset per player

    m.focusedIdx = 0   ' which player has focus; == panels.count() means add-player slot
    m.editMode   = false
    m.panelWidth = 420
    m.panelGap   = 0

    m.keyboardDialog = invalid
    m.deleteDialog   = invalid   ' delete round
    m.confirmDialog  = invalid   ' delete player
    m.addPlayerBox   = invalid

    m.repeatDirection = ""
    m.repeatFast = false
    m.repeatDelayTimer = m.top.findNode("repeatDelayTimer")
    m.repeatDelayTimer.observeField("fire", "onRepeatDelayTimerFire")
    m.repeatTimer = m.top.findNode("repeatTimer")
    m.repeatTimer.observeField("fire", "onRepeatTimerFire")
    m.repeatAccelTimer = m.top.findNode("repeatAccelTimer")
    m.repeatAccelTimer.observeField("fire", "onRepeatAccelTimerFire")

    refreshHint()
end sub

' ---- player count field observer -----------------------------------------

sub onPlayerCountChange()
    n = m.top.playerCount
    if n < 1 then n = 1
    if n > 8 then n = 8
    setupPlayers(n)
end sub

' ---- layout helpers -------------------------------------------------------

sub computeLayout(n as integer)
    if n >= 8
        availW = 1920
    else
        availW = 1820   ' 100px reserved on right for add-player box
    end if
    pw = (availW - (n + 1) * 20) / n
    if pw > 420 then pw = 420
    if pw < 150 then pw = 150
    gap = (availW - n * pw) / (n + 1)
    if gap < 10 then gap = 10
    m.panelWidth = pw
    m.panelGap   = gap
end sub

sub relayoutPanels()
    n = m.panels.count()
    computeLayout(n)
    for i = 0 to n - 1
        xPos = m.panelGap + i * (m.panelWidth + m.panelGap)
        m.panels[i].translation = [xPos, 120]
        m.panels[i].panelWidth  = m.panelWidth
    next
    positionAddPlayerBox()
end sub

' ---- player setup ---------------------------------------------------------

sub setupPlayers(n as integer)
    for i = 0 to m.panels.count() - 1
        m.top.removeChild(m.panels[i])
    next
    if m.addPlayerBox <> invalid
        m.top.removeChild(m.addPlayerBox)
        m.addPlayerBox = invalid
    end if

    m.panels  = []
    m.scores  = []
    m.names   = []
    m.cursors = []
    m.offsets = []

    computeLayout(n)

    for i = 0 to n - 1
        panel = CreateObject("roSGNode", "TeamPanel")
        panel.panelWidth = m.panelWidth
        xPos = m.panelGap + i * (m.panelWidth + m.panelGap)
        panel.translation = [xPos, 120]
        name = "PLAYER " + (i + 1).toStr()
        panel.teamName   = name
        panel.cursorIndex = -1
        panel.focused    = false
        m.top.appendChild(panel)

        m.panels.push(panel)
        m.scores.push([])
        m.names.push(name)
        m.cursors.push(0)   ' 0 = append slot when no rounds exist
        m.offsets.push(0)
    next

    m.focusedIdx = 0
    m.editMode   = false

    if n < 8 then createAddPlayerBox()

    refreshFocusRings()
    pushScores()
    refreshHint()
end sub

' ---- add-player box -------------------------------------------------------

sub createAddPlayerBox()
    if m.addPlayerBox <> invalid then return
    grp = CreateObject("roSGNode", "Group")

    outer = CreateObject("roSGNode", "Rectangle")
    outer.id     = "addOuter"
    outer.width  = 64
    outer.height = 64
    outer.color  = "0x000000C0"
    outer.translation = [0, 0]
    grp.appendChild(outer)

    inner = CreateObject("roSGNode", "Rectangle")
    inner.id     = "addInner"
    inner.width  = 58
    inner.height = 58
    inner.color  = "0x555555FF"
    inner.translation = [3, 3]
    grp.appendChild(inner)

    lbl = CreateObject("roSGNode", "Label")
    lbl.id        = "addLabel"
    lbl.text      = "+"
    lbl.width     = 64
    lbl.height    = 64
    lbl.horizAlign = "center"
    lbl.vertAlign  = "center"
    lbl.font      = "font:LargeBoldSystemFont"
    lbl.color     = "0xFFFFFFFF"
    lbl.translation = [0, 0]
    grp.appendChild(lbl)

    m.top.appendChild(grp)
    m.addPlayerBox = grp
    positionAddPlayerBox()
end sub

sub positionAddPlayerBox()
    if m.addPlayerBox = invalid then return
    n = m.panels.count()
    if n = 0 then return
    lastX = m.panels[n - 1].translation[0]
    xPos  = lastX + m.panelWidth + 20
    yPos  = 120 + 310   ' vertically centred in the 680px panel area
    m.addPlayerBox.translation = [xPos, yPos]
end sub

sub updateAddPlayerBoxHighlight()
    if m.addPlayerBox = invalid then return
    inner = m.addPlayerBox.findNode("addInner")
    lbl   = m.addPlayerBox.findNode("addLabel")
    if m.focusedIdx = m.panels.count()
        inner.color = "0xD4AF37FF"   ' gold = focused
        lbl.color   = "0x000000FF"   ' black text on gold
    else
        inner.color = "0x555555FF"   ' grey = unfocused
        lbl.color   = "0xFFFFFFFF"
    end if
end sub

' ---- score helpers -------------------------------------------------------

function computeTotal(scores as object) as integer
    total = 0
    for each s in scores
        total = total + s
    next
    return total
end function

function computeOffset(scores as object, cursorIdx as integer) as integer
    startIdx = scores.count() - 6
    if startIdx < 0 then startIdx = 0
    if cursorIdx >= 0 and cursorIdx < scores.count()
        if cursorIdx < startIdx then startIdx = cursorIdx
        if cursorIdx > startIdx + 5 then startIdx = cursorIdx - 5
    end if
    return startIdx
end function

function formatRoundScores(scores as object, startIdx as integer) as string
    if scores.count() = 0 then return ""
    text   = ""
    endIdx = startIdx + 5
    if endIdx >= scores.count() then endIdx = scores.count() - 1
    for i = startIdx to endIdx
        if text = ""
            text = scores[i].toStr()
        else
            text = text + chr(10) + scores[i].toStr()
        end if
    next
    return text
end function

sub pushScores()
    for i = 0 to m.panels.count() - 1
        m.offsets[i] = computeOffset(m.scores[i], m.cursors[i])
        m.panels[i].score       = computeTotal(m.scores[i])
        m.panels[i].roundOffset = m.offsets[i]
        m.panels[i].roundScores = formatRoundScores(m.scores[i], m.offsets[i])
    next
end sub

' ---- rendering helpers ---------------------------------------------------

sub refreshFocusRings()
    for i = 0 to m.panels.count() - 1
        m.panels[i].focused = (i = m.focusedIdx)
    next
    updateAddPlayerBoxHighlight()
end sub

sub syncCursorDisplays()
    for i = 0 to m.panels.count() - 1
        if i = m.focusedIdx
            m.panels[i].cursorIndex = m.cursors[i]
        else
            m.panels[i].cursorIndex = -1
        end if
    next
end sub

' Mirror sourceCursor onto the currently focused player, clamped to their data.
sub syncDestCursor(sourceCursor as integer)
    if m.focusedIdx >= m.panels.count() then return
    destCount = m.scores[m.focusedIdx].count()
    if sourceCursor = -2
        m.cursors[m.focusedIdx] = -2
    else if sourceCursor >= 0 and sourceCursor < destCount
        m.cursors[m.focusedIdx] = sourceCursor   ' same round exists
    else
        m.cursors[m.focusedIdx] = destCount       ' clamp to append slot
    end if
    newOffset = computeOffset(m.scores[m.focusedIdx], m.cursors[m.focusedIdx])
    m.offsets[m.focusedIdx] = newOffset
end sub

sub refreshHint()
    if m.editMode
        m.hintLabel.text = "Up/Down: adjust score   OK / Back: done"
    else
        m.hintLabel.text = "Up/Down: select   OK: edit/add/rename   *: delete   Left/Right: switch"
    end if
end sub

' ---- navigate helpers ----------------------------------------------------

sub moveCursor(direction as string)
    if m.focusedIdx >= m.panels.count() then return

    cur   = m.cursors[m.focusedIdx]
    count = m.scores[m.focusedIdx].count()

    if direction = "up"
        if cur = -2
            ' already at name, no move
        else if cur = 0
            cur = -2
        else if cur > 0
            cur = cur - 1
        else if cur = count
            if count > 0 then cur = count - 1 else cur = -2
        end if
    else
        if cur = -2
            if count > 0 then cur = 0 else cur = count
        else if cur >= 0 and cur < count
            cur = cur + 1
        end if
        ' cur = count (append): no move
    end if

    m.cursors[m.focusedIdx] = cur
    newOffset = computeOffset(m.scores[m.focusedIdx], cur)
    if newOffset <> m.offsets[m.focusedIdx]
        m.offsets[m.focusedIdx] = newOffset
        m.panels[m.focusedIdx].roundOffset  = newOffset
        m.panels[m.focusedIdx].roundScores  = formatRoundScores(m.scores[m.focusedIdx], newOffset)
    end if
    m.panels[m.focusedIdx].cursorIndex = cur
end sub

sub exitEditMode()
    m.editMode = false
    for i = 0 to m.panels.count() - 1
        m.panels[i].editMode = false
    next
    if m.focusedIdx < m.panels.count()
        count = m.scores[m.focusedIdx].count()
        m.cursors[m.focusedIdx] = count
        newOffset = computeOffset(m.scores[m.focusedIdx], count)
        if newOffset <> m.offsets[m.focusedIdx]
            m.offsets[m.focusedIdx] = newOffset
            m.panels[m.focusedIdx].roundOffset = newOffset
            m.panels[m.focusedIdx].roundScores = formatRoundScores(m.scores[m.focusedIdx], newOffset)
        end if
        m.panels[m.focusedIdx].cursorIndex = count
    end if
    stopRepeatTimers()
    refreshHint()
end sub

sub stopRepeatTimers()
    m.repeatDelayTimer.control = "stop"
    m.repeatTimer.control      = "stop"
    m.repeatAccelTimer.control = "stop"
    m.repeatDirection = ""
    m.repeatFast      = false
end sub

' ---- up/down logic -------------------------------------------------------

sub applyUpDown(direction as string)
    if m.focusedIdx >= m.panels.count() then return
    delta = 1
    if m.repeatFast then delta = 10

    scores = m.scores[m.focusedIdx]
    if scores.count() = 0 then return
    idx = m.cursors[m.focusedIdx]
    if idx < 0 or idx >= scores.count() then return

    if direction = "up"
        m.scores[m.focusedIdx][idx] = scores[idx] + delta
    else
        newVal = scores[idx] - delta
        if newVal < 0 then newVal = 0
        m.scores[m.focusedIdx][idx] = newVal
    end if
    pushScores()
end sub

sub onRepeatDelayTimerFire()
    if m.repeatDirection <> "" then m.repeatTimer.control = "start"
end sub

sub onRepeatTimerFire()
    if m.repeatDirection <> "" then applyUpDown(m.repeatDirection)
end sub

sub onRepeatAccelTimerFire()
    if m.repeatDirection = "" then return
    if m.focusedIdx >= m.panels.count() then return
    m.repeatFast = true

    scores = m.scores[m.focusedIdx]
    if scores.count() = 0 then return
    idx = m.cursors[m.focusedIdx]
    if idx < 0 or idx >= scores.count() then return

    val = scores[idx]
    if m.repeatDirection = "up"
        m.scores[m.focusedIdx][idx] = (val \ 10 + 1) * 10
    else
        if val mod 10 = 0
            snapped = val - 10
        else
            snapped = (val \ 10) * 10
        end if
        if snapped < 0 then snapped = 0
        m.scores[m.focusedIdx][idx] = snapped
    end if
    pushScores()
end sub

' ---- delete round dialog -------------------------------------------------

sub openDeleteRoundDialog()
    if m.focusedIdx >= m.panels.count() then return
    idx    = m.cursors[m.focusedIdx]
    scores = m.scores[m.focusedIdx]
    if idx < 0 or idx >= scores.count() then return

    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Delete Round " + (idx + 1).toStr() + "?"
    dialog.buttons = ["Delete", "Cancel"]
    dialog.buttonFocused = 1
    m.top.getScene().appendChild(dialog)
    m.deleteDialog = dialog
    dialog.observeField("buttonSelected", "onDeleteRoundButtonSelected")
    dialog.setFocus(true)
end sub

sub onDeleteRoundButtonSelected()
    if m.deleteDialog.buttonSelected = 0
        pi  = m.focusedIdx
        idx = m.cursors[pi]
        scores = m.scores[pi]
        if idx >= 0 and idx < scores.count()
            newScores = []
            for i = 0 to scores.count() - 1
                if i <> idx then newScores.push(scores[i])
            next
            m.scores[pi]  = newScores
            m.cursors[pi] = newScores.count()   ' move to append slot
            pushScores()
            m.panels[pi].cursorIndex = m.cursors[pi]
        end if
    end if
    m.top.getScene().removeChild(m.deleteDialog)
    m.deleteDialog = invalid
    m.top.setFocus(true)
end sub

' ---- delete player dialog ------------------------------------------------

sub openDeletePlayerDialog()
    if m.panels.count() <= 1 then return   ' can't delete last player
    if m.focusedIdx >= m.panels.count() then return

    name = m.names[m.focusedIdx]
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Delete " + name + "?"
    dialog.buttons = ["Delete", "Cancel"]
    dialog.buttonFocused = 1
    m.top.getScene().appendChild(dialog)
    m.confirmDialog = dialog
    dialog.observeField("buttonSelected", "onDeletePlayerButtonSelected")
    dialog.setFocus(true)
end sub

sub onDeletePlayerButtonSelected()
    if m.confirmDialog.buttonSelected = 0 then deletePlayer(m.focusedIdx)
    m.top.getScene().removeChild(m.confirmDialog)
    m.confirmDialog = invalid
    m.top.setFocus(true)
end sub

sub deletePlayer(pi as integer)
    if m.panels.count() <= 1 then return
    if pi < 0 or pi >= m.panels.count() then return

    m.top.removeChild(m.panels[pi])

    newPanels  = []
    newScores  = []
    newNames   = []
    newCursors = []
    newOffsets = []
    for i = 0 to m.panels.count() - 1
        if i <> pi
            newPanels.push(m.panels[i])
            newScores.push(m.scores[i])
            newNames.push(m.names[i])
            newCursors.push(m.cursors[i])
            newOffsets.push(m.offsets[i])
        end if
    next
    m.panels  = newPanels
    m.scores  = newScores
    m.names   = newNames
    m.cursors = newCursors
    m.offsets = newOffsets

    if m.focusedIdx >= m.panels.count()
        m.focusedIdx = m.panels.count() - 1
    end if

    if m.panels.count() < 8 and m.addPlayerBox = invalid
        createAddPlayerBox()
    end if

    relayoutPanels()
    refreshFocusRings()
    pushScores()
    syncCursorDisplays()
end sub

' ---- add player ----------------------------------------------------------

sub addPlayer()
    n = m.panels.count()
    if n >= 8 then return

    panel = CreateObject("roSGNode", "TeamPanel")
    panel.panelWidth  = m.panelWidth
    name = "PLAYER " + (n + 1).toStr()
    panel.teamName    = name
    panel.cursorIndex = -1
    panel.focused     = false
    m.top.appendChild(panel)

    m.panels.push(panel)
    m.scores.push([])
    m.names.push(name)
    m.cursors.push(0)
    m.offsets.push(0)

    if m.panels.count() >= 8 and m.addPlayerBox <> invalid
        m.top.removeChild(m.addPlayerBox)
        m.addPlayerBox = invalid
    end if

    relayoutPanels()

    m.focusedIdx = m.panels.count() - 1
    m.editMode   = false
    refreshFocusRings()
    pushScores()
    syncCursorDisplays()
    refreshHint()
end sub

' ---- rename dialog -------------------------------------------------------

sub openNameEntryForFocused()
    if m.focusedIdx >= m.panels.count() then return
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = "Rename Player"
    dialog.buttons = ["OK", "Cancel"]
    m.top.getScene().appendChild(dialog)
    m.keyboardDialog = dialog
    dialog.observeField("buttonSelected", "onNameEntryButtonSelected")
    dialog.setFocus(true)
end sub

sub onNameEntryButtonSelected()
    if m.keyboardDialog.buttonSelected = 0
        newName = UCase(m.keyboardDialog.keyboard.text.trim())
        if newName <> "" and m.focusedIdx < m.panels.count()
            m.names[m.focusedIdx]         = newName
            m.panels[m.focusedIdx].teamName = newName
        end if
    end if
    m.top.getScene().removeChild(m.keyboardDialog)
    m.keyboardDialog = invalid
    m.top.setFocus(true)
end sub

' ---- remote input --------------------------------------------------------

function onKeyEvent(key as string, press as boolean) as boolean
    if key = "up" or key = "down"
        if m.editMode
            if press
                m.repeatDirection = key
                m.repeatFast      = false
                applyUpDown(key)
                m.repeatDelayTimer.control = "start"
                m.repeatAccelTimer.control = "start"
            else
                stopRepeatTimers()
            end if
        else
            if press and m.focusedIdx < m.panels.count() then moveCursor(key)
        end if
        return true
    end if

    if not press then return false

    handled = true
    n = m.panels.count()

    if key = "left"
        cursorToSync = m.cursors[m.focusedIdx]
        if m.editMode then exitEditMode()
        if m.focusedIdx > 0
            m.focusedIdx = m.focusedIdx - 1
            syncDestCursor(cursorToSync)
        end if
        syncCursorDisplays()
        refreshFocusRings()

    else if key = "right"
        cursorToSync = m.cursors[m.focusedIdx]
        if m.editMode then exitEditMode()
        maxIdx = n - 1
        if n < 8 then maxIdx = n   ' add-player slot is reachable
        if m.focusedIdx < maxIdx
            m.focusedIdx = m.focusedIdx + 1
            syncDestCursor(cursorToSync)
        end if
        syncCursorDisplays()
        refreshFocusRings()

    else if key = "OK"
        if m.focusedIdx = n and n < 8
            addPlayer()
        else if m.editMode
            exitEditMode()
        else
            cur = m.cursors[m.focusedIdx]
            if cur = -2
                openNameEntryForFocused()
            else
                if cur >= m.scores[m.focusedIdx].count()
                    m.scores[m.focusedIdx].push(0)
                    m.cursors[m.focusedIdx] = m.scores[m.focusedIdx].count() - 1
                    pushScores()
                end if
                m.editMode = true
                m.panels[m.focusedIdx].cursorIndex = m.cursors[m.focusedIdx]
                m.panels[m.focusedIdx].editMode    = true
                refreshHint()
            end if
        end if

    else if key = "back"
        if m.editMode
            exitEditMode()
        else
            handled = false
        end if

    else if key = "options"
        if m.editMode
            handled = true   ' consume * in edit mode
        else if m.focusedIdx < n
            cur = m.cursors[m.focusedIdx]
            if cur = -2
                openDeletePlayerDialog()
            else if cur >= 0 and cur < m.scores[m.focusedIdx].count()
                openDeleteRoundDialog()
            else
                handled = false
            end if
        else
            handled = false
        end if

    else
        handled = false
    end if

    return handled
end function
