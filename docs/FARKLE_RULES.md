# Regolamento ufficiale Farkle di Manuscript

Versione 0.4, 15 ottobre 2026; **nota di contesto aggiornata al 30 ottobre 2026**. Questo documento consolida la consegna «Nuovo regolamento Farkle». Le regole implementate sono approvate; la taratura delle commissioni è provvisoria. La direzione futura degli incontri con miniature, descritta in [INCONTRI_E_SEGNI.md](INCONTRI_E_SEGNI.md), **non modifica questa tabella né costituisce implementazione di un nuovo sistema di combattimento**.

## Punteggio nello stesso lancio

Sei D6. Un singolo 1 vale **10**, un singolo 5 **5**; 2, 3, 4 e 6 non valgono singolarmente.

| Valore | Tris | Poker | Cinquina | Sestina |
|---|---:|---:|---:|---:|
| 1 | 75 | 110 | 320 | 625 |
| 2 | 20 | 120 | 340 | 650 |
| 3 | 30 | 130 | 360 | 675 |
| 4 | 40 | 140 | 380 | 700 |
| 5 | 50 | 150 | 400 | 725 |
| 6 | 60 | 160 | 420 | 750 |

| Altra combinazione | Punti |
|---|---:|
| Piccola scala 1–2–3–4–5 oppure 2–3–4–5–6 | 100 |
| Grande scala 1–2–3–4–5–6 | 200 |
| Tre coppie di valori distinti | 150 |
| Full house: quattro uguali e una coppia di altro valore | 200 |
| Due tris di valori distinti | 250 |

**Convenzione dichiarata:** poker, cinquina e sestina seguono la progressione provvisoria indicata dall'utente. I valori intermedi non sono una trascrizione completa di una fonte esterna. La tabella modificabile è `points` in [scoring.lua](../src/gameplay/farkle/scoring.lua); riavviare il gioco dopo una modifica, poiché il valutatore conserva risultati in cache.

## Selezione, accantonamento e alternative

Ogni dado mantiene il proprio ID fisico 1–6. Una selezione è valida soltanto se **tutti** i suoi dadi appartengono a gruppi validi e disgiunti: nessun dado può contare due volte. Non si usano dadi accantonati precedentemente per formare altre combinazioni, neppure aggiungendo successivamente altri dadi dello stesso tiro.

Si possono selezionare solo alcuni dadi utili e rilanciare gli altri, rinunciando anche a una combinazione già presente. Il pulsante **Scelte** elenca tutti i sottoinsiemi validi per ID, con gruppi, punti e dadi residui; non seleziona automaticamente nulla. Clic sui dadi e tasti 1–6 restano disponibili. Il limite naturale è 63 sottoinsiemi non vuoti; la finestra li suddivide in pagine.

**Convenzione di deduplicazione:** per lo stesso identico insieme di ID si mostra una sola partizione, quella di maggior valore; a parità di punti si preferisce la partizione che soddisfa il requisito di gruppo. Non si elimina alcun sottoinsieme fisicamente diverso. Il massimo riguarda la valutazione dei dadi scelti, non una scelta automatica dell'intero lancio.

Esempio `#1=1, #2=3, #3=3, #4=3, #5=4, #6=6`:

| Scelta | Dadi accantonati | Punti | Dadi rilanciabili |
|---|---|---:|---:|
| A | #1 | 10 | 5 |
| B | #2, #3, #4 | 30 | 3 |
| C | #1, #2, #3, #4 | 40 | 2 |

Tutte e tre sono eseguibili. Se si prende prima A e poi B nello stesso lancio, il totale è 40. Se si prendono tre 1 separatamente come singoli, valgono 30; presi insieme valgono 75. Un 1 accantonato e due 1 usciti nel tiro successivo valgono 30 complessivi, **non** un tris. Una sestina non somma anche poker e tris ricavati dagli stessi dadi. Con `1,2,3,4,5,5` si può scegliere piccola scala + singolo 5 = 105, oppure altri sottoinsiemi validi.

## Turno, ingresso e incasso

Prima di rilanciare o incassare dopo ogni tiro valido bisogna accantonare almeno una selezione valida **di quel tiro**. Il pulsante Incassa può accantonare la selezione corrente e concludere il turno in un'unica azione. Dopo un nuovo tiro non si può ignorarne tutti i dadi per incassare soltanto il provvisorio precedente.

Ogni commissione configura due soglie distinte in [rules.lua](../src/gameplay/farkle/rules.lua):

- `entry_min`: minimo del primo incasso della commissione, raggiunto interamente nello stesso turno.
- `bank_min`: minimo di ogni incasso successivo, dopo l'ingresso.

