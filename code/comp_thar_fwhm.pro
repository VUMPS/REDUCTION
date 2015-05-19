;+
;
;  NAME: 
;     comp_thar_fwhm
;
;  PURPOSE: 
;   
;
;  CATEGORY:
;      CHIRON
;
;  CALLING SEQUENCE:
;
;      comp_thar_fwhm
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
;      comp_thar_fwhm
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-19T12:36:27
;
;-
pro comp_thar_fwhm, $
postplot = postplot

angstrom = '!6!sA!r!u!9 %!6!n'
!p.color=0
!p.background=255
loadct, 39, /silent
usersymbol, 'circle', /fill, size_of_sym = 0.5
spawn, 'echo $home', mdir
mdir = mdir+'/'

thar = '/tous/vumps/iodspec/150516/rImageName176.fits'
tharim = readfits(thar)

display, tharim, /log

stop

plot, (tharim[3700:3800,2] - min(tharim[3700:3800,2]))/max(tharim[3700:3800,2] - min(tharim[3700:3800,2]))
oplot, (tharim[160:300,2] - min(tharim[160:300,2]))/max(tharim[160:300,2]), col=70 
oplot, (tharim[3700:3800,2] - min(tharim[3700:3800,2]))/max(tharim[3700:3800,2] - min(tharim[3700:3800,2])), col=250
xyouts, 0.1, 0.8, 'Order 2 Red=3750px Blue=180px', /normal 



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
end;comp_thar_fwhm.pro