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
		if keyword_set(postplot) then begin
		   fn = nextnameeps('red_sum')
		   thick, 2
		   ps_open, fn, /encaps, /color
		endif
		plot, red_sum[2000, *], $
		xtitle='Cross Dispersion Direction', $
		ytitle='Counts', $
		title='Summed counts for red quartz exposures', $
		/xsty
		stop
	if keyword_set(postplot) then begin
	   ps_close
	endif
	endif;debug ge 5
endif;KW(red_files)

if keyword_set(blue_files) then begin
	blue_sum = getimage(blue_files[0], redpar, geom=geom)
	for idx=1, n_elements(blue_files)-1 do begin
		blue_sum += getimage(blue_files[idx], redpar, geom=geom)
	endfor

	im_size = size(blue_sum)
	blue_dec = blue_sum
	;the sigmoid midpoint used for the decay function:
	sig_midpt = redpar.blues_sig_mid
	;the sigmoid steepness (how quickly it goes from 1 to zero:
	sig_stp = 1d-2
	decay_function = 1d - 1d /(1d + sig_stp * exp(-sig_stp*(dindgen(im_size[2]) - sig_midpt)))
	;loop through columns and attenuate the signal in the red:
	for col=0, im_size[1]-1 do blue_dec[col, *] *= decay_function

	if redpar.debug ge 5 then begin
		if keyword_set(postplot) then begin
		   fn = nextnameeps('blue_sum')
		   thick, 2
		   ps_open, fn, /encaps, /color
		endif
		plot, blue_sum[2000, *]/max(blue_sum[2000, *]), $
		xtitle='Cross Dispersion Direction', $
		ytitle='Normalized Counts', $
		title='Summed counts for blue quartz exposures', $
		/xsty
		oplot, decay_function, col=250
		oplot, blue_dec[2000, *]/max(blue_dec[2000, *]), col=70
		if keyword_set(postplot) then begin
		   ps_close
		endif
		stop

		plot, red_sum[2000, *]/max(red_sum[2000, *]), /xsty
		oplot, blue_dec[2000, *]/max(blue_dec[2000, *]), col=70
		stop
	endif;debug ge 5
endif else begin
	print, 'You did not pass the filenames for the blues files to'
	print, 'boost_blue_signal.pro. Returning from all.'
	retall
endelse;KW(blue_files)

output_image = red_sum + blue_dec

if redpar.debug ge 5 then begin
	if keyword_set(postplot) then begin
	   fn = nextnameeps('blue_sum')
	   thick, 2
	   ps_open, fn, /encaps, /color
	endif
	plot, output_image[2000, *]/max(output_image[2000, *]), $
	xtitle='Cross Dispersion Direction', $
	ytitle='Normalized Counts', $
	title='Combined Red + Blue Image for Order Finding', $
	/xsty
	stop
endif;debug ge 5

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