# Project Folio — direzione artistica corrente

**Stato:** guida di produzione. La scena illustrata resta distinta dai
risultati fisici e dalle regole Farkle; il 2.5D è una proposta, non un
nuovo renderer approvato.

## Identità

Una **bottega tipografica veneziana tra fine XV e inizio XVI secolo**,
nell'ambiente di Aldo Manuzio: fogli, matrici xilografiche, torchio,
correttori, caratteri mobili, legno, pigmenti e inchiostro.
**Non** uno scriptorium monastico o un fantasy medievale generico.

Il protagonista è un **artista originale ispirato al profilo di
Albrecht Dürer** — disegnatore e incisore, curioso e colto — non Dürer
stesso e non un ritratto della sua biografia. È muto e non gli si
impongono dialoghi. Il legame con la bottega aldina è narrativa di
finzione, non attribuzione di un episodio storico documentato.

Il sogno trae forza da poche anomalie legate a carta, xilografie,
inchiostro e tavolo. La tensione deve essere quella dell'azzardo:
**incasso o rilancio?** Non horror, maledizioni, effetti neon o
ornamenti decorativi ripetuti senza funzione.

## Tavolo e livelli della scena

Il **Tavolo del Mercante** è la composizione attualmente giocabile:
sei D6 tridimensionali in osso, tavolo g3d, avversario illustrato
oltre il piano e UI su livelli 2D separati. Evitare di sacrificare
leggibilità e picking dei dadi a favore dell'ornamento.

- Fondale senza personaggi: `resources/scenes/printshop-room.png`.
- Ritratto intercambiabile: `resources/opponents/<id>.png`.
- Menu: `resources/ui/menu_manuzio.png`.
- Dadi: materiale g3d color osso, patina sobria, punti incisi,
  contatto e ombra leggibili; identità/valori derivano dalla fisica.
- Font: **Aldine Aetna** con fallback **Cardo** (vedi
  [Tipografia](TYPOGRAPHY.md)).

Il possibile **2.5D** applica profondità, piani e composizione
illustrata ai fondali e ai personaggi. Non sostituisce g3d o il
solver dei dadi e non è un sistema già implementato.

Il **Folio** non è più una sidebar permanente della partita. Resta
consultabile con **F** e rimane il perno narrativo della futura
ricomposizione delle xilografie, **non** una barra da colorare per
raggiungere una soglia di punti. Il sistema competitivo finale
degli incontri non è ancora definito.

## Palette canonica

Il file autoritativo è `src/data/art_palette.lua`.
Toni opachi, contrasti funzionali, superfici artigianali:

| Ruolo | HEX |
|---|---|
| Pergamena | `#E7DCC8` |
| Inchiostro | `#352A23` |
| Legno | `#856448` |
| Salvia | `#8E957B` |
| Rosso cinabro | `#8D4B43` |
| Blu ardesia | `#6F8087` |
| Ocra | `#BE9A4F` |

I colori delle facce dei dadi, dello stato di selezione e dei
pulsanti devono restare leggibili in alto contrasto. Nessun
filtro fotografico indiscriminato per fingere materiali storici.

## Riferimenti e accuratezza

L'*Hypnerotomachia Poliphili* (1499) è un riferimento per
sogno e xilografie, non una storia da riprodurre. Le immagini
storiche della tipografia guidano gesti, utensili e luce
veneziana, ma **non** provano che l'ambiente raffigurato sia la
bottega reale di Manuzio. Non copiare composizioni o asset
protetti di artisti esterni.

Gli studi precedenti su menu, Flameng, prospettive folio e
ornamenti sono conservati nei
[commit Git storici](https://github.com/Askeladd22/Project_Folio/tree/0fc25e369bc2655aa42489ae9078b04b9cef1650/docs),
non costituiscono specifiche di produzione concorrenti.

## Verifiche necessarie

Controllare Windows LÖVE a 1280×720, 1920×1080, 1440p e ultrawide:
facce dei dadi e picking, materiali, ritratto, leggibilità dei
font, tavolo durante presa/lancio multiplo, contrasto, testo grande
e animazioni ridotte. La CI non sostituisce il collaudo visivo.
