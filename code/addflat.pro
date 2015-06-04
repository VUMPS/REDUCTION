;+
;
;  NAME: 
;     addflat
;
;  PURPOSE: 
;   To combine the quartz exposures to make an extracted master
;	quartz for flat-fielding. Optionally, this routine combines
;	quartz exposures of difference exposure times to get a higher
;	SNR in the blue.
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;
;      addflat
;
;  INPUTS:
;
;  OPTIONAL INPUTS:
;		bluefiles: a string array of filenames of the images to be used
;		for increasing the SNR in the blue.		
;
;  OUTPUTS:
;
;  OPTIONAL OUTPUTS:
;
;  KEYWORD PARAMETERS:
;    
;  EXAMPLE:
;      addflat
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-06-04T19:10:38
;		based on CHIRON reduction code
;
;-
pro addflat, flatfiles, sum, redpar, im_arr, $
bluefiles = bluefiles, orderlocs = orderlocs

compile_opt idl2

numwf=n_elements(flatfiles)
print, "Entering ADDFLAT routine Nflats= ",numwf

sum = 0
im = getimage(flatfiles[0], redpar, header=header) ; read the first image

if (size(im))[0] lt 2 then return ; file not found

geom = chip_geometry(flatfiles[0], hdr=header, redpar=redpar) ; returns CCD geometry in a structure 

sz = size(im)
nc=sz[1]  &  nr=sz[2]
im_arr1=dblarr(nc,nr,numwf)
im_arr1[*,*,0]=im
imnsz = size(im)
swidth = 50L
gdfltidx = dblarr(numwf)
normvalarr = 0d

ctwf=0   
fspot = 0 ;index the im array data cube
for j = 0, numwf-1 do begin
	;read in image, trim out overscan, correct for bias:
	im = getimage(flatfiles[j], redpar, header=header, geom=geom)
	if redpar.flatnorm eq 1 then begin
		;now find the median number of counts over a region of the chip
		;to make sure that flat has a high SNR:
		imswath = im[(sz[2]/2d - swidth):(sz[2]/2d + swidth),*]
		imswmed = median(imswath, dimen=1, /double)
		normval = max(imswmed)
		print,'flat #: ', strt(j),' max ADU/pixel: ', round(normval), ' minimum flat ADU/pixel: ',strt(round(redpar.minflatval))
		if normval ge redpar.minflatval then ctwf++
		if normval ge redpar.minflatval then gdfltidx[j] = 1
		if normval ge redpar.minflatval then normvalarr = [normvalarr, normval]
	endif 
	if redpar.flatnorm eq 0 then normval = 1d
	print, 'fspot is: ', fspot
	if redpar.flatnorm le 1 then im_arr1[*,*,fspot] = im/normval
    if normval ge redpar.minflatval then fspot++
endfor

;now to remove flat exposures that had too few counts:
if ctwf lt numwf then begin
  print, 'WARNING! You had flats that had too few counts! Now excluding them!'
  print, strt(ctwf)+' out of '+strt(numwf)+' are being used.'
  print, 'The flats being used are: '
  printt, flatfiles[where(gdfltidx eq 1)]
  print, 'The flats NOT being used are: '
  printt, flatfiles[where(gdfltidx ne 1)]
  stop
  im_arr = im_arr1[*,*,0:(ctwf-1)]
endif else im_arr = im_arr1

;"un-normalize" the flats:
if redpar.flatnorm eq 1 then im_arr *= mean(normvalarr[1:*])

print, 'ADDFLAT: calculating median flat...'
sum = dblarr(nc,nr)
for ncol=0,nc-1 do begin
  for nrow=0,nr-1 do begin
	 sum[ncol,nrow]=median(im_arr[ncol,nrow,*])
  endfor
endfor

;find pixels le 0, and count them
badp = where(sum le 0, nbadp)
;and set these to 1 (the mean) to make them less influential
if nbadp gt 0 then sum[badp] = 1.0

print, 'ADDFLAT: Now leaving routine.'
end;addflat.pro
