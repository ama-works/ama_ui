-- color/badge_style.lua
-- BadgeStyle — Sprites de badges pour UIMenuButton (RightBadge / LeftBadge)
--
-- Chaque entrée est une closure pré-construite : zéro allocation par frame.
-- Usage: menu:Button("Label", "Desc", { RightBadge = BadgeStyle.Lock })
--
-- 3 types de badges :
--   _badgeStatic(dict, texture)         → couleur fixe blanche, texture fixe
--   _badgeTint(dict, texture)           → blanc en normal, noir quand sélectionné
--   _badge2(dict, texNormal, texSel)    → deux textures (a/b) selon l'état
--
-- Format retourné par chaque closure : { dict, texture, color = {r,g,b,a} }

local function _badgeStatic(dict, texture)
    local d = { dict = dict, texture = texture, color = { r=255, g=255, b=255, a=255 } }
    return function(_) return d end
end

local function _badgeTint(dict, texture)
    local n = { dict = dict, texture = texture, color = { r=255, g=255, b=255, a=255 } }
    local s = { dict = dict, texture = texture, color = { r=0,   g=0,   b=0,   a=255 } }
    return function(isSelected) return isSelected and s or n end
end

local function _badge2(dict, texNormal, texSelected)
    local n = { dict = dict, texture = texNormal,   color = { r=255, g=255, b=255, a=255 } }
    local s = { dict = dict, texture = texSelected, color = { r=255, g=255, b=255, a=255 } }
    return function(isSelected) return isSelected and s or n end
end

BadgeStyle = {
    -- ── Statiques ─────────────────────────────────────────────────────────────
    None        = _badgeStatic("commonmenu",   ""),
    BronzeMedal = _badgeStatic("commonmenu",   "mp_medal_bronze"),
    GoldMedal   = _badgeStatic("commonmenu",   "mp_medal_gold"),
    SilverMedal = _badgeStatic("commonmenu",   "medal_silver"),
    Alert       = _badgeStatic("commonmenu",   "mp_alerttriangle"),
    Star        = _badgeStatic("commonmenu",   "shop_new_star"),
    RP          = _badgeStatic("mphud",        "mp_anim_rp"),
    LSPD        = _badgeStatic("3dtextures",   "mpgroundlogo_cops"),
    Vagos       = _badgeStatic("3dtextures",   "mpgroundlogo_vagos"),
    Bikers      = _badgeStatic("3dtextures",   "mpgroundlogo_bikers"),

    -- ── Tint (blanc normal / noir sélectionné) ────────────────────────────────
    Crown       = _badgeTint("commonmenu",     "mp_hostcrown"),
    Lock        = _badgeTint("commonmenu",     "shop_lock"),
    Tick        = _badgeTint("commonmenu",     "shop_tick_icon"),

    -- ── Deux textures (a=normal / b=sélectionné) ──────────────────────────────
    Ammo        = _badge2("commonmenu", "shop_ammo_icon_a",         "shop_ammo_icon_b"),
    Armour      = _badge2("commonmenu", "shop_armour_icon_a",       "shop_armour_icon_b"),
    Barber      = _badge2("commonmenu", "shop_barber_icon_a",       "shop_barber_icon_b"),
    Clothes     = _badge2("commonmenu", "shop_clothes_icon_a",      "shop_clothes_icon_b"),
    Franklin    = _badge2("commonmenu", "shop_franklin_icon_a",     "shop_franklin_icon_b"),
    Bike        = _badge2("commonmenu", "shop_bike_icon_a",         "shop_bike_icon_b"),
    Car         = _badge2("commonmenu", "shop_car_icon_a",          "shop_car_icon_b"),
    Boat        = _badge2("commonmenu", "shop_boat_icon_a",         "shop_boat_icon_b"),
    Heli        = _badge2("commonmenu", "shop_heli_icon_a",         "shop_heli_icon_b"),
    Plane       = _badge2("commonmenu", "shop_plane_icon_a",        "shop_plane_icon_b"),
    BoatPickup  = _badge2("commonmenu", "shop_boatpickup_icon_a",   "shop_boatpickup_icon_b"),
    Card        = _badge2("commonmenu", "shop_card_icon_a",         "shop_card_icon_b"),
    Gun         = _badge2("commonmenu", "shop_gunclub_icon_a",      "shop_gunclub_icon_b"),
    Heart       = _badge2("commonmenu", "shop_health_icon_a",       "shop_health_icon_b"),
    Makeup      = _badge2("commonmenu", "shop_makeup_icon_a",       "shop_makeup_icon_b"),
    Mask        = _badge2("commonmenu", "shop_mask_icon_a",         "shop_mask_icon_b"),
    Michael     = _badge2("commonmenu", "shop_michael_icon_a",      "shop_michael_icon_b"),
    Tattoo      = _badge2("commonmenu", "shop_tattoos_icon_a",      "shop_tattoos_icon_b"),
    Trevor      = _badge2("commonmenu", "shop_trevor_icon_a",       "shop_trevor_icon_b"),
    Key         = _badge2("commonmenu", "shop_key_icon_a",          "shop_key_icon_b"),
    Coke        = _badge2("commonmenu", "mp_specitem_coke_a",       "mp_specitem_coke_b"),
    Heroin      = _badge2("commonmenu", "mp_specitem_heroin_a",     "mp_specitem_heroin_b"),
    Meth        = _badge2("commonmenu", "mp_specitem_meth_a",       "mp_specitem_meth_b"),
    Weed        = _badge2("commonmenu", "mp_specitem_weed_a",       "mp_specitem_weed_b"),
    Package     = _badge2("commonmenu", "mp_specitem_package_a",    "mp_specitem_package_b"),
    Cash        = _badge2("commonmenu", "mp_specitem_cash_a",       "mp_specitem_cash_b"),

    -- ── Casino (mpawardcasino) ────────────────────────────────────────────────
    Badbeat          = _badgeStatic("mpawardcasino", "casino_award_badbeat"),
    CashingOut       = _badgeStatic("mpawardcasino", "casino_award_cashing_out"),
    FullHouse        = _badgeStatic("mpawardcasino", "casino_award_full_house"),
    HighRoller       = _badgeStatic("mpawardcasino", "casino_award_high_roller"),
    HouseKeeping     = _badgeStatic("mpawardcasino", "casino_award_house_keeping"),
    LooseCheng       = _badgeStatic("mpawardcasino", "casino_award_loose_cheng"),
    LuckyLucky       = _badgeStatic("mpawardcasino", "casino_award_lucky_lucky"),
    PlayToWin        = _badgeStatic("mpawardcasino", "casino_award_play_to_win"),
    StraightFlush    = _badgeStatic("mpawardcasino", "casino_award_straight_flush"),
    StrongArmTactics = _badgeStatic("mpawardcasino", "casino_award_strong_arm_tactics"),
    TopPair          = _badgeStatic("mpawardcasino", "casino_award_top_pair"),
}
