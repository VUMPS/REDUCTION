;+
;	NAME: SORTING_HAT
;
;	PURPOSE: To sort files according to binning and slit pair with ThAr
;				to run reduction code for extraction
;
; Resolutions for the sorting hat: 
; 	hgh: high resolution mode
;	med:  medium resolution mode
;	low: low resolution mode
;
; KEYWORDS:
;
;	OPTIONAL KEYWORDS: 
;  
;	REDUCE: runs reduce_ctio (reduce and get thar soln before running iod2fits)
;          if running reduce, need to pass in array of flats
;
;  IOD2FITS: matches thar solutions to correct observations and writes 
;				in fits format skip is an array of obnm that don-t need 
;				fits files skip=['2268'] thar_soln is the wavelength array
;				soln (if a matching thar not taken this night)
;
;  END_CHECK: checks to see that all 3x1 binned observations with input slit have been
;             reduced (iodspec), fits (fitspec), thar_soln
;
;	EXAMPLES: 
;		sorting_hat, '150516', image_prefix='vumps150516', /low, /reduce
;  
; MODIFICATION HISTORY:
;		-created 2015.05.17 Matt Giguere, based on CHIRON reduction code
;-
;
pro sorting_hat, date, $
image_prefix=image_prefix, $
iod2fits=iod2fits, $
reduce=reduce, $
end_check=end_check, $
thar_soln=thar_soln, $
getthid=getthid, $
resolution = resolution, $
obsnm=obsnm, $
flatsonly=flatsonly, $
tharonly=tharonly

angstrom = '!6!sA!r!u!9 %!6!n'
vmpsparfn = -1
spawn, 'pwd', pwddir
case pwddir of
   '/Users/matt/projects/VUMPS/REDUCTION/code': vmpsparfn = '/Users/matt/projects/VUMPS/REDUCTION/code/vumps.par'
endcase

;if the present working directory is not included in the above CASE
;statement, and therefore `vmpsparfn` is not defined, alert the user:
if size(vmpsparfn, /type) eq 2 then begin
  print, '******************************************************'
  print, 'You must be running things from a different directory.'
  print, 'Your current working directory is: '
  print, pwddir
  print, 'ctparfn has not set. '
  print, 'Either changed your working directory, or modify the case'
  print, 'statement above this line.'
  print, '******************************************************'
  stop
endif
redpar = readpar(vmpsparfn)
redpar.imdir = date+'/'  ; pass night into redpar
redpar.date = date
redpar.versiond=systime()
redpar.prefix = image_prefix

print, 'SORTING_HAT: date '+date+' run: '+image_prefix

;   Modes keyword
if ~keyword_set(resolution) then begin 
    print, 'Image resolution is not defined. Returning from sorting_hat'
    return
endif

resolutionidx = (where(resolution eq redpar.resolutionarr))[0]

;update the parameter structure with the current resolution:
redpar.resolutionidx = resolutionidx

if resolutionidx lt 0 then begin
    print, 'Error: unrecognized resolution. Returning from sorting_hat'
    return
 endif

logpath = redpar.logdir+'20'+strmid(date, 0, 2)+'/'
redpar.logdir=logpath
logsheet = redpar.rootdir+logpath+date+'.log'

iodspec_path = redpar.rootdir+redpar.iodspecdir+redpar.imdir
fits_path = redpar.rootdir+redpar.fitsdir+redpar.imdir

; if the nightly fitspec directory does not exist, create it:
if ~file_test(fits_path) then spawn, 'mkdir '+fits_path

thid_path = redpar.rootdir+redpar.thiddir
thid_path2 = redpar.rootdir+redpar.thidfiledir

;prepend output reduced files with this additional prefix:
redpre = redpar.red_prefix

;read in the logsheet for the night:
readcol,logsheet, skip=9, obnm, objnm, mdpt, exptm, slit, f='(a,a,a,a,a,)'

print, 'obnm after is: ', obnm
ut = gettime(mdpt) ; floating-point hours, >24h in the morning

