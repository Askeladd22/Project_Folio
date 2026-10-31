-- Headless historical-record regression: all PR #1-#39, merged and indexed.
-- Does not freeze future versions: new PRs are recorded in versioned entries.
local function read(path)
 local f=assert(io.open(path,'rb'),'missing file '..path)
 local result=f:read('*a')
 f:close()
 return result
end
local changes=read('CHANGELOG.md')
local current=read('version.txt'):match('^%s*(.-)%s*$')
assert(changes:find('## ['..current..']',1,true),
 'canonical version must be in the changelog')
assert(changes:find('## [0.1.0-dev.1]',1,true),
 'first canonical baseline must be retained')
local start=assert(changes:find('## Indice integrale',1,true),
 'historical index was deleted')
local history=changes:sub(start)
local count=0
for id in history:gmatch('%[PR #(%d+)%]%(') do
 count=count+1
 assert(tonumber(id)==count,'historical PR index missing/out of order: '..id)
 assert(history:find('https://github.com/Askeladd22/Project_Folio/pull/'..id,1,true),
  'historical PR link missing: '..id)
end
assert(count==39,'expected all 39 verified, merged pre-version PRs')
assert(changes:find('6 marzo 2026',1,true),
 'initial March 2026 history must be preserved')
assert(changes:find('1–2 luglio 2026',1,true),
 'early Farkle experiments must be documented')
assert(changes:find('semplice IA sperimentale',1,true),
 'July Farkle AI history must be distinguished from October Monk')
assert(changes:find('PR #36',1,true),
 'October Monk duel history must remain documented')
assert(changes:find('non',1,true))
print('PASS Project Folio retrospective history: 39 merged PRs, first commits, Farkle prototype and canonical version')
