local R=require('src.farkle.rules')
local D=require('src.farkle.dice')
local Controller=require('src.farkle.controller')
local entries={}
for i=1,6 do
 local body={
  {-0.5,-0.5,-0.5},{0.5,0.5,0.5},
  position={i,0,2},velocity={1,2,3},angular={1,1,1},asleep=false
 }
 entries[i]={body=body}
end
local used={[1]=true,[3]=true,[6]=true}
D.stage_kept(entries,used)
for i,entry in ipairs(entries) do
 local body=entry.body
 if used[i] then
  assert(math.abs(body.position[1]-(i-3.5)*2.0)<1e-9)
  assert(body.position[2]==-4.45 and body.position[3]==0.5)
  assert(body.asleep and body._manual_pending)
  for axis=1,3 do assert(body.velocity[axis]==0 and body.angular[axis]==0) end
 else
  assert(body.position[1]==i and body.position[2]==0 and not body._manual_pending)
 end
end
local user={game={used=used},duel={actor='player'}}
assert(Controller.shouldDrawTrayDie(user,1),'duel kept die must stay rendered in g3d')
user.duel=nil
assert(not Controller.shouldDrawTrayDie(user,1),'old build-only register remains isolated')
local hud=require('src.farkle.ui').hud
assert(hud.accepted.draw({game=R.new('duel'),duel={}})==nil,
 'no redundant flat portraits in the duel')
print('PASS kept physical dice remain visible, parked and excluded from 2D register')
