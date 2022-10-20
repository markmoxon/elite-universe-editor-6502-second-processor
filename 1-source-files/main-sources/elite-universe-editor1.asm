\ ******************************************************************************
\
\ ELITE UNIVERSE EDITOR (PART 1)
\
\ The Universe Editor is an extended version of BBC Micro Elite by Mark Moxon
\
\ The original 6502 Second Processor Elite was written by Ian Bell and David
\ Braben and is copyright Acornsoft 1985
\
\ The original BBC Master Elite was written by Ian Bell and David Braben and is
\ copyright Acornsoft 1986
\
\ The extra code in the Universe Editor is copyright Mark Moxon
\
\ The code on this site is identical to the source discs released on Ian Bell's
\ personal website at http://www.elitehomepage.org/ (it's just been reformatted
\ to be more readable)
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ******************************************************************************

\ ******************************************************************************
\
\       Name: CheckShiftCtrl
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Check for SHIFT and CTRL
\
\ ******************************************************************************

.CheckShiftCtrl

 STZ shiftCtrl          \ We now test for SHIFT and CTRL and set bit 7 and 6 of
                        \ shiftCtrl accordingly, so zero the byte first

IF _6502SP_VERSION

 JSR CTRL               \ Scan the keyboard to see if CTRL is currently pressed,
                        \ returning a negative value in A if it is

ELIF _MASTER_VERSION

IF _SNG47

 JSR CTRL               \ Scan the keyboard to see if CTRL is currently pressed,
                        \ returning a negative value in A if it is

ELIF _COMPACT

 JSR CTRLmc             \ Scan the keyboard to see if CTRL is currently pressed,
                        \ returning a negative value in A if it is

ENDIF

ENDIF

 BPL P%+5               \ If CTRL is being pressed, set bit 7 of shiftCtrl
 SEC                    \ (which we will shift into bit 6 below)
 ROR shiftCtrl

IF _6502SP_VERSION

 LDX #0                 \ Call DKS4 with X = 0 to check whether the SHIFT key is
 JSR DKS4               \ being pressed

ELIF _MASTER_VERSION

IF _SNG47

 LDA #0                 \ Call DKS4 to check whether the SHIFT key is being
 JSR DKS4               \ pressed

ELIF _COMPACT

 LDA #0                 \ Call DKS4mc to check whether the SHIFT key is being
 JSR DKS4mc             \ pressed

ENDIF

ENDIF

 CLC                    \ If SHIFT is being pressed, set the C flag, otherwise
 BPL P%+3               \ clear it
 SEC

 ROR shiftCtrl          \ Shift the C flag into bit 7 of shiftCtrl, moving the
                        \ CTRL bit into bit 6, so we now have SHIFT and CTRL
                        \ captured in bits 7 and 6 of shiftCtrl

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ConvertFile
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Convert the file format between platforms
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   K                   Ship number to search for
\
\   K+1                 Ship number to replace with
\
\   K+2                 How to process the ship heap addresses
\
\                         * 0 = Add &D000-&0800 to each address
\
\                         * 1 = Subtract &D000-&0800 from each address
\
\   K+3                 If non-zero, the ship number to delete
\
\ ******************************************************************************

.ConvertFile

 LDY #NOSH+1            \ Set a counter in Y to loop through all the slots

.fixb1

 LDA FRIN,Y             \ If the slot is empty, move on to the next slot
 BEQ fixb5

 CMP K+3                \ If the slot entry is not equal to the ship to delete
 BNE fixb2              \ in K+3, jump to fixb2

                        \ This ship type is not supported in this version, so we
                        \ need to clear the slot, though this will only work if
                        \ the unsupported ship is in the last slot

 LDA #0                 \ Zero the slot to delete the unsupported ship
 STA FRIN,Y

 BEQ fixb5              \ Jump to fixb5 to move on to the next slot (this BEQ is
                        \ effectively a JMP as A is always zero)

.fixb2

 CMP K                  \ If the slot entry is not equal to the search value in
 BNE fixb5              \ K, jump to fixb5

 LDA K+1                \ We have a match, so replace the slot entry with the
 STA FRIN,Y             \ replace value in K+1

 PHY                    \ Store the loop counter on the stack

 TYA                    \ Set X = Y * 2
 ASL A                  \
 TAX                    \ so we can use X as an index into UNIV for this slot

 LDA UNIV,X             \ Copy the address of the target ship's data block from
 STA V                  \ UNIV(X+1 X) to V(1 0)
 LDA UNIV+1,X
 STA V+1

 LDY #34                \ Set A = INWK+34, the high byte of the ship heap
 LDA (V),Y              \ address

 LDX K+2                \ If K+2 is zero, then jump to fixb3 to add to the heap
 BEQ fixb3              \ address

 SEC                    \ Subtract &D0-&08 from the high byte of the ship heap
 SBC #&D0-&08           \ address

 JMP fixb4              \ Jump to fixb4 to skip the following

