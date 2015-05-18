;+
;
;  NAME: 
;     vumps_dord
;
;  PURPOSE: 
;		Wrapper routine to call on FORDS. FORDS in turn determines
;		the order locations for a given spectrograph setting. 
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;      vumps_dord, ordfname, redpar, orc,ome, image=image
;
;  INPUTS:
;   ORDFNAME   (input string) Filename of FITS file to be used for order finding
;   REDPAR      parameter structure. Current mode is passed there.
;   IMAGE      optional image to use for order location, e.g. summed flat
;
;  OPTIONAL INPUTS:
;
;  OUTPUTS:
;     ORC  (array (# coeffs , # orders))] coefficients from the
;          polynomial fits to the order peaks.
;     OME  (optional output vector (# orders))] each entry gives the mean of the
;           absolute value of the difference between order locations and the polynomial
;           fit to these locations.
;
;  OPTIONAL OUTPUTS:
;
;  KEYWORD PARAMETERS:
;    
;  EXAMPLE:
;      vumps_dord, 'my_high_snr_exposure.fits', redpar, orc, ome
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-18T14:31:16
;		based on the CHIRON reduction code
;
;-
pro vumps_dord, ordfname, redpar, orc,ome, image=image

if n_params() lt 3 then begin
  print,'syntax: vumps_dord,ordfname, redpar,orc[,ome].'
  retall
end

print,'VUMPS_DORD: Entering routine.'

; read order-location image from the disk
if ~keyword_set(image) then begin
	image = getimage(ordfname, redpar, header=head)  
	if (size(image))[0] lt 2 then begin
		print, 'VUMPS_DORD: Image is not found. Returning from all'
		retall
	endif
endif

swid = 32

;find order location coeffs
fords,image,swid,orc, ome, redpar

  return
end
