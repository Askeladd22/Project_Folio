# Public-source FX research

Research date: 2026-10-15. Sources below were read through web search/page extraction. No gameplay video was watched or timed in this research pass. Thus no frame counts, exact durations, easing curves, sound envelopes, or claims of personally observed motion are supplied. No game executable, proprietary source, shader, texture, or audio was extracted. Suggested implementations are original hypotheses, not statements about the games' internal code.

## Strongest evidence: Luck be a Landlord

- [Developer's Effects API documentation](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Effects), edited by Dan DiIorio: effects test conditions per spin; animation choices include circle, rotate, bounce, shake, and texture cycles. Animation targets can be the source, source plus affected adjacent symbol, or all adjacent symbols. Execution-order flags distinguish effects before and after normal effects. This directly supports a source-to-target activation grammar and distinct animation motifs; it does not establish their duration or exact appearance.
- [Developer's Value Text tutorial](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Tutorial-1.6:-Value-Text): persistent reminder text can describe future value; the author recommends configurable color identifiers because players adjust contrast. This is a particularly useful accessibility reference: transient motion should be complemented by persistent state.
- [Official press kit](https://trampolinetales.com/lbal/presskit): source for approved reference screenshots and promotional material, not a reuse license for game art.

Original implementation hypothesis: enqueue an immutable activation record containing source, targets, value delta, and motif. Resolve one causal step at a time; keep a persistent value badge. Allow fast mode to shorten presentation without altering simulation order.

## Balatro

- [Official press kit](https://www.playbalatro.com/press-kit/) lists official GIFs, screenshots, and an official trailer. These are suitable next-step observation targets for scoring pulses, card destruction, and edition appearance. They were not played in this pass.
- [Steamodded edition documentation entry](https://github.com/Steamodded/smods/wiki/SMODS.Edition) now redirects readers to [the new documentation location](https://docs.smods.dev/Game%20Objects/SMODS.Center/SMODS.Edition). The new location could not be retrieved by the web tool. An older indexed mirror describes edition shader selection, shadows, application sounds, and a base dissolve pass; treat that as historical community API evidence only, not a verified current developer implementation.

Evidence boundary: this pass does not establish foil/holographic/polychrome formulas, scoring pulse timing, or dissolve noise parameters. Do not label a recreated shader as Balatro's shader.

Original implementation hypothesis: keep card face, material overlay, activation pulse, and removal mask independent. Foil can use a narrow moving specular band; holographic material can use low-amplitude color interference; polychrome can use a slow hue field. A noise-threshold mask can implement removal. These are generic techniques to prototype with original art, not reverse-engineered recipes.

## Dicey Dungeons

- [Official version 0.15 development post](https://diceydungeons.com/blog/2018/12/25/version-15.html) explicitly describes animated scene backgrounds, animated characters, tooltips, enemy move previews, and animation-speed controls. It supports offering readable previews plus adjustable pacing.
- [Official modding wiki](https://mods.diceydungeons.com/doku.php?id=start) is the supported documentation entry point.
- [Character documentation](https://mods.diceydungeons.com/doku.php?id=mods%3Aadding_characters) documents animation asset references but explicitly leaves animation authoring to other documentation. It is not evidence for dice or equipment tween parameters.

Original implementation hypothesis: dice insertion should have a clear accepted/rejected state, a short equipment-local response, and a persistent resulting value. Exact squash, travel arc, and audio synchronization require observation; none were measured here.

## Slay the Spire

- [Mega Crit official press kit](https://www.megacrit.com/press-kits/slay-the-spire/) supplies official launch trailers and screenshots and confirms the central role of cards and relics. It credits animation and sound contributors, but does not describe relic flash mechanics.

Evidence boundary: no reliable primary text found in this pass establishes relic flash shape, duration, reward timing, or their internal classes. Those remain observation tasks, not documented facts.

Original implementation hypothesis: flash the specific passive item responsible for an effect, then animate the consequence at its destination. Rewards should use an explicit reveal/inspect/choose progression with readable resting states. This is a proposed causal UI pattern, not an assertion about exact shipped behavior.

## Scriptorium: Master of Manuscripts

- [Yaza Games FAQ](https://www.yazagames.com/faq) describes manuscript design, commissions, workshop personalization, and a shared manuscript art direction with Inkulinati. It also describes image export per page. This supports material-oriented composition and decorative typography as references, not a particular paper shader.
- [Official Steam description](https://store.steampowered.com/app/3119540/Scriptorium_Master_of_Manuscripts/) describes blank parchment, a medieval asset library, ornate uppercase lettering, and a relaxed space without timers.

Original implementation hypothesis: stable parchment texture, restrained ink spread, occasional gilt sheen, and crisp text above surface effects. Avoid continuous high-contrast material animation beneath reading content. No physical material simulation was documented.

## BOOK OF HOURS

- [Weather Factory: The Early Draft Edition](https://weatherfactory.biz/boh-the-early-draft-edition/) explains books as shelf objects that also participate in recipe UI, and optional lore shown separately from main text with aspect links. This is direct evidence for separating atmospheric objects from focused reading panels.
- [Weather Factory: The Countdown Begins](https://weatherfactory.biz/the-countdown-begins/) names an in-game music player, workstation UI improvements, and pet sound effects. It establishes audio/UI features, not ambient-loop timing or sound character.
- [2019 technical prototype post](https://weatherfactory.biz/in-which-weather-factory-invents-the-3rd-dimension/) explains early spatial experiments. Historical prototype evidence must not be presented as final-release implementation.

Original implementation hypothesis: ambient light/weather can move slowly outside the active reading area, while actionable cards retain stable contrast and precise hover/selection states.

## Inkulinati

- [Official Steam description](https://store.steampowered.com/app/957960/Inkulinati/) explicitly describes drawing beasts and Hand Actions that smash units, draw barriers, and relocate units with a finger. This establishes the artist's hand as a causal part of the presentation, rather than a purely decorative cursor.
- [Yaza official site](https://www.yazagames.com/home) identifies medieval marginalia as the art inspiration.
- [Development partner Pineapple Works](https://pineapple.works/project/inkulinati/) identifies Unity and describes hand-drawn creatures battling on manuscript pages. Engine identification does not identify any particular shader or animation method.

Original implementation hypothesis: reveal original ink art with a directional mask following a quill path, then settle into a low-amplitude idle. Use the visible hand or tool only when it explains an action. Stroke order, wet-edge behavior, and timing remain unmeasured.

## Observation and reuse rules

For each later video observation, record the actual URL, game/version if known, playback speed, timestamp interval, and whether sound was heard. Separate direct observation from interpretation. Press access and public documentation do not automatically grant redistribution rights. This pass imported no third-party assets or code and recommends no unverified library license. Generic tweening, alpha masks, procedural noise, and color blending can be implemented independently in the project's existing engine.