.fixb3

 CLC                    \ Add &D0-&08 to the high byte of the ship heap address
 ADC #&D0-&08

.fixb4

 STA (V),Y              \ Update the high byte of the ship heap address

 PLY                    \ Retrieve the loop counter from the stack

.fixb5

 DEY                    \ Decrement the counter

 BPL fixb1              \ Loop back until all X bytes are searched

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: RotateShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Rotate ship in space
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The first vector to rotate:
\
\                         * If X = 15, rotate roofv_x
\                                      then roofv_y
\                                      then roofv_z
\
\                         * If X = 21, rotate sidev_x
\                                      then sidev_y
\                                      then sidev_z
\
\   Y                   The second vector to rotate:
\
\                         * If Y = 9,  rotate nosev_x
\                                      then nosev_y
\                                      then nosev_z
\
\                         * If Y = 21, rotate sidev_x
\                                      then sidev_y
\                                      then sidev_z
\
\   RAT2                The direction of the pitch or roll to perform, positive
\                       or negative (i.e. the sign of the roll or pitch counter
\                       in bit 7)
\
\ ******************************************************************************

.RotateShip

 PHX                    \ Store X and Y on the stack
 PHY

 JSR MVS5               \ Rotate vector_x by a small angle

 PLA                    \ Retrieve Y from the stack and add 2 to point to the
 TAY                    \ next axis
 INY
 INY

 PLA                    \ Retrieve X from the stack and add 2 to point to the
 TAX                    \ next axis
 INX
 INX

 PHX                    \ Store X and Y on the stack
 PHY

 JSR MVS5               \ Rotate vector_y by a small angle

 PLA                    \ Retrieve Y from the stack and add 2 to point to the
 TAY                    \ next axis
 INY
 INY

 PLA                    \ Retrieve X from the stack and add 2 to point to the
 TAX                    \next axis
 INX
 INX

 JSR MVS5               \ Rotate vector_z by a small angle

 JSR TIDY               \ Call TIDY to tidy up the orientation vectors, to
                        \ prevent the ship from getting elongated and out of
                        \ shape due to the imprecise nature of trigonometry
                        \ in assembly language

 JMP DrawShip+3         \ Draw the ship (but not on the scanner) and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: HideBulbs
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Hide both dashboard bulbs
\
\ ******************************************************************************

.HideBulbs

 BIT showingBulb        \ If bit 6 of showingBulb is set, then we are showing
 BVC P%+5               \ the station bulb, so call SPBLB to remove it
 JSR SPBLB

 BIT showingBulb        \ If bit 7 of showingBulb is set, then we are showing
 BPL P%+5               \ the E.C.M. bulb, so call ECBLB to remove it
 JSR ECBLB

 STZ showingBulb        \ Zero the bulb status byte

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ShowBulbs
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Show both dashboard bulbs according to the ship's INWK settings
\
\ ******************************************************************************

.ShowBulbs

 JSR HideBulbs          \ Hide both bulbs

 LDA INWK+36            \ Fetch the "docking" setting from bit 4 of INWK+36
 AND #%00010000         \ (NEWB)
 BEQ bulb1

 LDA #%01000000         \ Set bit 6 of showingBulb
 STA showingBulb

 JSR SPBLB              \ Show the S bulb

.bulb1

 LDA INWK+32            \ Fetch the E.C.M setting from bit 1 of INWK+32
 AND #%00000001
 BEQ bulb2

 LDA showingBulb        \ Set bit 7 of showingBulb
 ORA #%10000000
 STA showingBulb

 JSR ECBLB              \ Show the E bulb

.bulb2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ResetShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Reset the position of the current ship
\
\ ******************************************************************************

