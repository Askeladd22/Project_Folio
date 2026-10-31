# UI 2.0 — Studio P1: folio singolo o codice aperto?

**Stato: studio tecnico anticipato, non decisione finale e NON nuova UI giocabile.**
La P0 resta aperta finché mancano screenshot/FPS della baseline Windows.
Questo esperimento permette di studiare una scelta P1 in parallelo,
senza falsificare i gate della [roadmap](UI_V2_ROADMAP.md).

## Dato di partenza: spazio reale per i D6

Nel codice legacy `hud_minimal.lua`, il tray dichiarato è
`1460 × 808` unità virtuali nel canvas `1920 × 1080`.
È un **rettangolo di riferimento per il fit**, non un conteggio di pixel
effettivamente ricoperti dai dadi proiettati (contano prospettiva/ombra).

Due candidati, calcolati dal modulo puro
`src/features/farkle/ui_v2/layout_candidates.lua`:

| Grandezza, coordinate virtuali 1920×1080 | A: folio singolo | B: codice aperto |
|---|---:|---:|
| Tray per sei D6 g3d | **1402×666** | **1136×598** |
| Superficie rettangolare tray | **933.732** | **679.328** |
| Rapporto rispetto al tray legacy | **79,15%** | **57,59%** |
| Rapporto con candidato A | 100% | **72,75%** |
| Area contigua riservata a progressione/folio | 352×562 | **530×520** |
| Area progressione | 197.824 | **275.600** |
| Header / feedback / azioni primarie | Identici | Identici |

Il codice aperto offre il **39% di superficie in più al folio di
progressione**, ma sottrae circa **27% dell'area di tiro** rispetto
al folio singolo. Questo costo non è teorico: le facce numerate di sei
dadi fisici devono rimanere leggibili a 1280×720, specialmente mentre
si afferrano in gruppo, e la camera g3d viene adattata al tray scelto.

### Candidato A — folio singolo giocabile

```text
┌──────────────────── testata di commissione ─────────────────────┐
│   PAGINA FISICA GIOCABILE                    │ diario di lavoro  │
│   ┌──── dadi accantonati ────────────────┐   │                 │
│   ├──────────────────────────────────────┤   │ folio           │
│   │                                      │   │ progresso       │
│   │            6 D6 g3d                  │   │                 │
│   │         lancia / afferra             │   ├─────────────────┤
│   │                                      │   │ scelte / medaglie│
│   └──────────────────────────────────────┘   │                 │
├──────────────────── feedback di stato ─────────────────────────┤
│                   azione 1     azione 2                       │
└───────────────────────────────────────────────────────────────┘
```

La pagina di gioco mantiene quasi l'80% del tray legacy e il foglio
di progresso diventa una tavoletta/registro laterale, non una
seconda superficie su cui far rimbalzare i dadi. Contenuti narrativi
futuri avranno uno slot, senza sistemi fittizi di combattimento.

### Candidato B — libro aperto a due pagine

```text
┌──────────────────── testata di commissione ────────────────────┐
│                 LIBRO APERTO                                  │
│ ┌────── pagina sinistra ──────┐┌──────── pagina destra ──────┐ │
│ │   dadi accantonati         ││ folio / avanzamento          │ │
│ ├────────────────────────────┤│                               │ │
│ │       6 D6 g3d             ││ figure / testi              │ │
│ │       area più stretta     │├───────────────────────────────┤ │
│ │                            ││ scelte / medaglie             │ │
│ └────────────────────────────┘└───────────────────────────────┘ │
├────────────────── feedback di stato ──────────────────────────┤
│                   azione 1     azione 2                       │
└──────────────────────────────────────────────────────────────┘
```

È più vicino alla metafora di un codice aperto e offre spazio a
miniature e Segni **quando il game design li definirà**, ma la pagina
fisica di lancio si restringe in modo sostanziale.

## Proposta provvisoria

**A è la candidata tecnica di partenza**, NON una scelta di design
approvata. Per un gioco che pone al centro il gesto fisico di sei
dadi, la superficie di tiro e la leggibilità hanno priorità sul
realismo di due pagine simultanee.

