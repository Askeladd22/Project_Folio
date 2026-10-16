"""Reproduce compact measured tables from the Lua run; standard library only."""
import csv
from pathlib import Path
from math import sqrt

folder = Path(__file__).resolve().parent
rows = list(csv.DictReader((folder / 'results.csv').open()))
def interval(w, n):
    p=w/n; z=1.96; den=1+z*z/n
    center=(p+z*z/(2*n))/den
    half=z*sqrt(p*(1-p)/n+z*z/(4*n*n))/den
    return f'{100*(center-half):.1f}–{100*(center+half):.1f}%'
with (folder / 'measured-tables.md').open('w', encoding='utf8') as f:
    f.write('# Risultati misurati\n\n54.000 partite: 2.000 per ciascuna delle 27 coppie variante/politica.\n\n')
    f.write('| Variante | Agente | Vittorie (IC Wilson 95%) | Media | P10 / mediana / P90 |\n|---|---|---|---|---|\n')
    for r in rows:
        w,n=int(r['wins']),int(r['n'])
        f.write(f"| {r['variant']} | {r['agent']} | {100*w/n:.2f}% ({interval(w,n)}) | {float(r['mean']):.2f} | {r['p10']} / {r['p50']} / {r['p90']} |\n")
    f.write('\n## Comportamento del pianificatore\n\n| Variante | Opere capolettera / fregio / miniatura | Cambi per partita | Tentazioni per partita | Rischi da opera completa |\n|---|---|---|---|---|\n')
    for r in rows:
        if r['agent']!='planner': continue
        counts=[int(r['projects'+str(i)]) for i in (1,2,3)]; total=sum(counts)
        shares=' / '.join(f'{100*x/total:.1f}%' for x in counts)
        f.write(f"| {r['variant']} | {shares} | {int(r['changes'])/2000:.3f} | {int(r['temptations'])/2000:.3f} | {r['risk_rolls']} |\n")
    f.write('\nGli intervalli descrivono il campionamento sotto ciascuna politica; non sono test di differenza appaiati.\n')
print((folder/'measured-tables.md').read_text(encoding='utf8'))
