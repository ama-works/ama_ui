-- ============================================================================
-- config.lua — Configuration complete du menu NativeUI
-- ============================================================================
--
-- GUIDE RAPIDE POUR DEBUTANTS:
--
-- * Toutes les tailles (width, height, offsetX, etc.) sont en PIXELS
--   bases sur une resolution 1920x1080. Le systeme convertit automatiquement.
--
-- * Les couleurs sont au format { r = 0-255, g = 0-255, b = 0-255, a = 0-255 }
--   (a = alpha/transparence, 255 = opaque, 0 = invisible)
--
-- * Pour changer l'apparence du menu, modifie les valeurs ci-dessous.
--   Pas besoin de toucher aux fichiers .lua dans core/ ou items/.
--
-- * Chaque section indique quel fichier la lit.
--
-- ============================================================================

Config = Config or {}

-- -----------------------------------------------------------------------------
-- RESOLUTION DE REFERENCE
-- -----------------------------------------------------------------------------
-- Ne change PAS ces valeurs sauf si tu sais ce que tu fais.
-- Utilise dans: core/cache.lua
Config.BaseResolution = {
    width = 1920,
    height = 1080
}

-- -----------------------------------------------------------------------------
-- POSITION DU MENU (coin haut-gauche)
-- -----------------------------------------------------------------------------
-- Change x/y pour deplacer le menu sur l'ecran.
-- Utilise dans: core/menu.lua -> Menu.New()
Config.MenuPosition = {
    x = 50,
    y = 50
}