;**************************************************************
;REDUCING THE DATA:	
;**************************************************************
if keyword_set(reduce) then begin
	;only grab images in the current slit mode (low, med, or hgh):
	xsl=where(slit eq redpar.resolutionarr[resolutionidx],n_exps)
	if n_exps gt 0 then begin

	;reduce the object number and name arrs to the subset in the current resolution:
	obnm1=obnm[xsl]
	objnm1=objnm[xsl]

	;CREATE MEDIAN BIAS FRAME
	;only create the median bias if option is set in vumps.par:
	if redpar.biasmode eq 0 then begin
		;create the median bias frames if need be:
		fname = redpar.rootdir+redpar.biasdir+$
		redpar.date+'_bin11_medium_medbias.dat'
		print, 'Now testing median bias frame filename: ', fname 
		if ~file_test(fname) then begin
			print, '1x1 binning with medium read speed...'
			vumps_medianbias, redpar = redpar, framearr = obnm[where(objnm eq 'bias')], /medium, /bin11
		endif;~file_test(fname)
	endif

	;IDENTIFY FLAT FRAMES
	flatindx=where(objnm1 eq 'quartz',num_flat)
	if num_flat gt 0 then begin
		flatset = obnm1[flatindx]
		print, 'flat frames are: ', flatset
	endif else begin
		print, 'Sorting-hat: no flat files found. Returning.'
		return
	endelse

	;IDENTIFY THAR AND I2 FRAMES
	thariodindx=where(objnm1 eq 'thar' or objnm1 eq 'iodine',num_thariod)

	print, '******************************'
	print, 'THORIUM ARGON AND IODINE OBSERVATIONS TO BE PROCESSED: '
	print, obnm1[thariodindx]
	thar = fix(obnm1[thariodindx])

	starindx=where(objnm1 ne 'iodine' and objnm1 ne 'thar' $
	and objnm1 ne 'focus' and objnm1 ne 'junk' and objnm1 ne 'dark' $
	and objnm1 ne 'bias', num_star)

	if keyword_set(flatsonly) then starindx = where(objnm1 eq 'quartz')                               
	if keyword_set(flatsonly) then thar = 0
	star = fix(obnm1[starindx]) ; file numbers
	if keyword_set(obsnm) then star = obsnm
	if keyword_set(tharonly) then star = 0

	if redpar.debug ge 2 then print, 'Sorting-HAT: before calling reduce_vumps'
	;REDUCE ALL FRAMES
	reduce_vumps, redpar, resolution, flatset=flatset, star=star, thar=thar, date=date
	endif ;n_exps > 0
endif  ;reduce

stop

;**************************************************************
; ******* ThAr processing *******************	
;**************************************************************
 if keyword_set(getthid) then begin
		xsl=where(bin eq redpar.binnings[resolutionidx] and slit eq redpar.resolutionarr[resolutionidx],n_exps)

   if n_exps gt 0 then begin
	   obnm1=obnm[xsl]  &   objnm1=objnm[xsl]  
	   tharindx=where(objnm1 eq 'thar',num_thar)
	   print, '******************************'
	   print, 'THORIUM ARGON TO BE PROCESSED: '
	   print, obnm1[tharindx]
	   thar = obnm1[tharindx] ; string array
	   stop

	   if keyword_set(thar_soln) then thidfile =  thid_path2+thar_soln+'.thid' else begin 
		  if strmid(run,0,2) eq 'qa' then begin 
			 findthid, date, redpar, thidfile,run=run 
		  endif else  findthid, date, redpar, thidfile
		  if thidfile eq 'none' or thidfile eq '' then begin 
			 print, 'No previous THID files found, returning. Type ".c"'
			 stop
		  endif 
	   endelse ; thar_soln  

	   print, 'Initial THID file: '+thidfile
	   restore, thidfile
	   initwvc = thid.wvc 

	   print, 'Ready to go into AUTOTHID'   
	   !p.multi=[0,1,1]
	   for i=0,num_thar-1 do begin 
		  isfn = iodspec_path+redpre+run+thar[i]
		  print, 'ThAr file to fit: ', isfn
		  rdsk, t, isfn,1
		  ;NEW, AUTOMATED WAY OF DOING THINGS:
		  print, 'ThAr obs is: ', thar[i], ' ', strt((1d2*i)/(num_thar-1),f='(F8.2)'),'% complete.'
		  ;stop

		  rawfn = redpar.rootdir+redpar.rawdir+redpar.imdir+'/'+run+thar[i]+'.fits'
		  header = headfits(rawfn)
		  if strt(fxpar(header, 'COMPLAMP')) ne 'TH-AR' then begin
			 print, 'WARNING! NO TH-AR LAMP IN FOR: '
			 print, rawfn
			 print, 'TYPE THE IDL COMMAND: '
			 print, "chi_junk, date='"+redpar.date+"', seqnum='"+thar[i]+"', reason = 'No ThAr Lamp.', /chi_q, /log"
			 print, 'TO GET RID OF IT.'
			 stop
		  endif else begin
			 auto_thid, t, initwvc, 6., 6., .8, thid, awin=10, maxres=4, /orev
			 ;for fiber, narrow and regular slit modes:
			 ;thid, t, 64., 64.*[8797d,8898d], wvc, thid, init=initwvc, /orev 
			 ;for slicer mode:
			 ;thid, t, 65., 65.*[8662.4d,8761.9d], wvc, thid, init=initwvc, /orev 
			 
			 if thid.nlin lt 700d then begin
			   print, 'CRAPPY FIT TO THE THAR! INTERVENTION NEEDED!'
			   print, 'ONLY '+strt(thid.nlin)+' GOOD LINES FOUND!'
			   stop
			 endif
			 
			 fnm = thid_path2+redpre+run+thar[i]
			 fsuf = '.thid'
			 if file_test(fnm+fsuf) then spawn, $
			 'mv '+fnm+'.thid '+nextname(fnm,fsuf)
			 save, thid, file=fnm+fsuf

			 mkwave, w, thid.wvc
			 w = reverse(w,2) ; increase with increasing order numver
			 fnm = thid_path+'ctio_'+redpre+run+thar[i]
			 fsuf = '.dat'
			 if file_test(fnm+fsuf) then spawn, $
			 'mv '+fnm+'.dat '+nextname(fnm,fsuf)
			 save, w, file=fnm+fsuf
		  endelse
	   endfor
	endif;n_exps > 0