Un compromesso successivo, da validare in P1, può essere un
**libro apparentemente aperto ma con una pagina fisica di gioco
molto ampia e una pagina informativa richiamabile**. Non diventerà
un terzo sistema di gioco e non ridimensionerà i dadi fisici.

## Contratto geometrico e interattivo

I due candidati condividono:

- header compatto con commissione, obiettivo, assicurati, rischio, turni;
- sei D6 **completamente tridimensionali** e tray senza pulsanti
  sovrapposti, separato dalla mensola di dadi accantonati;
- due sole zone di azione primaria, fuori dal tray; i comandi veri
  rimangono quelli del controller Farkle corrente;
- stato breve sopra alle azioni;
- regione folio reale e una regione secondaria di consultazione;
- riserva per accessibilità, non dipendenze da FPS Lab 5;
- coordinate virtuali comuni `1920×1080`: la trasformazione al mouse
  e al viewport fisico resta quella di `resolution_manager.lua`.

Matrice di azioni prevista *senza nuove azioni*:

| Stato | Azione primaria | Altra azione disponibile |
|---|---|---|
| `fresh` | Lancia | Nessuna |
| `held` | Messaggio contestuale presa / Esc annulla | Non bancare mentre il dado è afferrato |
| `rolling` | Nessuna (feedback) | Nessuna |
| `ready` senza selezione | Rilancia se permesso | Incassa se permesso |
| `ready` con combinazione valida | Accantona | Incassa se permesso |
| `ready` con selezione non valida | Accantona disabilitato | Incassa disabilitato |
| `hot` | Rilancia tutti | Incassa se permesso |
| `rescue` | Medaglia Correttore | Accetta Farkle |
| `physics_error` | Riprova tiro **tecnico** | Nessuna |
| `ended` / `advance` | Prossimo turno / commissione | Nessuna |
| `upgrade` / `medal` | Dialog ricompensa, non HUD inferiore | Nessuna |
| `won` / `lost` | Stato terminale | Nessun riavvio automatico inventato |

I pulsanti `help`, `runmenu`, `folio`, `choices` e
`medaluse` continuano come interazioni secondarie senza rubare
spazio ai dadi. Per le regole reali consultare
[UI_V2_INTERACTION_MATRIX.md](UI_V2_INTERACTION_MATRIX.md).

## Come vedere le due proposte sopra la vera scena LÖVE

Da PowerShell nella radice di Manuscript:

```powershell
python scripts/run_ui_v2_layout_study.py
```

- **F6** alterna `single_folio` e `open_codex`;
- **F7** acquisisce PNG tramite LÖVE nella propria cartella salvataggi
  (percorso stampato nella console);
- **Esc** chiude il test.

Questa è una **sovrapposizione wireframe** su gioco reale, non un HUD
attivo: i rettangoli mostrano spazi e collisioni potenziali, non il
render della pagina definitiva. Il sistema non cambia né proiezione
del tray, né picking, né dimensioni fisiche dei dadi. La prossima
fase P2 potrà applicare la geometria scelta soltanto dopo la QA.

## Verifiche

```bash
lua5.4 tests/ui_v2_layout_candidates_test.lua
luajit tests/ui_v2_layout_candidates_test.lua
```

Il test verifica entrambe le proposte a
`1920×1080`, `1280×720`, `2560×1080`, `3440×1440`
e `1024×768`, compresi offset/letterboxing e click virtuali,
senza sovrapposizioni fra folio, azioni e piano di gioco. Valida
la dimensione minima dei dadi e quantifica la riduzione dell'area.
**Non** misura leggibilità effettiva delle texture, FPS o contrasto.

## Decisione sospesa fino alla P0 Windows

1. Acquisire baseline legacy con
   `python scripts/capture_ui_v2_baseline.py`.
2. Provare con F6 entrambe le alternative a 1280×720 e 1920×1080;
   salvare screenshot via F7.
3. Osservare i dadi 3D non coperti, i numeri leggibili, la progressione
   visibile, il punto di presa e l'accessibilità.
4. Annotare una scelta, oppure correggere geometrie e ripetere.
5. Solo allora marcare P1 come progettazione approvata e iniziare P2.

**La P0 resta IN CORSO; nessuna valutazione è spacciata per
test grafico superato.**
