-- Local playtest CSVs. Written only inside this lab's LÖVE save identity,
-- never to the production run log of the main game.
local M={}
M.MATCH_FILE='merchant_matches.csv'
M.DECISION_FILE='merchant_decisions.csv'
M.MATCH_FILE_V2='merchant_matches_v2.csv'
M.DECISION_FILE_V2='merchant_decisions_v2.csv'
M.FEEDBACK_FILE='merchant_feedback_v1.csv'
M.SUMMARY_FILE='merchant_summary_v1.csv'
M.V3_MATCH_FILE='merchant_v3_matches.csv'
M.V3_HAND_FILE='merchant_v3_hands.csv'
M.V3_DECISION_FILE='merchant_v3_decisions.csv'
M.V3_FEEDBACK_FILE='merchant_v3_feedback.csv'
M.CORRECTOR_MATCH_FILE='corrector_matches_v1.csv'
M.CORRECTOR_EVENT_FILE='corrector_events_v1.csv'
M.CORRECTOR_FEEDBACK_FILE='corrector_feedback_v1.csv'
M.match_columns={'id','seed','rounds','player_score','merchant_score','winner','end_reason',
 'raises','accepted','declined','player_farkles','player_rerolls','merchant_farkles',
 'raise_blocked_end','player_sheets','merchant_sheets','max_pot'}
M.decision_columns={'id','seed','step','round','actor','action','provisional','dice_available',
 'faces','detail','player_score','merchant_score','pot','player_sheets','merchant_sheets'}
M.match_columns_v2={'id','variant','seed','merchant_initial_score','player_initial_score',
 'initial_pot','rounds','player_score','merchant_score','winner','end_reason',
 'player_farkles','merchant_farkles','player_rerolls','raises','accepted','declined',
 'max_pot','player_sheets','merchant_sheets'}
M.decision_columns_v2={'id','seed','variant','round','player_score_before','merchant_score_before',
 'score_diff_merchant_minus_player','provisional','dice_available','action','next_roll_outcome'}
M.feedback_columns={'id','variant','seed','pressure','banking_influenced','main_influence','notes'}
M.v3_match_columns={'id','seed','initial_pot','hands_played','artist_hands','merchant_hands',
 'winner','reason','total_counteroffers','merchant_withdrawals','x_draws',
 'merchant_hand_win_pct','pot_awarded','artist_sheets','merchant_sheets'}
M.v3_hand_columns={'id','seed','hand','initial_symbols','initial_offer','player_result',
 'player_farkle','player_rerolls','merchant_symbols','characters_drawn','counteroffers',
 'merchant_continues','merchant_withdrawals','x_draws','winner','end_reason'}
M.v3_decision_columns={'id','seed','step','hand','actor','action','artist_score','merchant_score',
 'score_difference','provisional','dice_available','offer','player_result','probability',
 'threshold','public_remaining','outcome','symbol','points_added'}
M.v3_feedback_columns={'id','seed','counteroffer_rerolls','banked_below_estimate',
 'merchant_decisions_clear','felt_competitive','loss_cause','notes'}
M.corrector_match_columns={'id','seed','turns','player_sheets','corrector_sheets',
 'center_sheets','player_points','corrector_points','winner','end_reason','player_farkles',
 'corrector_farkles','corrector_rerolls','corrector_banked_turns',
 'corrector_sheets_bought','sheets_stolen','player_banked_turns',
 'player_decision_opportunities'}
M.corrector_event_columns={'id','seed','step','turn','actor','action','player_points',
 'corrector_points','player_sheets','corrector_sheets','pot','provisional',
 'dice_available','faces','kept','points','detail'}
M.corrector_feedback_columns={'id','seed','decision_changes','threat_perceived','notes'}

local function field(v)
 v=tostring(v==nil and '' or v)
 if v:find('[,"\r\n]') then v='"'..v:gsub('"','""')..'"' end
 return v
end
function M.line(values)
 local out={};for i,v in ipairs(values) do out[i]=field(v) end
 return table.concat(out,',')..'\n'
end
local function row(columns,source)
 local values={};for i,k in ipairs(columns) do values[i]=source[k] end;return M.line(values)
end

