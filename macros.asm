; --------------------------------------------
; MACROS (imported where needed)
; --------------------------------------------

!source "coretables_labels.a"

; immediate_a_mod_n
; Parameters: 	a - Dividend.
;		n - Divisor [immediate]
; Return value: a
!macro immediate_a_mod_n .n {

		sec
-		sbc #.n
		bcs -
		adc #.n
}

; immediate_a_div_by_n
; Parameters: 	a - Dividend.
;		n - Divisor [immediate]
; Return value: y
!macro immediate_a_div_by_n .n {

		ldy #0
		sec
-		iny
		sbc #.n
		bcs -
		dey
}

; immediate_xa_div_by_n_16
; Parameters: 	a - Dividend low.
;               x - Dividend high.
;		n - Divisor [immediate]
; Return value: ay
!macro immediate_xa_div_by_n_16 .n {

	sta tmp		; dividend low
	stx tmp2	; dividend high

	lda #0	        ;preset remainder to 0
	sta tmp3
	sta tmp4
	ldx #16	        ;repeat for each bit: ...

-	asl tmp		;dividend lb & hb*2, msb -> Carry
	rol tmp2	;dividend+1
	rol tmp3	;remainder lb & hb * 2 + msb from carry
	rol tmp4	;remainder+1
	lda tmp3
	sec
	sbc #.n		;substract divisor to see if it fits in
	tay
	lda tmp4
	sbc #0
	bcc +		;if carry=0 then divisor didn't fit in yet

	sta tmp4
	sty tmp3	;else save substraction result as new remainder,
	inc tmp		;and INCrement result cause divisor fit in 1 times

+	dex
	bne -
	ldy tmp
	lda tmp2
}

; move_sprite_left
; Parameters: 	.sprite - sprite offset index
; 	 	.speed  - sprite pixels / frame
!macro move_sprite_left .sprite,.speed {

		lda xtablelo+.sprite
		sec
		sbc #.speed
		sta xtablelo+.sprite
		bcs +
		dec xtablehi+.sprite
+
}

; move_sprite_right
; Parameters: 	.sprite - sprite offset index
; 	 	.speed  - sprite pixels / frame
!macro move_sprite_right .sprite,.speed {

		lda xtablelo+.sprite
		clc
		adc #.speed
		sta xtablelo+.sprite
		bcc +
		inc xtablehi+.sprite
+
}

; move_sprite_up
; Parameters: 	.sprite - sprite offset index
; 	 	.speed  - sprite pixels / frame
!macro move_sprite_up .sprite,.speed {

		lda ytable+.sprite
		sec
		sbc #.speed
		sta ytable+.sprite
}

; move_sprite_down
; Parameters: 	.sprite - sprite offset index
; 	 	.speed  - sprite pixels / frame
!macro move_sprite_down .sprite,.speed {

		lda ytable+.sprite
		clc
		adc #.speed
		sta ytable+.sprite
}

; get_selected_weapon
; Destroys:	a
; Params:	none
; Returns:	a - selected weapon index
!macro get_selected_weapon {
		lda SelWeapon
}

; MACROS END
; --------------------------------------------


