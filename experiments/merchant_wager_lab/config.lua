-- Experimental parameters for "Il Mercante e la posta".
-- Deliberately simple and possibly unbalanced: change values here only,
-- never in the production rules or in the main game's settings.
return {
 starting_sheets=4,   -- proof sheets per contender
 opening_stake=1,     -- sheets each contender deposits at the start
 win_threshold=80,    -- reaching it ends the match after the current full round
 max_rounds=3,        -- one player turn + one Merchant turn per round
 merchant_dice=3,     -- virtual D6 thrown by the Merchant
 merchant_rerolls=1,  -- extra rolls the Merchant may take per turn
 raise_threshold=30,  -- the Merchant raises after banking at least this much
 raise_sheets=1,      -- sheets added by "Alzo" and matched by "Vedo"
 variants={
  A={label='Controllo',merchant_start=0,player_start=0,opening_stake=1},
  B={label='Inseguimento',merchant_start=30,player_start=0,opening_stake=1},
  C={label='Alta posta',merchant_start=0,player_start=0,opening_stake=2},
 },
 seeds={101,202,303},
}
