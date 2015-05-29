;+
;
;  NAME: 
;     make_vumps_solar_spectrum
;
;  PURPOSE: 
;   
;
;  CATEGORY:
;      VUMPS
;
;  CALLING SEQUENCE:
;
;      make_vumps_solar_spectrum
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
;      make_vumps_solar_spectrum
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-28T17:05:46
;
;-
pro make_vumps_solar_spectrum, $
postplot = postplot, $
halpha = halpha, $
nad = nad

angstrom = '!6!sA!r!u!9 %!6!n'
!p.color=0
!p.background=255
loadct, 39, /silent
usersymbol, 'circle', /fill, size_of_sym = 0.5
spawn, 'echo $home', mdir
mdir = mdir+'/'

if keyword_set(nad) then begin
	fnhgh = '/tous/vumps/fitspec/150524/rvumps150524.1018.fits'
	imhgh = readfits(fnhgh)

	fnmed = '/tous/vumps/fitspec/150524/rvumps150524.1021.fits'
	immed = readfits(fnmed)

	fnlow = '/tous/vumps/fitspec/150524/rvumps150524.1024.fits'
	imlow = readfits(fnlow)

	ord = 48

	if keyword_set(postplot) then begin
	   fn = nextnameeps('nad_vumps')
	   thick, 2
	   ps_open, fn, /encaps, /color
	endif
	plot, imhgh[0,1000:1600,ord], imhgh[1,1000:1600,ord]/max(imhgh[1,1000:1600,ord]), $
	/xsty, xtitle='Wavelength [A]', ytitle='Normalized Flux'

	oplot, immed[0,1000:1600,ord], immed[1,1000:1600,ord]/max(immed[1,1000:1600,ord]), col=70

	oplot, imlow[0,1000:1600,ord], imlow[1,1000:1600,ord]/max(imlow[1,1000:1600,ord]), col=250

	items = ['High Resolution', 'Medium Resolution', 'Low Resolution']

	al_legend, items, colors=[0, 70, 250], linestyle=[0,0,0]

	if keyword_set(postplot) then begin
	   ps_close
	endif
	stop
endif

if keyword_set(halpha) then begin
	
	;restore images if they have not already been restored for
	;the Na D plot:
	imsize = size(imhgh)
	if imsize[0] ne 3 then begin
		fnhgh = '/tous/vumps/fitspec/150524/rvumps150524.1018.fits'
		imhgh = readfits(fnhgh)

		fnmed = '/tous/vumps/fitspec/150524/rvumps150524.1021.fits'
		immed = readfits(fnmed)

		fnlow = '/tous/vumps/fitspec/150524/rvumps150524.1024.fits'
		imlow = readfits(fnlow)
	endif
	ord = 58
	xmin = 2700
	xmax = 3500

	if keyword_set(postplot) then begin
	   fn = nextnameeps('halpha_vumps')
	   thick, 2
	   ps_open, fn, /encaps, /color
	endif
	plot, imhgh[0,xmin:xmax,ord], imhgh[1,xmin:xmax,ord]/max(imhgh[1,xmin:xmax,ord]), $
	/xsty, xtitle='Wavelength [A]', ytitle='Normalized Flux'

	oplot, immed[0,xmin:xmax,ord], immed[1,xmin:xmax,ord]/max(immed[1,xmin:xmax,ord]), col=70

	oplot, imlow[0,xmin:xmax,ord], imlow[1,xmin:xmax,ord]/max(imlow[1,xmin:xmax,ord]), col=250

	items = ['High Resolution', 'Medium Resolution', 'Low Resolution']

	al_legend, items, colors=[0, 70, 250], linestyle=[0,0,0], /right

	if keyword_set(postplot) then begin
	   ps_close
	endif
	stop
endif

filename = '/tous/vumps/fitspec/150524/rvumps150524.1020.fits'
im = readfits(filename)
wav = reform(im[0,*,*])
spec = reform(im[1,*,*])

;get the dimensions of the spectrum:
specsz = size(spec)

;number of pixels in the dispersion direction
ndsprsn = specsz[1]

;number of orders:
nord = specsz[2]

if keyword_set(postplot) then begin
	fn = nextnameeps('vumps_solar')
	thick, 2
	xsize = 4
	ysize = 4
	ps_open, fn, /encaps, /color, inxsize=xsize, inysize=ysize, /inches
endif else begin
	;now create a window to display the spectrum in:
	window, 1, xpos=200, ypos=200, xsize=1100, ysize=1100
endelse

;
; Use a dummy plot to determine the plot region, establish device variables,
;	and determine the aspect ratio.
;
Plot, [0,1], /NoData, XStyle=4, YStyle=4, /NoErase

dev_x_range = !X.Window * !D.X_VSize	;window range in device
dev_y_range = !Y.Window * !D.Y_VSize	; coordinates
dev_x_width = dev_x_range(1) - dev_x_range(0) + 1
dev_y_width = dev_y_range(1) - dev_y_range(0) + 1
dev_aspect = dev_x_width / dev_y_width	;device aspect (width/height)
winsz = [2, !D.X_VSize, !D.Y_VSize]

print, 'x range: ', dev_x_range
print, 'y range: ', dev_y_range
print, 'x width: ', dev_x_width
print, 'y width: ', dev_y_width
print, 'winsz: ', winsz
;calculate the height of each order, leaving a space for a buffer:
bottom_padding = 20
order_padding = 1
ordhgt = floor((winsz[2] - (nord - order_padding) - bottom_padding)/nord)

;now loop through orders plotting to display:
for ord=0, nord-1 do begin

	;interpolate the spectrum in the x direction to have the same
	;number of pixels as the display:
	orderout = interpol(spec[*,ord], winsz[1])

	;now interpolate the wavelengths for color:
	wavout = interpol(wav[*,ord], winsz[1])

	;now convert this to rgb:
	rgb = intarr(3, winsz[1], 2)
	
	;now get an rgb value for each pixel in the order:
	for i=0, winsz[1]-1 do begin
		rgb[*,i,0] = wavelength_to_rgb(wavout[i] / 10.)*255. * orderout[i]/max(orderout)
		;stop
	endfor
	
	for row=0, ordhgt-1 do begin
		tv, rgb, 0, $
		bottom_padding + row + ord*(ordhgt + order_padding), $
		xsize = !D.X_VSize, $
		ysize = 1, $
		true=1, /device
	endfor;loop through order height
	;stop
endfor ;loop through orders

if keyword_set(postplot) then begin
   ps_close
endif

stop
end;make_vumps_solar_spectrum.pro