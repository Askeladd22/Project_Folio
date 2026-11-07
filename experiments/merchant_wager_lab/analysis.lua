-- Summarize the versioned match and subjective-feedback CSVs in the LÖVE save.
local Log=require('experiments.merchant_wager_lab.log')
local M={}
local variants={'A','B','C'}

local function parse(line)
 local fields={};local value={};local quoted=false;local i=1
 while i<=#line do
  local ch=line:sub(i,i)
  if quoted then
   if ch=='"' and line:sub(i+1,i+1)=='"' then value[#value+1]='"';i=i+1
   elseif ch=='"' then quoted=false
   else value[#value+1]=ch end
  elseif ch==',' then fields[#fields+1]=table.concat(value);value={}
  elseif ch=='"' and #value==0 then quoted=true
  else value[#value+1]=ch end
  i=i+1
 end
 fields[#fields+1]=table.concat(value)
 return fields
end

local function rows(fs,path)
 if not fs.getInfo(path) then return {} end
 local source=assert(fs.read(path),'cannot read '..path)
 local lines={};for line in source:gmatch('[^\r\n]+') do lines[#lines+1]=line end
 if #lines<2 then return {} end
 local header=parse(lines[1]);local indexes={}
 for i,k in ipairs(header) do indexes[k]=i end
 local result={}
 for i=2,#lines do
  local values=parse(lines[i]);local row={}
  for k,n in pairs(indexes) do row[k]=values[n] or '' end
  result[#result+1]=row
 end
 return result
end

local function number(row,key) return tonumber(row[key]) or 0 end
local function mean(total,count) return count>0 and total/count or 0 end

function M.summarize(match_rows,feedback_rows)
 local feedback={}
 for _,f in ipairs(feedback_rows) do feedback[f.id]=f end
 local out={}
 for _,variant in ipairs(variants) do
  local a={variant=variant,games=0,player_wins=0,player_losses=0,ties=0,player_win_pct=0,
   avg_player_score=0,avg_merchant_score=0,avg_player_rerolls=0,avg_player_farkles=0,
   avg_merchant_farkles=0,avg_raises=0,banking_yes_pct=0,pressure_none=0,
   pressure_moderate=0,pressure_strong=0,feedback_count=0,banking_responses=0}
  local ps,ms,rerolls,pf,mf,raises=0,0,0,0,0,0
  for _,r in ipairs(match_rows) do
   if r.variant==variant then
    a.games=a.games+1;ps=ps+number(r,'player_score');ms=ms+number(r,'merchant_score')
    rerolls=rerolls+number(r,'player_rerolls');pf=pf+number(r,'player_farkles')
    mf=mf+number(r,'merchant_farkles');raises=raises+number(r,'raises')
    if r.winner=='player' then a.player_wins=a.player_wins+1
    elseif r.winner=='merchant' then a.player_losses=a.player_losses+1
    else a.ties=a.ties+1 end
    local f=feedback[r.id]
    if f then
     a.feedback_count=a.feedback_count+1
     if f.pressure=='none' then a.pressure_none=a.pressure_none+1
     elseif f.pressure=='moderate' then a.pressure_moderate=a.pressure_moderate+1
     elseif f.pressure=='strong' then a.pressure_strong=a.pressure_strong+1 end
    end
   end
  end
  a.player_win_pct=100*mean(a.player_wins,a.games)
  a.avg_player_score=mean(ps,a.games);a.avg_merchant_score=mean(ms,a.games)
  a.avg_player_rerolls=mean(rerolls,a.games);a.avg_player_farkles=mean(pf,a.games)
  a.avg_merchant_farkles=mean(mf,a.games);a.avg_raises=mean(raises,a.games)
  for _,f in ipairs(feedback_rows) do
   if f.variant==variant and (f.banking_influenced=='yes' or f.banking_influenced=='no') then
    a.banking_responses=a.banking_responses+1
   end
  end
  -- Count "yes" independently from the response denominator; values are kept
  -- per variant to avoid inferring motivation from telemetry.
  local yes=0
  for _,r in ipairs(match_rows) do
   if r.variant==variant then local f=feedback[r.id];if f and f.banking_influenced=='yes' then yes=yes+1 end end
  end
  a.banking_yes_pct=100*mean(yes,a.banking_responses)
  out[#out+1]=a
 end
 return out
end

local columns={'variant','games','player_wins','player_losses','ties','player_win_pct',
 'avg_player_score','avg_merchant_score','avg_player_rerolls','avg_player_farkles',
 'avg_merchant_farkles','avg_raises','banking_yes_pct','pressure_none',
 'pressure_moderate','pressure_strong','feedback_count'}

function M.run(fs)
 local summaries=M.summarize(rows(fs,Log.MATCH_FILE_V2),rows(fs,Log.FEEDBACK_FILE))
 local csv={Log.line(columns)}
 local report={'Riepilogo Merchant Wager Lab — descrittivo, non conclusivo (campioni piccoli).'}
 for _,s in ipairs(summaries) do
  local values={};for i,k in ipairs(columns) do values[i]=s[k] end
  csv[#csv+1]=Log.line(values)
  report[#report+1]=('%s: partite %d; vittorie/sconfitte/pari %d/%d/%d; vittorie %.1f%%; punti medi A/M %.1f/%.1f; rilanci medi %.2f; Farkle medi A/M %.2f/%.2f; rialzi medi %.2f; banking influenzato %.1f%% (%d risposte); pressione nessuna/moderata/forte %d/%d/%d'):format(
   s.variant,s.games,s.player_wins,s.player_losses,s.ties,s.player_win_pct,
   s.avg_player_score,s.avg_merchant_score,s.avg_player_rerolls,s.avg_player_farkles,
   s.avg_merchant_farkles,s.avg_raises,s.banking_yes_pct,s.banking_responses,
   s.pressure_none,s.pressure_moderate,s.pressure_strong)
 end
 assert(fs.write(Log.SUMMARY_FILE,table.concat(csv)))
 return table.concat(report,'\n'),summaries
end
return M
