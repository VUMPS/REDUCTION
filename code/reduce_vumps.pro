;+
;
;  NAME: 
;     reduce_vumps
;
;  PURPOSE: 
;   
;
;  CATEGORY:
;      CHIRON
;
;  CALLING SEQUENCE:
;
;      reduce_vumps
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
;      reduce_vumps
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-18T10:53:21
;   	 based on CHIRON reduction code
;
;-
pro reduce_vumps, redpar, resolution, flatset=flatset, thar=thar, $                   
   order_ind=order_ind,  star=star, date=date


;Prefix added to FITS headers:  
prefix=redpar.prefix   ; e.g. 'ImageName'   

;Identify the resolution (e.g. low, med, hgh):
resolutionidx = redpar.resolutionidx

;Raw image path, e.g. /raw/vumps/150516/
indir=redpar.rootdir+redpar.rawdir+redpar.imdir 

;Output reduced file path
outdir= redpar.rootdir + redpar.iodspecdir + date + '/'
if ~file_test(outdir) then spawn, 'mkdir '+outdir

if ~keyword_set (order_ind) then begin
   print, 'REDUCE_VUMPS: ORDER definition is not given at input, use flat instead'
   order_ind = -1
endif 

; Try to read from the disk previously saved flats
if ~keyword_set (flatset) then begin
     name = redpar.rootdir+redpar.flatdir+prefix+resolution+'.flat'
     tmp = file_search(name, count=flatcount)
     stop
     if flatcount eq 0 then begin
       print, 'REDUCE_VUMPS: FLATS are not given at input, not found on disk, returning.'
       return
     endif else begin
       print, 'REDUCE_VUMPS: reading previously saved flat from disk' 
       rdsk, sum, name, 1 ; restore saved flat
       flatfnums='SUM'        
    endelse 
 endif else begin ; flats are given
    nrecf = n_elements(flatset)
    recnums = strt(flatset,f='(I)')  ;convert to strings
    flatfnums = prefix + recnums
    flatfnames = indir + prefix + recnums + redpar.suffix  ;array of flat-field files 
 endelse 

;7.  Record number of Stellar spectra here:
nrec = n_elements(star)
recnums = strt(star, f='(I)')  ; convert to string with leading zeros    
spnums = prefix + recnums
spfnames = indir + prefix + recnums + redpar.suffix
; string array of spectrum file names
outprefix = redpar.red_prefix +  prefix
outfnames= outdir + outprefix  + recnums  + '.fits'

; Order-Finding Exposure: strong exposure, such as iodine or bright star(B star)
if order_ind ge 0 then begin
	recint = order_ind
	recnums = strt(recint,f='(I)')
	ordfname = indir + prefix + recnums + redpar.suffix
endif else ordframe='FLAT'

;THORIUMS:  Insert record numbers to reduce  here:
;3. Record numbers for thar and iodine (don-t need sky subtraVUMPSn)
if keyword_set(thar) then threc = thar else threc = -1 
if threc[0] ge 0 then begin
	thnrec = n_elements(threc)
	threcnums = strtrim(string(threc,format='(I)'),2) ;convert to strings 
	thspfnames = indir + prefix + threcnums + redpar.suffix
	thoutfnames = outdir + outprefix  + threcnums + '.fits'
endif else threcnums = 'none'
  
print,''
print,'    ****ECHOING PARAMETER VALUES FROM REDUCE_VUMPS****'
print,'If values are incorrect stop the program'
print,' '
print,'SPECTRA:'
print,spfnames
print,' '
print,'FLATS:'
print,flatfnames
print,' '
print,'DEFAULT ORDER FILE:'
print, order_ind
print,' '
print, 'THORIUM/IODINE: '
print, thspfnames

if redpar.debug ge 2 then print, 'REDUCE_VUMPS: type ".c" to continue' 
if redpar.debug ge 2 then stop

; CRUNCH  FLATS
sumname = redpar.rootdir+redpar.flatdir+prefix+resolution+'_sum.fits'

if keyword_set(flatset) then begin
	;if redpar.debug then stop, 'REDUCE_VUMPS: debug stop before flats, .c to continue'
	ADDFLAT, flatfnames,sum, redpar, im_arr  ; crunch the flats (if redpar.flatnorm=0 then sum = wtd mean)
	if (size(sum))[0] lt 2 then stop ; no data!

	;write a trimmed flat to file: SUM DOUBLE Array[4038,4112]
	writefits, sumname, sum
	print, 'REDUCE_VUMPS: summed flat is written to '+sumname  
	;if redpar.debug then stop, 'Debug stop after flats, .c to continue'
endif else begin
	print, 'Using previously saved flat '+name 
	;get existing flat from disk
	sum = readfits(sumname)
	bin = redpar.binnings[resolutionidx] ; set correct binning for order definition
	redpar.binning = [fix(strmid(bin,0,1)), fix(strmid(bin,2,1))]
	print, 'The binning is ', redpar.binning
endelse

;FIND DEFAULT ORDER LOCATIONS.  
if order_ind ge 0 then begin
	vumps_dord, ordfname, redpar, orc, ome 
endif else vumps_dord, ordfname, redpar, orc, ome, image=sum

;write the order locations to file:
orcname = redpar.rootdir+redpar.orderdir+prefix+resolution+'.orc'
writefits, orcname, orc

print, 'REDUCE_VUMPS: order location is written to '+orcname  
if redpar.debug then stop, 'Debug stop after order location, .c to continue'

; GET FLAT FIELD
xwid = redpar.xwids[resolutionidx]
if redpar.debug gt 1 then stop, 'REDUCE_VUMPS: debug stop before getting flat' 
flat = getflat(sum, orc, xwid, redpar, im_arr=im_arr)

flatname = redpar.rootdir+redpar.flatdir+prefix+resolution+'_flat.fits'
;fitsname = redpar.rootdir+redpar.flatdir+prefix+mode+'flat.fits'

;wdsk, flat, name, /new
writefits, flatname, flat
;rdsk2fits, filename=fitsname, data = flat
print, 'REDUCE_VUMPS: extracted flat field is written to '+flatname  
FF = flat[*,*,0] ; the actual flat
if redpar.debug ge 2 then stop, 'Debug stop after flat field, .c to continue'

;REDUCE ThAr,Iodines (RED)
    if keyword_set(thar) then begin
		numthar=n_elements(threc)
	 	FOR i=0,numthar-1 do begin
	   		redpar.seqnum = strt(threcnums[i])
			VUMPS_SPEC,prefix,thspfnames[i], thoutfnames[i],redpar, orc,xwid=xwid,/nosky
	 	ENDFOR
	 	CATCH, /CANCEL ; clear the catch block in case we bailed on the last one
	endif

PRINT, 'RIGHT BEFORE STELLAR CALL TO VUMPS_SPEC'
if redpar.debug gt 1 then STOP
;STELLAR SPECTRA REDUVUMPSN (RED)
	FOR i=0,nrec-1 do begin
	   redpar.seqnum = recnums[i]
     	VUMPS_SPEC,prefix,spfnames[i],outfnames[i],redpar, orc, xwid=xwid, flat=ff, /cosmics
     ENDFOR
end;reduce_vumps.pro
