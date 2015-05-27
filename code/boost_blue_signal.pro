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
postplot = postplot

angstrom = '!6!sA!r!u!9 %!6!n'
!p.color=0
!p.background=255
loadct, 39, /silent
usersymbol, 'circle', /fill, size_of_sym = 0.5
spawn, 'echo $home', mdir
mdir = mdir+'/'

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