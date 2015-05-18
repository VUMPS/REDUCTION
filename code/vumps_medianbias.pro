;+
;
;  NAME: 
;     vumps_medianbias
;
;  PURPOSE: 
;    To create and store median bias frames for the various modes for 
;	 bias subtraction
;
;  CATEGORY:
;      CHIRON
;
;  CALLING SEQUENCE:
;
;      vumps_medianbias
;
;  INPUTS:
;
;  OPTIONAL INPUTS:
;
;  OUTPUTS:
;
;  KEYWORD PARAMETERS:
;    
;  EXAMPLE:
;      vumps_medianbias, redpar = redpar, log = log, /bin11, /normal, framearr = framearr
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015.05.17 8:32:39 PM
;
;-

pro vumps_medianbias, $
help = help, $
postplot = postplot, $
redpar = redpar, $
bin11 = bin11, $
bin31 = bin31, $
slow = slow, $
medium = medium, $
fast = fast, $
bobsmed = bobsmed, $
framearr = framearr

if keyword_set(bin31) then binsz='31'
if keyword_set(bin11) then binsz='11'
if keyword_set(medium) then rdspd = 'medium'
if keyword_set(fast) then rdspd = 'fast'

;locate Bias OBServations (bobs):
bobs = framearr
bobsct = n_elements(framearr)
fnbase = redpar.rootdir + redpar.rawdir + redpar.date + '/' + redpar.prefix
print, fnbase

bcube = dblarr(long(redpar.xdim), long(redpar.ydim), bobsct)

for i=0, bobsct-1 do begin
	biasim = double(readfits(fnbase + framearr[i] + redpar.suffix, hd))

	geom = chip_geometry(hdr=hd)

	;1. subtract median value from upper left quadrant (both image and overscan region):
	idx = [geom.ccd_full.upleft[0], geom.ccd_full.upleft[1], geom.ccd_full.upleft[2], geom.ccd_full.upleft[3]]
	biasim[idx[0]:idx[1], idx[2]:idx[3]] -= $
	median(biasim[geom.bias_trim.upleft[0]:geom.bias_trim.upleft[1], geom.bias_trim.upleft[2]:geom.bias_trim.upleft[3]])

	;2. now do the same for the upper right quadrant:
	idx = [geom.ccd_full.upright[0], geom.ccd_full.upright[1], geom.ccd_full.upright[2], geom.ccd_full.upright[3]]
	biasim[idx[0]:idx[1], idx[2]:idx[3]] -= $
	median(biasim[geom.bias_trim.upright[0]:geom.bias_trim.upright[1], geom.bias_trim.upright[2]:geom.bias_trim.upright[3]])

	;3. and the bottom left quadrant:
	idx = [0L, geom.ccd_full.botleft[1], geom.ccd_full.botleft[2], geom.ccd_full.botleft[3]]
	biasim[idx[0]:idx[1], idx[2]:idx[3]] -= $
	median(biasim[geom.bias_trim.botleft[0]:geom.bias_trim.botleft[1], geom.bias_trim.botleft[2]:geom.bias_trim.botleft[3]])

	;4. now the bottom right:
	idx = [geom.ccd_full.botright[0], geom.ccd_full.botright[1], geom.ccd_full.botright[2], geom.ccd_full.botright[3]]
	biasim[idx[0]:idx[1], idx[2]:idx[3]] -= $
	median(biasim[geom.bias_trim.botright[0]:geom.bias_trim.botright[1], geom.bias_trim.botright[2]:geom.bias_trim.botright[3]])

	;now save the bias image to a cube:
	bcube[*,*,i] = biasim
endfor

bobsmed = median(bcube, /double, dimen=3)


fname = redpar.rootdir+redpar.biasdir+redpar.date+'_bin'+binsz+'_'+rdspd+'_medbias.dat'
stop
save, bobsmed, filename=fname
print, 'Median bias frome filename saved as: ', fname
end;vumps_medianbias.pro