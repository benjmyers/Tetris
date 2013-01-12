


;; x86 Tetris w/o interrupts
;; Author: M Myers

assume cs:code, ds:data

code	segment

start:
	cli
	mov	ax,0b800h	;; beginning of video ram
	mov	ds,ax	;; set ES to above

;; CLEARING SCREEN
;; AX = vram address, BL = row looping value, BH = column looping value,
;; CL = multiplication buffer, CH = character, DX = 16-bit addition
	mov	bl,0	;; row value for looping
	mov	bh,0	;; column value for looping
	mov	cl,80	;; store 80 in buffer
	mov	ch,' '	;; store space in register
	mov	dx,0
columnclear:
	mov	ax,0	;; clear ax for use
	mov	dl,bh

	mov	al,bl	;; for multiplication
	mul	cl	;; row*80
	add	ax,dx	;; row*80 + column
	add	ax,ax	;; 2*(row*80 + column)
	
	mov	si,ax	;; point to vram at address ax
	mov	[si],ch	;; store space at vram address

	add	bh,1	;; increment column looping value
	cmp	bh,80	;; column looping value vs. width of window
	jl	columnclear	;; if less than, return to start of loop

rowclear:
	add	bl,1	;; increment row looping value
	mov	bh,0	;; reset column loop value
	cmp	bl,25	;; row looping value vs. length of window
	jl	columnclear	;; if less than, jump to columnclear loop

;; DRAWING ASTERISKS
;; AX = vram address, BL = row looping value, BH = column looping value,
;; CL = multiplication buffer, CH = character, DX = 16-bit addition, (DH = color)

	mov	bl,0	;; reset row looping value to 0
	mov	bh,1	;; reset column looping value to 1
	mov	cl,80	;; store 80 in buffer
	mov	ch,'*'	;; store asterisk in register
	mov	dx,0	;; clear, implicitly store color in bh (static)

columnast:
	mov	ax,0
	mov	dl,bh

	mov	al,bl	;; for multiplication
	mul	cl	;; row*80
	add	ax,dx	;; row*80 + column
	add	ax,ax	;; 2*(row*80 + column)

	mov	si,ax	;; point to vram at address ax
	mov	[si],ch	;; store asterisk at vram address
	add	si,1	;; increment address pointer
	mov	[si],dh	;; make black

	add	bh,1	;; increment column looping value
	cmp	bh,10	;; column vs. 10
	jle	columnast	;; if less than or equal to, jump to start of loop

rowast:
	add	bl,1	;; increment row looping value
	mov	bh,0	;; reset column loop value
	cmp	bl,20	;; row looping value vs. 20
	jl	columnast	;; if less than, jump to columnast loop

;; DRAWING BORDER
;; AX = vram address, BL = looping value (row for vertical, column for horizontal), 
;; CL = multiplication buffer, CH = character, DH = color

	mov	bx,0	;; reset looping value to 0
	mov	ch,'|'	;; move line into register
	mov	dh,7	;; store color in register
vertborder:
	mov	al,160	;; for left side
	mul	bl	;; 2*(r*80 + 0)

	mov	si,ax	;; point to vram at address ax
	mov	[si],ch	;; store line at vram address
	add	si,1	;; increment address by 1
	mov	[si],dh	;; make white

	mov	al,80	;; for right side
	mul	bl	;; r*80
	add	ax,11	;; r*80 + 11
	add	ax,ax	;; 2*(r*80 + 11)

	mov	si,ax	;; point to vram at address ax
	mov	[si],ch	;; store line at vram address
	add	si,1	;; increment address by 1
	mov	[si],dh	;; make white

	add	bl,1	;; increment looping value
	cmp	bl,20	;; row value vs. 20
	jl	vertborder	;; if less than, return to start of loop
	
	mov	bl,0	;; reset looping value
	mov	cl,20	;; store 20 in buffer
	mov	ch,'='	;; store underscore in register	

horizborder:	
	mov	al,80	;; for bottom
	mul	cl	;; 20*80
	add	ax,bx	;; 20*80 + c
	add	ax,ax

	mov	si,ax	;; point to vram at address ax
	mov	[si],ch	;; store underscore at address
	add	si,1	;; increment address value
	mov	[si],dh	;; make white

	add	bl,1	;; increment looping value
	cmp	bl,11	;; column value vs. 11
	jle	horizborder	;; if less than or equal to, return to start of loop

finishinit:
	call	startloop

;; SET/GET PIXEL
;; BL = row, BH = column, AL = color
;; takes from 0-9; actually from 1-10

