;+
;
;  NAME: 
;     getimage
;
;  PURPOSE: 
;   To restore a VUMPS image and properly subtract the bias and return only the
;	on sky pixels, NOT the overscan or trim regions.
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;
;      getimage
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
;      getimage
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-18T12:35:47
;		based on the CHIRON getimage routine
;
;-
function getimage, filename, redpar, header=header, geom=geom

if redpar.debug gt 2 then print, filename

if ~file_test(filename) then begin 
	print, 'File '+filename+' was not found'
	return, 0
endif

im = double(readfits(filename,header))

;get CCD geometry (e.g. overscan region, quadrant regions):
if ~keyword_set(geom) then geom = chip_geometry(name, hdr=header, redpar=redpar)

;check to make sure chip_geometry correctly returned pars:
if (geom.status ne 'OK') then begin
	print, 'chip geometry did not return the correct parameters for '+filename
	return, 0
endif

;If the median bias frame option is set in vumps.par use this method:
if redpar.biasmode eq 0 then begin
   rdspd = geom.readout_speed
   if strt(sxpar(header, 'CCDSUM')) eq '1 1' then binsz = '11'
   
   ;HARDCODE THIS IN FOR VUMPS FOR NOW:
   binsz = '11'
   
   fname = redpar.rootdir+redpar.biasdir+redpar.date+'_bin'+binsz+'_'+strt(rdspd)+'_medbias.dat'
   restore, fname
   
   ;First subtract the median overscan from each quadrant. This part floats 
   ;around over the course of the night, but the substructure doesn't change:
   
   ;1. subtract median value from overscan regions in the upper left
   ; quadrant from the FULL upper left quadrant:
   idx = geom.ccd_full.upleft
   bidx = geom.bias_trim.upleft
   for i=idx[2], idx[3] do im[idx[0]:idx[1], i] -= median(im[bidx[0]:bidx[1], i])
   
   ;2. now do the same for the upper right quadrant:
   idx = geom.ccd_full.upright
   bidx = geom.bias_trim.upright
   for i=idx[2], idx[3] do im[idx[0]:idx[1], i] -= median(im[bidx[0]:bidx[1], i])
   
   ;3. and the bottom left quadrant:
   idx = geom.ccd_full.botleft
   bidx = geom.bias_trim.botleft
   for i=idx[2], idx[3] do im[idx[0]:idx[1], i] -= median(im[bidx[0]:bidx[1], i])
   
   ;4. now the bottom right:
   idx = geom.ccd_full.botright
   bidx = geom.bias_trim.botright
   for i=idx[2], idx[3] do im[idx[0]:idx[1], i] -= median(im[bidx[0]:bidx[1], i])
   ;now subtract the median bias frame:

   im = im - bobsmed
   print, 'GETIMAGE: SUBTRACTED MEDIAN BIAS FRAME:'
   print, fname
endif

imupleft = im[geom.image_trim.upleft[0]:geom.image_trim.upleft[1],geom.image_trim.upleft[2]:geom.image_trim.upleft[3]]
biasupleft = im[geom.bias_trim.upleft[0]:geom.bias_trim.upleft[1],geom.bias_trim.upleft[2]:geom.bias_trim.upleft[3]]
gainupleft = geom.gain.upleft

imupright = im[geom.image_trim.upright[0]:geom.image_trim.upright[1],geom.image_trim.upright[2]:geom.image_trim.upright[3]]
biasupright = im[geom.bias_trim.upright[0]:geom.bias_trim.upright[1],geom.bias_trim.upright[2]:geom.bias_trim.upright[3]]
gainupright = geom.gain.upright

imbotleft = im[geom.image_trim.botleft[0]:geom.image_trim.botleft[1],geom.image_trim.botleft[2]:geom.image_trim.botleft[3]]
biasbotleft = im[geom.bias_trim.botleft[0]:geom.bias_trim.botleft[1],geom.bias_trim.botleft[2]:geom.bias_trim.botleft[3]]
gainbotleft = geom.gain.botleft

