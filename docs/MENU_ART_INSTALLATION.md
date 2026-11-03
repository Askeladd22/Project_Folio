# Project Folio — installazione e revisione dei fondali

## Fondale incluso: bottega alla Manuzio (dalla v0.1.9)

La scena **tipografica veneziana 1920×1080** è ora inclusa
direttamente nel repository nel percorso
`resources/ui/menu_manuzio.png`. Un precedente caricamento GitHub
aveva conservato l'immagine con un nome non riconosciuto dal loader.
La 0.1.9 ha corretto il percorso usando gli stessi byte originali.

```powershell
git pull --ff-only
python scripts/install_menu_art.py --verify-installed --manuzio
.\Avvia.cmd
```

**Non occorre più scaricare il pacchetto ZIP.** L'installatore
`--manuzio` resta disponibile solo per future versioni artistiche
o per installare manualmente un file alternativo.
`resources/ui/menu.png` resta il fallback incluso.
`menu_illustrated.png` è stato rimosso dal repository dopo
l'abbandono della scena monastica, ma resta supportato
opzionalmente per installazioni locali già esistenti.

**SHA-256 del nuovo PNG:**
`65e6748253a54dc58486b73cd3cea1a772e8a033509baaf1243240bcaa858d15`.

Ordine di caricamento del codice: **Manuzio → illustrazione precedente, se presente localmente → vecchio sfondo**. I controlli e i pulsanti restano disegnati in Lua.
I controlli visivi reali su Windows sono ancora da completare.

[Specifiche artistiche della bottega](MANUZIO_PRINTSHOP_ART_DIRECTION.md).

---

## Archivio: primo fondale illustrato (0.1.6–0.1.7)

> **Documento storico.** L'immagine monastica non fa più parte del
> repository corrente. I comandi qui sotto servivano per l'asset
> precedente, non per la bottega rinascimentale ora distribuita
> direttamente via Git.

**Versione minima del gioco:** `0.1.7` · **Asset opzionale:** `resources/ui/menu_illustrated.png`

La nuova immagine della bottega è **un fondale di 1920×1080**, senza
pulsanti, titoli o altri elementi interattivi incorporati. È stata
preparata separatamente nella conversazione come
`ProjectFolio_Illustrated_Menu_Asset.zip`. Il repository GitHub
**non contiene ancora il file binario**: il codice usa `menu.png`
finché non viene installato il PNG. Non sostituire l'asset legacy.

## Installazione Windows verificata

Nella cartella del repository, dopo avere scaricato il pacchetto ZIP:

```powershell
git pull --ff-only
python scripts/install_menu_art.py "$env:USERPROFILE\Downloads\ProjectFolio_Illustrated_Menu_Asset.zip"
python scripts/install_menu_art.py --verify-installed
.\Avvia.cmd
```

L'installatore controlla: path esatto nell'archivio, dimensioni native
**1920×1080**, struttura e CRC dei chunk PNG, SHA-256 dichiarato nel
README dello ZIP, dimensione massima 16 MiB e duplicati. Copia
`resources/ui/menu_illustrated.png` in modo atomico; non tocca
`resources/ui/menu.png`. Se esiste un altro file illustrato, lo
conserva e segnala come usare `--force` per una sostituzione
deliberata. È possibile installare anche un PNG diretto, con le
stesse verifiche del formato.

SHA-256 della prima illustrazione distribuita nella conversazione:
`6d4561fdb193065dbd0094aa92fda0cdb8f7d5e436a46abbec62f53bbf73d219`.
È un identificatore del **file distribuito**, non un valore fissato
nel gioco: eventuali revisioni originali possono avere altri hash.

## Composizione del nuovo sfondo

- **Area riservata alla UI:** primo 32,5% della composizione. Il
  pannello principale si restringe quando l'illustrazione è
  realmente caricata, non quando si usa il fallback fotografico.
- **16:9:** visualizzazione *cover* senza ritagli; controllare
  1280×720, 1920×1080 e 2560×1440.
- **4:3 / 5:4:** il crop orizzontale è **ancorato a sinistra**
  per non perdere lo spazio riservato al pannello.
- **Ultrawide:** *cover* con eventuale taglio verticale;
  verificare che il soggetto e gli strumenti rimangano leggibili.
- **Colori:** la nuova immagine conserva i pigmenti originari.
  Il vecchio `menu.png` mantiene la correzione cromatica
  applicata nelle versioni precedenti.
- **Accessibilità:** high contrast mantiene la sua oscuratura
  originale; big text richiede una verifica di overflow su Windows.

## Checklist di accettazione visiva (da compilare su LÖVE Windows)

- [ ] Menu e tooltip leggibili a **1280×720** e **1920×1080**.
- [ ] Titolo, sei azioni e pulsante mute dentro il pannello.
- [ ] Il pannello non copre il correttore, il compositore o
      lo stampatore al torchio; i protagonisti rimangono leggibili.
- [ ] 4:3 e ultrawide non tagliano la zona di navigazione.
- [ ] **New Game**, **Sfida il Monaco**, **Settings**, **Wishlist**
      e **Quit** reagiscono correttamente; Continue resta disabilitato.
- [ ] **Settings** e scelta delle commissioni conservano
      il fondale e non perdono pulsanti o hitbox.
- [ ] Contrasto elevato, font ingrandito e riduzione animazioni
      non causano clipping.
- [ ] Audio, Farkle, dadi 3D e gameplay rimangono invariati.

La CI prova installazione, geometria e invarianti senza GPU;
**non certifica la resa visiva reale né la qualità illustrativa**.
La vecchia checklist completa rimane in
[WINDOWS_TECHNICAL_QA.md](WINDOWS_TECHNICAL_QA.md).

## Limiti di distribuzione

Lo ZIP fornito nella conversazione deve essere estratto/installato
localmente; non può essere scaricato con `git pull` finché il PNG
non viene aggiunto a GitHub. Un clone senza immagine opzionale
continua a visualizzare il fondale precedente, senza errori.