Il primo incasso riuscito registra l'ingresso. Un Farkle o un incasso rifiutato non lo registrano. L'ingresso resta tra turni della stessa commissione e si azzera passando alla successiva. Una soglia zero elimina solo il vincolo numerico: non permette incassi vuoti o di selezioni illegali. Sotto soglia si può accantonare, ma non incassare; occorre continuare. Un tentativo di incasso non valido non modifica selezione, dadi usati o punti.

**Farkle:** nessun sottoinsieme del tiro produce punti. Si perdono soltanto i provvisori del turno, insieme ai requisiti speciali ancora provvisori; gli incassi precedenti restano. La medaglia conserva l'eccezione descritta sotto.

**Hot dice:** quando tutti i sei dadi sono stati accantonati, anche attraverso più tiri, si possono rilanciare tutti e sei senza perdere il provvisorio. In alternativa si può incassare se consentito. Ottenere hot dice e incassarlo sono eventi distinti; un successivo Farkle può perdere il requisito provvisorio.

## Commissioni e progressione solitaria

**Stato implementato (baseline corrente):** nessun avversario artificiale; la sfida deriva da commissioni e turni limitati. La nuova direzione con figure animate è progettuale e va confrontata con questa baseline, non confusa con il regolamento già operativo.

| Commissione | Obiettivo assicurato | Turni | Ingresso | Incassi successivi | Condizione da incassare |
|---|---:|---:|---:|---:|---|
| Salterio per la parrocchia | 100 | 4 | 0 | 0 | Nessuna |
| Libro di ore del mercante | 150 | 5 | 40 | 20 | Un gruppo di almeno tre uguali |
| Codice di rappresentanza | 200 | 5 | 50 | 25 | Un ciclo di hot dice |

**Tutti questi numeri sono parametri di test, non valori bilanciati.** Gli obiettivi iniziali derivano dalla vecchia scala divisa per dieci; le nuove combinazioni impediscono di considerarla una conversione equivalente. I turni sono conservati. L'HUD segnala «parametri test».

Punti e requisito possono essere incassati in turni differenti. Tris, poker, cinquina, sestina, full 4+2 e due tris soddisfano il requisito di gruppo; scale e tre coppie no. Il Codice richiede l'ottenimento e l'incasso degli hot dice, non un rilancio supplementare obbligatorio. Incasso e Farkle consumano un turno; se i requisiti mancano alla scadenza la run termina. Punti, ingresso e requisiti si azzerano per la commissione seguente; la build rimane.

Dopo il Salterio si sceglie la modifica del dado 1; dopo il Libro di ore il Correttore oppure nessuna medaglia. In «Senza mod» si prosegue senza queste ricompense.

## Integrazione futura con gli incontri — nessuna modifica alle regole presenti

**Direzione approvata:** le figure di un libro potranno diventare avversari che utilizzano intenzioni e Segni, mentre il giocatore manterrà il Farkle con i suoi dadi e l'incasso. Le regole di punteggio, la disgiunzione delle combinazioni, il significato del Farkle, gli hot dice, le mappe fisiche delle facce e i modificatori esistenti **restano la fonte canonica**. Nessuna conversione punti→danno, costo di sigillatura/rasura, salute, limitazione di rilanci o condizione speciale di vittoria è approvata da questo documento.

Le attuali commissioni (Salterio/Libro di ore/Codice) con target, limiti e soglie rappresentano lo **stato del software**, non la forma finale del libro popolato da miniature. Non trasferire automaticamente i 4/5 turni a ciascun nuovo incontro. Se una futura regola di nemico cambia la convenienza di incassare, deve essere descritta e testata separatamente, evitando premi che annullino il rischio del Farkle o un obbligo universale di rilanciare. Vedere [Incontri e Segni](INCONTRI_E_SEGNI.md).

## Dadi e medaglia esistenti

- **Inciso:** sul dado 1 la faccia 2 diventa 1; mappa individuale letta sia dal renderer sia dal punteggio. Con orientamenti uniformi P(1)=2/6, P(2)=0; nessuna geometria modificata.
- **Pesato:** filtro esistente di accettazione delle proposte fisiche: 1 sempre accettato, altri valori con probabilità 1/2; un rifiuto provoca un rilancio fisico visibile del solo dado interessato. Con proposte IID uniformi i pesi ideali sono 2:1:1:1:1:1, non una misura della simulazione né una massa eccentrica. Con proposte stazionarie q, la distribuzione accettata è proporzionale a qᵢaᵢ. Attesa potenzialmente lunga, senza alterazione invisibile della faccia.
- **Correttore:** una volta per commissione, dopo Farkle, rilancia gli stessi dadi liberi conservando provvisori e requisiti in attesa. Un ulteriore Farkle li perde; si può rinunciare e conservare la medaglia per un altro turno. Non cambia facce o probabilità.

Il recupero tecnico A/B non è una medaglia e non assegna risultati numerici: vedere [contratti tecnici](TECHNICAL.md).

