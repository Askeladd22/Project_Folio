-- Canonical splash visual language, no retired Scriptorium PNGs/shaders.
return {
 assets={
  background_path='resources/ui/menu.png',
  title_font='resources/font/IMFeENsc28P.ttf',
  subtitle_font='resources/font/EagleLake-Regular.ttf',
 },
 timing={intro_seconds=4.0,title_seconds=5.0,reduced_factor=.5},
 text={branding_title={key='branding.title',default='Project Folio'}},
 flow={next_module='main_menu',skip_audio='confirm',skip_mouse_button=1},
}
