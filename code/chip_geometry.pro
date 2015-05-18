;+
;
;  NAME: 
;     chip_geometry
;
;  PURPOSE: 
;   
;
;  CATEGORY:
;      CHIRON
;
;  CALLING SEQUENCE:
;
;      chip_geometry
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
;      chip_geometry
;
;  MODIFICATION HISTORY:
;        c. Matt Giguere 2015-05-17T20:49:15
;		based on the routine of the same name for CHIRON.
;
;-
function biasTrim, inBias
	return, [ $
		long(inBias[0]) + 3, $ ; col start
		long(inBias[1]) - 3, $ ; col end
		long(inBias[2]), $ ; row start
		long(inBias[3]) $ ; row end
	]
end;biasTrim subroutine

function chip_geometry, $
file_name, $
redpar=redpar, $
hdr = hdr

;create the boiler-plate structure to return:
results = { 				$
	status: 'error', 		$
	controller: 'unknown',	$
	ccd: 'unknown',    $
	amps: ['upleft','upright', 'botleft', 'botright'], $
	bias_trim: {upleft: [0,0,0,0], upright: [0,0,0,0], botleft: [0,0,0,0], botright: [0,0,0,0]},		$
	bias_full: {upleft: [0,0,0,0], upright: [0,0,0,0], botleft: [0,0,0,0], botright: [0,0,0,0]},		$
	image_trim: {upleft: [0,0,0,0], upright: [0,0,0,0], botleft: [0,0,0,0], botright: [0,0,0,0]},	$
	image_full: {upleft: [0,0,0,0], upright: [0,0,0,0], botleft: [0,0,0,0], botright: [0,0,0,0]},	$
	ccd_full: {upleft: [0,0,0,0], upright: [0,0,0,0], botleft: [0,0,0,0], botright: [0,0,0,0]},	$
	gain:	{upleft: 0.0, upright: 0.0, botleft: 0.0, botright: 0.0},					$
	read_noise: {upleft: 0.0, upright: 0.0, botleft: 0.0, botright: 0.0}, 				$
	bin: { row: 1,	col: 1 },								$
	readout_speed: 'unknown'    $
}


;NOW UPDATE WITH THE VUMPS/ARC/E2V-SPECIFIC SPECS:
; many of these keys are not currently in the FITS headers, but they will be...
; using the ARC controller with the 4K e2v detector
results.controller = 'ARC'
results.ccd = '201 (e2v 4k, 15micron)'
keys = { $
	amplist: 'AMPLIST',		$
	bias: 'BSEC',			$
	ccd_full: 'SCSEC',      $
	image_full: 'DSEC',		$
	image_trim:	'TSEC',		$
	gain: 'GAIN',			$
	read_noise: 'RON',		$
	bin: 'CCDSUM'			$
}
results.readout_speed = 'normal'
amps = { upleft: '21', upright: '22' , botleft: '11', botright: '12' }
validAmpList = '11 12 21 22' ; we could be off if we use a different arrangement of amps

results.bias_trim.upleft = [2047, 2096, 2056, 4111]
results.bias_trim.upright = [2103, 2152, 2056, 4111]
results.bias_trim.botleft = [2047, 2096, 0, 2055]
results.bias_trim.botright = [2103, 2152, 0, 2055]

results.bias_full.upleft = [2044, 2099, 2056, 4111]
results.bias_full.upright = [2100, 2155, 2056, 4111]
results.bias_full.botleft = [2044, 2099, 0, 2055]
results.bias_full.botright = [2100, 2155, 0, 2055]

results.image_trim.upleft = [0, 2043, 2056, 4111]
results.image_trim.upright = [2156, 4199, 2056, 4111]
results.image_trim.botleft = [0, 2043, 0, 2055]
results.image_trim.botright = [2156, 4199, 0, 2055]

results.image_full.upleft = [0, 2043, 2056, 4111]
results.image_full.upright = [2156, 4199, 2056, 4111]
results.image_full.botleft = [0, 2043, 0, 2055]
results.image_full.botright = [2156, 4199, 0, 2055]

results.ccd_full.upleft = [0, 2099, 2056, 4111]
results.ccd_full.upright = [2100, 4199, 2056, 4111]
results.ccd_full.botleft = [0, 2099, 0, 2055]
results.ccd_full.botright = [2100, 4199, 0, 2055]

results.gain.upleft = 2.06
results.gain.upright = 2.03
results.gain.botleft = 1.99
results.gain.botright = 2.00

medium_rn = { $
	upleft:   4.0,  $
	botleft:  3.7, $
	upright:  4.1, $
	botright: 3.9 $
}
	      
results.read_noise.upleft = medium_rn.upleft
results.read_noise.upright = medium_rn.upright
results.read_noise.botleft = medium_rn.botleft
results.read_noise.botright = medium_rn.botright

results.status = 'OK'
return, results
end;chip_geometry.pro