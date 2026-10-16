"""Paired-seed comparisons and Wilson intervals, standard library only."""
import csv, json, math
from pathlib import Path

root = Path(__file__).resolve().parent
rows = list(csv.DictReader((root / 'results.csv').open()))
games = {}
for r in csv.DictReader((root / 'games.csv').open()):
    games.setdefault((r['config'], r['agent']), {})[int(r['seed'])] = int(r['win'])
out = {'intervals': [], 'paired': []}
for r in rows:
    n, k = int(r['n']), int(r['wins'])
    p, z = k / n, 1.96
    center = (p + z*z/(2*n)) / (1+z*z/n)
    margin = z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))/(1+z*z/n)
    out['intervals'].append({'config': r['config'], 'agent': r['agent'],
                             'wilson95': [center-margin, center+margin]})
for config in sorted({r['config'] for r in rows}):
    for a, b in [('planner', 'greedy'), ('planner', 'planner_no_rerolls'),
                 ('planner','fixed_BCD'), ('planner','fixed_ACD'),
                 ('greedy','greedy_fixed_BCD'), ('greedy','greedy_fixed_ACD')]:
        ga, gb = games[config, a], games[config, b]
        assert ga.keys() == gb.keys() and len(ga) >= 2000
        ds = [ga[s]-gb[s] for s in ga]
        mean = sum(ds)/len(ds)
        se = math.sqrt(sum((d-mean)**2 for d in ds)/(len(ds)-1)/len(ds))
        out['paired'].append({'config': config, 'a': a, 'b': b,
            'delta_pp': mean*100, 'paired95_pp': [(mean-1.96*se)*100, (mean+1.96*se)*100]})
(root / 'statistics.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
for r in out['paired']:
    print(r)
