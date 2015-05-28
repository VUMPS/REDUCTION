;+
; PURPOSE: To find the latest THID file for a given night
;
; INPUT: night='110820', parfile, [mode=mode]
; run is needed for the old format, otherwise run  'chi'+night
; if mode is specified, only THID files for this mode will be searched
;
; OUTPUT: found = name of the file
;
; CREATED:
; Oct 17, 2011 AT
;
; MODIFICATION HISTORY:
; *routine wasn't working since the 2012 upgrade. 
; Changed a number of things, removed hard coding 
; and got it up and running. 20120504 ~MJG
; *Modified the file search line to work with multiple years 20130111 ~MJG
; Made sure thar lamp was in for observation, got rid of 1 goto. 20130901 ~MJG
;-

pro findthid, $
date=date, $
redpar, $
thidfile, $
resolution=resolution, $
image_prefix=image_prefix

depth = 10 ; how many nights back to look?
thidfile='none'
logdir = redpar.rootdir+redpar.logdir
if ~keyword_set(resolution) then resolution = redpar.resolutionarr[redpar.resolutionidx]
if ~keyword_set(image_prefix) then image_prefix = redpar.prefix
if ~keyword_set(date) then date = redpar.date
pfxtg = redpar.red_prefix

;The extra "../*/" takes care of the year directory:
logs = file_search(logdir+'../*/*.log', count=nlogs)
if nlogs eq 0 then return ; No logfiles
print, nlogs,' logsheets found by FINDTHID'
logs = logs[sort(logs)]

start = (where(logdir+date+'.log' eq logs))[0] 
if start lt 0 then stop, 'Night '+date+' is not found in the logs!'

found = 0
lookback = (start - depth) > 0
; start with the current night
for i=start, lookback ,-1 do begin ; try all nights backwards
   ;for the case where the automatic hourly log generator is currently 
   ;creating the logs, wait 180 seconds for it to finish before proceeding:
   spawn, 'tail '+logs[i], logout
   if logout[0] eq '' then wait, 180
   ; read logsheets
   readcol,logs[i], skip=9, obnm, objnm, mdpt, exptm, slit, f='(a,a,a,a,a,)'
   if keyword_set(resolution) then sel = where((objnm eq 'thar') and (slit eq resolution)) else  sel = where(objnm eq 'thar')
   if sel[0] lt 0 then continue ; nothing for this night! 

   curnight = strmid(logs[i], strlen(logdir))
   curnight = strmid(curnight, 0, strpos(curnight,'.log'))
   crun = 'vumps'+curnight
   print, curnight
   stop

   if strpos(crun,'.') lt 0 then crun=crun+'.' ; add the point

   thidfile =''
   j=0L
   while j le n_elements(sel)-1 and thidfile eq '' do begin ; search thids
	 fn = redpar.rootdir+redpar.thidfiledir+curnight+'/'+crun+obnm[sel[j]]+'.thid'
	 print, fn
	 print, 'Looking for '+fn
	 if file_test(fn) then begin 
		thidfile = fn
		print, 'FOUND thid file '+thidfile
		return
	 endif 
	 j++
   endwhile
endfor

end;findthid.pro
