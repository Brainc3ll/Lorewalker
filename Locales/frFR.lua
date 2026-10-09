if GetLocale() ~= "frFR" then return end

local env = select(2, ...)
local L = env.L

L["ESC"] = "ÉCHAP"
L["GOODBYE"] = GOODBYE
L["ACCEPT"] = ACCEPT
L["AUTO_ACCEPT"] = ACCEPT
L["DECLINE"] = DECLINE
L["CANCEL"] = CANCEL
L["CONTINUE"] = CONTINUE
L["COMPLETE"] = COMPLETE
L["OBJECTIVES"] = "Objectifs"
L["REQUIRED_ITEMS"] = TURN_IN_ITEMS
L["REWARDS"] = REWARDS
L["LEARN_SPELL_OBJECTIVE"] = LEARN_SPELL_OBJECTIVE
L["WIP"] = "En cours de développement"
L["FORMAT_SECONDS"] = "%g s"

-- Frames
L["DIALOG_FRAME"] = "Fenêtre de dialogue"
L["DIALOG_SETTINGS_OPEN"] = "Ouvrir les paramètres"
L["DIALOG_SETTINGS_MODE"] = "Mode de dialogue"
L["DIALOG_QUEST_LEVEL"] = "Niveau %d"

-- Playback
L["PLAYBACK_PAUSE_CHARACTERS"] = {
    "…",
    "!",
    "?",
    ".",
    ",",
    ";",
    ":",
}
L["PLAYBACK_SPEED_MODIFIER"] = 1

-- Config
L["CONFIG_GENERAL"] = "Général"
L["CONFIG_GENERAL_PREFERENCES"] = "Préférences"
L["CONFIG_GENERAL_PREFERENCES_FONT"] = "Police"
L["CONFIG_GENERAL_OTHER"] = "Autre"
L["CONFIG_GENERAL_OTHER_RESETBUTTON"] = "Réinitialiser tous les paramètres"
L["CONFIG_GENERAL_OTHER_RESETPROMPT"] = "Voulez-vous vraiment réinitialiser tous les paramètres ?"
L["CONFIG_GENERAL_OTHER_RESETPROMPT_YES"] = "Confirmer"
L["CONFIG_GENERAL_OTHER_RESETPROMPT_NO"] = "Annuler"

L["CONFIG_DIALOGUE"] = "Dialogue"
L["CONFIG_DIALOGUE_MODE_CLASSIC"] = "Classique"
L["CONFIG_DIALOGUE_MODE_IMMERSIVE"] = "Immersif"
L["CONFIG_DIALOGUE_MODE_STORY"] = "Histoire"
L["CONFIG_DIALOGUE_PREFERENCES"] = "Préférences"
L["CONFIG_DIALOGUE_PREFERENCES_FORCEGOSSIP"] = "Afficher les dialogues masqués"
L["CONFIG_DIALOGUE_PREFERENCES_SHOWQUESTLEVEL"] = "Afficher le niveau des quêtes"
L["CONFIG_DIALOGUE_FRAME"] = "Fenêtre de dialogue"
L["CONFIG_DIALOGUE_RIGHTCLICKTOCLOSE"] = "Clic droit pour fermer"
L["CONFIG_DIALOGUE_CLOSETOPREVIOUSPAGE"] = "Fermer vers la page précédente"
L["CONFIG_DIALOGUE_CLOSETOPREVIOUSPAGE_DESCRIPTION"] = "Sur les pages de quête, le raccourci de fermeture ramène à la page précédente au lieu de fermer l'interface."
L["CONFIG_DIALOGUE_IMMERSIVE"] = "Immersif"
L["CONFIG_DIALOGUE_IMMERSIVE_SPLITPARAGRAPHS"] = "Découper en paragraphes"
L["CONFIG_DIALOGUE_IMMERSIVE_SPLITPARAGRAPHS_DESCRIPTION"] = "Découpe le dialogue en paragraphes. Si désactivé, le découpe en phrases."
L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACK"] = "Défilement du texte"
L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACK_DESCRIPTION"] = "Affiche le texte du dialogue progressivement."
L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKSPEED"] = "Vitesse de défilement"
L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKAUTOPROGRESS"] = "Avance automatique"
L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKAUTOPROGRESSDELAY"] = "Délai"
L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKPUNCTUATIONPAUSING"] = "Pause à la ponctuation"
L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKAUTOCLOSE"] = "Fermeture automatique"
L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKAUTOCLOSE_DESCRIPTION"] = "Ferme le dialogue après le dernier message lorsqu'aucun choix n'est proposé."
L["CONFIG_DIALOGUE_IMMERSIVE_CONTENTPREVIEWALPHA"] = "Luminosité de l'aperçu du contenu"

