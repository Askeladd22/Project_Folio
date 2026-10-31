-- Explicit optional one-commission Farkle race; no effect on solo runs.
-- Both players use the same Rules/Scoring; bot has independent virtual D6.
-- Player still throws all six physical g3d D6 with unchanged controller.
local Bot=require('src.gameplay.farkle.opponent_bot')
local Rules=require('src.gameplay.farkle.rules')
local M={}
local Duel={}
Duel.__index=Duel
local complete={ended=true,lost=true,won=true,upgrade=true,medal=true,advance=true}

function M.new(random)
 return setmetatable({bot=Bot.new(random),processed={},finished=false,
  winner=nil,last=nil,name='Monaco del folio'},Duel)
end

function Duel:after_player_turn(player)
 if self.finished or not player or not complete[player.phase] then return nil end
 if player.stage~=1 then return nil end
 local id=tostring(player.stage)..':'..tostring(player.turn)
 if self.processed[id] then return nil end
 self.processed[id]=true
 local report=self.bot:turn()
 if not report then return nil end
 local b=self.bot.game
 local target=Rules.contracts[1].target
 local p_finished=player.bank>=target
 local b_finished=b.bank>=target
 local last_turn=player.turn>=Rules.contracts[1].limit
 if p_finished or b_finished or last_turn then
  self.finished=true
  if player.bank>b.bank then self.winner='player'
  elseif player.bank<b.bank then self.winner='bot'
  else self.winner='tie' end
  -- Reaching the target outranks a larger below-target total.
  if p_finished and not b_finished then self.winner='player' end
  if b_finished and not p_finished then self.winner='bot' end
 end
 self.last={report=report,player=player.bank,bot=b.bank,
   winner=self.winner,finished=self.finished}
 return self.last
end

return M
