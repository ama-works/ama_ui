-- ============================================================================
-- color/panel_colour.lua
-- Équivalent de RageUI.PanelColour — palettes dédiées aux ColorPanel
-- Format : { r, g, b }  (pas d'alpha — utilisé directement par ColorPanel)
-- ============================================================================

ama_ui = ama_ui or {}

ama_ui.PanelColour = {

    -- Palette coiffure GTA V (64 couleurs, index 0-63)
    HairCut = {
        {  22,  19,  19 }, -- 0  Noir profond
        {  30,  28,  25 }, -- 1  Noir
        {  76,  56,  45 }, -- 2  Brun foncé
        {  69,  34,  24 }, -- 3  Brun chocolat
        { 123,  59,  31 }, -- 4  Brun
        { 149,  68,  35 }, -- 5  Brun clair
        { 165,  87,  50 }, -- 6  Brun doré
        { 175, 111,  72 }, -- 7  Caramel
        { 159, 105,  68 }, -- 8  Châtain
        { 198, 152, 108 }, -- 9  Châtain clair
        { 213, 170, 115 }, -- 10 Blond foncé
        { 223, 187, 132 }, -- 11 Blond
        { 202, 164, 110 }, -- 12 Blond miel
        { 238, 204, 130 }, -- 13 Blond doré
        { 229, 190, 126 }, -- 14 Blond sablé
        { 250, 225, 167 }, -- 15 Blond platine
        { 187, 140,  96 }, -- 16 Auburn
        { 163,  92,  60 }, -- 17 Auburn foncé
        { 144,  52,  37 }, -- 18 Roux foncé
        { 134,  21,  17 }, -- 19 Rouge sombre
        { 164,  24,  18 }, -- 20 Rouge
        { 195,  33,  24 }, -- 21 Rouge vif
        { 221,  69,  34 }, -- 22 Rouge orangé
        { 229,  71,  30 }, -- 23 Orange brûlé
        { 208,  97,  56 }, -- 24 Orange
        { 113,  79,  38 }, -- 25 Bronze
        { 132, 107,  95 }, -- 26 Gris fumé
        { 185, 164, 150 }, -- 27 Gris clair
        { 218, 196, 180 }, -- 28 Gris argent
        { 247, 230, 217 }, -- 29 Blanc cassé
        { 102,  72,  93 }, -- 30 Prune
        { 162, 105, 138 }, -- 31 Mauve
        { 171, 174,  11 }, -- 32 Jaune-vert
        { 239,  61, 200 }, -- 33 Rose vif
        { 255,  69, 152 }, -- 34 Rose bonbon
        { 255, 178, 191 }, -- 35 Rose pâle
        {  12, 168, 146 }, -- 36 Turquoise
        {   8, 146, 165 }, -- 37 Bleu canard
        {  11,  82, 134 }, -- 38 Bleu foncé
        { 118, 190, 117 }, -- 39 Vert clair
        {  52, 156, 104 }, -- 40 Vert
        {  22,  86,  85 }, -- 41 Vert sombre
        { 152, 177,  40 }, -- 42 Vert lime
        { 127, 162,  23 }, -- 43 Vert olive
        { 241, 200,  98 }, -- 44 Jaune doré
        { 238, 178,  16 }, -- 45 Jaune
        { 224, 134,  14 }, -- 46 Ambre
        { 247, 157,  15 }, -- 47 Orange clair
        { 243, 143,  16 }, -- 48 Orange vif
        { 231,  70,  15 }, -- 49 Orange foncé
        { 255, 101,  21 }, -- 50 Orange fluo
        { 254,  91,  34 }, -- 51 Rouge orangé vif
        { 252,  67,  21 }, -- 52 Rouge-orange
        { 196,  12,  15 }, -- 53 Rouge sang
        { 143,  10,  14 }, -- 54 Bordeaux
        {  44,  27,  22 }, -- 55 Brun très foncé
        {  80,  51,  37 }, -- 56 Brun moyen
        {  98,  54,  37 }, -- 57 Brun roux
        {  60,  31,  24 }, -- 58 Acajou foncé
        {  69,  43,  32 }, -- 59 Acajou
        {   8,  10,  14 }, -- 60 Noir absolu
        { 212, 185, 158 }, -- 61 Beige
        { 212, 185, 158 }, -- 62 Beige (variante)
        { 213, 170, 115 }, -- 63 Blond foncé (variante)
    },

    -- Palette maquillage GTA V (64 couleurs, index 0-63)
    -- Utilisée avec SetPedHeadOverlayColor(ped, overlayID, 2, colorIdx, 0)
    MakeUp = {
        { 153,  37,  50 }, -- 0  Rouge bordeaux
        { 200,  57,  93 }, -- 1  Rouge cerise
        { 189,  81, 108 }, -- 2  Rose bordeaux
        { 184,  99, 122 }, -- 3  Rose rosé
        { 166,  82, 107 }, -- 4  Rouge rosé foncé
        { 177,  67,  76 }, -- 5  Rouge corail
        { 127,  49,  51 }, -- 6  Rouge sombre
        { 164, 100,  93 }, -- 7  Rose terracotta
        { 193, 135, 121 }, -- 8  Rose saumon
        { 203, 160, 150 }, -- 9  Rose clair
        { 198, 145, 143 }, -- 10 Rose nude
        { 171, 111,  99 }, -- 11 Terracotta
        { 176,  96,  80 }, -- 12 Brun rose
        { 168,  76,  51 }, -- 13 Brun rouge
        { 180, 113, 120 }, -- 14 Rose mauve
        { 202, 127, 146 }, -- 15 Rose moyen
        { 237, 156, 190 }, -- 16 Rose pastel
        { 231, 117, 164 }, -- 17 Rose vif
        { 222,  62, 129 }, -- 18 Fuchsia
        { 179,  76, 110 }, -- 19 Rose foncé
        { 113,  39,  57 }, -- 20 Bordeaux foncé
        {  79,  31,  42 }, -- 21 Bordeaux très foncé
        { 170,  34,  47 }, -- 22 Rouge foncé
        { 222,  32,  52 }, -- 23 Rouge vif
        { 207,   8,  19 }, -- 24 Rouge pur
        { 229,  84, 112 }, -- 25 Rouge rosé
        { 220,  63, 181 }, -- 26 Violet rose
        { 192,  39, 178 }, -- 27 Violet
        { 160,  28, 169 }, -- 28 Violet foncé
        { 110,  24, 117 }, -- 29 Violet sombre
        { 115,  20, 101 }, -- 30 Prune
        {  86,  22,  92 }, -- 31 Prune foncé
        { 109,  26, 157 }, -- 32 Violet bleu
        {  27,  55, 113 }, -- 33 Bleu marine
        {  29,  78, 167 }, -- 34 Bleu
        {  30, 116, 187 }, -- 35 Bleu moyen
        {  33, 163, 206 }, -- 36 Bleu ciel
        {  37, 194, 210 }, -- 37 Cyan
        {  35, 204, 165 }, -- 38 Turquoise
        {  39, 192, 125 }, -- 39 Vert menthe
        {  27, 156,  50 }, -- 40 Vert
        {  20, 134,   4 }, -- 41 Vert vif
        { 112, 208,  65 }, -- 42 Vert lime
        { 197, 234,  52 }, -- 43 Jaune-vert
        { 225, 227,  47 }, -- 44 Jaune vif
        { 255, 221,  38 }, -- 45 Jaune
        { 250, 192,  38 }, -- 46 Jaune doré
        { 247, 138,  39 }, -- 47 Orange
        { 254,  89,  16 }, -- 48 Orange vif
        { 190, 110,  25 }, -- 49 Brun doré
        { 247, 201, 127 }, -- 50 Pêche
        { 251, 229, 192 }, -- 51 Crème pêche
        { 245, 245, 245 }, -- 52 Blanc
        { 179, 180, 179 }, -- 53 Gris clair
        { 145, 145, 145 }, -- 54 Gris
        {  86,  78,  78 }, -- 55 Gris foncé
        {  24,  14,  14 }, -- 56 Noir
        {  88, 150, 158 }, -- 57 Bleu gris
        {  77, 111, 140 }, -- 58 Bleu acier
        {  26,  43,  85 }, -- 59 Bleu nuit
        { 160, 126, 107 }, -- 60 Beige rosé
        { 130,  99,  85 }, -- 61 Beige brun
        { 109,  83,  70 }, -- 62 Brun beige
        {  62,  45,  39 }, -- 63 Brun très foncé
    }

}
