# RQ-001 — Primo mandato Deep research

**Stato:** prompt pronto, **ricerca non ancora avviata**. Avvio: in ChatGPT scegliere **Deep research** dal menu strumenti (+) oppure digitare /Deepresearch e incollare il brief. Rivedere il piano proposto e specificare fonti.

## Prompt da utilizzare

Sei un ricercatore in game studies e game design, con competenze su giochi di dadi, probabilità, teoria delle decisioni, storia del gioco e prototipazione. Devi svolgere una ricerca documentata per **Project Folio**, roguelite 2.5D LÖVE ambientato nella Venezia aldina tra la fine del XV e l'inizio del XVI secolo.

**Contesto vincolante:** protagonista incisore muto che usa dadi fisici; rivali onirici nati dalle xilografie; niente combattimento in HP come loop canonico; niente mazzo di carte richiesto al giocatore; tre pilastri Simplicity, World Structure, Swelling Power; vincolo mastery, not accommodation. Il gioco attuale usa Farkle con sei D6. Esistono prototipi Merchant Wager V4 (cassa token + poste), Encounter A (offerte) ed Encounter C (prove contese), P4ND0RA asimmetrico. **Non equiparare un esperimento alla build canonica**.

**Domanda:** quali strutture ludiche possono trasformare il Farkle o una diversa meccanica di dadi in un vero duello rivale, migliorando agency, chiarezza dell'avversario, rischio/ricompensa e sviluppo di skill? La ricerca deve ammettere esplicitamente la conclusione che conservare Farkle sia preferibile.

**Attività obbligatorie:**
1. Reperisci regolamenti originali e analisi affidabili su almeno **10** sistemi pertinenti: giochi storici (zara/azar, hazard, giochi a coppie di dadi quando documentabili), famiglie tradizionali push-your-luck e board game moderni con scelte, scommesse, drafting, maggioranze o avversari asimmetrici. Non forzare parallelismi deboli.
2. Distingui **fonti primarie storiche, regolamenti commerciali, studi accademici e testimonianze della community**. Per ogni regola storica chiarisci epoca, luogo, attestazione e incertezze. Non attribuire alla Venezia del 1500 un regolamento non documentato.
3. Costruisci una matrice comparativa: oggetto della decisione, informazione disponibile, rischio, interazione, possibilità di strategy mastery, carico cognitivo, connessione alla posta e integrazione in Folio. Indica limiti di comparabilità.
4. Seleziona 3–5 direzioni **strutturalmente diverse** (almeno una che mantenga Farkle, almeno una che cambi il gioco di dadi), con pro e contro reali e possibili exploit.
5. Interroga il design: come può vincere il Mercante, che cosa vince, come il giocatore comprende la sua risposta, perché una decisione coraggiosa/prudente cambia davvero l'esito?
6. Proponi fino a 3 esperimenti isolati e falsificabili, specificando seed, strategie di controllo, risultati osservabili e test umani. Nessuna progettazione di asset/UI prima di chiarire la meccanica.
7. Raccomanda un ordine di test con criteri di arresto ed esplicite incertezze. Evidenzia risultati che contraddicono le ipotesi iniziali.

**Deliverable:** sintesi esecutiva; protocollo delle fonti con link verificabili; schede dei 10+ giochi; matrice; analisi critica; 3–5 direzioni; piano di esperimenti con metriche; raccomandazione provvisoria; bibliografia. Segnala testi non accessibili e fatti non verificati. Evita argomenti basati soltanto su popolarità o impressioni.

**Fonti di contesto interne (se disponibili):** README, docs/project_vision.md, docs/farkle_rules.md, research/BASELINE.md e README dei tre laboratori nel repository Askeladd22/Project_Folio. Se GitHub non è disponibile come sorgente Deep research, chiedi i file o usa i link pubblici; non dichiarare di averli letti senza accesso. Non aprire PR o alterare codice.

## Dopo la consegna

Il report è un input alla review critica, non un mandato automatico per implementare. Archiviare con data e link, compilare schede fonti, poi applicare [PROTOCOL.md](PROTOCOL.md).