.ResetShip

 JSR MV5                \ Draw the current ship on the scanner to remove it

 LDA #26                \ Modify ZINF so it only resets the coordinates and
 STA ZINF+1             \ orientation vectors (and keeps other ship settings)

 JSR ZINF               \ Reset the coordinates and orientation vectors

 LDA #NI%-1             \ Undo the modification
 STA ZINF+1

 JSR InitialiseShip     \ Initialise the ship coordinates

 JMP DrawShip           \ Draw the ship and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: ChangeValue
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Update one of the ship's details
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Offset of INWK byte within INWK block
\
\   A                   The minimum allowed value + 1
\
\   Y                   The maximum allowed value + 1
\
\ ******************************************************************************

.ChangeValue

 STA P                  \ Store the minimum value in P

 STY K                  \ Store the maximum value in K

 BIT shiftCtrl          \ If SHIFT is being held, jump to chan1 to reduce the
 BMI chan1              \ value

 INC INWK,X             \ Increment the value at the correct offset

 LDA INWK,X             \ If we didn't go past the maximum value, jump to
 CMP K                  \ StoreValue to store the value
 BNE StoreValue

 DEC INWK,X             \ Otherwise decrement the value again so we don't
                        \ overflow

 JMP chan2              \ Jump to chan2 to beep and return from the subroutine

.chan1

 DEC INWK,X             \ Decrement the value at the correct offset

 LDA INWK,X             \ If we didn't go past the miniumum value, jump to
 CMP P                  \ StoreValue to store the value
 BNE StoreValue

 INC INWK,X             \ Otherwise increment the value again so we don't
                        \ underflow

.chan2

 JMP BEEP               \ Beep to indicate we have reached the maximum and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: StoreValue
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Store an updated ship's details and update the dashboard
\
\ ******************************************************************************

.StoreValue

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JSR UpdateDashboard    \ Update the dashboard

 RTS                    \ Return from the subroutine


\ ******************************************************************************
\
\       Name: ModifyExplosion
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Apply mods for explosions
\
\ ******************************************************************************

.ModifyExplosion

 LDA #&4C               \ Modify DOEXP so that it jumps to DrawExplosion instead
 STA DOEXP              \ to draw the cloud but without progressing it
 LDA #LO(DrawExplosion)
 STA DOEXP+1
 LDA #Hi(DrawExplosion)
 STA DOEXP+2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: RevertExplosion
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Reverse mods for explosions
\
\ ******************************************************************************

.RevertExplosion

IF _6502SP_VERSION

 LDA #&A5               \ Revert DOEXP to its default behaviour of drawing the
 STA DOEXP              \ cloud
 LDA #&64
 STA DOEXP+1
 LDA #&29
 STA DOEXP+2

ELIF _MASTER_VERSION

 LDA #&A5               \ Revert DOEXP to its default behaviour of drawing the
 STA DOEXP              \ cloud
 LDA #&BB
 STA DOEXP+1
 LDA #&29
 STA DOEXP+2

ENDIF

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ChangeSeeds
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Edit galaxy seeds
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   ForceLongRange      Show the Long-range chart after changing the seeds
\
\ ******************************************************************************

.ChangeSeeds

 LDA #8                 \ Clear the top part of the screen, draw a white border,
 JSR TRADEMODE          \ and set up a printable trading screen with a view type
                        \ in QQ11 of 8 (Status Mode screen)

 LDA #10                \ Move the text cursor to column 10
 JSR DOXC

 LDA #12                \ Print extended token 12 ("GALACTIC SEEDS{cr}{cr}")
 JSR PrintToken

 JSR NLIN4              \ Draw a horizontal line at pixel row 19 to box in the
                        \ title, and move the text cursor down one line

 LDY #&FF               \ Set maximum number for gnum to 255
 STY QQ25

 STZ V                  \ Set seed counter in V to 0

.seed1

 JSR TT67               \ Print a newline

 LDY V
 LDX QQ21,Y             \ Get seed Y

 CLC                    \ Print the 8-bit number in X to 3 digits, without a
 JSR pr2                \ decimal point

 JSR TT162              \ Print a space

 JSR gnum               \ Call gnum to get a number from the keyboard

 BEQ seed2              \ If no number was entered, skip the following to leave
                        \ this seed alone

 LDY V                  \ Store the new seed in the current galaxy seeds
 STA QQ21,Y

 STA NA%+11,Y          \ Store the new seed in the last saved commander file

.seed2

 INC V                  \ Next seed

 LDY V                  \ Loop back until all seeds are edited
 CPY #6
 BNE seed1

IF _6502SP_VERSION

 LDA #&2C               \ Disable the JSR TT110 in zZ
 STA zZ+8

ELIF _MASTER_VERSION

 LDA #&2C               \ Disable the JSR TT110 in zZ
 STA zZ+6