endif ; getthid

;**************************************************************
;******* Write FITS files for reduced data ************
; from the input logsheet, find all observations matching the selected mode
;**************************************************************
if keyword_set(iod2fits) then begin
     x1=where(bin eq redpar.binnings[resolutionidx] and slit eq redpar.modes[resolutionidx] $
	     and objnm ne 'junk' and objnm ne 'dark' $
            and objnm ne 'focus' and objnm ne 'bias',n_found)
 
     tharindx=where((objnm eq 'thar') and (bin eq redpar.binnings[resolutionidx]) and (slit eq redpar.resolutionarr[resolutionidx]),  num_thar)
;     if x1[0] lt 0 or num_thar eq 0 then stop, 'Sorting_hat: no matching observations or ThAr for iod2fits. Stop'
if ( (n_found gt 0) and (num_thar gt 0)) then begin

      print,'Number of '+resolutionidx+' observations: ',n_found
      print, 'ThAr files: ', obnm[tharindx]
 
;  thar file is defined on input?
    if keyword_set(thar_soln) then begin
           restore, thid_path2+thar_soln+'.thid' ; thid structure
            mkwave, w, thid.wvc
            w = reverse(w,2) ; increase with increasing order number    
       endif else begin             
; get all wavelength solutions for this date and this mode,e UT of ThAr exposures 
;       wavfiles = thid_path+'ctio_'+run+obnm[tharindx]+'.dat' ; string array of wavelength solution file names  
         thidfiles = thid_path2+redpre+run+obnm[tharindx]+'.thid' ; string array of wavelength solution file names  
         ;stop
         wavut = ut[tharindx] ; time of ThAr exposures
