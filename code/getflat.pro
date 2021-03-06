;+
;
;  NAME: 
;     getflat
;
;  PURPOSE: 
;   To extract the master flat-field and divide by the flat model to
;	create a normalized flat.
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;      flat = getflat(sum, orc, xwid, redpar, im_arr=im_arr)
;
;  INPUTS:
;		IM: summed flat-field image
;		ORC: The order locations
;		XWID: the extraction width
;
;  OPTIONAL INPUTS:
;
;  OUTPUTS:
;		the extracted and normalized flat field [pixels,orders,3]
;		plane 1: flat plane 2: extracted quartz, plane 3: smoothed orders
;
;  OPTIONAL OUTPUTS:
;
;  KEYWORD PARAMETERS:
;    
;  EXAMPLE:
;      getflat
;
;  MODIFICATION HISTORY:
;		 -CHIRON version Oct 24, 2011 AT
;			added redpar and plotting options. 20120412~MJG
;			incorporated weighting to get a better smoothed order 20120510~MJG
;			20150518 adapted to VUMPS
;        - improved docs, added blues MJ Giguere 2015-06-04T19:44:22
;
;-
function getflat, im, orc, xwid, redpar, $
im_arr=im_arr, $
blue_flat=blue_flat

!p.multi=[0, 1, 1]

order = 8 ; polynomial order
threshold = 1d-4 ; min. signal relative to max in each order
;getsky,im,orc,sky = sky   ; subtract scattered light  
if keyword_set(im_arr) then imarrsz = size(im_arr)  ; imarrsz[3] is the number of observations

