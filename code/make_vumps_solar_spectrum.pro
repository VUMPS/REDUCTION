;+
;
;  NAME: 
;     make_vumps_solar_spectrum
;
;  PURPOSE: 
;   
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;
;      make_vumps_solar_spectrum
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
;      make_vumps_solar_spectrum
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-28T17:05:46
;
;-
pro make_vumps_solar_spectrum, $
postplot = postplot, $
halpha = halpha, $
nad = nad

angstrom = '!6!sA!r!u!9 %!6!n'
!p.color=0
!p.background=255
loadct, 39, /silent
usersymbol, 'circle', /fill, size_of_sym = 0.5
spawn, 'echo $home', mdir
mdir = mdir+'/'

filename = '/tous/vumps/fitspec/150524/rvumps150524.1020.fits'
im = readfits(filename)
wav = reform(im[0,*,*])
spec = reform(im[1,*,*])

if keyword_set(nad) then begin
	fnhgh = '/tous/vumps/fitspec/150524/rvumps150524.1018.fits'
	imhgh = readfits(fnhgh)

	fnmed = '/tous/vumps/fitspec/150524/rvumps150524.1021.fits'
	immed = readfits(fnmed)

	fnlow = '/tous/vumps/fitspec/150524/rvumps150524.1024.fits'
	imlow = readfits(fnlow)

	ord = 48

	if keyword_set(postplot) then begin
	   fn = nextnameeps('nad_vumps')
	   thick, 2
	   ps_open, fn, /encaps, /color
	endif
	plot, imhgh[0,1000:1600,ord], imhgh[1,1000:1600,ord]/max(imhgh[1,1000:1600,ord]), $
	/xsty, xtitle='Wavelength [A]', ytitle='Normalized Flux'

	oplot, immed[0,1000:1600,ord], immed[1,1000:1600,ord]/max(immed[1,1000:1600,ord]), col=70

	oplot, imlow[0,1000:1600,ord], imlow[1,1000:1600,ord]/max(imlow[1,1000:1600,ord]), col=250

	items = ['High Resolution', 'Medium Resolution', 'Low Resolution']

	al_legend, items, colors=[0, 70, 250], linestyle=[0,0,0]

	if keyword_set(postplot) then begin
	   ps_close
	endif
	stop
endif

if keyword_set(postplot) then begin
   fn = nextnameeps('plot')
   thick, 2
   ps_open, fn, /encaps, /color
endif

display, spec
if keyword_set(postplot) then begin
   ps_close
endif

stop
end;make_vumps_solar_spectrum.pro