-- -----------------------------------------------------------------------------
-- LAYOUT GLOBAL
-- -----------------------------------------------------------------------------
-- itemHeight = hauteur de chaque ligne du menu (en px).
-- Utilise dans: core/menu.lua, items/*.lua, input/mouse.lua
Config.Layout = {
    itemHeight = 35
}

-- -----------------------------------------------------------------------------
-- HEADER (banniere du haut)
-- -----------------------------------------------------------------------------
-- size.width DEFINIT LA LARGEUR DU MENU ENTIER (tous les elements s'alignent dessus).
-- Utilise dans: core/menu.lua -> _DrawHeader()
Config.Header = {
    size = {
        width = 431,    -- * Largeur du menu entier. Change ici pour elargir/retrecir.
        height = 87    -- Hauteur de la banniere du haut.
    },

    -- Sprite GTA (banniere bleue par defaut)
    sprite = {
        dict = "commonmenu",
        name = "interaction_bgd",
        use = true,         -- true = afficher le sprite, false = rectangle uni
        heading = 0.0,
        alpha = 255,
        color = { r = 255, g = 255, b = 255, a = 255 }  -- Tint (255 = couleur normale)
    },

    -- Couleur de secours si le sprite ne charge pas
    background = { r = 0, g = 0, b = 0, a = 255 },

    -- Texte du titre
    title = {
        font = 1,                                           -- 0=normal, 1=script, 7=pricedown
        size = 0.95,                                        -- Taille du texte
        color = { r = 255, g = 255, b = 255, a = 255 },
        alignment = 1,                                      -- 0=gauche, 1=centre, 2=droite
        offsetX = 215.5,                                    -- Ignoré si alignment=1 (centre auto = menuWidth/2 dans _Recalculate)
        offsetY   = 15,                                     -- Position Y calibrée pour refHeight
        refHeight = 65,                                     -- Hauteur de référence pour offsetY (scale auto si headerHeight change)
        shadow = { enabled = true }
    },

    -- Effet glare (scaleform natif GTA V "mp_menu_glare" superposé sur le header)
    -- enabled     : true = activé, false = désactivé (aucun scaleform chargé)
    -- widthScale  : multiplicateur de largeur  (1.0 = largeur menu, 2.0 = 2× la largeur)
    -- heightScale : multiplicateur de hauteur  (1.0 = hauteur header, 2.0 = 2× la hauteur)
    -- offsetX     : décalage horizontal en pixels depuis le bord gauche du menu
    -- offsetY     : décalage vertical   en pixels depuis le haut du header
    -- ⚠️ mp_menu_glare a son propre cadrage interne : agrandir widthScale/heightScale
    --    élargit la zone de dessin et rend le reflet plus visible / imposant.
    glare = {
        enabled     = true,
        widthScale  = 4.5, --position size width  = 431 Largeur du menu entier.        (4.5 scale width du glare)
        heightScale = 11.0,--position size height = 87 Hauteur de la banniere du haut. (11.0 scale du glare)
        offsetX     = 655, --position x du glare (655)
        offsetY     = 390  --position y du glare (390)
    }
}

-- -----------------------------------------------------------------------------
-- SUBTITLE (barre sous le header)
-- -----------------------------------------------------------------------------
-- Utilise dans: core/menu.lua -> _DrawSubtitle()
Config.Subtitle = {
    size = {
        width = 431,    -- Re-synchronise en bas du fichier
        height = 29
    },
    padding = {
        top = 3, bottom = 3,
        left = 8, right = 8
    },
    -- Texte du sous-titre (a gauche)
    text = {
        font = 0,
        size = 0.28,
        color = { r = 245, g = 245, b = 245, a = 255 },
        offsetX = 10,
        offsetY = 3
    },
    background = { r = 0, g = 0, b = 0, a = 255 },

    -- Compteur "2 / 6" (a droite)
    -- offsetX : nil = calcul automatique (menuWidth - padding.right) dans _Recalculate
    counter = {
        font = 0,
        size = 0.28,
        color = { r = 245, g = 242, b = 242, a = 255 },
        offsetY = 3,
        alignment = 2       -- Aligne a droite
    }
}

-- -----------------------------------------------------------------------------
-- FOND DES ITEMS (gradient_bgd)
-- -----------------------------------------------------------------------------
-- Le rectangle/sprite derriere TOUS les items visibles.
-- Utilise dans: core/menu.lua -> _DrawItemsBackground()
Config.ItemsBackground = {
    sprite = {
        dict = "commonmenu",
        name = "gradient_bgd",
        use = false,
        heading = 0.0,
        alpha = 255,
        color = { r = 255, g = 255, b = 255, a = 255 }
    },
    -- Couleur de secours si sprite off
    color = { r = 36, g = 36, b = 36, a = 225 }
}

-- -----------------------------------------------------------------------------
-- BUTTON (item de base -- les autres types heritent de ces valeurs par defaut)
-- -----------------------------------------------------------------------------
-- Utilise dans: core/menu.lua -> _DrawItems() (label + highlight)
Config.Button = {
    background = {
        default  = { r = 0, g = 0, b = 0, a = 120 },
        selected = { r = 255, g = 255, b = 255, a = 255 },  -- Le rectangle blanc de selection
        hovered  = { r = 255, g = 255, b = 255, a = 180 },
        disabled = { r = 0, g = 0, b = 0, a = 80 },
        height = 0,     -- 0 = utilise Config.Navigation.size.height
        offsetY = 0
    },
    label = {
        font = 0,
        size = 0.26,
        offsetX = 10,       -- Marge gauche du texte
        offsetY = 7,        -- Marge haute du texte
        rightPadding = 20,  -- Espace reserve a droite (pour eviter de depasser)
        color = {
            default  = { r = 255, g = 255, b = 255, a = 255 },  -- Texte blanc
            selected = { r = 0, g = 0, b = 0, a = 255 },        -- Texte noir quand selectionne 0, 255, 255, 255
            disabled = { r = 163, g = 159, b = 148, a = 255 }   -- Texte gris quand desactive
        }
    },
    -- Sprites de badge (RightBadge / LeftBadge) — utilise BadgeStyle.*
    badge = {
        size         = 35,      -- Taille du sprite badge (px carre)
        offsetRightX = 9,       -- Distance depuis le bord droit du menu
        offsetLeftX  = 6,       -- Distance depuis le bord gauche du menu
        -- offsetY: nil = centre verticalement automatiquement dans l'item
    }
}

-- -----------------------------------------------------------------------------
-- LIST (item avec fleches <- valeur ->)
-- -----------------------------------------------------------------------------
-- Utilise dans: items/list.lua -> DrawCustom(), core/menu.lua -> _DrawItems()
Config.List = {
    background = {
        default  = { r = 0, g = 0, b = 0, a = 120 },
        selected = { r = 255, g = 255, b = 255, a = 255 },
        hovered  = { r = 255, g = 255, b = 255, a = 180 },
        disabled = { r = 0, g = 0, b = 0, a = 80 },
        height = 0,
        offsetY = 0
    },
    label = {
        font = 0,
        size = 0.26,
        offsetX = 10,
        offsetY = 7,
        rightPadding = 20,
        color = {
            default  = { r = 255, g = 255, b = 255, a = 255 },
            selected = { r = 0, g = 0, b = 0, a = 255 },
            disabled = { r = 163, g = 159, b = 148, a = 255 }
        }
    },
    value = {
        font = 0,
        size = 0.26,
        offsetRightX = 10,   -- Distance depuis le bord droit du menu
        offsetY = 7,
        color = {
            default  = { r = 245, g = 242, b = 242, a = 255 },
            selected = { r = 0, g = 0, b = 0, a = 255 },
            disabled = { r = 163, g = 159, b = 148, a = 255 }
        }
    },
    labelValueGap = 10,      -- Espace entre le label et la valeur
    ui = {
        left = "←",         -- Caractere fleche gauche
        right = "→",        -- Caractere fleche droite
        onlyOnSelected = true -- true = fleches visibles seulement sur l'item selectionne
    }
}

-- -----------------------------------------------------------------------------
-- CHECKBOX (case a cocher avec sprite GTA)
-- -----------------------------------------------------------------------------
-- Utilise dans: items/checkbox.lua -> DrawCustom()
Config.Checkbox = {
    background = {
        default  = { r = 0, g = 0, b = 0, a = 120 },
        selected = { r = 255, g = 255, b = 255, a = 255 },
        hovered  = { r = 255, g = 255, b = 255, a = 180 },
        disabled = { r = 0, g = 0, b = 0, a = 80 },
        height = 0,
        offsetY = 0
    },
    label = {
        font = 0,
        size = 0.26,
        offsetX = 10,
        offsetY = 7,
        rightPadding = 20,
        color = {
            default  = { r = 255, g = 255, b = 255, a = 255 },
            selected = { r = 0, g = 0, b = 0, a = 255 },
            disabled = { r = 163, g = 159, b = 148, a = 255 }
        }
    },
    -- Sprite GTA (la petite box cochee/decochee)
    sprite = {
        dict = "commonmenu",
        unchecked = "shop_box_blankb",   -- Sprite quand decoche
        checked = "shop_box_tickb",      -- Sprite quand coche
        size = 32,                       -- Taille du sprite (px)
        offsetRightX = 10,               -- Distance depuis le bord droit
        -- offsetY: nil -> centre verticalement automatiquement
        color = {
            default  = { r = 245, g = 242, b = 242, a = 255 },
            -- selected: nil -> utilise default
            disabled = { r = 0, g = 0, b = 0, a = 255 }
        }
    },
    labelSpriteGap = 10     -- Espace entre le label et la checkbox
}

-- -----------------------------------------------------------------------------
-- SLIDER PROGRESS (barre horizontale controlee avec <- ->)
-- -----------------------------------------------------------------------------
-- Utilise dans: items/slider.lua -> DrawCustom()
Config.SliderProgress = {
    step = 1,               -- Increment par pression gauche/droite
    background = {
        default  = { r = 0, g = 0, b = 0, a = 120 },
        selected = { r = 255, g = 255, b = 255, a = 255 },
        hovered  = { r = 255, g = 255, b = 255, a = 180 },
        disabled = { r = 0, g = 0, b = 0, a = 80 },
        height = 0,
        offsetY = 0
    },
    label = {
        font = 0,
        size = 0.26,
        offsetX = 10,
        offsetY = 7,
        rightPadding = 20,
        color = {
            default  = { r = 255, g = 255, b = 255, a = 255 },
            selected = { r = 0, g = 0, b = 0, a = 255 },
            disabled = { r = 163, g = 159, b = 148, a = 255 }
        }
    },
    labelBarGap = 10,       -- Espace entre le label et la barre
    bar = {
        width = 120,        -- Largeur de la barre (px)
        height = 8,         -- Hauteur de la barre (px)
        rectangle = {
            black = { height = 7 }  -- Hauteur du fond+fill (override bar.height)
        },
        offsetRightX = 10,  -- Distance depuis le bord droit du menu
        -- offsetY: nil -> centre verticalement automatiquement
        showValue = false,  -- true = affiche "25/100" a droite de la barre
        color = {
            background         = { r = 93, g = 182, b = 229, a = 255 },
            backgroundSelected = { r = 93, g = 182, b = 229, a = 255 },
            backgroundDisabled = { r = 93, g = 182, b = 229, a = 255 },
            fill               = { r = 57, g = 119, b = 200, a = 255 }
            -- fillSelected / fillDisabled: nil -> utilise fill
        }
    },
    -- Texte valeur (seulement si bar.showValue = true)
    value = {
        font = 0,
        size = 0.26,
        offsetRightX = 12,
        offsetY = 7,
        color = {
            default  = { r = 245, g = 242, b = 242, a = 255 },
            selected = { r = 0, g = 0, b = 0, a = 255 },
            disabled = { r = 163, g = 159, b = 148, a = 255 }
        }
    }
}

-- -----------------------------------------------------------------------------
-- PROGRESS (barre de statut passive — santé, stamina, faim, soif, etc.)
-- -----------------------------------------------------------------------------
-- Utilise dans: items/progress.lua -> DrawCustom()
-- Pas de fleches : la valeur est mise a jour via item.value en Lua.
Config.Progress = {
    step = 1,
    background = {
        default  = { r = 0, g = 0, b = 0, a = 120 },
        selected = { r = 255, g = 255, b = 255, a = 255 },
        hovered  = { r = 255, g = 255, b = 255, a = 180 },
        disabled = { r = 0, g = 0, b = 0, a = 80 },
        height = 0,
        offsetY = 0
    },
    label = {
        font = 0,
        size = 0.26,
        offsetX = 10,
        offsetY = 7,
        rightPadding = 20,
        color = {
            default  = { r = 255, g = 255, b = 255, a = 255 },
            selected = { r = 0, g = 0, b = 0, a = 255 },
            disabled = { r = 163, g = 159, b = 148, a = 255 }
        }
    },
    labelBarGap = 10,
    bar = {
        width = 120,
        height = 8,
        rectangle = {
            black = { height = 7 }
        },
        offsetRightX = 10,
        -- offsetY: nil -> centre verticalement
        color = {
            background         = { r = 93, g = 182, b = 229, a = 255 },
            backgroundSelected = { r = 93, g = 182, b = 229, a = 255 },
            backgroundDisabled = { r = 93, g = 182, b = 229, a = 255 },
            fill               = { r = 57, g = 119, b = 200, a = 255 }
        }
    }
}

-- -----------------------------------------------------------------------------
-- HERITAGE (slider avec icones femme/homme et remplissage depuis le centre)
-- -----------------------------------------------------------------------------
-- Utilise dans: items/heritage.lua -> DrawCustom()
Config.Heritage = {
    step = 1,
    labelBarGap = 10,       -- Espace entre le label et le widget (icones + barre)
    offsetRightX = 0,      -- Distance depuis le bord droit du menu

    -- Icones femme/homme
    icons = {
        dict = "mpleaderboard",
        left = "leaderboard_female_icon",
        right = "leaderboard_male_icon",
        size = 20,          -- Taille des icones (px)
        gap = 1,            -- Espace entre icone et barre
        color = {
            female = {
                default  = { r = 255, g = 255, b = 255, a = 255 },
                selected = { r = 255, g = 105, b = 180, a = 255 }  -- Rose quand selectionne
            },
            male = {
                default  = { r = 255, g = 255, b = 255, a = 255 },
                selected = { r = 57, g = 119, b = 200, a = 255 }   -- Bleu quand selectionne
            }
        }
    },

    -- Barre de progression (remplissage depuis le centre)
    bar = {
        width = 120,
        height = 8,
        rectangle = {
            black = { height = 7 }
        },
        fillFromCenter = true,  -- Le fill part du centre de la barre
        -- centerValue: nil -> centre = (min+max)/2 automatiquement
        color = {
            background         = { r = 93, g = 182, b = 229, a = 255 },
            backgroundSelected = { r = 93, g = 182, b = 229, a = 255 },
            backgroundDisabled = { r = 93, g = 182, b = 229, a = 255 },
            fill               = { r = 57, g = 119, b = 200, a = 255 }
        }
    },

    -- Trait vertical fixe au centre de la barre
    divider = {
        width = 2,
        height = 20,
        color = {
            default  = { r = 245, g = 242, b = 242, a = 255 },
            selected = { r = 0, g = 0, b = 0, a = 255 },
            disabled = { r = 163, g = 159, b = 148, a = 255 }
        }
    }
}


-- -----------------------------------------------------------------------------
-- WINDOW HERITAGE (panneau portraits mère/père sous le subtitle)
-- -----------------------------------------------------------------------------
-- Utilise dans: items/windows.lua -> DrawCustom()
Config.Window = {
    size = {
        width  = 431,   -- Re-sync en bas du fichier (suit Config.Header.size.width)
        height = 195,    -- Plus haut qu'un item normal pour loger les portraits
    },

    -- Sprite de fond du panneau
    background = {
        dict    = "pause_menu_pages_char_mom_dad",
        name    = "mumdadbg",
        use     = true,
        heading = 0.0,
        color   = { r = 255, g = 255, b = 255, a = 255 }
    },

    -- Portraits mère / père
    portraits = {
        dict = "char_creator_portraits",    -- dict GTA V natif (textures natives)

        mom = {
            prefix  = "female_",            -- nom du sprite = prefix .. mumIndex  ex: "female_0"
            offsetX = 50,                   -- distance depuis le bord gauche du menu
            size    = 160,                   -- largeur ET hauteur du portrait mère (px)
            color   = { r = 255, g = 255, b = 255, a = 255 }
        },
        dad = {
            prefix  = "male_",              -- nom du sprite = prefix .. dadIndex  ex: "male_3"
            offsetX = 50,                   -- distance depuis le bord droit du menu (symétrique)
            size    = 160,                   -- largeur ET hauteur du portrait père (px)
            color   = { r = 255, g = 255, b = 255, a = 255 }
        }
    }
}



-- -----------------------------------------------------------------------------
-- DESCRIPTION (box en bas du menu, affiche la description de l'item selectionne)
-- -----------------------------------------------------------------------------
-- Utilise dans: core/menu.lua -> _DrawDescription()
Config.Description = {
    size = {
        width = 431,
        height = 64
    },
    spacing = 4,        -- Espace entre le dernier item et la box description
    background = { r = 0, g = 0, b = 0, a = 204 },
    padding = {
        left = 7, right = 7,
        top = 11, bottom = 11
    },
    text = {
        font = 0,
        size = 0.26,
        color = { r = 245, g = 242, b = 242, a = 255 },
        offsetX = 7,
        offsetY = 9,
        maxWidth = 421,     -- Largeur de wrap du texte
        lineHeight = 19     -- Hauteur de ligne (le moteur prend le max avec la hauteur native)
    }
}

-- -----------------------------------------------------------------------------
-- NAVIGATION (rectangle de selection / highlight)
-- -----------------------------------------------------------------------------
-- Le rectangle blanc qui suit la selection.
-- Utilise dans: core/menu.lua -> _DrawNavigationHighlight()
Config.Navigation = {
    size = {
        width = 430,    -- Re-synchronise en bas
        height = 35     -- Hauteur du highlight
    },
    offsetY = 0         -- Decalage vertical apres centrage
}

-- -----------------------------------------------------------------------------
-- SEPARATOR (ligne de separation, la navigation saute dessus)
-- -----------------------------------------------------------------------------
-- Utilise dans: items/separator_jump.lua -> DrawCustom()
Config.Separator = {
    line = {
        enabled = true,
        width = 410,
        height = 1,
        color = { r = 57, g = 119, b = 200, a = 255 }
    },
    label = {
        font = 0,
        size = 0.28,
        offsetY = 6,
        color = { r = 57, g = 119, b = 200, a = 255 }
    }
}

-- -----------------------------------------------------------------------------
-- PANELS — STATISTICS
-- -----------------------------------------------------------------------------
-- Utilise dans: panels/statistics_panel.lua -> FlushStatBuffer()
-- barW est calculé dynamiquement : menuWidth - bar.offsetX - bar.padRight
Config.StatisticsPanel = {
    background = {
        offsetY   = 4,      -- Distance depuis le haut du panel (px)
        rowHeight = 40,     -- Hauteur d'une ligne stats (px)
        color     = { r = 0, g = 0, b = 0, a = 170 }
    },
    label = {
        offsetX = 10,       -- Marge gauche du label (px)
        offsetY = 10,       -- Marge haute du label dans la ligne (px)
        size    = 0.26,
        color   = { r = 245, g = 245, b = 245, a = 255 }
    },
    bar = {
        offsetX  = 190,     -- Distance depuis le bord gauche (zone texte fixe)
        offsetY  = 18,      -- Distance depuis le haut de la ligne (px)
        padRight = 11,      -- Marge droite → barW = menuWidth - offsetX - padRight
        height   = 6,       -- Hauteur de la barre (px)
        divCount = 4,       -- Nombre de diviseurs (4 = 5 sections égales)
        colorBg   = { r = 87,  g = 87,  b = 87,  a = 255 },  -- Fond gris
        colorFill = { r = 255, g = 255, b = 255, a = 255 },  -- Fill blanc (simple)
        colorDiv  = { r = 0,   g = 0,   b = 0,   a = 255 }   -- Diviseurs noirs
    }
}

-- -----------------------------------------------------------------------------
-- PANELS — STATISTICS ADVANCED
-- -----------------------------------------------------------------------------
-- StatisticsPanelAdvanced partage Config.StatisticsPanel pour le rendu des barres.
-- Cette section definit uniquement les couleurs par defaut des trois segments.
-- Utilise dans: panels/statistics_panel.lua -> StatisticsPanelAdvanced()
Config.StatisticsPanelAdvanced = {
    -- Couleur du segment principal (remplissage de base)
    colorMain      = { r = 255, g = 255, b = 255, a = 255 },
    -- Couleur du segment secondaire positif (portion ajoutee au-dela du principal)
    colorSecondary = { r = 0,   g = 153, b = 204, a = 255 },
    -- Couleur du segment secondaire negatif (portion soustraite en arriere du principal)
    colorNegative  = { r = 185, g = 0,   b = 0,   a = 255 }
}

-- -----------------------------------------------------------------------------
-- PANELS — PERCENTAGE
-- -----------------------------------------------------------------------------
-- Utilise dans: panels/percentage_panel.lua -> PercentagePanel()
-- barW est calcule dynamiquement : menuWidth - bar.offsetX - bar.padRight
Config.PercentagePanel = {
    background = {
        offsetY = 4,        -- Espace depuis le bas du dernier item (px)
        height  = 56        -- Hauteur du fond sprite (px)
    },
    bar = {
        offsetX  = 9,       -- Distance depuis le bord gauche du menu (px)
        offsetY  = 40,      -- Distance depuis le haut du panel (px)
        height   = 8,       -- Hauteur de la barre (px)
        padRight = 9        -- Marge droite -> barW = menuWidth - offsetX - padRight
    },
    -- Textes : gauche, centre, droite
    text = {
        left = {
            offsetX = 25,   -- Distance depuis le bord gauche (px)
            offsetY = 10,   -- Distance depuis le haut du panel (px)
            size    = 0.26
        },
        middle = {
            -- offsetX = nil -> calcule automatiquement a menuWidth * 0.5
            offsetY = 10,
            size    = 0.26
        },
        right = {
            -- offsetX = nil -> calcule automatiquement a menuWidth - padRight
            offsetY  = 10,
            padRight = 33,  -- Distance depuis le bord droit (px)
            size     = 0.26
        }
    },
    color = {
        text    = { r = 245, g = 245, b = 245, a = 255 },  -- Blanc casse (labels)
        barBg   = { r = 87,  g = 87,  b = 87,  a = 255 },  -- Gris (fond barre)
        barFill = { r = 245, g = 245, b = 245, a = 255 }   -- Blanc (remplissage)
    },
    sprite = {
        dict = "commonmenu",
        name = "gradient_bgd"
    }
}

-- -----------------------------------------------------------------------------
-- PANELS — COLOR
-- -----------------------------------------------------------------------------
-- Utilise dans: panels/color_panel.lua -> ColorPanel()
-- Affiche une rangee de carres de couleur avec deux fleches de navigation.
Config.ColorPanel = {
    background = {
        offsetY = 4,        -- Espace depuis le bas du dernier item (px)
        height  = 95        -- Hauteur du fond sprite (px)
    },
    -- Fleche gauche (sprite commonmenu/arrowleft)
    arrowLeft = {
        offsetX = 7.5,      -- Distance depuis le bord gauche (px)
        offsetY = 44,       -- Distance depuis le haut du panel (px)
        width   = 20,
        height  = 20
    },
    -- Fleche droite (sprite commonmenu/arrowright)
    -- offsetX = nil -> calcule a menuWidth - padRight
    arrowRight = {
        padRight = 37.5,    -- Distance depuis le bord droit (px)
        offsetY  = 44,
        width    = 20,
        height   = 20
    },
    -- Titre centre (ex: "HairCut (3 of 21)")
    -- offsetX = nil -> menuWidth * 0.5
    header = {
        offsetY = 8,
        size    = 0.26
    },
    -- Carres de couleur
    box = {
        offsetX = 42,       -- Distance depuis le bord gauche pour le premier carre (px)
        offsetY = 35,       -- Distance depuis le haut du panel (px)
        width   = 37.5,     -- Largeur d'un carre (px) — aussi l'espacement entre carres
        height  = 37.5      -- Hauteur d'un carre (px)
    },
    -- Barre blanche sous le carre selectionne
    selection = {
        offsetX = 42,       -- Aligne avec box.offsetX (px)
        offsetY = 30,       -- Distance depuis le haut du panel (px)
        width   = 37.5,     -- Meme largeur qu'un carre
        height  = 4         -- Hauteur du trait de selection (px)
    },
    color = {
        text      = { r = 245, g = 245, b = 245, a = 255 },  -- Blanc casse
        selection = { r = 245, g = 245, b = 245, a = 255 }   -- Barre de selection
    },
    sprite = {
        dict = "commonmenu",
        name = "gradient_bgd"
    }
}

-- -----------------------------------------------------------------------------
-- PANELS — GRID (2D : axes X et Y)
-- -----------------------------------------------------------------------------
-- Utilise dans: panels/grid_panel.lua -> GridPanel()
-- Sprite grille : pause_menu_pages_char_mom_dad/nose_grid (centree dans le panel)
-- Sprite cercle : mpinventory/in_world_circle (curseur draggable)
Config.GridPanel = {
    background = {
        offsetY = 4,        -- Espace depuis le bas du dernier item (px)
        height  = 230       -- Hauteur du fond sprite (px) — hauteur reelle du panel
    },
    grid = {
        -- offsetX = nil -> calcule a (menuWidth - width) * 0.5 (grille centree)
        offsetY = 42.5,     -- Distance depuis le haut du panel (px)
        width   = 150,
        height  = 150,
        sprite  = {
            dict = "grid",
            name = "nose_grid"
        }
    },
    circle = {
        width  = 15,        -- Taille du cercle curseur (px)
        height = 15,
        sprite = {
            dict = "mpinventory",
            name = "in_world_circle"
        }
    },
    areaPadding = 20,       -- Marge interne de la zone active (px de chaque cote)
    -- Labels directionnels
    text = {
        top = {
            -- offsetX = nil -> menuWidth * 0.5
            offsetY = 13.5,
            size    = 0.26
        },
        bottom = {
            -- offsetX = nil -> menuWidth * 0.5
            offsetY = 199.5,
            size    = 0.26
        },
        left = {
            offsetX = 87.75,
            offsetY = 105,
            size    = 0.26
        },
        right = {
            -- offsetX = nil -> calcule a menuWidth - padRight (431 - 333.25 = 97.75)
            padRight = 97.75,
            offsetY  = 105,
            size     = 0.26
        }
    },
    color = {
        text = { r = 245, g = 245, b = 245, a = 255 }
    },
    sprite = {
        dict = "commonmenu",
        name = "gradient_bgd"
    }
}

-- -----------------------------------------------------------------------------
-- PANELS — GRID HORIZONTAL (axe X uniquement, Y fixe a 0.5)
-- -----------------------------------------------------------------------------
-- Utilise dans: panels/grid_panel_h.lua -> GridPanelH()
-- Sprite grille : RageUI/horizontal_grid (axe X visible uniquement)
-- Labels : gauche et droite seulement (pas de haut/bas)
Config.GridPanelH = {
    background = {
        offsetY = 4,        -- Espace depuis le bas du dernier item (px)
        height  = 120       -- Hauteur du fond sprite (px)
    },
    grid = {
        -- offsetX = nil -> calcule a (menuWidth - width) * 0.5
        offsetY = 0.0,      -- La grille commence au bord haut du fond (px)
        width   = 150,
        height  = 150,      -- Hauteur du sprite (seul l'axe X est interactif)
        sprite  = {
            dict = "grid",
            name = "horizontal_grid"
        }
    },
    circle = {
        width  = 15,
        height = 15,
        sprite = {
            dict = "mpinventory",
            name = "in_world_circle"
        }
    },
    areaPadding = 20,       -- Marge interne de la zone active (px de chaque cote)
    -- Labels gauche / droite (PAS de top/bottom)
    text = {
        left = {
            offsetX = 57.75,
            offsetY = 65,
            size    = 0.26
        },
        right = {
            -- offsetX = nil -> calcule a menuWidth - padRight (431 - 373.25 = 57.75)
            padRight = 57.75,
            offsetY  = 65,
            size     = 0.26
        }
    },
    color = {
        text = { r = 245, g = 245, b = 245, a = 255 }
    },
    sprite = {
        dict = "commonmenu",
        name = "gradient_bgd"
    }
}

-- -----------------------------------------------------------------------------
-- PANELS — GRID VERTICAL (axe Y uniquement, X fixe a 0.5)
-- -----------------------------------------------------------------------------
-- Utilise dans: panels/grid_panel_v.lua -> GridPanelV()
-- Sprite grille : RageUI/vertical_grid (axe Y visible uniquement)
-- Labels : haut et bas seulement (pas de gauche/droite)
Config.GridPanelV = {
    background = {
        offsetY = 4,        -- Espace depuis le bas du dernier item (px)
        height  = 240       -- Hauteur du fond sprite (px)
    },
    grid = {
        -- offsetX = nil -> calcule a (menuWidth - width) * 0.5
        offsetY = 47.5,     -- Distance depuis le haut du panel (px)
        width   = 150,
        height  = 150,
        sprite  = {
            dict = "grid",
            name = "vertical_grid"
        }
    },
    circle = {
        width  = 15,
        height = 15,
        sprite = {
            dict = "mpinventory",
            name = "in_world_circle"
        }
    },
    areaPadding = 20,       -- Marge interne de la zone active (px de chaque cote)
    -- Labels haut / bas (PAS de gauche/droite)
    text = {
        top = {
            -- offsetX = nil -> menuWidth * 0.5
            offsetY = 15,
            size    = 0.26
        },
        bottom = {
            -- offsetX = nil -> menuWidth * 0.5
            offsetY = 210,
            size    = 0.26
        }
    },
    color = {
        text = { r = 245, g = 245, b = 245, a = 255 }
    },
    sprite = {
        dict = "commonmenu",
        name = "gradient_bgd"
    }
}

-- -----------------------------------------------------------------------------
-- NOUVEAU STYLE (grey rows + arrow sans white highlight)
-- enabled = true  → grey rows + flèche orange (style menu resource)
-- enabled = false → style NativeUI classique (white highlight, pas de grey rows)
-- Utilise dans: core/menu.lua -> _DrawItems(), _Recalculate()
-- -----------------------------------------------------------------------------
Config.NewStyle = {
    enabled = true,
    itemRow = {
        offsetX = 15,   -- inset px depuis le bord gauche ET droit du menu
        gapPx   = 3,    -- réduction de hauteur (crée le gap visuel entre items)
        color   = { r = 36, g = 36, b = 36, a = 255 },
    },
    arrow = {
        dict    = "icon",
        name    = "arrow_right_36dp",
        offsetX = 1,    -- px depuis le bord gauche du menu
        offsetY = 2,    -- px depuis le haut de l'item
        width   = 50,
        height  = 30,
        color   = { r = 241, g = 101, b = 34, a = 255 },
    },
    -- Position du label GAUCHE (overrides les configs individuelles Button/List/etc.)
    -- offsetX = marge gauche depuis le bord gauche du menu (px)
    -- offsetY = marge haute dans l'item (px)
    label = {
        offsetX = 30,
        offsetY = 5,
    },
    -- Couleur du texte label quand l'item est sélectionné (remplace les .color.selected de chaque type)
    selectedColor = { r = 0, g = 255, b = 255, a = 255 },
}
-- -----------------------------------------------------------------------------
-- PERFORMANCE
-- -----------------------------------------------------------------------------
-- Utilise dans: renderer/text.lua (cache mesures texte)
Config.Performance = {
    enableCache = true,         -- Active le cache de mesures de texte
    maxCachedTexts = 200        -- Nombre max d'entrees avant reset du cache
}

-- -----------------------------------------------------------------------------
-- SYNCHRONISATION DES LARGEURS ET VALEURS DERIVEES
-- -----------------------------------------------------------------------------
-- Regle unique : modifier UNIQUEMENT Config.Header.size.width pour redimensionner
-- le menu. Toutes les valeurs ci-dessous se recalculent automatiquement.
--
-- NE PAS modifier les lignes suivantes a la main.
-- ─────────────────────────────────────────────────────────────────────────────

local _W = Config.Header.size.width     -- alias court, evite la repetition

-- 1. ELEMENTS QUI HERITENT DIRECTEMENT DE LA LARGEUR DU HEADER
--    (rects/sprites dessines a la meme largeur que le header)
Config.Subtitle.size.width    = _W
Config.Description.size.width = _W
Config.Navigation.size.width  = _W
Config.Window.size.width      = _W

-- 2. LARGEUR DE WRAP DU TEXTE DESCRIPTION
--    maxWidth doit rester dans le menu : Header.size.width - padding.left - padding.right.
--    Sans cette ligne, maxWidth reste a sa valeur hardcodee (ex: 421 pour 431px)
--    et ne suit pas un changement de largeur → le texte deborde ou se tronque trop tot.
--    _Recalculate lit dText.maxWidth en priorite sur le calcul dynamique, donc on
--    l'ecrase ici pour qu'il soit toujours coherent avec la largeur reelle du menu.
do
    local _dp = Config.Description.padding
    Config.Description.text.maxWidth = _W - (_dp.left or 7) - (_dp.right or 7)
end

-- 3. LARGEUR DE LA LIGNE DU SEPARATEUR
--    La ligne doit rester dans le menu avec une marge laterale symetrique.
--    Marge d'origine : 431 - 410 = 21 px (soit ~10-11 px de chaque cote).
--    Formule conservee : Header.size.width - 21
Config.Separator.line.width = _W - 21

-- ─── Ce qui est DEJA dynamique (aucune sync supplementaire necessaire) ────────
--
-- 4. GLARE : auto-centre sur le header dans _Recalculate. offsetX/Y = fine-tuning
--    en pixels (0 = centre exact). Changer width/height deplace le glare automatiquement.
--
-- 5. TITRE HEADER (title.offsetX) : ignore quand alignment=1 (centre auto dans
--    _Recalculate : self.x + menuW * 0.5). Pas de sync necessaire.
--    Si alignment=0 ou 2 et que tu veux centrer manuellement, decommente :
--    Config.Header.title.offsetX = _W * 0.5
--
-- 6. COUNTER DU SUBTITLE (counter.offsetX) : nil → _Recalculate calcule
--    automatiquement menuWidth - padding.right. Pas de sync necessaire.
--
-- 7. PORTRAIT DAD (Window) : la position X est calculee dans windows.lua par
--    x + menuW - dadOffX - dadSize (depuis le bord droit), ou menuW = _menuWidth
--    mis a jour dans _Recalculate. Pas de sync necessaire dans config.lua.
--
-- 8. PANELS (PercentagePanel, ColorPanel, GridPanel*) : tous lisent
--    _AmaUIPanelMenu._menuWidth dynamiquement au moment du rendu et calculent
--    les positions de droite en temps reel. Pas de valeur statique a synchroniser.
