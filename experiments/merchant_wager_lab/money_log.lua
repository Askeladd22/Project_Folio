-- Versioned V4 CSVs, deliberately separate from V2/V3/Corrector and runs.csv.
local M={}
M.MATCHES='merchant_v4_matches.csv'
M.HANDS='merchant_v4_hands.csv'
M.LEDGER='merchant_v4_transactions.csv'
M.POLICY='merchant_v4_policy.csv'
local match_keys={'id','seed','raises_enabled','winner','reason','hands',
 'artist_hands','merchant_hands','artist_denari','merchant_denari','pot_denari','raises','folds'}
local hand_keys={'id','seed','hand','winner','reason','award_denari','raised',
 'artist_balance_denari','merchant_balance_denari','initial_offer','final_offer',
 'artist_result','artist_farkle','artist_rerolls'}
local ledger_keys={'match','seed','step','hand','actor','action','amount',
 'balance_before','balance_after','pot_before','pot_after','reason'}
local policy_keys={'id','seed','step','hand','actor','action','offer','chance',
 'artist_wins','merchant_wins','artist_balance','merchant_balance','reason'}
local function safe(v)
 v=tostring(v==nil and '' or v)
 if v:find('[,"\r\n]') then return '"'..v:gsub('"','""')..'"' end
 return v
end
local function row(keys,data)
 local fields={}
 for i,key in ipairs(keys) do fields[i]=safe(data[key]) end
 return table.concat(fields,',')..'\n'
end
local function header(keys) return table.concat(keys,',')..'\n' end
local function append(fs,file,keys,content)
 if not fs.getInfo(file) then assert(fs.write(file,header(keys)),'cannot initialize '..file) end
 assert(fs.append(file,content),'cannot append '..file)
end
local function rows(keys,items,map)
 local out={}
 for _,item in ipairs(items) do out[#out+1]=row(keys,map and map(item) or item) end
 return table.concat(out)
end
function M.next_id(fs)
 if not fs.getInfo(M.MATCHES) then return 1 end
 local content=fs.read(M.MATCHES) or ''
 local lines=0
 for _ in content:gmatch('\n') do lines=lines+1 end
 return math.max(lines,1)
end
function M.save(fs,m)
 assert(m.phase=='over' and not m.saved,'save once after finished match')
 local outcome=require('experiments.merchant_wager_lab.money_duel').record(m)
 local hand_rows=rows(hand_keys,m.wager.hands,function(h)
  local base_hand=m.base.completed_hands[h.hand] or {}
  return {id=m.id,seed=m.seed,hand=h.hand,winner=h.winner,reason=h.reason,
   award_denari=h.award,raised=h.raised and 'yes' or 'no',
   artist_balance_denari=h.balances.artist,
   merchant_balance_denari=h.balances.merchant,
   initial_offer=base_hand.initial_offer,final_offer=base_hand.offer,
   artist_result=base_hand.player_result,
   artist_farkle=base_hand.player_farkle and 'yes' or 'no',
   artist_rerolls=base_hand.player_rerolls}
 end)
 -- Transaction and decision ledgers are written before the match marker,
 -- so a partial save does not falsely mark a match as fully saved.
 append(fs,M.HANDS,hand_keys,hand_rows)
 append(fs,M.LEDGER,ledger_keys,rows(ledger_keys,m.wager.ledger))
 append(fs,M.POLICY,policy_keys,rows(policy_keys,m.policy_log,function(p)
  local x={}
  for k,v in pairs(p) do x[k]=v end
  x.id=m.id;x.seed=m.seed
  return x
 end))
 append(fs,M.MATCHES,match_keys,row(match_keys,outcome))
 m.saved=true
 return true
end
return M
