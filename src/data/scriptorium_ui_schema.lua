local Colors = require("src.data.colors")

return {
    colors = {
        inkwell_order = Colors.inkwell_order,
        short = {
            ROSSO = "R",
            VERDE = "G",
            GIALLO = "Y",
            BLU = "B",
            MARRONE = "Br",
            NERO = "N",
            VIOLA = "P",
            BIANCO = "W",
        },
        labels = {
            MARRONE = {key = "scriptorium.color.label.brown", default = "BROWN"},
            VERDE = {key = "scriptorium.color.label.green", default = "GREEN"},
            NERO = {key = "scriptorium.color.label.black", default = "BLACK"},
            ROSSO = {key = "scriptorium.color.label.red", default = "RED"},
            BLU = {key = "scriptorium.color.label.blue", default = "BLUE"},
            GIALLO = {key = "scriptorium.color.label.yellow", default = "YELLOW"},
            VIOLA = {key = "scriptorium.color.label.purple", default = "PURPLE"},
            BIANCO = {key = "scriptorium.color.label.white", default = "WHITE"},
        },
    },
    hud = {
        status_header = {
            key = "scriptorium.hud.status_header",
            default = "Folio {folio} | Stains: {stains} | Quality: {quality}",
        },
        open_rows_compact = {
            key = "scriptorium.hud.open_rows_compact",
            default = "Open rows {open}/{max}",
        },
        status_badge = {
            key = "scriptorium.hud.status_badge",
            default = "Objective: {objective} {done}/{target}  •  {open_rows}",
        },
        objective_complete_rows = {
            key = "folio.objective.complete_rows",
            default = "Complete rows",
        },
        inkwell_title = {
            key = "scriptorium.hud.inkwell_title",
            default = "Inkwell",
        },
        inkwell_recovery = {
            key = "scriptorium.hud.inkwell_recovery",
            default = "Choose +1 drop ({count} left)",
        },
        brief_title = {
            key = "scriptorium.hud.brief_title",
            default = "Brief",
        },
        brief_bust_open_rows = {
            key = "scriptorium.hud.brief.bust_open_rows",
            default = "Bust: lose wet buffer, +1/+2 stains by rerolls (OPEN rows, {choices} choices)",
        },
        brief_bust_any_rows = {
            key = "scriptorium.hud.brief.bust_any_rows",
            default = "Bust: lose wet buffer, +1/+2 stains by rerolls ({choices} choices)",
        },
        brief_objective = {
            key = "scriptorium.hud.brief.objective",
            default = "Objective: {objective} {done}/{target}",
        },
        brief_open_rows = {
            key = "scriptorium.hud.brief.open_rows",
            default = "Open rows: {rows} / {max}",
        },
        brief_guided_rows = {
            key = "scriptorium.hud.brief.guided_rows",
            default = "Guided rows: {rows}",
        },
        brief_wet_buffer = {
            key = "scriptorium.hud.brief.wet_buffer",
            default = "Wet buffer: {current}/{max}",
        },
        brief_reroll_cap = {
            key = "scriptorium.hud.brief.reroll_cap",
            default = "Reroll cap: {max} (used {used})",
        },
        brief_bust_active = {
            key = "scriptorium.hud.brief.bust_active",
            default = "Bust active: choose one highlighted cell",
        },
        dice_in_hand = {
            key = "scriptorium.hud.dice_in_hand",
            default = "Dice in hand",
        },
        roll_to_draw = {
            key = "scriptorium.hud.roll_to_draw",
            default = "Roll to draw dice",
        },
        turn_palette = {
            key = "scriptorium.hud.turn_palette",
            default = "Turn Palette",
        },
        turn_palette_fixed = {
            key = "scriptorium.hud.turn_palette_fixed",
            default = "Turn palette (fixed)",
        },
        list_separator = {
            key = "scriptorium.hud.list_separator",
            default = ", ",
        },
        list_empty = {
            key = "scriptorium.hud.list_empty",
            default = "-",
        },
        moves_label = {
            key = "scriptorium.hud.moves_label",
            default = "Moves: {count}",
        },
        wet_buffer_title = {
            key = "scriptorium.hud.wet_buffer_title",
            default = "Wet Buffer",
        },
        wet_buffer_undo_short = {
            key = "scriptorium.hud.wet_buffer_undo_short",
            default = "U",
        },
        counter_ratio = {
            key = "scriptorium.hud.counter_ratio",
            default = "{current}/{max}",
        },
        action_reroll_title = {
            key = "scriptorium.hud.action.reroll_title",
            default = "REROLL",
        },
        action_reroll_sub_available = {
            key = "scriptorium.hud.action.reroll_sub_available",
            default = "available",
        },
        action_commit_title = {
            key = "scriptorium.hud.action.commit_title",
            default = "COMMIT",
        },
        action_commit_sub_saturated = {
            key = "scriptorium.hud.action.commit_sub_saturated",
            default = "Ink saturated",
        },
        bust_penalty = {
            key = "scriptorium.hud.action.bust_penalty",
            default = "Bust penalty: {count} stain{suffix}",
        },
        bust_penalty_suffix_plural = {
            key = "scriptorium.hud.action.bust_penalty_suffix_plural",
            default = "s",
        },
        action_roll_title_ready = {
            key = "scriptorium.hud.action.roll_title_ready",
            default = "ROLL",
        },
        action_roll_title_wait = {
            key = "scriptorium.hud.action.roll_title_wait",
            default = "ROLLING",
        },
        action_roll_sub_ready = {
            key = "scriptorium.hud.action.roll_sub_ready",
            default = "roll dice",
        },
        action_roll_sub_wait = {
            key = "scriptorium.hud.action.roll_sub_wait",
            default = "wait",
        },
        system_restart_folio = {
            key = "scriptorium.hud.system.restart_folio",
            default = "RESTART FOLIO",
        },
        system_settings = {
            key = "scriptorium.hud.system.settings",
            default = "SETTINGS",
        },
        system_main_menu = {
            key = "scriptorium.hud.system.main_menu",
            default = "MAIN MENU",
        },
    },
    overlays = {
        pattern_fallback_name = {
            key = "folio.pattern.fallback_name",
            default = "Window",
        },
        objective_complete_rows = {
            key = "folio.objective.complete_rows",
            default = "Complete rows",
        },
        setup_title = {
            key = "scriptorium.overlay.setup.title",
            default = "Preparing the Parchment",
        },
        setup_subtitle = {
            key = "scriptorium.overlay.setup.subtitle",
            default = "Pricking & Ruling   |   Pattern {pattern}",
        },
        setup_step_1 = {
            key = "scriptorium.overlay.setup.step_1",
            default = "1. Pricking",
        },
        setup_step_2 = {
            key = "scriptorium.overlay.setup.step_2",
            default = "2. Ruling",
        },
        setup_step_3 = {
            key = "scriptorium.overlay.setup.step_3",
            default = "3. Start writing",
        },
        setup_note_select_guided = {
            key = "scriptorium.overlay.setup.note_select_guided",
            default = "Select exactly {count} guided rows (pricking).",
        },
        setup_note_max_open = {
            key = "scriptorium.overlay.setup.note_max_open",
            default = "Ruling: max open rows = {count}.",
        },
        setup_note_guided_open = {
            key = "scriptorium.overlay.setup.note_guided_open",
            default = "Both guided rows start open at folio start.",
        },
        setup_note_turn_flow = {
            key = "scriptorium.overlay.setup.note_turn_flow",
            default = "Turn flow: roll 4d6, palette = 3 available inkwell colors.",
        },
        setup_note_reroll_cap = {
            key = "scriptorium.overlay.setup.note_reroll_cap",
            default = "Reroll cap: {count} per turn.",
        },
        setup_note_reroll_default = {
            key = "scriptorium.overlay.setup.note_reroll_default",
            default = "Reroll only unplaced dice after at least one placement.",
        },
        setup_note_wet_buffer = {
            key = "scriptorium.overlay.setup.note_wet_buffer",
            default = "Wet buffer max: {count} dice. Commit when full.",
        },
        setup_note_bust_open_rows = {
            key = "scriptorium.overlay.setup.note_bust_open_rows",
            default = "Bust: lose wet buffer, +1/+2 stains by rerolls in OPEN rows ({choices} choices).",
        },
        setup_note_bust_any_rows = {
            key = "scriptorium.overlay.setup.note_bust_any_rows",
            default = "Bust: lose wet buffer, +1/+2 stains by rerolls ({choices} choices).",
        },
        setup_note_goal = {
            key = "scriptorium.overlay.setup.note_goal",
            default = "Goal: {objective} {target}.",
        },
        setup_preview_title = {
            key = "scriptorium.overlay.setup.preview_title",
            default = "Page Preview",
        },
        setup_rules_title = {
            key = "scriptorium.overlay.setup.rules_title",
            default = "Preparation",
        },
        setup_card_pricking_title = {
            key = "scriptorium.overlay.setup.card_pricking_title",
            default = "Pricking",
        },
        setup_card_pricking_subtitle = {
            key = "scriptorium.overlay.setup.card_pricking_subtitle",
            default = "Select {count} guided rows",
        },
        setup_card_start_title = {
            key = "scriptorium.overlay.setup.card_start_title",
            default = "Start Writing",
        },
        setup_card_start_subtitle = {
            key = "scriptorium.overlay.setup.card_start_subtitle",
            default = "Guided rows open automatically",
        },
        setup_guided_row_selected = {
            key = "scriptorium.overlay.setup.guided_row_selected",
            default = "ROW {row} *",
        },
        setup_guided_row_unselected = {
            key = "scriptorium.overlay.setup.guided_row_unselected",
            default = "ROW {row}",
        },
        setup_auto_row_enabled = {
            key = "scriptorium.overlay.setup.auto_row_enabled",
            default = "AUTO {row}",
        },
        setup_auto_row_locked = {
            key = "scriptorium.overlay.setup.auto_row_locked",
            default = "LOCKED",
        },
        setup_helper_ready = {
            key = "scriptorium.overlay.setup.helper_ready",
            default = "Ready: press START FOLIO",
        },
        setup_helper_select = {
            key = "scriptorium.overlay.setup.helper_select",
            default = "Select {count} guided rows",
        },
        setup_start_cta = {
            key = "scriptorium.overlay.setup.start_cta",
            default = "START FOLIO",
        },
        setup_start_cta_locked = {
            key = "scriptorium.overlay.setup.start_cta_locked",
            default = "START FOLIO (LOCKED)",
        },
        ruling_title = {
            key = "scriptorium.overlay.ruling.title",
            default = "Ruling in Play",
        },
        ruling_subtitle = {
            key = "scriptorium.overlay.ruling.subtitle",
            default = "Open or close rows before the next roll",
        },
        ruling_status = {
            key = "scriptorium.overlay.ruling.status",
            default = "Open rows: {rows}  |  Max open: {max}  |  Actions: {actions}",
        },
        ruling_list_separator = {
            key = "scriptorium.overlay.ruling.list_separator",
            default = ", ",
        },
        ruling_list_empty = {
            key = "scriptorium.overlay.ruling.list_empty",
            default = "-",
        },
        ruling_close_row = {
            key = "scriptorium.overlay.ruling.close_row",
            default = "CLOSE ROW {row}",
        },
        ruling_open_row = {
            key = "scriptorium.overlay.ruling.open_row",
            default = "OPEN ROW {row}",
        },
        ruling_open_guided_row = {
            key = "scriptorium.overlay.ruling.open_guided_row",
            default = "OPEN GUIDED ROW {row}",
        },
        ruling_done = {
            key = "scriptorium.overlay.ruling.done",
            default = "Done",
        },
        ruling_done_warning = {
            key = "scriptorium.overlay.ruling.done_warning",
            default = "Open a row with empty cells",
        },
        result_title_failed = {
            key = "scriptorium.overlay.result.title_failed",
            default = "Folio Failed",
        },
        result_title_completed = {
            key = "scriptorium.overlay.result.title_completed",
            default = "Folio Completed",
        },
        result_subtitle_failed = {
            key = "scriptorium.overlay.result.subtitle_failed",
            default = "No valid rows could be opened.",
        },
        result_subtitle_completed = {
            key = "scriptorium.overlay.result.subtitle_completed",
            default = "The parchment dries. The ink settles.",
        },
        result_rows_completed = {
            key = "scriptorium.overlay.result.rows_completed",
            default = "Rows completed: {count}",
        },
        result_stains = {
            key = "scriptorium.overlay.result.stains",
            default = "Stains: {count}",
        },
        result_turns = {
            key = "scriptorium.overlay.result.turns",
            default = "Turns: {count}",
        },
        result_quality_working = {
            key = "folio.quality.working",
            default = "Working",
        },
        result_cta_deliver = {
            key = "scriptorium.overlay.result.cta_deliver",
            default = "Deliver commission",
        },
        result_cta_next = {
            key = "scriptorium.overlay.result.cta_next",
            default = "Continue to next folio",
        },
    },
    actions = {
        message_bust_title = {
            key = "scriptorium.actions.message.bust.title",
            default = "BUST!",
        },
        message_bust_subtext = {
            key = "scriptorium.actions.message.bust.subtext",
            default = "The folio is ruined. Reputation lost.",
        },
        message_stain_blocked_title = {
            key = "scriptorium.actions.message.stain_blocked.title",
            default = "Stain blocked",
        },
        message_stain_blocked_subtext = {
            key = "scriptorium.actions.message.stain_blocked.subtext",
            default = "Choose another highlighted cell",
        },
        message_bust_followup_title = {
            key = "scriptorium.actions.message.bust_followup.title",
            default = "Bust",
        },
        message_bust_followup_subtext = {
            key = "scriptorium.actions.message.bust_followup.subtext",
            default = "Choose another highlighted cell",
        },
        message_bust_result_ruined_title = {
            key = "scriptorium.actions.message.bust_result.ruined_title",
            default = "BUST! Folio ruined",
        },
        message_bust_result_title = {
            key = "scriptorium.actions.message.bust_result.title",
            default = "Bust!",
        },
        message_bust_result_subtext = {
            key = "scriptorium.actions.message.bust_result.subtext",
            default = "Stain at row {row}, col {col} (+{count})",
        },
        message_bust_result_wet_lost_subtext = {
            key = "scriptorium.actions.message.bust_result.wet_lost_subtext",
            default = "Wet lost: {lost} | +{stains} stain(s)",
        },
        message_completed_title = {
            key = "scriptorium.actions.message.completed.title",
            default = "COMPLETED!",
        },
        message_completed_subtext = {
            key = "scriptorium.actions.message.completed.subtext",
            default = "Folio completed successfully.",
        },
        message_inkwell_full_title = {
            key = "scriptorium.actions.message.inkwell_full.title",
            default = "Inkwell full",
        },
        message_inkwell_full_subtext_choose_missing = {
            key = "scriptorium.actions.message.inkwell_full.subtext_choose_missing",
            default = "Choose a color with missing drops",
        },
        message_row_reward_title = {
            key = "scriptorium.actions.message.row_reward.title",
            default = "Row reward",
        },
        message_row_reward_subtext = {
            key = "scriptorium.actions.message.row_reward.subtext",
            default = "{color} +1 drop recovered",
        },
        message_ruling_title = {
            key = "scriptorium.actions.message.ruling.title",
            default = "Ruling",
        },
        message_ruling_adjust_after_commit_subtext = {
            key = "scriptorium.actions.message.ruling.adjust_after_commit_subtext",
            default = "Adjust rows after commit, then roll",
        },
        message_ruling_swap_cancelled_subtext = {
            key = "scriptorium.actions.message.ruling.swap_cancelled_subtext",
            default = "Swap cancelled",
        },
        message_ruling_select_open_row_to_close_subtext = {
            key = "scriptorium.actions.message.ruling.select_open_row_to_close_subtext",
            default = "Select an OPEN row to close",
        },
        message_ruling_cannot_close_row_subtext = {
            key = "scriptorium.actions.message.ruling.cannot_close_row_subtext",
            default = "Cannot close this row",
        },
        message_ruling_cannot_open_row_subtext = {
            key = "scriptorium.actions.message.ruling.cannot_open_row_subtext",
            default = "Cannot open this row",
        },
        message_ruling_choose_open_row_to_close_subtext = {
            key = "scriptorium.actions.message.ruling.choose_open_row_to_close_subtext",
            default = "Select an open row to close first",
        },
        message_row_reward_pending_title = {
            key = "scriptorium.actions.message.row_reward_pending.title",
            default = "Row reward pending",
        },
        message_row_reward_pending_subtext = {
            key = "scriptorium.actions.message.row_reward_pending.subtext",
            default = "Choose inkwell recovery first",
        },
        message_ruling_pending_title = {
            key = "scriptorium.actions.message.ruling_pending.title",
            default = "Ruling pending",
        },
        message_ruling_pending_subtext = {
            key = "scriptorium.actions.message.ruling_pending.subtext",
            default = "Finish ruling adjustments first",
        },
        message_prepare_parchment_title = {
            key = "scriptorium.actions.message.prepare_parchment.title",
            default = "Prepare parchment",
        },
        message_prepare_parchment_subtext = {
            key = "scriptorium.actions.message.prepare_parchment.subtext",
            default = "Complete pricking and ruling first",
        },
        message_folio_failed_title = {
            key = "scriptorium.actions.message.folio_failed.title",
            default = "Folio failed",
        },
        message_folio_failed_no_rows_subtext = {
            key = "scriptorium.actions.message.folio_failed.no_rows_subtext",
            default = "No rows can be opened",
        },
        message_no_open_cells_title = {
            key = "scriptorium.actions.message.no_open_cells.title",
            default = "No open cells",
        },
        message_no_open_cells_before_roll_subtext = {
            key = "scriptorium.actions.message.no_open_cells.before_roll_subtext",
            default = "Open a row before rolling",
        },
        message_no_open_cells_subtext_open_row_to_continue = {
            key = "scriptorium.actions.message.no_open_cells.subtext_open_row_to_continue",
            default = "Open another row to continue",
        },
        message_no_dice_left_title = {
            key = "scriptorium.actions.message.no_dice_left.title",
            default = "No dice left",
        },
        message_no_dice_left_subtext = {
            key = "scriptorium.actions.message.no_dice_left.subtext",
            default = "Commit wet dice to continue",
        },
        message_wet_buffer_full_title = {
            key = "scriptorium.actions.message.wet_buffer_full.title",
            default = "Wet buffer full",
        },
        message_wet_buffer_full_subtext_press_commit = {
            key = "scriptorium.actions.message.wet_buffer_full.subtext_press_commit",
            default = "Press Commit to dry",
        },
        message_wet_buffer_full_subtext_auto_commit = {
            key = "scriptorium.actions.message.wet_buffer_full.subtext_auto_commit",
            default = "Auto-commit applied",
        },
        message_place_first_title = {
            key = "scriptorium.actions.message.place_first.title",
            default = "Place 1 die first",
        },
        message_place_first_subtext_before_reroll = {
            key = "scriptorium.actions.message.place_first.subtext_before_reroll",
            default = "Choose at least one die before reroll",
        },
        message_reroll_limit_title = {
            key = "scriptorium.actions.message.reroll_limit.title",
            default = "Reroll limit reached",
        },
        message_reroll_limit_subtext_commit_before_new_roll = {
            key = "scriptorium.actions.message.reroll_limit.subtext_commit_before_new_roll",
            default = "Commit wet dice before a new roll",
        },
        message_row_completed_title = {
            key = "scriptorium.actions.message.row_completed.title",
            default = "Row completed",
        },
        message_row_completed_subtext_choose_ink = {
            key = "scriptorium.actions.message.row_completed.subtext_choose_ink",
            default = "Choose {count} ink recovery in the inkwell",
        },
        message_humid_parchment_title = {
            key = "scriptorium.actions.message.humid_parchment.title",
            default = "Humid parchment",
        },
        message_humid_parchment_subtext_die_remains_wet = {
            key = "scriptorium.actions.message.humid_parchment.subtext_die_remains_wet",
            default = "{count} die remains wet",
        },
        message_ink_still_wet_title = {
            key = "scriptorium.actions.message.ink_still_wet.title",
            default = "Ink still wet",
        },
        message_ink_still_wet_subtext_stains_from_risk = {
            key = "scriptorium.actions.message.ink_still_wet.subtext_stains_from_risk",
            default = "+{count} stain(s) from risk",
        },
        message_select_die_title = {
            key = "scriptorium.actions.message.select_die.title",
            default = "Select a die",
        },
        message_select_die_subtext_before_seal = {
            key = "scriptorium.actions.message.select_die.subtext_before_seal",
            default = "Pick one die before using seals",
        },
        message_select_die_subtext_click_tray_first = {
            key = "scriptorium.actions.message.select_die.subtext_click_tray_first",
            default = "Click a die in tray/chips first",
        },
        message_seal_title = {
            key = "scriptorium.actions.message.seal.title",
            default = "Seal",
        },
        message_seal_subtext_reroll_one_die = {
            key = "scriptorium.actions.message.seal.subtext_reroll_one_die",
            default = "Reroll 1 die",
        },
        message_seal_subtext_adjusted_die_to = {
            key = "scriptorium.actions.message.seal.subtext_adjusted_die_to",
            default = "Adjusted die to {value}",
        },
        message_placement_blocked_title = {
            key = "scriptorium.actions.message.placement_blocked.title",
            default = "Placement blocked",
        },
        message_placement_blocked_subtext_no_palette_fit = {
            key = "scriptorium.actions.message.placement_blocked.subtext_no_palette_fit",
            default = "No palette color fits this cell",
        },
        message_placement_blocked_subtext_cannot_place_die = {
            key = "scriptorium.actions.message.placement_blocked.subtext_cannot_place_die",
            default = "Cannot place die",
        },
        message_double_award_title = {
            key = "scriptorium.actions.message.double_award.title",
            default = "Double!",
        },
        message_double_award_subtext = {
            key = "scriptorium.actions.message.double_award.subtext",
            default = "+1 Seal",
        },
        message_undo_locked_title = {
            key = "scriptorium.actions.message.undo_locked.title",
            default = "Undo locked",
        },
        message_undo_locked_subtext_after_reroll = {
            key = "scriptorium.actions.message.undo_locked.subtext_after_reroll",
            default = "Cannot undo after reroll",
        },
        instruction_setup_guided = {
            key = "scriptorium.actions.instruction.setup_guided",
            default = "Preparing parchment: pick {count} guided row(s), both start open",
        },
        instruction_close_message = {
            key = "scriptorium.actions.instruction.close_message",
            default = "Click to close the message",
        },
        instruction_stain_pick = {
            key = "scriptorium.actions.instruction.stain_pick",
            default = "Bust: choose one highlighted cell for the stain",
        },
        instruction_ink_recovery = {
            key = "scriptorium.actions.instruction.ink_recovery",
            default = "Row completed: choose {count} inkwell recovery (+1 drop each)",
        },
        instruction_ruling_select_close = {
            key = "scriptorium.actions.instruction.ruling_select_close",
            default = "Ruling: select an open row to close",
        },
        instruction_ruling_adjust = {
            key = "scriptorium.actions.instruction.ruling_adjust",
            default = "Ruling: adjust rows, then press ROLL",
        },
        instruction_waiting_roll_start = {
            key = "scriptorium.actions.instruction.waiting_roll_start",
            default = "Press ROLL to start the next turn",
        },
        instruction_waiting_review = {
            key = "scriptorium.actions.instruction.waiting_review",
            default = "Review the folio state, then press ROLL",
        },
        instruction_rolling = {
            key = "scriptorium.actions.instruction.rolling",
            default = "Dice are moving...",
        },
        instruction_wet_buffer_full = {
            key = "scriptorium.actions.instruction.wet_buffer_full",
            default = "Wet buffer full: press Commit to dry",
        },
        instruction_select_die = {
            key = "scriptorium.actions.instruction.select_die",
            default = "Select a die to place",
        },
        instruction_place_reroll_commit = {
            key = "scriptorium.actions.instruction.place_reroll_commit",
            default = "Place a die on an open row, then Reroll or Commit",
        },
        instruction_mouse_only = {
            key = "scriptorium.actions.instruction.mouse_only",
            default = "Mouse-only mode",
        },
        flow = {
            confirm_mouse_button = 1,
            system_settings_module = "settings",
            system_main_menu_module = "main_menu",
            audio_toggle = "toggle",
            audio_confirm = "confirm",
            audio_back = "back",
            audio_move = "move",
        },
    },
    module = {
        legend_title = {
            key = "scriptorium.module.legend.title",
            default = "Constraints",
        },
        flow_message_folio_title = {
            key = "scriptorium.module.flow.message.folio_title",
            default = "Folio {index}/{total}",
        },
        flow_message_next_ready_subtitle = {
            key = "scriptorium.module.flow.message.next_ready_subtitle",
            default = "Ready. Press ROLL to start.",
        },
        flow_message_commission_complete_title = {
            key = "scriptorium.module.flow.message.commission_complete_title",
            default = "COMMISSION COMPLETE",
        },
        flow_message_dirty_finish_subtitle = {
            key = "scriptorium.module.flow.message.dirty_finish_subtitle",
            default = "Dirty finish: {stains} stains (threshold {threshold})",
        },
        flow_message_victory_title = {
            key = "scriptorium.module.flow.message.victory_title",
            default = "VICTORY!",
        },
        flow_message_game_over_title = {
            key = "scriptorium.module.flow.message.game_over_title",
            default = "GAME OVER",
        },
        result_quality_failed = {
            key = "scriptorium.module.result.quality.failed",
            default = "Failed",
        },
        result_quality_working = {
            key = "folio.quality.working",
            default = "Working",
        },
        stain_pick_hint = {
            key = "scriptorium.module.stain_pick.hint",
            default = "BUST: choose where the stain lands",
        },
        overview_completed = {
            key = "scriptorium.module.overview.completed",
            default = "Completed",
        },
        overview_grid_size = {
            key = "scriptorium.module.overview.grid_size",
            default = "{rows}x{cols} grid",
        },
        overview_progress_ratio = {
            key = "scriptorium.module.overview.progress_ratio",
            default = "{filled}/{total}",
        },
        overview_click_to_zoom = {
            key = "scriptorium.module.overview.click_to_zoom",
            default = "Click to zoom",
        },
        zoom_back_to_overview = {
            key = "scriptorium.module.zoom.back_to_overview",
            default = "Back to overview",
        },
        zoom_progress = {
            key = "scriptorium.module.zoom.progress",
            default = "Progress: {filled}/{total}",
        },
        tile_preview_delta = {
            key = "scriptorium.module.tile_preview.delta",
            default = "+Q{quality} / +R{risk}",
        },
        row_rules_separator = {
            key = "scriptorium.module.row_rules.separator",
            default = " • ",
        },
        element_display_folio = {
            key = "scriptorium.module.element_display.folio",
            default = "Folio",
        },
        element_display_dropcaps = {
            key = "scriptorium.module.element_display.dropcaps",
            default = "Dropcaps/Corners",
        },
        element_display_borders = {
            key = "scriptorium.module.element_display.borders",
            default = "Borders",
        },
        element_display_miniature = {
            key = "scriptorium.module.element_display.miniature",
            default = "Miniature",
        },
        unlock_locked = {
            key = "scriptorium.module.unlock.locked",
            default = "Locked",
        },
        unlock_locked_complete = {
            key = "scriptorium.module.unlock.locked_complete",
            default = "Locked: complete {element}",
        },
        constraint_lines = {
            {
                key = "scriptorium.module.constraint.specific_value",
                default = "Specific value",
            },
            {
                key = "scriptorium.module.constraint.specific_color",
                default = "Specific color",
            },
            {
                key = "scriptorium.module.constraint.diff_adjacent_colors",
                default = "Different adjacent colors",
            },
            {
                key = "scriptorium.module.constraint.diff_adjacent_values",
                default = "Different adjacent values",
            },
            {
                key = "scriptorium.module.constraint.same_diagonal_values",
                default = "Same value on diagonals",
            },
            {
                key = "scriptorium.module.constraint.color_value_pair",
                default = "Color + value pair",
            },
            {
                key = "scriptorium.module.constraint.odd_only",
                default = "Odd values only",
            },
            {
                key = "scriptorium.module.constraint.even_only",
                default = "Even values only",
            },
            {
                key = "scriptorium.module.constraint.no_gold_marked",
                default = "No gold in marked cells",
            },
            {
                key = "scriptorium.module.constraint.all_values_diff_row",
                default = "All values differ in row",
            },
            {
                key = "scriptorium.module.constraint.permanent_stain",
                default = "Permanent stain (BUST)",
            },
        },
        row_rule_labels = {
            ODD_ONLY = {
                key = "scriptorium.module.row_rule.odd_only",
                default = "ODD",
            },
            EVEN_ONLY = {
                key = "scriptorium.module.row_rule.even_only",
                default = "EVEN",
            },
            NO_COLOR_REPEAT = {
                key = "scriptorium.module.row_rule.no_color_repeat",
                default = "NO COLOR",
            },
            NO_VALUE_REPEAT = {
                key = "scriptorium.module.row_rule.no_value_repeat",
                default = "NO VALUE",
            },
        },
    },
}