function M.match_row(record) return row(M.match_columns,record) end
function M.decision_rows(match,id)
 local out={}
 for step,d in ipairs(match.decisions) do
  local r={id=id,seed=match.seed,step=step,dice_available=d.available}
  for k,v in pairs(d) do if r[k]==nil then r[k]=v end end
  out[#out+1]=row(M.decision_columns,r)
 end
 return table.concat(out)
end

-- fs: love.filesystem (or a test double with getInfo/read/write/append).
function M.next_id(fs)
 if not fs.getInfo(M.MATCH_FILE) then return 1 end
 local text=fs.read(M.MATCH_FILE) or '';local lines=0
 for _ in text:gmatch('\n') do lines=lines+1 end
 return math.max(lines,1)
end
function M.next_id_v2(fs)
 if not fs.getInfo(M.MATCH_FILE_V2) then return 1 end
 local text=fs.read(M.MATCH_FILE_V2) or '';local lines=0
 for _ in text:gmatch('\n') do lines=lines+1 end
 return math.max(lines,1)
end
function M.next_id_v3(fs)
 if not fs.getInfo(M.V3_MATCH_FILE) then return 1 end
 local text=fs.read(M.V3_MATCH_FILE) or '';local lines=0
 for _ in text:gmatch('\n') do lines=lines+1 end
 return math.max(lines,1)
end
function M.next_id_corrector(fs)
 if not fs.getInfo(M.CORRECTOR_MATCH_FILE) then return 1 end
 local text=fs.read(M.CORRECTOR_MATCH_FILE) or '';local lines=0
 for _ in text:gmatch('\n') do lines=lines+1 end
 return math.max(lines,1)
end
local function append(fs,file,columns,text)
 if not fs.getInfo(file) then assert(fs.write(file,M.line(columns))) end
 assert(fs.append(file,text))
end
function M.save(fs,match,record)
 append(fs,M.MATCH_FILE,M.match_columns,M.match_row(record))
 append(fs,M.DECISION_FILE,M.decision_columns,M.decision_rows(match,record.id))
end

function M.save_v2(fs,match,record)
 append(fs,M.MATCH_FILE_V2,M.match_columns_v2,row(M.match_columns_v2,record))
 local rows={}
 for _,d in ipairs(match.player_decisions) do
  rows[#rows+1]=row(M.decision_columns_v2,{
   id=record.id,seed=match.seed,variant=match.config.variant,round=d.round,
   player_score_before=d.player_score,merchant_score_before=d.merchant_score,
   score_diff_merchant_minus_player=d.score_diff,provisional=d.provisional,
   dice_available=d.dice_available,action=d.action,next_roll_outcome=d.roll_outcome})
 end
 append(fs,M.DECISION_FILE_V2,M.decision_columns_v2,table.concat(rows))
end

function M.save_feedback(fs,record)
 append(fs,M.FEEDBACK_FILE,M.feedback_columns,row(M.feedback_columns,record))
end

function M.save_v3(fs,match,record)
 assert(record,'V3 match record is required')
 append(fs,M.V3_MATCH_FILE,M.v3_match_columns,row(M.v3_match_columns,record))
 local rows={}
 for _,h in ipairs(match.completed_hands) do
  local x_count=0
  for _,symbol in ipairs(h.symbols) do if symbol=='X' then x_count=x_count+1 end end
  rows[#rows+1]=row(M.v3_hand_columns,{
   id=match.id,seed=match.seed,hand=h.number,initial_symbols=table.concat(h.initial_symbols,' '),
   initial_offer=h.initial_offer,player_result=h.player_result,
   player_farkle=h.player_farkle and 'yes' or 'no',player_rerolls=h.player_rerolls,
   merchant_symbols=table.concat(h.symbols,' '),characters_drawn=h.char_draws,
   counteroffers=h.counteroffers,merchant_continues=h.merchant_continues,
   merchant_withdrawals=h.merchant_withdrawals,x_draws=x_count,
   winner=h.winner,end_reason=h.end_reason})
 end
 append(fs,M.V3_HAND_FILE,M.v3_hand_columns,table.concat(rows))
 rows={}
 for _,d in ipairs(match.decisions) do
  local remaining=''
  if d.remaining then
   local parts={}
   for i,label in ipairs({'V10','V20','V30','V40','X'}) do
    parts[#parts+1]=label..'='..d.remaining[i]
   end
   remaining=table.concat(parts,' ')
  end
  rows[#rows+1]=row(M.v3_decision_columns,{
   id=match.id,seed=match.seed,step=d.step,hand=d.hand,actor=d.actor,action=d.action,
   artist_score=d.player_score,merchant_score=d.merchant_score,
   score_difference=d.merchant_score-d.player_score,provisional=d.provisional,
   dice_available=d.dice_available,offer=d.offer,player_result=d.player_result,
   probability=d.probability,threshold=d.threshold,public_remaining=remaining,
   outcome=d.outcome,symbol=d.symbol,points_added=d.added})
 end
 append(fs,M.V3_DECISION_FILE,M.v3_decision_columns,table.concat(rows))
end

function M.save_v3_feedback(fs,record)
 append(fs,M.V3_FEEDBACK_FILE,M.v3_feedback_columns,row(M.v3_feedback_columns,record))
end

function M.save_corrector(fs,match,record)
 append(fs,M.CORRECTOR_MATCH_FILE,M.corrector_match_columns,
  row(M.corrector_match_columns,record))
 local rows={}
 for _,event in ipairs(match.events) do
  local values={id=record.id,seed=match.seed}
  for key,value in pairs(event) do values[key]=value end
  rows[#rows+1]=row(M.corrector_event_columns,values)
 end
 append(fs,M.CORRECTOR_EVENT_FILE,M.corrector_event_columns,table.concat(rows))
end

function M.save_corrector_feedback(fs,record)
 append(fs,M.CORRECTOR_FEEDBACK_FILE,M.corrector_feedback_columns,
  row(M.corrector_feedback_columns,record))
end
return M
