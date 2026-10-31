-- PROVISIONAL 2026-10-31 design fixture from docs/INCONTRI_E_SEGNI.md.
-- Numbers are examples to falsify via A/B/C tests, NOT approved balance.
-- No production module imports this file.
return {
 id='leone-bordura-v0',
 title='Leone della Bordura (esperimento)',
 target_wins=3,
 max_hands=6,
 occasion_margin=25,
 assault_farkle_enemy_marks=2,
 signs={
  {id='assalto-20',category='assalto',strength=20},
  {id='assalto-40',category='assalto',strength=40},
  {id='guardia-30',category='guardia',strength=30},
  {id='guardia-50',category='guardia',strength=50},
  {id='occasione-35',category='occasione',strength=35},
  {id='occasione-55',category='occasione',strength=55},
 },
}
