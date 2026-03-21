-- ============================================================================
-- imports.lua — Bootstrap ama_ui pour resources externes
--
-- Usage dans fxmanifest.lua d'une autre resource :
--
--   dependency 'ama_ui'
--   client_scripts {
--       '@ama_ui/imports.lua',   -- ← une seule ligne, toute la lib disponible
--       'client/*.lua',
--   }
--
-- Donne accès à :
--   ama_ui.CreateMenu / CreateSubMenu / Visible / IsVisible
--   ama_ui.ColorPanel / GridPanel / GridPanelH / GridPanelV
--   ama_ui.PercentagePanel / StatisticsPanel / StatisticsPanelAdvanced
-- ============================================================================

ama_ui = exports['ama_ui']:getSharedObject()

-- Panels disponibles comme globaux (compatibilité menu:SetPanels)
ColorPanel              = ama_ui.ColorPanel
GridPanel               = ama_ui.GridPanel
GridPanelH              = ama_ui.GridPanelH
GridPanelV              = ama_ui.GridPanelV
PercentagePanel         = ama_ui.PercentagePanel
StatisticsPanel         = ama_ui.StatisticsPanel
StatisticsPanelAdvanced = ama_ui.StatisticsPanelAdvanced
