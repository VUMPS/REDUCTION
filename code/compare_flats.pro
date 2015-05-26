;+
;
;  NAME: 
;     compare_flats
;
;  PURPOSE: 
;   
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;
;      compare_flats
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
;      compare_flats
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-26T17:43:05
;
;-
pro compare_flats, $
postplot = postplot

angstrom = '!6!sA!r!u!9 %!6!n'
!p.color=0
!p.background=255
loadct, 39, /silent
usersymbol, 'circle', /fill, size_of_sym = 0.5
spawn, 'echo $home', mdir
mdir = mdir+'/'
;***********************************************
;***********************************************

f23fn = '/raw/vumps/150523/vumps150523.1043.fit'
flat23m = readfits(f23fn) 

f24fn = '/raw/vumps/150524/vumps150524.1037.fit'
flat24l = readfits(f24fn)

s24hfn = '/raw/vumps/150524/vumps150524.1015.fit'
sun24h = readfits(s24hfn)

s24mfn = '/raw/vumps/150524/vumps150524.1021.fit'
sun24m = readfits(s24mfn)

s24lfn = '/raw/vumps/150524/vumps150524.1025.fit'
sun24l = readfits(s24lfn)

if keyword_set(postplot) then begin
   fn = nextnameeps('compare_flats')
   thick, 2
   ps_open, fn, /encaps, /color
endif

xinit = 2500
xran = 500
xarr = lindgen(xran)+xinit
plot, xarr, flat23m[2000,xinit:(xinit+xran)], /xsty, $
xtitle='Cross Dispersion', $
ytitle='Counts'

oplot, xarr, flat24l[2000,xinit:(xinit+xran)], col=70

oplot, xarr, sun24h[2000, xinit:(xinit+xran)], col=250

oplot, xarr, sun24m[2000, xinit:(xinit+xran)], col=210

oplot, xarr, sun24l[2000, xinit:(xinit+xran)], col=200

items=['Med res flat 150523', 'Low res flat 150524', $
'High Res Sun 150524', 'Med Res Sun', 'Low Res Sun']
al_legend, items, colors=[0, 70, 250, 210, 200], linestyle=[0, 0, 0, 0, 0]

if keyword_set(postplot) then begin
   ps_close
endif

stop
end;compare_flats.pro