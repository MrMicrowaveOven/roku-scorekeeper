' BackgroundDeco.brs — purely decorative symbols scattered on the background.
' All symbols are semi-transparent so they read as subtle texture.

sub init()
    ' symbol, x, y, size, rotation (degrees — unused; SceneGraph rotation not reliable for text)
    ' Layout: spread across full 1920x1080, avoiding centre-screen cluster
    symbols = [
        ' ---- card suits ----
        {s: chr(9824), x:  80, y:  60,  sz: 110},   ' ♠
        {s: chr(9829), x: 340, y: 900,  sz:  90},   ' ♥
        {s: chr(9830), x: 1700, y: 80,  sz: 100},   ' ♦
        {s: chr(9827), x: 1550, y: 920, sz:  85},   ' ♣
        {s: chr(9829), x: 950, y:  30,  sz:  70},   ' ♥
        {s: chr(9824), x: 1820, y: 500, sz:  80},   ' ♠
        {s: chr(9830), x:  60, y: 600,  sz:  75},   ' ♦
        {s: chr(9827), x: 700, y: 980,  sz:  65},   ' ♣
        {s: chr(9829), x: 1300, y: 950, sz:  75},   ' ♥

        ' ---- dice faces ----
        {s: chr(9856), x: 200,  y: 820, sz: 95},    ' ⚀
        {s: chr(9859), x: 1650, y: 350, sz: 85},    ' ⚃
        {s: chr(9861), x: 100,  y: 280, sz: 80},    ' ⚅
        {s: chr(9857), x: 1100, y:  20, sz: 70},    ' ⚁
        {s: chr(9860), x: 1780, y: 780, sz: 90},    ' ⚄
        {s: chr(9858), x: 480,  y:  50, sz: 75},    ' ⚂

        ' ---- tally groups (four verticals + slash = IIIII rendered as text) ----
        {s: "||||",    x: 1420, y: 30,  sz: 60},
        {s: "||||",    x:  80,  y: 450, sz: 55},
        {s: "||||",    x: 1750, y: 180, sz: 50},
        {s: "||||",    x: 620,  y: 920, sz: 58},

        ' ---- poker chip rings (best available unicode approximation) ----
        {s: chr(9711), x: 820,  y:  40, sz: 90},    ' ◯  large circle
        {s: chr(9711), x: 1480, y: 870, sz: 80},    ' ◯
        {s: chr(9711), x:  50,  y: 750, sz: 70},    ' ◯
        {s: chr(9711), x: 1860, y: 650, sz: 85}     ' ◯
    ]

    for each item in symbols
        lbl = CreateObject("roSGNode", "Label")
        lbl.text        = item.s
        lbl.translation = [item.x, item.y]
        lbl.width       = item.sz * 2
        lbl.height      = item.sz * 2
        lbl.horizAlign  = "center"
        lbl.vertAlign   = "center"
        lbl.color       = "0xFFFFFFFF"
        lbl.opacity     = 0.11
        m.top.appendChild(lbl)
    next
end sub