imbotright = im[geom.image_trim.botright[0]:geom.image_trim.botright[1],geom.image_trim.botright[2]:geom.image_trim.botright[3]]
biasbotright = im[geom.bias_trim.botright[0]:geom.bias_trim.botright[1],geom.bias_trim.botright[2]:geom.bias_trim.botright[3]]
gainbotright = geom.gain.botright

ron2 = [variance(biasupleft), variance(biasupright), variance(biasbotleft), variance(biasbotright)] ; estimate of readout noise
redpar.ron = sqrt(mean(ron2))  ; readout noise in ADU

if redpar.biasmode eq 1 then begin
; If the median overscan option is set in vumps.par, then subtract the bias using this method:
	szimupl=size(imupleft)  &   szbupl=size(biasupleft) 
	if szimupl[2] ne szbupl[2] then stop, 'BIAS and image have different number of lines!' 
	for k=0,szimupl[2]-1 do imupleft[*,k] = imupleft[*,k]- median(biasupleft[*,k])

	szimupr=size(imupright)  &   szbupr=size(biasupright) 
	if szimupr[2] ne szbupr[2] then stop, 'BIAS and image have different number of lines!' 
	for k=0,szimupr[2]-1 do imupright[*,k] = imupright[*,k]- median(biasupright[*,k])

	szimbotl=size(imbotleft)  &   szbbotl=size(biasbotleft) 
	if szimbotl[2] ne szbbotl[2] then stop, 'BIAS and image have different number of lines!' 
	for k=0,szimbotl[2]-1 do imbotleft[*,k] = imbotleft[*,k]- median(biasbotleft[*,k])

	szimbotr=size(imbotright)  &   szbbotr=size(biasbotright)
	if szimbotr[2] ne szbbotr[2] then stop, 'BIAS and image have different number of lines!' 
	for k=0,szimbotr[2]-1 do imbotright[*,k] = imbotright[*,k]- median(biasbotright[*,k])
endif

case geom.readout_speed of
	'fast': readout_speed_index = 0
	'medium': readout_speed_index = 1
	'slow': readout_speed_index = 2
endcase

gains = redpar.gains[*,readout_speed_index]

;store the gain for only the lower left amp:
redpar.gain = gains[0]

if redpar.debug ge 2 then begin 
   print, 'READ OUT SPEED IS: ', geom.readout_speed
   print, 'BINNING: ', geom.bin.row, geom.bin.col
   print, 'RON noise [upleft,upright, botleft, botright]: ', sqrt(ron2)
endif

gainupleft=gains[3]    & gainupleft = gainupleft[0]
gainupright=gains[2]   & gainupright = gainupright[0]
gainbotleft=gains[0]   & gainbotleft = gainbotleft[0]
gainbotright=gains[1]  & gainbotright = gainbotright[0]

imupleft=imupleft*gainupleft
imupright=imupright*gainupright
imbotleft=imbotleft*gainbotleft
imbotright=imbotright*gainbotright

im=[[imbotleft, imbotright],[imupleft, imupright]]  ; join the four parts

; Trim the image?
sz = size(im)
if (redpar.xtrim[0] eq 0) and (redpar.xtrim[1] eq 0) then xtrim=[0,sz[1]-1] else xtrim=redpar.xtrim/geom.bin.row 
if (redpar.ytrim[0] eq 0) and (redpar.ytrim[1] eq 0) then ytrim=[0,sz[2]-1] else ytrim=redpar.ytrim/geom.bin.col 
im = im[xtrim[0]:xtrim[1], ytrim[0]:ytrim[1]]

; remember the binning in redpar
redpar.binning = [geom.bin.row, geom.bin.col]

;im=rotate(im,1) 
if redpar.debug ge 11 then stop		

return, im

end
  

