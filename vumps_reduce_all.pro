;+
;
;  NAME: 
;     vumps_reduce_all
;
;  PURPOSE: 
;   The file to run to execute the VUMPS reduction code for all 3 modes.
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;
;      vumps_reduce_all, date='yymmdd'
;
;  KEYWORD PARAMETERS:
;    
;  EXAMPLE:
;      vumps_reduce_all, date='150516
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015.05.17 18:37:37
;
;-
pro vumps_reduce_all, $
help = help, $
date = date, $
doppler = doppler, $
skipbary = skipbary, $
skipdistrib = skipdistrib, $
skipqc = skipqc


if keyword_set(help) then begin
	print, '*************************************************'
	print, '*************************************************'
	print, '        HELP INFORMATION FOR chi_reduce_all'
	print, 'KEYWORDS: '
	print, ''
	print, 'HELP: Use this keyword to print all available arguments'
	print, ''
	print, ''
	print, ''
	print, '*************************************************'
	print, '                     EXAMPLE                     '
	print, "IDL>"
	print, 'IDL> '
	print, '*************************************************'
	stop
endif

print, 'Started @: ', systime()
spawn, 'hostname', host

rawdir = '/raw/vumps/'
lfn = '/tous/vumps/logsheets/20'+strmid(date, 0, 2)+'/'+strt(date)+'.log'

;This part gets the image prefix:
spawn, 'ls -1 '+rawdir+date+'/', filearr
nel = n_elements(filearr)
nfa = strarr(nel)
for i=0, nel-1 do nfa[i] = strmid(filearr[i], 0, strlen(filearr[i])-9)
uniqprefs =  nfa(uniq(nfa))
pref = 'junk'
ii=-1
repeat begin
  ii++
  pref = uniqprefs[ii]
  print, 'pref is: ', uniqprefs[ii]
  print, 'pref 1st 2 are: ', strmid(uniqprefs[ii], 0,2)
endrep until ( ((strmid(uniqprefs[ii],0,2) eq 'qa') or $
        (strmid(uniqprefs[ii],0,2) eq 'ch')) and $
        (strmid(uniqprefs[ii], 0, 4) ne 'chir') and $
        (strmid(uniqprefs[ii], 0, 1, /reverse) eq '.'))

print, 'pref is: ', pref
;stop, 'pref is: ', pref

modearr = [$
'low', $ 
'med', $
'hgh']

for i=0, 3 do begin
  print, '*************************************************'
  print, ' NOW ON TO THE ', MODEARR[I], ' MODE...'
  print, '*************************************************'
  sorting_hat,date,run=pref,mode=modearr[i],/reduce,/getthid,/iod2fits
endfor

print, 'Finished @: ', systime()

end;vumps_reduce_all.pro