; check existence of wavelength solutions, stop if not found
        for k=0,num_thar-1 do begin
            res = file_search(thidfiles[k], count=count)
            if count eq 0 then stop, 'Missing THID file '+ thidfiles[k]
        endfor 

         restore, thidfiles[0] ; w, first solution of the night
         mkwave, w, thid.wvc
         w = reverse(w,2) ; increase with increasing order numver
         ww = dblarr(num_thar,n_elements(w[*,0]),n_elements(w[0,*]))
         ww[0,*,*] = w
         for k=1,num_thar-1 do begin ; all other solutions in ww array
           restore, thidfiles[k]
           mkwave, w, thid.wvc
           w = reverse(w,2) ; increase with increasing order numver
           ww[k,*,*] = w
         endfor
    endelse ;thar_soln 

     for i=0,n_found-1 do begin	
			obnm[i]=strtrim(obnm[x1[i]])
			nxck=0
			if keyword_set(skip) then xck=where(obnmx1[[i]] eq skip,nxck) 
			if nxck eq 0 then begin
				rdsk,sp,iodspec_path+redpre+run+obnm[x1[i]],1   
				rdsk,hd,iodspec_path+redpre+run+obnm[x1[i]],2   
				sz=size(sp)  &   ncol=sz[1]    &    nord=sz[2]
				spec=fltarr(2,ncol,nord)
            if ~keyword_set(thar_soln) then begin ; find closest ThAr
                      ut0 = ut[x1[i]]
                      timediff = abs(ut0 - wavut)
                      sel = (where(timediff eq min(timediff)))[0]  
                      w = ww[sel,*,*]
                      ;save the ThAr filename to write
                      ;to the FITS header a few lines later:
                      thidfile_name = thidfiles[sel]
             endif
                ;the zeroth dimension of spec is the wavelength solution:
				spec[0,*,*]=w
				;the first dimension of spec is the actual spectrum:
				spec[1,*,*]=sp
				outfile=redpre+run+obnm[i]+'.fits'
				;*******************************************************
				;now to add reduction code info to fits headers:
				;*******************************************************
				;the number of tags in the redpar structure:
				nt = n_tags(redpar)
				tnms = string(tag_names(redpar), format='(A-8)')
				endhd = hd[-1]
				hd = hd[0:n_elements(hd)-2]
				for ii=0, nt-1 do begin
				  ;print, 'line: ', i
				  remlen = 78 - strlen(tnms[ii]+' = ')
				  vals = redpar.(ii)
				  val = strt(vals[0])
				  for j=1, n_elements(vals)-1 do begin
					 val += ', '+strt(vals[j])
					 print, 'j is: ', j, 'val is now: ', val
				  endfor
					 hd = [hd, tnms[ii]+'= '+"'"+string(val+"'", format='(A-'+strt(remlen)+')')]
				endfor
				hd = [hd, string('THARFNAM', format='(A-8)')+'= '+"'"+string(thidfile_name+"'", format='(A-'+strt(remlen)+')')]
				hd = [hd,endhd]
				
				;now change the NAXIS and NAXISn values to reflect the reduced data:
				specsz = size(spec)
				fxaddpar, hd, 'NAXIS', specsz[0], 'Number of data axes'
				fxaddpar, hd, 'NAXIS1', specsz[1], 'Axis 1 length: 0=wavelength, 1=spectrum'
				fxaddpar, hd, 'NAXIS2', specsz[2], 'Axis 2 length: extracted pixels along each echelle order'
				fxaddpar, hd, 'NAXIS3', specsz[3], 'Axis 3 length: number of echelle orders extracted'
				fxaddpar, hd, 'RESOLUTN', thid.resol, 'Resolution determined from the ThAr.'
				fxaddpar, hd, 'THIDNLIN', thid.nlin, 'Number of ThAr lines used for wav soln.'
				
				print, 'now writing: ', outfile, ' ', strt(i/(n_found - 1d)*1d2),'% complete.'
				writefits,fits_path+outfile, spec,hd
				
			   if redpar.debug ge 1 and redpar.debug le 2 then begin
				 fdir = redpar.plotsdir + 'fits/'
				 spawn, 'mkdir '+fdir
				 fdir = redpar.plotsdir + 'fits/' + redpar.date
				 spawn, 'mkdir '+fdir
				 fdir = fdir + '/halpha'
				 spawn, 'mkdir '+fdir
				 fname = fdir+'/'+'halpha'+redpar.prefix+obnm[i]
				 if file_test(fname+'.eps') then spawn, 'mv '+fname+'.eps '+nextnameeps(fname+'_old')+'.eps'
				 ps_open, fname, /encaps, /color
				 !p.multi=[0,1,1]
			   endif;debug plot fname and dirs
			   
			   if redpar.debug ge 1 then begin
				 ;only plot if debug is greater than 0:
				 plot, spec[0,*,39], spec[1,*,39], /xsty, /ysty, $
				 xtitle='Wavelength['+angstrom+']', ytitle='Flux', $
				 title=outfile, yran=[0,1.1*max(spec[1,*,39])]
			   endif;debug plotting
			   if redpar.debug ge 1 and redpar.debug le 2 then begin
				 ps_close
				 spawn, 'convert -density 200 '+fname+'.eps '+fname+'.png'
			   endif ;ps_close & png
			endif
     endfor  ;  iod2fits
     endif; num_thar and n_found > 0
  endif ;iod2fits

;**************************************************************
; ******* END-CHECK *********************
;THE END CHECK TO MAKE SURE EVERYTHING HAS BEEN PROCESSED:
;**************************************************************
 if keyword_set(end_check) then  begin
	x1=where(bin eq redpar.binnings[resolutionidx] and slit eq redpar.resolutionarr[resolutionidx] and objnm ne 'quartz',n_check)
        if x1[0] lt 0 then begin
          print, 'Sorting_hat: no files found! returning'
          return
        endif

        	for k=0,n_check-1 do begin
			if objnm[x1[k]] eq 'thar' then begin
				fthar=file_search(thid_path+'*'+obnm[x1[k]]+'*',count=thar_count)
				if thar_count eq 0 then print, objnm[x1[k]]+' '+obnm[x1[k]]+' has no ThAr soln '
			endif else begin
				fiod=file_search(iodspec_path+'*'+obnm[x1[k]]+'*',count=iod_count)
				if iod_count eq 0 then print, objnm[x1[k]]+' '+obnm[x1[k]]+'  has no iodspec'
				
				ffits=file_search(fits_path+'*'+obnm[x1[k]]+'*',count=fits_count)
				if fits_count eq 0 then print, objnm[x1[k]]+' '+obnm[x1[k]]+'  has no fitspec'
			endelse 
		endfor       
      endif ; end_check
end ;sorting_hat.pro
