;+
;
;  NAME: 
;     vumps_setup_thar
;
;  PURPOSE: 
;   
;
;  CATEGORY:
;      CHIRON
;
;  CALLING SEQUENCE:
;
;      vumps_setup_thar
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
;      vumps_setup_thar
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-22T19:11:11
;
;-
pro vumps_setup_thar, $
postplot = postplot

angstrom = '!6!sA!r!u!9 %!6!n'
!p.color=0
!p.background=255
loadct, 39, /silent
usersymbol, 'circle', /fill, size_of_sym = 0.5
spawn, 'echo $home', mdir
mdir = mdir+'/'

fn = '/tous/vumps/iodspec/150522/rvumps150522.1085.fits'
tharim = readfits(fn)

tharim = rotate(tharim, 2)
display, tharim
stop
thid, tharim, 70, 70. * [8710, 8835], wvc, thid, /orev

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
end;vumps_setup_thar.pro