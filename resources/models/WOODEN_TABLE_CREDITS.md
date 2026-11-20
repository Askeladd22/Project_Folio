# Wooden Table (game ready asset) — attribuzione

**Autore originale:** Pixel Life  
**Titolo originale:** *Wooden Table (game ready asset)*  
**Fonte:** https://sketchfab.com/3d-models/wooden-table-game-ready-asset-7283ac1841504452b53005b8103bb064  
**Licenza dichiarata nei metadati GLB allegati dall'utente:** [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)

## Modifiche di Project Folio

- Il modello utente `wooden_table_game_ready_asset.glb` (~12 MB, originale completo) è stato analizzato; **non è incluso integralmente nella PR**.
- `resources/models/wooden_table_mesh.lua` conserva una silhouette geometrica **derivata** dall'originale attraverso clustering dei vertici e quantizzazione. La variante tracciata è circa 243 vertici geometrici, 497 triangoli prima di scartare eventuali triangoli degeneri; la texture originale NON è riprodotta.
- Finitura di gioco: texture `resources/textures/wood.png` già presente nel progetto, con colore e illuminazione del renderer g3d. Il materiale finale può quindi differire dal render Sketchfab.
- Su una copia locale dotata del GLB completo nel percorso `resources/models/wooden_table_game_ready_asset.glb`, il renderer può usare l'asset originale attraverso il caricatore glTF esistente. Il fallback tracciato evita di dipendere da quella copia.
- Le due varianti sono esclusivamente decorative. Piano di contatto, muro fisico, caratteristiche e risultati dei D6 rimangono governati dalla scena fisica di Folio.

**Identificazione del file originale analizzato:** SHA-256 `939270f79a7b821657b141d2305e13057effdb6f3a746e327afc5e31d1af2369`.

Questa attribuzione va mantenuta nei crediti del gioco e nelle eventuali distribuzioni del modello derivato. Verificare sul sito originale la disponibilità e gli obblighi della licenza prima di pubblicare commercialmente. Non attribuire a Pixel Life il nuovo shader, la geometria fisica o altre modifiche di Project Folio.