;combine blues summed flat with normal summed flat
;based on the order locations:
if redpar.blues_flat then begin
	loadct, 0, /silent
	display, blue_flat, min=1, max=7d4, /log
	;get the dimensions of the order location 2D array:
	orcsz = size(orc)
	bluesz = size(blue_flat)
	imsz = size(im)
	if bluesz[1] ne imsz[1] then stop, 'Warning! The red flats and blue flats do not have the same dimensions!'
	if bluesz[2] ne imsz[2] then stop, 'Warning! The red flats and blue flats do not have the same dimensions!'
	;the number of echelle orders extracted:
	nords = orcsz[2]
	xarr = dindgen(bluesz[1])
	yarr = poly(xarr, orc[*,redpar.blues_flat_ord])
	loadct, 39, /silent
	plot, blue_flat[bluesz[1]/2, *], /xsty
	oplot, xarr, yarr, col=250
	combined_flat = im * 0d

	;the sigmoid steepness (how quickly it goes from 1 to zero:
	sig_stp = 1d-2

	;create array of midpoints:
	sig_midpt = yarr

	for col=0, bluesz[1]-1 do begin
		print, col
		decay_function = 1d - 1d /(1d + sig_stp * exp(-sig_stp*(dindgen(imsz[2]) - sig_midpt[col])))	
		combined_flat[col, *] = decay_function * blue_flat[col,*] + im[col,*]
		if redpar.debug ge 10 then begin
			plot, combined_flat[col,*], /xsty, yrange=[0, 6.5d4]
			wait, 0.05
		endif;redpar.debug
	endfor
	im = combined_flat
endif;redpar.blues_flat


if redpar.flatnorm le 1 then begin
	getspec, im, orc, xwid, sp, redpar=redpar   ; extract im to flat [npix,nord]
	sz = size(sp) & ncol = sz[1] & nord = sz[2]
	flat = fltarr(ncol,nord,3) ; flat, smoothed flat, flat/sm
	smflt = fltarr(ncol,nord)                  ;intialize smoothed flat
	ix = findgen(ncol) ; argument for polynomial
endif; flatnorm le 1


if redpar.debug ge 2 then stop

if redpar.debug ge 1 and redpar.debug le 2 then begin
  fdir = redpar.plotsdir + 'flats/'
  spawn, 'mkdir '+fdir
  fdir = redpar.plotsdir + 'flats/' + redpar.date
  spawn, 'mkdir '+fdir
  fdir = redpar.plotsdir + 'flats/' + redpar.date +'/'+redpar.resolutionarr[redpar.resolutionidx]
  spawn, 'mkdir '+fdir
  fname = nextnameeps(fdir+'/'+'flats')
  ps_open, fname, /encaps, /color
  !p.font=1
  !p.multi=[0,2,3]
endif;debug plots

if redpar.flatnorm le 1 then begin
for j = 0, nord-1 do begin      ;row by row polynomial
	s = sp[*, j]          
	strong = where(s ge threshold*max(s), nstrong) ; strong signal
	if nstrong lt order+1 then stop, 'GETFLAT: No signal, stopping'
	cf = poly_fit(ix[strong],s[strong],order, yfit=yfit) 
	ss1 = poly(ix,cf)

	;now mask out extremely bad regions that affect the fit (e.g. the debris 
	;at the center of the chip):
	stronger = where(s ge 0.8*ss1)
	cf2 = poly_fit(ix[stronger],s[stronger],order, yfit=yfit) 
	ss = poly(ix,cf2)

	;	  ss = median(s, medwidth)       ;median smooth the orders
	; zeroes = where (ss eq 0., nz)  ;make sure we don-t divide by 0
	; if nz ne 0 then ss[zeroes] = 1.       
	smflt[*, j] = ss              ; build smoothed flat

	;I tried implementing CONTF since the continuum fit with poly is clearly affected by 
	;low regions where there are artefacts on the CCD, but I can't quite get contf working 
	;as well as poly, so I'll comment it out for now. ~20120504 MJG
	;contf, s, ssc, nord=6, frac=0.5, sbin=30
	;stop
	if redpar.debug ge 1 then begin
		plot, ix, s, li=1, title='Order '+strt(j), /xsty, /nodata
		oplot, ix, s, li=1, color=50
		oplot, ix, ss
		loadct, 39, /silent
		oplot, ix[stronger], yfit, color=250
		print, j
		x1 = 0.2*n_elements(s)
		x2 = 0.7*n_elements(s)
		y1 = 0.1*max(ss)
		y2 = y1
		xyouts, x1, y1, '(N!dADU!n)!u1/2!n: '+strt(sqrt(max(ss)), f='(F8.1)')
		
		;calculate an empirical SNR at blaze peak:
		xmin = round(n_elements(ix)/2 - 0.05 * n_elements(ix))
		xmax = round(n_elements(ix)/2 + 0.05 * n_elements(ix))
		emp_snr = mean(s[xmin:xmax]/ss[xmin:xmax])/stddev(s[xmin:xmax]/ss[xmin:xmax])
		xyouts, x2, y2, greek('mu')+'/'+greek('sigma')+': '+strt(emp_snr, f='(F8.1)')
		if redpar.debug ge 10 then stop
	endif;debug > 0
	if redpar.debug ge 1 and redpar.debug le 2 then begin
		if j mod 6 eq 5 then begin
		ps_close
		print, 'fname is: ', fname
		spawn, 'convert -density 200 '+fname+'.eps '+fname+'.png'
		fname = nextnameeps(fdir+'/'+'flats')
		ps_open, fname, /encaps, /color
		!p.font=1
		!p.multi=[0,2,3]
	endif
endif;debug plots
endfor
if redpar.debug ge 1 and redpar.debug le 2 then begin 
  ps_close
  print, 'fname is: ', fname
  spawn, 'convert -density 200 '+fname+'.eps '+fname+'.png'
endif;psplot
endif;flatnorm le 1

;divide by median smoothed flat to remove low frequencies
if redpar.flatnorm le 1 then tmp = sp/smflt  
;do not let the flat set weird values; they-re prob. cosmics.
j = where(tmp lt 0.1 or tmp gt 10, nneg)
if nneg gt 0 then tmp[j] = 1.              
flat[*,*,0] = tmp
flat[*,*,1] = sp
flat[*,*,2] = smflt

if redpar.debug ge 2 then stop ; debugging 
return, flat
end;getflat.pro