setPixel:
	push	ax	;; backup ax on stack
	push	bx	;; backup bx on stack
	push	cx
	
	mov	ax,0	;; temporarily set ax to 0
	add	bh,1	;; offset column
	mov	cx,0

	mov	al,bl	;; move row to ax for multiplying
	mov	cx,80	;; store row offset in buffer register
	mul	cx	;; r*80
	add	al,bh	;; r*80 + c	
	mov	cx,2	;; store 2 in buffer
	mul	cx	;; 2*(r*80 + c)
	add	ax,1	;; holds color address
	
	mov	si,ax	;; point to vram at address ax
	pop	cx
	pop	bx	;; access previous bx value
	pop	ax	;; access ax from stack
	mov	[si],al	;; store color at address ax
	ret		;; return to call location

getPixel:
	push	ax
	push	bx	;; backup bx on stack
	push	cx

	mov	ax,0	;; reset ax for use
	add	bh,1	;; offset column
	mov	cx,0	
	
	mov	al,bl	;; move row to ax for multiplying
	mov	cx,80	;; store length of row in buffer
	mul	cx	;; r*80
	add	al,bh	;; r*80 + c	
	mov	cx,2	;; store 2 in buffer
	mul	cx	;; 2*(r*80 + c)
	add	ax,1	;; holds color address
	;;;;; ARE WE ACCESSING VIDEO OR DATA HERE????????????????????????
	mov	si,ax	;; point to vram address at ax
	pop	cx
	pop	bx	;; access previous bx value
	pop	ax
	mov	al,[si]	;; save color of asterisk in al

	ret		;; return to call location

;; SET PIECE
;; AL = piece address, CL = looping value, DX = address buffer
setPiece:
	push	ds
	push	cx
	push	dx
	push	ax	;; push ax to stack
	
	mov	ax,data
	mov	ds,ax
	pop	ax

	mov	si,ax	;; point to x address in si
	mov	cx,0	;; clear cx for looping
	mov	dx,0	;; clear dx for storage
	
setPieceLoop:
	mov	dl,[si]	;; move contents of address to dl
	push	dx	;; store dx on stack
	add	si,1	;; increment address

	add	cl,1	;; increment looping value
	cmp	cl,8	;; looping value vs. 8
	jl	setPieceLoop	;; if less than, return to start of loop
	
	mov	cl,0	;; reset looping value
	mov	si,offset currentpiecex	;; point to first pixel of current piece
	add	si,7	;; point to last pixel of current piece
	
setPieceContd:
	pop	dx	;; access top of stack
	mov	[si],dl	;; copy piece address to current piece
	sub	si,1	;; decrement current piece address
	
	add	cl,1	;; increment looping value
	cmp	cl,8	;; looping value vs. 8
	jl	setPieceContd	;; if less than, return to start of loop

	pop	dx
	pop	cx
	pop	ds
	ret		;; return to call location

;; SHOW/HIDE CURRENT PIECE
;; AL = piece address/ color, BL = row, BH = column, CL = looping value

showCurrentPiece:
	push	ax	;; push ax to stack
	push	bx
	push	cx
	push	ds ;; video mem

	mov	ax,data
	mov	ds,ax	
	mov	si,offset currentpiecex	;; point to address of current piece
	mov	ax,0
	mov	ax,7	;; store color (white)
	mov	cx,0	;; reset for looping
showCurrentPieceLoop:
	add	si,cx
	mov	bh,[si]	;; store column in register
	add	si,4	;; point to row
	mov	bl,[si]	;; store row in register
	
	pop	ds ;; go back to video mem

	push	ax
	mov	ax,0b800h
	mov	ds,ax
	pop	ax

	call	setPixel	;; call setPixel function
		
	push	ds
	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax
	mov	si,offset currentpiecex
	add	cx,1	;; increment looping value
	cmp	cx,4	;; looping value vs. 4
	jl	showCurrentPieceLoop	;; if less than, return to start of loop
	pop	ds
	pop	cx
	pop	bx
	pop	ax
	ret		;; return to call location

hideCurrentPiece:

	push	ax	;; push ax to stack
	push	bx
	push	cx
	push	ds ;; video mem

	mov	ax,data
	mov	ds,ax	
	mov	si,offset currentpiecex	;; point to address of current piece
	mov	ax,0
	mov	ax,0	;; store color (black)
	mov	cx,0	;; reset for looping
hideCurrentPieceLoop:
	add	si,cx
	mov	bh,[si]	;; store column in register
	add	si,4	;; point to row
	mov	bl,[si]	;; store row in register
	
	pop	ds ;; go back to video mem

	push	ax
	mov	ax,0b800h
	mov	ds,ax
	pop	ax

	call	setPixel	;; call setPixel function

	push	ds
	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax
	mov	si,offset currentpiecex
	add	cx,1	;; increment looping value
	cmp	cx,4	;; looping value vs. 4
	jl	hideCurrentPieceLoop	;; if less than, return to start of loop
	pop	ds
	pop	cx
	pop	bx
	pop	ax
	ret		;; return to call location

;; CAN THE CURRENT PIECE MOVE DOWN?
;; AL = current piece address, BL = row, BH = column, CL = looping value

canmovedown:  ;; ret 1 in al if can move, 0 if can?t
	push	bx
	push	cx
	push	ds

	mov	cx,0
	call	hidecurrentpiece
	mov	ax,data
	mov	ds,ax
