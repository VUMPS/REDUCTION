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
skipqc = skipqc, $
resolution=resolution


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

spawn, 'echo $VUMPS_PAR_PATH', vmpsparfn
redpar = readpar(vmpsparfn)
rawdir = redpar.rootdir + redpar.rawdir
lfn = '/tous/vumps/logsheets/20'+strmid(date, 0, 2)+'/'+strt(date)+'.log'

;This part gets the image prefix:
spawn, 'ls -1 '+rawdir+date+'/', filearr
nel = n_elements(filearr)

;make a string array that has the same number of elements
;as the number of files for the night:
nfa = strarr(nel)

;chop off the individual image information in the filename and only
; keep the prefixes:

;first, find the position of the 'sequence number.fit' in each filename:
sqpos = stregex(filearr, '[0-9]+.fit')

;now extract everything UP TO the sequence number:
for i=0, nel-1 do nfa[i] = strmid(filearr[i], 0, sqpos[i])

;now determine how many unique image prefixes are in the 
;data directory for the night:
uniqprefs =  nfa(uniq(nfa))
if n_elements(uniqprefs) gt 1 then begin
	print, 'ERROR! There was more than one image prefix in the'
	print, 'raw data directory. Please ammend the image prefixes'
	print, 'to have one consistent name before proceeding.'
	return
endif;

pref = uniqprefs
print, 'The prefix is: ', pref

if keyword_set(resolution) then begin
resolutionarr = resolution
endif else begin
resolutionarr = [$
'hgh', $ 
'med', $
'low']
endelse

for i=0, n_elements(resolutionarr)-1 do begin
  print, '*************************************************'
  print, ' NOW ON TO THE ', resolutionarr[i], ' MODE...'
  print, '*************************************************'
  sorting_hat,date,image_prefix=pref,resolution=resolutionarr[i],/reduce,/getthid,/iod2fits
endfor

print, 'Finished @: ', systime()

end;vumps_reduce_all.pro