## Verifica quantitativa preliminare

Enumerazione esatta, modello IID uniforme (non frequenze fisiche osservate):

| Dadi liberi | Esiti Farkle / totale | Rischio |
|---:|---:|---:|
| 1 | 4/6 | 66,667% |
| 2 | 16/36 | 44,444% |
| 3 | 60/216 | 27,778% |
| 4 | 204/1296 | 15,741% |
| 5 | 600/7776 | 7,716% |
| 6 | 1080/46656 | 2,315% |

Con sei dadi e il dado 1 modificato presente: inciso 1,736%, pesato 1,984% nel rispettivo modello ideale. Se è già accantonato si usa il modello normale. L'HUD etichetta il valore teorico e non include la medaglia.

Sul tiro iniziale uniforme la media del massimo accantonabile passa da 399,113 vecchi punti a **51,423** nuovi punti; non è una semplice divisione per dieci. Il massimo resta sotto 40 nel **56,842%** degli esiti e sotto 50 nel **61,986%**, Farkle inclusi. Questi dati descrivono il tiro, non l'incasso finale né una strategia ottima. Con tre dadi, guadagno massimo medio 1850/216=8,565: la soglia locale di indifferenza di un solo rilancio con successivo incasso libero è 30,833 punti. Soglie, condizione mancante e turni residui possono rendere inapplicabile questo confronto.

Sono state eseguite 4.800 mini-run numeriche isolate: 400 per combinazione di 2 profili di soglia, 3 build e 2 politiche. Politica «valore»: massimo del tiro; «riserva»: massimo di punti + 12×dadi residui. Entrambe incassano se consentito a 40 provvisori o quando possono consegnare; usano sempre il Correttore disponibile. Sono euristiche, non strategie ottime.

| Soglie provvisorie | Vittorie politica valore, IC Wilson 95% | Vittorie politica riserva, IC Wilson 95% |
|---|---:|---:|
| Normale senza medaglia | 162/400; 35,8–45,4% | 144/400; 31,4–40,8% |
| Inciso + Correttore dalla terza commissione | 200/400; 45,1–54,9% | 153/400; 33,6–43,1% |
| Pesato + Correttore dalla terza commissione | 193/400; 43,4–53,1% | 162/400; 35,8–45,4% |

Con soglie azzerate, politica valore: 167/400, 203/400, 202/400 rispettivamente. Campioni distinti e intervalli sovrapposti: non dimostrano un miglioramento causato dalle soglie. Il confronto build è confuso anche dalla medaglia assente nel controllo. Dati, seed e metodo sono conservati in [exact.csv](../audits/farkle-official/exact.csv), [simulation.csv](../audits/farkle-official/simulation.csv) e nello script storico di analisi dello stesso audit.

**Proposta da playtestare, non ulteriore modifica:** confrontare la tabella corrente con obiettivi e turni identici ma ingresso/incasso 0/0. Solo dopo valutare l'eventuale aumento degli obiettivi, separato dall'aumento delle soglie. Non cercare una percentuale arbitraria di vittorie. La riserva di dadi è una scelta reale ma la specifica euristica «riserva» testata non risulta superiore.

## Test, limiti e decisioni aperte

La suite copre tutte le combinazioni, ID disgiunti, selezione parziale, tiri separati, soglie e ingresso, hot ottenuti/incassati, Farkle, commissioni, medaglia e mapping. Smoke reali coprono avvio, selezione e rilancio fisico, inciso/pesato, A/B e HUD 1280×720/1920×1080; gli stati rari dell'HUD usano anche fixture numeriche, le cui pose 3D possono provenire dal tiro precedente. Non sono prove di uniformità fisica. Comandi riproducibili nel [README](../README.md).

Restano da valutare con giocatori: taratura degli incarichi, utilità di mostrare fino a 63 selezioni, influenza delle soglie sulle scelte forzate, convenienza relativa delle build. Incassare quando la consegna è soddisfatta domina il rischio senza premio aggiuntivo; equipaggiare gratuitamente una medaglia opzionale amplia le possibilità senza costo. Con sei dadi normali e Correttore disponibile, due Farkle IID consecutivi hanno probabilità circa 0,0536%: quel singolo tentativo può essere quasi privo di rischio, ma consuma il salvataggio. Non si certificano divertimento, equilibrio o assenza di strategie dominanti.

### Note architetturali (ottobre 2026)

La progressione delle tre commissioni è isolata in `src/gameplay/farkle/commission_progress.lua`. Il codice pubblico continua a esporre `R.contracts`, e l'estrazione **non cambia** obiettivi, limiti di turni, combinazioni, medaglie o ricompense. Soltanto i risultati fisici **accettati** dal controller vengono pubblicati come `dice.roll_accepted`: i ritentativi tecnici non sono tiri di Farkle aggiuntivi.

