local Presentation=require('src.features.farkle.presentation')
local F={}
local fonts={}
local colors={ink={.16,.20,.20},red={.66,.16,.19},green={.18,.39,.28},blue={.18,.34,.53},gold={.69,.49,.15}}
local words={'Lux','in','folio','manet','et','manus','opus','texit','hora','post','horam','memoria','crescit','inter','folia','silentia'}
function F.draw(s,p,x,y,w,h,txt,target)
 local g=love.graphics
 local bank,pot=Presentation.folio_values(p,s)
 local fixed=math.max(0,math.min(1,bank/math.max(1,target)))
 local wet=math.max(fixed,math.min(1,(bank+pot)/math.max(1,target)))
 local function pigment(color,threshold,span)
  local stable=math.max(0,math.min(1,(fixed-threshold)/span))
  local pending=math.max(0,math.min(1,(wet-threshold)/span))
  local alpha=stable*.94+math.max(0,pending-stable)*.32
  local rgb=colors[color]
  g.setColor(rgb[1],rgb[2],rgb[3],alpha)
  return {rgb[1],rgb[2],rgb[3],alpha}
 end
 g.setColor(.06,.08,.07,.3);g.rectangle('fill',x+7,y+9,w,h,2)
 g.setColor(.96,.95,.88,1);g.rectangle('fill',x,y,w,h,2)
 for strip=1,16 do
  g.setColor(.64,.60,.46,.018+(strip%3)*.006)
  g.rectangle('fill',x,y+strip*h/17,w,h/34)
 end
 g.setColor(.56,.49,.32,.45);g.setLineWidth(1)
 g.rectangle('line',x+2,y+2,w-4,h-4,2)
 txt('FOLIO '..s.stage,x+w*.18,y+h*.045,w*.64,math.max(13,math.floor(w*.043)),{.38,.32,.24,1},'center')
 local left,right,top,bottom=x+w*.20,x+w*.82,y+h*.17,y+h*.85
 g.setColor(.54,.47,.37,.15)
 g.line(left,y+h*.13,left,bottom);g.line(right,y+h*.13,right,bottom)
 for row=1,17 do
  local baseline=top+row*h*.036
  g.setColor(.46,.48,.46,.13);g.setLineWidth(.7)
  g.line(left,baseline,right,baseline)
  local rowLeft=row<5 and left+w*.18 or left
  local available=right-rowLeft
  for word=1,4 do
   local index=(row-1)*4+word
   local threshold=(index-1)/90
   local color=pigment('ink',threshold,.025)
   local text=words[(row*3+word*5)%#words+1]
  local size=math.max(9,math.floor(w*.033))
  fonts[size]=fonts[size] or g.newFont('resources/font/IMFeENsc28P.ttf',size)
  local font=fonts[size]
  local fit=math.min(1,(available/4-3)/math.max(1,font:getWidth(text)))
  g.setFont(font);g.setColor(unpack(color))
  g.print(text,rowLeft+(word-1)*available/4,baseline-h*.026,0,fit,1)
  end
 end
 local initial=pigment('red',.045,.14)
 txt('M',left,top+h*.012,w*.19,math.floor(w*.17),initial)
 pigment('gold',.16,.12);g.setLineWidth(math.max(1,w*.004))
 g.rectangle('line',left-w*.015,top-h*.005,w*.18,h*.15)
 local stemX=x+w*.11
 for segment=1,24 do
  local start=y+h*(.13+(segment-1)*.030)
  local finish=start+h*.030
  pigment('green',(segment-1)/29,.06)
  g.setLineWidth(math.max(1,w*.004))
  g.line(stemX+math.sin(segment*.8)*w*.022,start,stemX+math.sin((segment+1)*.8)*w*.022,finish)
  local side=segment%2==0 and 1 or -1
  local leafX=stemX+side*w*.045
  pigment(segment%3==0 and 'blue' or 'green',(segment-1)/27,.07)
  g.push();g.translate(leafX,start+h*.012);g.rotate(side*.65)
  g.ellipse('fill',0,0,w*.014,h*.020);g.pop()
  if segment%3==1 then
   local flowerX=stemX-side*w*.045
   pigment(segment%2==0 and 'blue' or 'red',segment/28,.06)
   for petal=1,5 do
    local angle=petal*math.pi*2/5
    g.ellipse('fill',flowerX+math.cos(angle)*w*.014,start+math.sin(angle)*w*.014,w*.012,w*.009)
   end
   pigment('gold',segment/28,.06);g.circle('fill',flowerX,start,w*.007)
  end
 end
 for segment=1,15 do
  local offset=(segment-1)/15
  local ornamentX=left+offset*(right-left)
  pigment(segment%3==0 and 'red' or 'blue',.20+offset*.70,.06)
  g.setLineWidth(math.max(1,w*.004))
  g.arc('line','open',ornamentX,y+h*.115,w*.022,0,math.pi)
  pigment('gold',.28+offset*.65,.06)
  g.circle('fill',ornamentX,y+h*.115,w*.005)
 end
 for segment=1,10 do
  pigment('red',.56+(segment-1)*.04,.05)
  local ornamentY=top+(segment-1)*(bottom-top)/10
  g.line(right+w*.035,ornamentY,right+w*.035,ornamentY+h*.035)
  pigment('gold',.60+(segment-1)*.035,.04)
  g.circle('fill',right+w*.035,ornamentY+h*.045,w*.006)
 end
 local pulse=p and p.conclusion and p.conclusion.kind=='bank' and 1-p.conclusion.age/Presentation.feedback_duration or 0
 if pulse>0 then
  g.setColor(.86,.70,.29,pulse*.5);g.setLineWidth(2)
  g.rectangle('line',x+5,y+5,w-10,h-10,2)
 end
 txt(s.bank..' assicurati',x+w*.15,y+h*.90,w*.72,math.max(12,math.floor(w*.039)),{.15,.29,.24,1},'center')
 txt(s.pot..' a rischio',x+w*.15,y+h*.94,w*.72,math.max(12,math.floor(w*.039)),{.51,.25,.20,1},'center')
 g.setLineWidth(1)
 return {fixed=fixed,wet=wet}
end
return F