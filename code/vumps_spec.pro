;+
;
;  NAME: 
;     vumps_spec
;
;  PURPOSE: 
;		To read in images, extract the spectrum, divide by flat.
;   
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;
;      vumps_spec
;
;  INPUTS:
;
;    PREFIX (input string)   prefix of all file names (i.e., 'qa11.' for qa11.nnnn.fits)
;        to all observations made with a particular spectrograph setting. 
;        The following files are expected to exist:
;	 * prefix.sum - Summed flat field (from addwf.pro)
;	 * prefix.ord - default order location coefficients (from VUMPS_dord)
;    SPFNAME  (input string) filename of given observation.
;    OUTFNAME (input string) complete path and filename of wdsk-d output.
;    REDPAR   global parameter structure
;    ORC order location coefficients
;    NOSKY (flag) Throw flag to supress sky subtraction.  Use for ThAr
;        images or to speed things up if sky subtraction (which is
;        actually a scattered light subtraction) should not be
;        performed.  Do not combine this flag with cosmics, which
;        requires a good bg subtraction
;    COSMICS (flag) Throw this flag to initiate cosmic ray removal.
;
;  OPTIONAL INPUTS:
;
;  OUTPUTS:
;
;OUTPUT
;   The following file may be created by VUMPS_spec:
;	  * spfname.ord - order location coefficients, if they were determined
;         OUTFNAME is the path and filename of the output, reduced spectrum.
;         OUTFNAME.opt -- optimally extracted spectrum from the cosmic
;                         ray removal algorithm.
;
;  OPTIONAL OUTPUTS:
;
;  KEYWORD PARAMETERS:
;    
;  EXAMPLE:
;      vumps_spec
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-18T16:15:43
;		adapted from CHIRON reduction code
;
;-
pro vumps_spec, $
prefix, $
spfname, $
outfname, $
redpar, $
orc, $
xwid=xwid, $
flat=flat, $
nosky=nosky, $
cosmics=cosmics

DEBUG=redpar.debug

if n_params() lt 5 then begin
  print,'syntax: VUMPS_spec,prefix,spfname,outfname,redpar,orc[,thar[,nosky]]'
  retall
endif

print,''
print,'VUMPS_SPEC: Entering routine.'
; cancel previous erros 
CATCH, /CANCEL

print,'spfname=',spfname

; Read the image file
im = getimage(spfname, redpar, header=head)  
if (size(im))[0] lt 2 then begin
print, 'Image is not found. Returning from VUMPS_SPEC.'
stop
endif

sz = size(im)		
ncol = sz[1]				;# columns in image
nrow = sz[2]				;# rows in image
szf = size(flat)		

if keyword_set(flat) then begin
ncolf = szf[1]				;# columns in image
nrowf = szf[2]				;# rows in image
if ncol ne ncolf  then begin
  print, 'VUMPS_SPEC: HALT! Your image is not the same size as your flat!'
  stop
endif;im and flat not equal dimensions
endif;KW(flat)

;OLD SCHOOL WAY OF FLAT FIELDING:
  if keyword_set(flat) and redpar.flatnorm eq 2 then spec = im/flat 

;EXTRACT SPECTRUM
if not keyword_set(thar) then begin
	getspec, im, orc, xwid, spec, sky=sky, $
			 cosmics=cosmics, optspec=optspec, $
			 diff=replace, gain=redpar.gain, ron=redpar.ron, $
			 redpar = redpar
endif else begin
  ; ThAR - no cosmic removal
	getspec,im,orc,xwid,spec, gain=redpar.gain, ron=redpar.ron, $
	redpar = redpar
endelse

;save the original spec
spec_o = spec

if redpar.debug ge 1 then begin
print, '***********************************************'
print, 'RIGHT BEFORE FLAT-FIELDING...'
print, '***********************************************'
if redpar.debug gt 1 then stop
endif

if redpar.debug ge 2 then stop
; flat-field correction
  if keyword_set(flat) and redpar.flatnorm le 1 then spec = double(spec)/flat else print, 'VUMPS_SPEC: WARNING: no flat-field correction!'
i=0
specsz = size(spec)
nords = specsz[2]

!p.multi=[0, 1, 3]
if redpar.debug ge 1 and redpar.debug le 2 then begin
  fdir = redpar.plotsdir + 'extracts/'
  spawn, 'mkdir '+fdir
  fdir = redpar.plotsdir + 'extracts/' + redpar.imdir
  spawn, 'mkdir '+fdir
  fdir = redpar.plotsdir + 'extracts/' + redpar.imdir + redpar.seqnum
  spawn, 'mkdir '+fdir
endif;debug plots

for i=0, nords-1 do begin
  if redpar.debug ge 1 and redpar.debug le 2 then begin
	 fname = fdir+'/'+redpar.prefix+redpar.seqnum+'_Ord'+strt(i)
	 if file_test(fname) then spawn, 'mv '+fname+' '+nextnameeps(fname+'_old')
	 ps_open, fname, /encaps, /color
  endif;debug plots
  
  if redpar.debug ge 1 then begin
	plot, spec_o[*,i], title=redpar.prefix+redpar.seqnum+' Order '+strt(i)+' Extracted', /xsty, /ysty, ytitle='Flux'
	if keyword_set(flat) then begin
		plot, flat[*,i], title=redpar.date+' '+redpar.resolutionarr[redpar.resolutionidx]+' Mode Order '+strt(i)+' Flat', /xsty, /ysty, ytitle='Flux'
	endif else begin
		plot, spec_o[*,i], /nodata
	endelse
	plot, spec[*,i], title=redpar.prefix+redpar.seqnum+' Order '+strt(i)+' Spec/Flat', /xsty, /ysty, $
	xtitle='Dispersion Direction [pix]', ytitle='Flux'
	xmid = where(spec[*,i] eq max(spec[*,i]))
	spec_center = spec[(xmid - 0.005*specsz[1]):(xmid + 0.005*specsz[1]), i]
	sqrtcts = sqrt(median(spec_center))
	xyouts, 0.2, 0.2, '(N!dADU!n)!u1/2!n: '+strt(sqrtcts, f='(F8.1)'), /normal
	meansig = mean(spec_center)/stddev(spec_center)
	xyouts, 0.7, 0.2, greek('mu')+'/'+greek('sigma')+': '+strt(meansig, f='(F8.1)'), /normal
  endif
  
  if redpar.debug ge 1 and redpar.debug le 2 then begin
	 ps_close
	 spawn, 'convert -density 200 '+fname+'.eps '+fname+'.png'
  endif
endfor

;YOU'RE GOING TO WANT TO INCLUDE THESE PLOTS!!
print,'VUMPS_SPEC: Saving extracted spectrum to ' + outfname
spec=rotate(spec,2)
spec[where(spec lt 0)] = 0d
sxaddpar, head, 'BSCALE', 1.
sxaddpar, head, 'BZERO', 0.
sxaddpar, head, 'BITPIX', -64



writefits, outfname, spec, head
;wdsk,spec,outfname,1,/new			;write image to disk
;wdsk,head,outfname,2


; DEBUG
;   plot, intspec[*,0]
;   tvscl, congrid(intspec,n_elements(intspec[*,0], 8*n_elements(intspec[0,*]))
;   stop, 'VUMPS-SPEC DEBUG: spectrum plot'

return
end;vumps_spec.pro
