```lua
-- Sur un item List → panels en mode souris uniquement
ColorPanel("Couleur", colors, minIdx, curIdx, function(h, a, newMin, newCur)
    minIdx = newMin; curIdx = newCur
end, listItemIndex, true)   -- ← true = MouseOnly

PercentagePanel(pct, "Opacité", "0%", "100%", function(h, a, newPct)
    pct = newPct
end, listItemIndex, true)   -- ← true = MouseOnly

-- Sur un item Button/Checkbox → clavier actif (comportement normal)
ColorPanel("Couleur", colors, minIdx, curIdx, callback, buttonIndex)
-- ou explicitement false :
ColorPanel("Couleur", colors, minIdx, curIdx, callback, buttonIndex, false)
```