canmoveloop:
	mov	ax,data
	mov	ds,ax
	mov	si,offset currentpiecex
	add	si,cx
	mov	bh,[si]
	add	si,4
	mov	bl,[si]
	add	bl,1

	push	ax
	mov	ax,0b800h
	mov	ds,ax
	pop	ax

	call	getpixel
	cmp	al,7
	je	canmovefailure
	
	add	cx,1
	cmp	cx,4
	jl	canmoveloop

	call	showcurrentpiece

	mov	al,1

	pop	ds
	pop	cx
	pop	bx
	ret
canmovefailure:	
	call	showcurrentpiece
	mov	al,0
	pop	ds
	pop	cx
	pop	bx
	ret
	
endprog2:
	jmp	finishinit

	;--------------------- GAME PLAY ---------------------
startloop:
	;piece number is now in the data seg
	push	ds	;; at this point, ds points to vram
	mov	ax,data
	mov	ds,ax
	
moveloop:
	mov	cx,0
	mov	si,offset currentpiecenum
	mov	cl,[si] 
	add	cl,1	; piecenumber ++
	cmp	cl,7	; if piecenumber > 7 reset to 0
	je	resetpiecenum
	cmp	cl,7
	jne	movepiece

resetpiecenum:
	mov	cl,1

movepiece:
	mov	[si],cl
	; si = piecenum*8 + address of pieceline
	mov	ax,8
	mul	cx
	add	ax,offset currentpiecex
	call	setpiece
	;; loop through and see if free
	push	cx ;; put cl (piece number) on stack for safe keeping
	mov	cx,0
	
freeloop:
	push	ax
	mov	ax,1234h
	pop	ax

	cmp	cx,4
	je	incrementloop

	mov	si,offset currentpiecex
	add	si,cx

	mov	bh,[si]
	add	si,4
	mov	bl,[si]

	pop	ds	;; ds now points to vram
	push	ax
	mov	ax,0b800h
	mov	ds,ax
	pop	ax
	call	getpixel
	push	ds
	;; go back to data
	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax

	cmp	al,7
	je	endprog2 ;game over
	add	si,1
	add	cx,1
	jmp	freeloop

incrementloop:
	call	canmovedown
	cmp	al,1
	jne	moveloop
	call	hidecurrentpiece

	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax

	mov	si,offset currentpiecex
	add	si,4
	mov	cx,0
addys:
	cmp	cx,4
	je	getkey
	mov	bh,[si]
	add	bh,1
	mov	[si],bh
	add	si,1
	add	cx,1
	jmp	addys

idleloop:
	cmp	ax,60000
	je	incrementloop
	add	ax,1
	jmp	idleloop

;; --------- KEY BOARD ------------
getkey:
	mov	ax,1234h

	in	al,64h	;read - is there a key?
	and	al,1
	jz	nokey	; if no key, 
	;there was a keystroke
	in	al,60h	;get the key
	cmp	al,4bh	;left?
	jz	leftkey
	cmp	al,4dh	;right?
	jz	rightkey
	
nokey:
	call clearkeybuff
	;; just go back to the loop
	call	showcurrentpiece
	jmp	idleloop
	
leftkey:
	call clearkeybuff
	;; move it left
	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax

	mov	si,offset currentpiecex
	mov	cx,0
subxs:
	cmp	cx,4
	je	incdone
	mov	bh,[si]
	sub	bh,1
	mov	[si],bh
	add	si,1
	add	cx,1
	jmp	subxs
	
rightkey:
	call clearkeybuff
	;; move it right
	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax

	mov	si,offset currentpiecex
	mov	cx,0
addxs:
	cmp	cx,4
	je	incdone
	mov	bh,[si]
	add	bh,1
	mov	[si],bh
	add	si,1
	add	cx,1
	jmp	addxs
incdone:
	call	showcurrentpiece
	jmp	idleloop
	
clearkeybuff:
	in	al,60h	;read from buffer
	in	al,64h	;read from command
	and	al,1	
	jnz	clearkeybuff
	ret	
		
code	ends

data	segment
currentpiecex  	db     	0,0,0,0
currentpiecey  	db     	0,0,0,0
piecex_line	db		5,5,5,5
piecey_line    	db     	0,1,2,3
piecex_l       	db     	5,6,7,5
piecey_l       	db     	0,0,0,1
piecex_r       	db     	5,6,7,7
piecey_r       	db     	0,0,0,1
piecex_s       	db     	5,6,6,7
piecey_s       	db     	1,1,0,0
piecex_z       	db      	5,6,6,7
piecey_z       	db     	0,0,1,1
piecex_t      	db     	5,6,7,6
piecey_t        db     	0,0,0,1
piecex_box		db		5,6,5,6
piecey_box      db     	0,0,1,1
currentpiecenum	db		0
data	ends

	end	start
