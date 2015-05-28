device, true=24
device, retain=2, decomposed=0

;usersym, cos(findgen(32*!pi*2/32.)), sin(findgen(32*!pi*2/32.)), /fill             

;DEVICE, SET_CHARACTER_SIZE=[9,12]
;Window, XSIZE=1, YSIZE=1, xpos = 275, /pixmap, /free
!p.background =255
!p.color = 0
;loadct, 39, /silent
;Run 1 window to get rid of the stupid IDL white window:
;window, xsize=1,ysize=1, /pixmap, /free
;wdelete, !D.Window
plot, findgen(50)
!p.color=0
winup, /all
Print, 'Your IDL startup file was executed on ', systime()

;Modify the Path:
;See your .cshrc file for the definition of the path. 
   