ENDIF

 STA jmp-3              \ Disable the JSR MESS in zZ

 JSR zZ                 \ Call the modified zZ to change galaxy

IF _6502SP_VERSION

 LDA #&20               \ Re-enable the JSR TT110 in zZ
 STA zZ+8

ELIF _MASTER_VERSION

 LDA #&20               \ Re-enable the JSR TT110 in zZ
 STA zZ+6

ENDIF

 STA jmp-3              \ Re-enable the JSR MESS in zZ

 JSR UpdateChecksum     \ Update the commander checksum to cater for the new
                        \ values

.ForceLongRange

 LDA QQ14               \ Store the current fuel level on the stack
 PHA

 LDA #70                \ Set the fuel level to 7 light years, for the chart
 STA QQ14               \ display

 STZ KL                 \ Flush the key logger

 LDA #f4                \ Jump to ForceChart, setting the key that's "pressed"
 JMP ForceChart         \ to red key f4 (so we show the Long-range Chart)

\ ******************************************************************************
\
\       Name: DrawExplosion
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Draw an explosion
\
\ ******************************************************************************

.DrawExplosion

 LDA INWK+31            \ If bit 3 of the ship's byte #31 is clear, then nothing
 AND #%00001000         \ is being drawn on-screen for this ship anyway, so
 BEQ P%+5               \ skip the following

 JSR PTCLS              \ Call PTCLS to redraw the cloud, returning from the
                        \ subroutine using a tail call

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FlipShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Flip ship around in space
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The orientation vector to flip:
\
\                         * 10 = negate nosev
\
\ ******************************************************************************

.FlipShip

 PHA

 JSR NwS1               \ Call NwS1 to flip the sign of nosev_x_hi (byte #10)

 JSR NwS1               \ And again to flip the sign of nosev_y_hi (byte #12)

 JSR NwS1               \ And again to flip the sign of nosev_z_hi (byte #14)

 PLA

 RTS

\ ******************************************************************************
\
\       Name: EraseShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Erase the current ship from the screen
\
\ ******************************************************************************

.EraseShip

 LDA INWK+31            \ If bit 5 of byte #31 is clear, then the ship is not
 AND #%00100000         \ exploding, so jump to eras1
 BEQ eras1

 JMP DrawExplosion      \ Call DrawExplosion to draw the existing cloud to
                        \ remove it, returning from the subroutine using a tail
                        \ call

.eras1

 JSR MV5                \ Draw the current ship on the scanner to remove it

 LDX TYPE               \ Get the current ship type

 LDA shpcol,X           \ Set A to the ship colour for this type, from the X-th
                        \ entry in the shpcol table

IF _6502SP_VERSION

 JSR DOCOL              \ Send a #SETCOL command to the I/O processor to switch
                        \ to this colour

ELIF _MASTER_VERSION

 STA COL                \ Switch to this colour

ENDIF

 LDA NEWB               \ Set bit 7 of the ship to indicate it has docked (so
 ORA #%10000000         \ the call to LL9 removes it from the screen)
 STA NEWB

 JMP LL9                \ Draw the existing ship to erase it and mark it as gone
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: SwitchDashboard
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Change the dashboard
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The dashboard to display:
\
\                         * 250 = the Universe Editor dashboard
\
\                         * 251 = the main game dashboard
\
\ ******************************************************************************

IF _6502SP_VERSION

.SwitchDashboard

 LDX #LO(dashboardBuff) \ Set (Y X) to point to the dashboardBuff parameter
 LDY #HI(dashboardBuff) \ block

 JMP OSWORD             \ Send an OSWORD command to the I/O processor to
                        \ draw the dashboard, returning from the subroutine
                        \ using a tail call

ENDIF

\ ******************************************************************************
\
\       Name: GETYN
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Wait until either "Y" or "N" is pressed
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Set if "Y" was pressed, clear if "N" was pressed
\
\ ******************************************************************************

IF _6502SP_VERSION

.GETYN

 JSR t                  \ Scan the keyboard until a key is pressed, returning
                        \ the ASCII code in A and X

 CMP #'y'               \ If "Y" was pressed, return from the subroutine with
 BEQ gety1              \ the C flag set (as the CMP sets the C flag)

 CMP #'n'               \ If "N" was not pressed, loop back to keep scanning
 BNE GETYN              \ for key presses

 CLC                    \ Clear the C flag

.gety1

 RTS                    \ Return from the subroutine

ENDIF

.endUniverseEditor1
