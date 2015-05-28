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
postplot = postplot

angstrom = '!6!sA!r!u!9 %!6!n'
!p.color=0
!p.background=255
;loadct, 39, /silent
usersymbol, 'circle', /fill, size_of_sym = 0.5
spawn, 'echo $home', mdir
mdir = mdir+'/'

filename = '/tous/vumps/fitspec/150524/rvumps150524.1020.fits'
im = readfits(filename)
wav = reform(im[0,*,*])
spec = reform(im[1,*,*])

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