L["CONFIG_EFFECTS"] = "Effets"
L["CONFIG_EFFECTS_HIDEUI"] = "Masquer l'interface"
L["CONFIG_EFFECTS_CAMERA"] = "Effets de caméra"
L["CONFIG_EFFECTS_CAMERA_NONE"] = "Aucun"
L["CONFIG_EFFECTS_CAMERA_FULL"] = "Complet"
L["CONFIG_EFFECTS_CAMERA_BALANCED"] = "Équilibré"
L["CONFIG_EFFECTS_CAMERA_CUSTOM"] = "Personnalisé"

L["CONFIG_TTS"] = "Synthèse vocale"

L["CONFIG_KEYBINDINGS"] = "Raccourcis"
L["CONFIG_KEYBINDINGS_ACTIONS"] = "Actions"
L["CONFIG_KEYBINDINGS_DEVICE_KBM"] = "Clavier/souris"
L["CONFIG_KEYBINDINGS_DEVICE_GAMEPAD"] = "Manette"
L["CONFIG_KEYBINDINGS_CONFIRM"] = "Confirmer"
L["CONFIG_KEYBINDINGS_CONFIRM_USEINTERACTKEY"] = "Utiliser la touche d'interaction"
L["CONFIG_KEYBINDINGS_CLOSE"] = "Fermer"
L["CONFIG_KEYBINDINGS_SCROLLDOWN"] = "Défiler vers le bas"
L["CONFIG_KEYBINDINGS_SCROLLUP"] = "Défiler vers le haut"
L["CONFIG_KEYBINDINGS_SCROLLLEFT"] = "Défiler vers la gauche"
L["CONFIG_KEYBINDINGS_SCROLLRIGHT"] = "Défiler vers la droite"
L["CONFIG_KEYBINDINGS_PREVIOUSDIALOG"] = "Dialogue précédent"
L["CONFIG_KEYBINDINGS_NEXTDIALOG"] = "Dialogue suivant"
L["CONFIG_KEYBINDINGS_SELECTOPTION"] = "Choisir l'option %d"

L["CONFIG_APPEARANCE"] = "Apparence"
L["CONFIG_APPEARANCE_POSITION"] = "Position"
L["CONFIG_APPEARANCE_POSITION_LOCKFRAMEPOSITIONS"] = "Verrouiller la position des fenêtres"
L["CONFIG_APPEARANCE_POSITION_RESTOREPOSITIONS"] = "Restaurer les positions"
L["CONFIG_APPEARANCE_POSITION_RESTOREPOSITIONS_PROMPT"] = "Voulez-vous vraiment réinitialiser la position de toutes les fenêtres ?"
L["CONFIG_APPEARANCE_POSITION_RESTOREPOSITIONS_PROMPT_YES"] = "Confirmer"
L["CONFIG_APPEARANCE_POSITION_RESTOREPOSITIONS_PROMPT_NO"] = "Annuler"
L["CONFIG_APPEARANCE_DIALOG"] = "Fenêtre de dialogue"
L["CONFIG_APPEARANCE_DIALOG_THEME"] = "Thème"
L["CONFIG_APPEARANCE_DIALOG_THEME_LIGHT"] = "Clair"
L["CONFIG_APPEARANCE_DIALOG_THEME_DARK"] = "Sombre"
L["CONFIG_APPEARANCE_DIALOG_FRAMETHEME"] = "Thème du cadre"
L["CONFIG_APPEARANCE_DIALOG_FRAMETHEME_DEFAULT"] = "Par défaut"
L["CONFIG_APPEARANCE_DIALOG_FRAMETHEME_FOREVER"] = "Forever"
L["CONFIG_APPEARANCE_DIALOG_FONTSIZE"] = "Taille de police"
L["CONFIG_APPEARANCE_IMMERSIVE"] = "Immersif"
L["CONFIG_APPEARANCE_IMMERSIVE_FONTSIZE"] = "Taille de police des bulles"

L["CONFIG_AUDIO"] = "Audio"
L["CONFIG_AUDIO_GENERAL"] = "Général"
L["CONFIG_AUDIO_GENERAL_ENABLEGLOBALAUDIO"] = "Activer le son"

L["CONFIG_ABOUT"] = "À propos"
L["CONFIG_ABOUT_CONTRIBUTORS"] = "Contributeurs"
L["CONFIG_ABOUT_DEVELOPER"] = "Développeur"
L["CONFIG_ABOUT_DEVELOPER_ADAPTIVEX"] = "AdaptiveX"

-- Contributors
L["CONTRIBUTORS_ZAMESTOTV"] = "ZamestoTV"
L["CONTRIBUTORS_ZAMESTOTV_DESCRIPTION"] = "Traducteur — Russe"
L["CONTRIBUTORS_CRAZYYOUNGS"] = "Crazyyoungs"
L["CONTRIBUTORS_CRAZYYOUNGS_DESCRIPTION"] = "Traducteur — Coréen"
L["CONTRIBUTORS_LANJIAN625"] = "lanjian625"
L["CONTRIBUTORS_LANJIAN625_DESCRIPTION"] = "Code — Correctif de bêta"
