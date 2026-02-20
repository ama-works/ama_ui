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

Config = {}

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
        height = 87     -- Hauteur de la banniere du haut.
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
        offsetX = 215.5,                                    -- Position X (width/2 si centre)
        offsetY = 15,                                       -- Position Y dans le header
        shadow = { enabled = true }
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
    counter = {
        font = 0,
        size = 0.28,
        color = { r = 245, g = 242, b = 242, a = 255 },
        offsetX = 420,
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
        use = true,
        heading = 0.0,
        alpha = 255,
        color = { r = 255, g = 255, b = 255, a = 255 }
    },
    -- Couleur de secours si sprite off
    color = { r = 0, g = 0, b = 0, a = 120 }
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
            selected = { r = 0, g = 0, b = 0, a = 255 },        -- Texte noir quand selectionne
            disabled = { r = 163, g = 159, b = 148, a = 255 }   -- Texte gris quand desactive
        }
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
        offsetRightX = 20,  -- Distance depuis le bord droit du menu
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
-- HERITAGE (slider avec icones femme/homme et remplissage depuis le centre)
-- -----------------------------------------------------------------------------
-- Utilise dans: items/heritage.lua -> DrawCustom()
Config.Heritage = {
    step = 1,
    labelBarGap = 10,       -- Espace entre le label et le widget (icones + barre)
    offsetRightX = 12,      -- Distance depuis le bord droit du menu

    -- Icones femme/homme
    icons = {
        dict = "mpleaderboard",
        left = "leaderboard_female_icon",
        right = "leaderboard_male_icon",
        size = 20,          -- Taille des icones (px)
        gap = 6,            -- Espace entre icone et barre
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

Config.ParentSelector = {
    -- Position des flèches ◄ ►
    arrowOffsetX = 120,        -- Distance depuis la droite
    arrowFont = 0,
    arrowSize = 0.35,
    arrowColor = { r = 255, g = 255, b = 255, a = 200 },
    arrowColorSelected = { r = 255, g = 255, b = 255, a = 255 },
    
    -- Position du nom (Hannah, Benjamin, etc.)
    valueOffsetX = 60,         -- Distance depuis la droite
    valueFont = 0,
    valueSize = 0.26,
    valueColor = { r = 255, g = 255, b = 255, a = 255 },
    valueColorSelected = { r = 255, g = 255, b = 255, a = 255 },
}

-- -----------------------------------------------------------------------------
-- PROGRESS (barre avec fleches optionnelles)
-- -----------------------------------------------------------------------------
-- Utilise dans: items/progress.lua -> DrawCustom()
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
    },
    -- Fleches <- -> autour de la barre
    arrows = {
        enabled = true,          -- true = afficher les fleches
        onlyOnSelected = true,   -- true = fleches visibles seulement quand selectionne
        dict = "commonmenu",
        left = "arrowleft",
        right = "arrowright",
        size = 20,               -- Taille des sprites fleches (px)
        gap = 1,                 -- Espace entre fleche et barre
        offsetRightX = 1,
        offsetY = 7,
        color = {
            default  = { r = 245, g = 242, b = 242, a = 255 },
            selected = { r = 0, g = 0, b = 0, a = 255 },
            disabled = { r = 163, g = 159, b = 148, a = 255 }
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
-- PERFORMANCE
-- -----------------------------------------------------------------------------
-- Utilise dans: renderer/text.lua (cache mesures texte)
Config.Performance = {
    enableCache = true,         -- Active le cache de mesures de texte
    maxCachedTexts = 200        -- Nombre max d'entrees avant reset du cache
}

-- -----------------------------------------------------------------------------
-- SYNCHRONISATION DES LARGEURS
-- -----------------------------------------------------------------------------
-- * Tout suit la largeur du Header. Ne modifie QUE Header.size.width.
Config.Subtitle.size.width     = Config.Header.size.width
Config.Description.size.width  = Config.Header.size.width
Config.Navigation.size.width   = Config.Header.size.width
