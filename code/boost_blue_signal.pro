;+
;
;  NAME: 
;     boost_blue_signal
;
;  PURPOSE: To combine two sets of exposures with different
;		exposure times to "boost" the signal in the blue. The
;		blue exposures are expected to be saturated in the red,
;		and are hence exponentially attenuated within this 
;		routine.
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;
;      boost_blue_signal
;
;  INPUTS:
;
;  OPTIONAL INPUTS:
;
;  OUTPUTS:
;
;  OPTIONAL OUTPUTS:
;
;  KEYWORD PARAMETERS:
;    
;  EXAMPLE:
;      boost_blue_signal
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-27T14:43:32
;
;-
pro boost_blue_signal, $
blue_files = blue_files, $
redpar = redpar, $
red_files = red_files, $
red_flat = red_flat, $
output_image = output_image, $
postplot = postplot

angstrom = '!6!sA!r!u!9 %!6!n'
!p.color=0
!p.background=255
loadct, 39, /silent
usersymbol, 'circle', /fill, size_of_sym = 0.5
spawn, 'echo $home', mdir
mdir = mdir+'/'

if keyword_set(red_files) then begin
	red_sum = getimage(red_files[0], redpar, geom=geom)
	for idx=1, n_elements(red_files)-1 do begin
		red_sum += getimage(red_files[idx], redpar, geom=geom)
	endfor
	if redpar.debug ge 5 then begin
		plot, red_sum[2000, *], $
		xtitle='Cross Dispersion Direction', $
		ytitle='Counts', $
		title='Summed counts for red quartz exposures', $
		/xsty
		stop
	endif;debug ge 5
endif;KW(red_files)

if keyword_set(blue_files) then begin
	blue_sum = getimage(blue_files[0], redpar, geom=geom)
	for idx=1, n_elements(blue_files)-1 do begin
		blue_sum += getimage(blue_files[idx], redpar, geom=geom)
	endfor
	if redpar.debug ge 5 then begin
		plot, blue_sum[2000, *], $
		xtitle='Cross Dispersion Direction', $
		ytitle='Counts', $
		title='Summed counts for blue quartz exposures', $
		/xsty
		stop
	endif;debug ge 5
endif;KW(red_files)

stop
if keyword_set(postplot) then begin
   fn = nextnameeps('plot')
   thick, 2
   ps_open, fn, /encaps, /color
endif

if keyword_set(postplot) then begin
   ps_close
endif

stop
end;boost_blue_signal.pro 