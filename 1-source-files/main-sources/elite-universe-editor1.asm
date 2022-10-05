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

IF _6502SP_VERSION

currentSlot = XSAV2     \ XSAV2 and YSAV2 are unused in the original game, so we
repeatingKey = YSAV2    \ can reuse them

keyA = &41
keyE = &22
keyK = &46
keyL = &56
keyO = &36
keyP = &37
keyQ = &10
keyR = &33
keyW = &21

keyAt = &47
keyCopy = &69
keyDelete = &59
keyDown = &29
keyEscape = &70
keyReturn = &49
keyUp = &39

ELIF _MASTER_VERSION

currentSlot = &0000     \ &0000 and &0001 are unused in the original game, so we
repeatingKey = &0001    \ can reuse them

IF _SNG47

token8 = &A49E

ELIF _COMPACT

token8 = &A495

ENDIF

OSFILE = &FFDD          \ The address for the OSFILE routine

keyA = &41              \ See TRANTABLE for key values
keyE = &45
keyK = &4B
keyL = &4C
keyO = &4F
keyP = &50
keyQ = &51
keyR = &52
keyW = &57

keyAt = &40
keyCopy = &8B
keyDelete = &7F
keyDown = &8E
keyEscape = &1B
keyReturn = &0D
keyUp = &8F

ENDIF

\ ******************************************************************************
\
\       Name: UniverseEditor
\       Type: Subroutine
\   Category: Universe editor
\    Summary: The entry point for the universe editor
\
\ ******************************************************************************

.UniverseEditor

IF _6502SP_VERSION

 LDA #&24               \ Disable the TRB XX1+31 instruction in part 9 of LL9
 STA LL74+20            \ that disables the laser once it has fired, so that
                        \ lasers remain on-screen while in the editor

ELIF _MASTER_VERSION

 LDA #&24               \ Disable the STA XX1+31 instruction in part 9 of LL9
 STA LL74+16            \ that disables the laser once it has fired, so that
                        \ lasers remain on-screen while in the editor

ENDIF

 LDA #&60               \ Disable DOEXP so that by default it draws an explosion
 STA DOEXP+9            \ cloud but doesn't recalculate it

 LDX #8                 \ The size of the default universe filename

.scen0

 LDA DefaultName,X      \ Copy the X-th character of the filename to NAME
 STA NAME,X

 DEX                    \ Decrement the loop counter

 BPL scen0              \ Loop back for the next byte of the universe filename

 LDA #0                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 0 (space
                        \ view)

 JSR SIGHT              \ Draw the laser crosshairs

 JSR RESET              \ Call RESET to initialise most of the game variables

 LDA #0                 \ Send a #SETVDU19 0 command to the I/O processor to
 JSR DOVDU19            \ switch to the mode 1 palette for the space view,
                        \ which is yellow (colour 1), red (colour 2) and cyan
                        \ (colour 3)

 JSR SOLAR              \ Add the sun, planet and stardust, according to the
                        \ current system seeds

 LDX #1                 \ Get the details for the sun from slot 1
 STX currentSlot
 JSR GetShipData

 JSR ZINF               \ Initialise the sun so it's in front of us
 JSR InitialiseShip

 LDA #%10000001         \ Set x_sign = -1, so the sun is to the left
 STA INWK+2

\ LDA INWK+8             \ Move the sun behind us
\ EOR #%10000000
\ STA INWK+8

 JSR STORE              \ Store the updated sun

 JSR LL9                \ Draw the sun

 LDX #0                 \ Get the details for the planet from slot 0
 STX currentSlot
 JSR GetShipData

 LDA #128               \ Set the planet to a meridian planet
 STA FRIN
 STA TYPE

 JSR ZINF               \ Initialise the planet so it's in front of us
 JSR InitialiseShip

 LDA #%00000001         \ Set x_sign = 1, so the planet is to the right
 STA INWK+2

 JSR STORE              \ Store the updated planet

 JSR LL9                \ Draw the planet

 LDX #0                 \ Set the current slot to 0 (planet)
 STX currentSlot

 JSR PrintSlotNumber    \ Print the current slot number at text location (0, 1)

.scen1

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 BNE scen1              \ If a key was already being held down when we entered
                        \ this routine, keep looping back up to scen1, until
                        \ the key is released

.scen2

 LDY #2                 \ Delay for 2 vertical syncs (2/50 = 0.04 seconds) to
 JSR DELAY              \ make the rate of key repeat manageable

 JSR RDKEY              \ Scan the keyboard, returning the internal key number
                        \ in X (or 0 for no key press)

 BEQ scen2              \ Keep looping up to scen2 until a key is pressed

.scen3

 JSR ProcessKey         \ Process the key press

 LDX currentSlot        \ Get the ship data for the current ship, so we know the
 JSR GetShipData        \ current ship data is always in INWK for the main loop

 LDA repeatingKey       \ Fetch the type of key press (0 = non-repeatable,
                        \ 1 = repeatable)

 BNE scen2              \ Loop back to wait for next key press (for repeatable
                        \ keys)

 BEQ scen1              \ Loop back to wait for next key press (non-repeatable
                        \ keys)

\ ******************************************************************************
\
\       Name: QuitEditor
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Quit the universe editor
\
\ ******************************************************************************

.QuitEditor

 LDA FRIN+1             \ If we are showing the station, call SPBLB to remove
 BMI P%+5               \ the space station bulb
 JSR SPBLB

IF _6502SP_VERSION

 LDA #&14               \ Re-enable the TRB XX1+31 instruction in part 9 of LL9
 STA LL74+20

ELIF _MASTER_VERSION

 LDA #&85               \ Re-enable the STA XX1+31 instruction in part 9 of LL9
 STA LL74+20

ENDIF

 LDA #&A5               \ Re-enable DOEXP
 STA DOEXP+9

 JSR DFAULT             \ Restore correct commander name to NAME

 JMP BR1                \ Quit the scene editor by returning to the start

\ ******************************************************************************
\
\       Name: keyTable
\       Type: Variable
\   Category: Universe editor
\    Summary: Movement key table for each of the four views
\
\ ******************************************************************************

.keyTable

                        \ x-plus        x-minus
                        \ z-plus        z-minus
                        \ xrot-plus     xrot-minus
                        \ zrot-plus     zrot-minus

IF _6502SP_VERSION

                        \ Front view

 EQUB &79, &19          \ Right arrow   Left arrow
 EQUB &62, &68          \ SPACE         ?
 EQUB &51, &42          \ S             X
 EQUB &67, &66          \ >             <

                        \ Rear view

 EQUB &19, &79          \ Left arrow    Right arrow
 EQUB &68, &62          \ ?             SPACE
 EQUB &51, &42          \ S             X
 EQUB &67, &66          \ >             <

                        \ Left view

 EQUB &68, &62          \ ?             SPACE
 EQUB &79, &19          \ Right arrow   Left arrow
 EQUB &51, &42          \ S             X
 EQUB &67, &66          \ >             <

                        \ Right view

 EQUB &62, &68          \ SPACE         ?
 EQUB &19, &79          \ Left arrow    Right arrow
 EQUB &51, &42          \ S             X
 EQUB &67, &66          \ >             <

ELIF _MASTER_VERSION

                        \ Front view

 EQUB &8D, &8C          \ Right arrow   Left arrow
 EQUB &20, &2F          \ SPACE         ?
 EQUB &53, &58          \ S             X
 EQUB &2E, &2C          \ >             <

                        \ Rear view

 EQUB &8C, &8D          \ Left arrow    Right arrow
 EQUB &2F, &20          \ ?             SPACE
 EQUB &53, &58          \ S             X
 EQUB &2E, &2C          \ >             <

                        \ Left view

 EQUB &2F, &20          \ ?             SPACE
 EQUB &8D, &8C          \ Right arrow   Left arrow
 EQUB &53, &58          \ S             X
 EQUB &2E, &2C          \ >             <

                        \ Right view

 EQUB &20, &2F          \ SPACE         ?
 EQUB &8C, &8D          \ Left arrow    Right arrow
 EQUB &53, &58          \ S             X
 EQUB &2E, &2C          \ >             <

ENDIF

\ ******************************************************************************
\
\       Name: ProcessKey
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Process key presses
\
\ ******************************************************************************

.ProcessKey

 LDX #1                 \ Set repeatingKey = 1 to indicate that the following
 STX repeatingKey       \ keys are repeating keys

 PHA                    \ Set Y = VIEW * 8, to act as an index into keyTable
 LDA VIEW
 ASL A
 ASL A
 ASL A
 TAY
 PLA

 LDX #0                 \ Set X = 0 for the x-axis

 CMP keyTable,Y         \ Right arrow (move ship right along the x-axis)
 BNE keys1
 LDY #0
 JMP MoveShip

.keys1

 CMP keyTable+1,Y       \ Left arrow (move ship left along the x-axis)
 BNE keys2
 LDY #%10000000
 JMP MoveShip

.keys2

 LDX #3                 \ Set X = 3 for the y-axis

 CMP #keyUp             \ Up arrow (move ship up along the y-axis)
 BNE keys3
 LDY #0
 JMP MoveShip

.keys3

 CMP #keyDown           \ Down arrow (move ship down along the y-axis)
 BNE keys4
 LDY #%10000000
 JMP MoveShip

.keys4

 LDX #6                 \ Set X = 6 for the z-axis

 CMP keyTable+2,Y       \ SPACE (move ship away along the z-axis)
 BNE keys5
 LDY #0
 JMP MoveShip

.keys5

 CMP keyTable+3,Y       \ ? (move ship closer along the z-axis)
 BNE keys6
 LDY #%10000000
 JMP MoveShip

.keys6

 CMP #keyK              \ K (rotate ship around the y-axis)
 BNE keys7

 LDX #0                 \ Rotate (sidev, nosev) by a small positive angle (yaw)
 STX RAT2
 LDX #21
 LDY #9
 JMP RotateShip

.keys7

 CMP #keyL              \ L (rotate ship around the y-axis)
 BNE keys8

 LDX #%10000000         \ Rotate (sidev, nosev) by a small negative angle (yaw)
 STX RAT2
 LDX #21
 LDY #9
 JMP RotateShip

.keys8

 CMP keyTable+4,Y       \ S (rotate ship around the x-axis)
 BNE keys9

 LDX #0                 \ Rotate (roofv, nosev) by a small positive angle
 STX RAT2               \ (pitch)
 LDX #15
 LDY #9
 JMP RotateShip

.keys9

 CMP keyTable+5,Y       \ X (rotate ship around the x-axis)
 BNE keys10

 LDX #%10000000         \ Rotate (roofv, nosev) by a small negative angle
 STX RAT2               \ (pitch)
 LDX #15
 LDY #9
 JMP RotateShip

.keys10

 CMP keyTable+6,Y       \ > (rotate ship around the x-axis)
 BNE keys11

 LDX #0                 \ Rotate (roofv, sidev) by a small positive angle
 STX RAT2               \ (pitch)
 LDX #15
 LDY #21
 JMP RotateShip

.keys11

 CMP keyTable+7,Y       \ < (rotate ship around the x-axis)
 BNE keys12

 LDX #%10000000         \ Rotate (roofv, sidev) by a small negative angle
 STX RAT2               \ (pitch)
 LDX #15
 LDY #21
 JMP RotateShip

.keys12

 LDX #0                 \ Set repeatingKey = 0 to indicate that the following
 STX repeatingKey       \ keys are non-repeating keys

 CMP #f0                \ f0 pressed (front view)
 BEQ keys13

 CMP #f1                \ f1 pressed (rear view)
 BEQ keys13

 CMP #f2                \ f2 pressed (left view)
 BEQ keys13

 CMP #f3                \ f3 pressed (right view)
 BNE keys14

.keys13

 JMP ChangeView         \ Process a change of view

.keys14

 CMP #keyO              \ O pressed (toggle station/sun)
 BNE P%+5
 JMP SwapStationSun

 CMP #keyP              \ P pressed (toggle planet type)
 BNE P%+5
 JMP TogglePlanetType

 CMP #keyReturn         \ RETURN pressed (add ship)
 BNE P%+5
 JMP AddShip

 CMP #keyW              \ W (next slot)
 BNE P%+5
 JMP NextSlot

 CMP #keyQ              \ Q (previous slot)
 BNE P%+5
 JMP PreviousSlot

 CMP #keyR              \ R (reset current ship)
 BNE P%+5
 JMP ResetShip

 CMP #keyAt             \ @ (show disc access menu)
 BNE P%+5
 JMP ShowDiscMenu

 CMP #keyEscape         \ If ESCAPE is being pressed, jump to QuitEditor to quit
 BNE P%+5               \ the universe editor
 JMP QuitEditor
                        \ The following controls only apply to ships in slots 2
                        \ and up, and do not apply to the planet, sun or station

 LDX currentSlot        \ Get the current slot number to pass to the following
                        \ routines, so they can do nothing (and give an error
                        \ beep) if this is the station or planet

 CMP #keyDelete         \ DELETE pressed (delete ship)
 BNE P%+5
 JMP DeleteShip

 CMP #keyCopy           \ COPY pressed (copy ship)
 BNE P%+5
 JMP CopyShip

 CMP #keyA              \ A (fire laser)
 BNE P%+5
 JMP FireLaser

 CMP #keyE              \ E (explode ship)
 BNE P%+5
 JMP ExplodeShip

.pkey1

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

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JMP DrawShip           \ Draw the ship and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: ChangeView
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Change view to front, rear, left or right
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   Internal key number for f0, f1, f2 or f3
\
\ Other entry points:
\
\   ChangeView+8        Change to view X, even if we are already on that view
\                       (so this redraws the view)
\
\ ******************************************************************************

.ChangeView

 AND #3                 \ If we get here then we have pressed f0-f3, so extract
 TAX                    \ bits 0-1 to set X = 0, 1, 2, 3 for f0, f1, f2, f3

 CPX VIEW               \ If we are already on this view, jump to view1 to
 BEQ view1              \ ignore the key press and return from the subroutine

                        \ Otherwise this is a new view, so set it up

 JSR LOOK1              \ Otherwise this is a new view, so call LOOK1 to switch
                        \ to view X and draw the stardust

 JSR NWSTARS            \ Set up a new stardust field (not sure why LOOK1
                        \ doesn't draw the stardust - it should)

 JSR PrintSlotNumber    \ Print the current slot number at text location (0, 1)

 JSR DrawShips          \ Draw all ships

.view1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DrawShips
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Draw all ships, planets, stations etc.
\
\ ******************************************************************************

.DrawShips

 LDX #0                 \ We count through all the occupied ship slots, from
                        \ slot 0 and up

.draw1

 LDA FRIN,X             \ If the slot is empty, return from the subroutine as
 BEQ draw2              \ we are done

 PHX                    \ Store the counter on the stack

 JSR GetShipData        \ Fetch the details for the ship in slot X

 LDA INWK+31            \ If bit 5 of byte #31 is clear, then the ship is not
 AND #%00100000         \ exploding, so jump to draw3 to skip the following
 BEQ draw3

                        \ The ship is exploding

\ LDA #&A5               \ Re-enable DOEXP
\ STA DOEXP+9

 JSR DrawShip+3         \ Draw the ship (but not on the scanner)

\ LDA #&60               \ Disable DOEXP again
\ STA DOEXP+9

 BNE draw4

.draw3

 JSR DrawShip           \ Draw the ship

.draw4

 PLX                    \ Retrieve the counter from the stack

 INX                    \ Move to the next slot

 CPX #NOSH              \ Loop back until we have drawn all the ships
 BCC draw1

.draw2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DrawShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Draw a single ship
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   DrawShip+3          Do not draw the ship on the scanner
\
\ ******************************************************************************

.DrawShip

 JSR MV5                \ Draw the ship on the scanner

 JSR PLUT               \ Call PLUT to update the geometric axes in INWK to
                        \ match the view (front, rear, left, right)

 JSR LL9                \ Draw the ship

 LDY #31                \ Fetch the ship's explosion/killed state from byte #31
 LDA INWK+31            \ and copy it to byte #31 in INF (so the ship's data in
 STA (INF),Y            \ K% gets updated)

 LDX currentSlot        \ Get the ship data for the current slot, as otherwise
 JMP GetShipData        \ we will leave the wrong axes in INWK, and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TogglePlanetType
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Toggle the planet between meridian and crater
\
\ ******************************************************************************

.TogglePlanetType

 LDX #0                 \ Switch to slot 0, which is the planet, and highlight
 JSR SwitchToSlot       \ the existing contents

 LDA TYPE               \ Flip the planet type between 128 and 130
 EOR #%00000010
 STA TYPE
 STA FRIN

 JSR STORE              \ Store the new planet details

 JMP DrawShip           \ Draw the ship and return from the subroutine using a
                        \ tail call

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
 AND #%00100000         \ exploding, so jump to eras2
 BEQ eras2

 LDA INWK+31            \ If bit 3 of byte #31 is clear, then the explosion is
 AND #%00001000         \ not already being shown on-screen, so jump to eras2
 BEQ eras1              \ to return from the subroutine

 JSR LL14               \ Call LL14 to draw the existing cloud to remove it

.eras1

 RTS                    \ Return from the subroutine

.eras2

 JSR MV5                \ Draw the current ship on the scanner to remove it

 LDY currentSlot        \ Get the current ship type
 LDX FRIN,Y

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
\       Name: SwapStationSun
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Toggle through the sun and two types of station
\
\ ******************************************************************************

.SwapStationSun

 LDX #1                 \ Switch to slot 1, which is the station or sun, and
 JSR SwitchToSlot       \ highlight the existing contents

 LDA TYPE               \ If we are showing the sun, jump to swap1 to switch it
 BMI swap1              \ to a Coriolis space station

 LDA tek                \ If we are showing a Coriolis station (i.e. tech level
 CMP #10                \ < 10), jump to swap2 to switch it to a Dodo station
 BCC swap2

                        \ Otherwise we are showing a Dodo station, so switch it
                        \ to the sun

 JSR EraseShip          \ Erase the existing space station

 JSR KS4                \ Switch to the sun, erasing the space station bulb

 JSR ZINF               \ Reset the sun's data block

 LDA #129               \ Set the type for the sun
 STA TYPE

 JSR InitialiseShip     \ Initialise the sun so it's in front of us

 JSR STORE              \ Store the updated sun

 BNE swap5              \ Jump to swap4 (this BNE is effectively a JMP as A is
                        \ never zero)

.swap1

                        \ Remove sun and show Coriolis

 JSR WPLS               \ Call WPLS to remove the sun from the screen, as we
                        \ can't have both the sun and the space station at the
                        \ same time

 LDA #1                 \ Set the tech level for a Coriolis station
 STA tek

 BNE swap4              \ Jump to swap4 (this BNE is effectively a JMP as A is
                        \ never zero)

.swap2

                        \ Switch from Coriolis to Dodo

 JSR SPBLB              \ Call SPBLB to show the space station bulb

 JSR EraseShip          \ Erase the existing space station

 LDA #10                \ Set the tech level for a Dodo station
 STA tek

.swap4

 LDA #SST               \ Set the ship type to the space station
 STA TYPE

 JSR ZINF               \ Reset the station coordinates

 JSR NWSPS              \ Add a new space station to our local bubble of
                        \ universe

\ LDX #10                \ Flip the station around nosev to reverse the flip
\ JSR FlipShip           \ that's done in NWSPS

 JSR InitialiseShip     \ Initialise the station so it's in front of us

 JSR STORE              \ Store the updated station

.swap5

 JMP DrawShip           \ Draw the ship and return from the subroutine using a
                        \ tail call

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

 JSR MV5                \ Draw the ship on the scanner to remove it

 PLY                    \ Store X and Y on the stack
 PLX
 PHX
 PHY

 JSR MVS5               \ Rotate vector_x by a small angle

 PLA                    \ Retrieve X and Y from the stack and add 2 to each of
 CLC                    \ them to point to the next axis
 ADC #2
 TAY
 PLA
 ADC #2
 TAX

 PHX                    \ Store X and Y on the stack
 PHY

 JSR MVS5               \ Rotate vector_y by a small angle

 PLA                    \ Retrieve X and Y from the stack and add 2 to each of
 CLC                    \ them to point to the next axis
 ADC #2
 TAY
 PLA
 ADC #2
 TAX

 JSR MVS5               \ Rotate vector_z by a small angle

 JSR TIDY               \ Call TIDY to tidy up the orientation vectors, to
                        \ prevent the ship from getting elongated and out of
                        \ shape due to the imprecise nature of trigonometry
                        \ in assembly language

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JMP DrawShip           \ Draw the ship and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: MoveShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Move ship in space
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Axis (0, 3, 6 for x, y, z)
\
\   Y                   Direction of movement (bit 7)
\
\ ******************************************************************************

.MoveShip

 STX K                  \ Store the axis in K, so we can retrieve it below

 STY K+3                \ Store the sign of the movement in the sign byte of
                        \ K(3 2 1)

 JSR MV5                \ Draw the ship on the scanner to remove it

 LDX #0                 \ Set the high byte of K(3 2 1) to 0
 STX K+2

IF _6502SP_VERSION

 JSR DKS4               \ Call DKS4 with X = 0 to check whether the SHIFT key is
                        \ being pressed

ELIF _MASTER_VERSION

IF _SNG47

 LDA #0                 \ Call DKS4 to check whether the SHIFT key is being
 JSR DKS4               \ pressed

ELIF _COMPACT

 LDA #0                 \ Call DKS4mc to check whether the SHIFT key is being
 JSR DKS4mc             \ pressed

ENDIF

ENDIF

 BMI move1              \ IF SHIFT is being pressed, jump to move1

 LDY #1                 \ Set Y = 1 to use as the delta and jump to move2
 BNE move2

.move1

 LDY #20                \ Set Y = 20 to use as the delta

.move2

 LDA TYPE               \ If this is the planet or sun, jump to move3
 BMI move3

 STY K+1                \ Set the low byte of K(3 2 1) to the delta
 BPL move4

.move3

 STY K+2                \ Set the high byte of K(3 2 1) to the delta

.move4

 LDX K                  \ Fetch the axis into X (the comments below are for the
                        \ x-axis)

 JSR MVT3               \ K(3 2 1) = (x_sign x_hi x_lo) + K(3 2 1)

 LDA K+1                \ Set (x_sign x_hi x_lo) = K(3 2 1)
 STA INWK,X
 LDA K+2
 STA INWK+1,X
 LDA K+3
 STA INWK+2,X

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JMP DrawShip           \ Draw the ship and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: InitialiseShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Set the coordinates and orientation for a ship just in front of us
\
\ ******************************************************************************

.InitialiseShip

                        \ This routine is called following ZINF, so the
                        \ orientation vectors are set as follows:
                        \
                        \   sidev = (1,  0,  0)
                        \   roofv = (0,  1,  0)
                        \   nosev = (0,  0, -1)

 LDA TYPE               \ If this is a ship or station, jump to init3 to set a
 BPL init3              \ distance of 2 or 5

 LDA #%10000000         \ Pitch the planet so the crater is visible (in case we
 JSR TWIST2             \ switch planet types straight away)
 LDA #%10000000
 JSR TWIST2

 LDA #2                 \ This is a planet/sun, so set A = 2 to store as the
                        \ sign-byte distance

 LDX VIEW               \ If this is the left or right view, jump to init1
 CPX #2
 BCC init1

 STA INWK+2             \ This is the front or rear view, so set x_sign = 2

 BCS init2              \ Jump to init2 (this BCC is effectively a JMP as we
                        \ just passed through a BCS)

.init1

 STA INWK+8             \ This is the left or right view, so set z_sign = 2

.init2

 LDA #0                 \ Set A = 0 to store as the high-byte distance for the
                        \ planet/sun

 BEQ init5              \ Jump to init5 (this BEQ is effectively a JMP as A is
                        \ always zero)

.init3

 CMP #SST               \ If this is a space station, jump to init4 to set a
 BEQ init4              \ distance of 5

 LDA #2                 \ Set A = 2 to store as the high-byte distance for the
                        \ new ship, so it's is a little way in front of us

 BNE init5              \ Jump to init5 (this BNE is effectively a JMP as A is
                        \ never zero)

.init4

 LDA #5                 \ Set A = 5 to store as the high-byte distance for the
                        \ new station, so it's a little way in front of us

.init5

                        \ This routine is called following ZINF, so the
                        \ orientation vectors are set as follows:
                        \
                        \   sidev = (1,  0,  0)
                        \   roofv = (0,  1,  0)
                        \   nosev = (0,  0, -1)

 LDX VIEW               \ If this is the front view, jump to init11 to set z_hi
 CPX #1
 BCC init11

 BEQ init7              \ If this is the rear view, jump to init7 to set z_sign
                        \ and z_hi and point the ship away from us

 STA INWK+1             \ This is the left or right view, so set the distance
                        \ in x_hi

 CPX #3                 \ If this is the right view, jump to init6
 BEQ init6

                        \ This is the left view, so spawn the ship to the left
                        \ (negative y_sign) and pointing away from us:
                        \
                        \   sidev = (0,   0,  1)
                        \   roofv = (0,   1,  0)
                        \   nosev = (-1,  0,  0)

 LDA INWK+2             \ This is the left view, so negate x_sign
 ORA #%10000000
 STA INWK+2

 LDX #0                 \ Set byte #22 = sidev_x_hi = 0
 STX INWK+22

 STX INWK+14            \ Set byte #14 = nosev_z_hi = 0

 LDX #96                \ Set byte #26 = sidev_z_hi = 96 = 1
 STX INWK+26

 LDX #128+96            \ Set byte #10 = nosev_x_hi = -96 = -1
 STX INWK+10

 LDA TYPE               \ If this is not the station, jump to init10
 CMP #SST
 BNE init10

                        \ This is the station, so flip it around so the slot is
                        \ pointing at us

 LDX #96                \ Set byte #10 = nosev_x_hi = 96 = 1
 STX INWK+10

 BNE init10             \ Jump to init10 (this BNE is effectively a JMP as X is
                        \ never zero)

.init6

                        \ This is the right view, so spawn the ship pointing
                        \ away from us:
                        \
                        \   sidev = (0,  0, -1)
                        \   roofv = (0,  1,  0)
                        \   nosev = (1,  0,  0)

 LDX #0                 \ Set byte #22 = sidev_x_hi = 0
 STX INWK+22

 STX INWK+14            \ Set byte #14 = nosev_z_hi = 0

 LDX #128+96            \ Set byte #26 = sidev_z_hi = -96 = -1
 STX INWK+26

 LDX #96                \ Set byte #10 = nosev_x_hi = 96 = 1
 STX INWK+10

 LDA TYPE               \ If this is not the station, jump to init10
 CMP #SST
 BNE init10

                        \ This is the station, so flip it around so the slot is
                        \ pointing at us

 LDX #128+96            \ Set byte #10 = nosev_x_hi = -96 = -1
 STX INWK+10

 BNE init10             \ Jump to init10 (this BNE is effectively a JMP as X is
                        \ never zero)

.init7

                        \ This is the rear view, so spawn the ship behind us
                        \ (negative z_sign) and pointing away from us

 PHA                    \ Store the distance on the stack

 LDA INWK+8             \ This is the rear view, so negate z_sign
 ORA #%10000000
 STA INWK+8

 LDX #128+96            \ Set byte #14 = nosev_z_hi = -96 = -1
 STX INWK+14

 LDA TYPE               \ If this is not the station, jump to init8
 CMP #SST
 BNE init8

                        \ This is the station, so flip it around so the slot is
                        \ pointing at us

 LDX #96                \ Set byte #14 = nosev_z_hi = 96 = 1
 STX INWK+14

.init8

 PLA                    \ Retrieve the distance from the stack

.init9

 STA INWK+7             \ Store the distance in z_hi

.init10

 RTS                    \ Return from the subroutine

.init11

                        \ This is the front view, so flip the ship around so it
                        \ is pointing at us

 LDX #10                \ Flip the ship around nosev to point it towards us
 JSR FlipShip

 JMP init9              \ Jump to init9

\ ******************************************************************************
\
\       Name: AddShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Add a new ship
\
\ ******************************************************************************

.AddShip

 LDA #0                 \ Set the delay in DLY to 0, so any new in-flight
 STA DLY                \ messages will be shown instantly

 LDA #185               \ Print text token 25 ("SHIP") followed by a question
 JSR ShowPrompt         \ mark

 JSR BEEP               \ Make a high beep to prompt for the ship type

 JSR TT217              \ Scan the keyboard until a key is pressed, and return
                        \ the key's ASCII code in A (and X)

 CMP #'1'               \ Check key is '1' or higher
 BCS add1

 BCC add4               \ Key is invalid, so jump to add4 to return from the
                        \ subroutine (this BCC is effectively a JMP as we just
                        \ passed through a BCS)

.add1

 CMP #'9'+1             \ If key is '1' to '9', jump to add2 to process
 BCC add2

IF _6502SP_VERSION

 CMP #'a'               \ If key is less than 'A', it is invalid, so jump to
 BCC add4               \ add4 to return from the subroutine

 CMP #'y'               \ If key is 'Y or greater, it is invalid, so jump to
 BCS add4               \ add4  to return from the subroutine

                        \ Key is 'A' to 'X'

 SBC #'a'-11            \ Otherwise calculate ship type with 'A' = 10 (the C
                        \ flag is clear for this calculation)

ELIF _MASTER_VERSION

 CMP #'A'               \ If key is less than 'A', it is invalid, so jump to
 BCC add4               \ add4 to return from the subroutine

 CMP #'Y'               \ If key is 'Y or greater, it is invalid, so jump to
 BCS add4               \ add4  to return from the subroutine

                        \ Key is 'A' to 'X'

 SBC #'A'-11            \ Otherwise calculate ship type with 'A' = 10 (the C
                        \ flag is clear for this calculation)

ENDIF

 BCS add3               \ Jump to add3 (this BCS is effectively a JMP as the C
                        \ flag will be set from the subtraction)

.add2

                        \ Key is '1' to '9'

 CMP #'2'               \ '2' is invalid as it is the space station, so jump to
 BEQ add4               \ add4 to return from the subroutine

 SEC                    \ Calculate the ship type from the key pressed
 SBC #'0'

.add3

 STA TYPE               \ Store the new ship type

 JSR ZINF               \ Call ZINF to reset INWK and the orientation vectors

 JSR InitialiseShip     \ Initialise the ship coordinates

 JSR CreateShip         \ Create the new ship

.add4

 LDA #185               \ Print text token 25 ("SHIP") followed by a question
 JMP ShowPrompt         \ mark to remove it from the screen, and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: FireLaser
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Fire the current ship's laser
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Slot number
\
\ ******************************************************************************

.FireLaser

 CPX #2                 \ If this is the station or planet, jump to
 BCC MakeErrorBeep      \ MakeErrorBeep as you can't fire their lasers

 LDA INWK+31            \ Toggle bit 6 in byte #31 to denote that the ship is
 EOR #%01000000         \ firing its laser at us (or to switch it off)
 STA INWK+31

 JMP DrawShip+3         \ Draw the ship (but not on the scanner), returning from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: ExplodeShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Explode the current ship
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Slot number
\
\ ******************************************************************************

.ExplodeShip

 CPX #2                 \ If this is the station or planet, jump to 
 BCC MakeErrorBeep      \ MakeErrorBeep as you can't explode them

 LDA #&A5               \ Re-enable DOEXP
 STA DOEXP+9

 LDA INWK+31            \ If bit 5 of byte #31 is set, then the ship is already
 AND #%00100000         \ exploding, so jump to expl1 to move the explosion on
 BNE expl1              \ by one step

 JSR MV5                \ Draw the current ship on the scanner to remove it

 LDA INWK+31            \ Set bit 7 and clear bit 5 in byte #31 to denote that
 ORA #%10000000         \ the ship is exploding
 AND #%11101111
 STA INWK+31

 JSR DrawShip+3         \ Draw the explosion (but not on the scanner) to get it
                        \ going (as only calling this once at the start of a new
                        \ explosion doesn't show a lot)

.expl1

 JSR DrawShip+3         \ Draw the explosion (but not on the scanner)

 LDA #&60               \ Disable DOEXP again
 STA DOEXP+9

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CreateShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Create a ship
\
\ ******************************************************************************

.CreateShip

 LDA TYPE               \ Fetch the type of ship to create

 JSR NWSHP              \ Add the new ship and store it in K%

 BCC MakeErrorBeep      \ If ship was not added, jump to MakeErrorBeep to make
                        \ an error beep and return from the subroutine using a
                        \ tail call

 JSR GetCurrentSlot     \ Set X to the slot number of the new ship

 BCS MakeErrorBeep      \ If we didn't find the slot, jump to MakeErrorBeep to
                        \ make an error beep and return from the subroutine
                        \ using a tail call

 JSR UpdateSlotNumber   \ Store and print the new slot number in X

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JMP DrawShip           \ Draw the ship, returning from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: MakeErrorBeep
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Make an error beep
\
\ ******************************************************************************

.MakeErrorBeep

 LDA #40                \ Call the NOISE routine with A = 40 to make a low,
 JMP NOISE              \ long beep, returning from the subroutine using a tail
                        \ call

\ ******************************************************************************
\
\       Name: ShowPrompt
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Show a prompt on-screen
\
\ ------------------------------------------------------------------------------
\
\ Display an in-flight message in capitals at the bottom of the space view.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.ShowPrompt

 PHA                    \ Store token number on the stack

IF _6502SP_VERSION

 LDA #YELLOW            \ Send a #SETCOL YELLOW command to the I/O processor to
 JSR DOCOL              \ switch to colour 1, which is yellow

ELIF _MASTER_VERSION

 LDA #YELLOW            \ Switch to colour 1, which is yellow
 STA COL

ENDIF

 LDX #0                 \ Set QQ17 = 0 to switch to ALL CAPS
 STX QQ17

 LDA #10                \ Move the text cursor to column 10
 JSR DOXC

 LDA #22                \ Move the text cursor to row 22
 JSR DOYC

 PLA                    \ Get token number

 JMP prq                \ Print the text token in A, followed by a question mark
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: CopyShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Duplicate the ship in the current slot
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Slot number
\
\ ******************************************************************************

.CopyShip

 CPX #2                 \ If this is the station or planet, jump to
 BCC MakeErrorBeep      \ MakeErrorBeep as you can't duplicate them

 LDA INWK+3             \ Move the current away from the origin a bit so the new
 CLC                    \ ship doesn't overlap the original ship
 ADC #10
 STA INWK+3
 BCC P%+4
 INC INWK+3

 JSR CreateShip         \ Create a new ship of the same type

 JMP HighlightShip      \ Highlight the new ship, so we can see which one it is,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: DeleteShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Delete the ship from the current slot
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Slot number
\
\ ******************************************************************************

.DeleteShip

 CPX #2                 \ If this is the station or planet, jump to
 BCC MakeErrorBeep      \ MakeErrorBeep as you can't delete them

 JSR EraseShip          \ Erase the current ship from the screen

 LDX currentSlot        \ Delete the current ship, shuffling the slots down
 JSR KILLSHP

 LDX currentSlot        \ If the current slot is still full, jump to delt1 to
 LDA FRIN,X             \ keep this as the current slot
 BNE delt1

 DEX                    \ If we get here we just emptied the last slot, so
                        \ switch to the previous slot

.delt1

 JMP SwitchToSlot       \ Switch to slot X to load the new ship's data,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: UpdateSlotNumber
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Set current slot number to INF ship and update slot number
\             on-screen
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   New slot number
\
\ Returns:
\
\   currentSlot         Slot number for ship currently in INF
\
\ ******************************************************************************

.UpdateSlotNumber

 PHX                    \ Store the new slot number on the stack

 JSR PrintSlotNumber    \ Erase the current slot number from screen

 PLX                    \ Retrieve the new slot number from the stack

 STX currentSlot        \ Set the current slot number to the new slot number

 JMP PrintSlotNumber    \ Print new slot number and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: PrintSlotNumber
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Print the current slot number
\
\ ******************************************************************************

.PrintSlotNumber

 LDX currentSlot        \ Print the current slot number at text location (0, 1)
 JMP ee3                \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: GetCurrentSlot
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Fetch the slot number for the ship in INF
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   Slot number for ship in INF
\
\   C flag              Clear = success (ship slot found)
\                       Set = failure (ship slot not found)
\
\ ******************************************************************************

.GetCurrentSlot

 LDX #2                 \ Start at slot 2 (first ship slot)

.slot1

 LDA FRIN,X             \ If slot is empty, move onto next slot
 BEQ slot2

 TXA                    \ Set Y = X * 2
 ASL A
 TAY

 LDA UNIV,Y             \ If INF(1 0) <> UNIV(1 0), jump to next slot
 CMP INF
 BNE slot2
 LDA UNIV+1,Y
 CMP INF+1
 BNE slot2

 CLC                    \ Return with C flag clear to indicate success
 RTS

.slot2

 INX                    \ Otherwise increment X to point to the next slot

 CPX #NOSH              \ If we haven't reached the last slot yet, loop back
 BCC slot1

 RTS                    \ Return from the subroutine with C flag set to indicate
                        \ failure

\ ******************************************************************************
\
\       Name: NextSlot
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Go to next slot
\
\ ******************************************************************************

.NextSlot

 LDX currentSlot        \ Fetch the current slot number

 INX                    \ Increment to point to the next slot

 LDA FRIN,X             \ If slot X contains a ship, jump to SwitchToSlot to get
 BNE SwitchToSlot       \ the ship's data and return from the subroutine using a
                        \ tail call

 LDX #0                 \ Otherwise wrap round to slot 0, the planet

 BEQ SwitchToSlot       \ Jump to SwitchToSlot to get the planet's data (this BEQ
                        \ is effectively a JMP as X is always 0), returning from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PreviousSlot
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Go to previous slot
\
\ ******************************************************************************

.PreviousSlot

 LDX currentSlot        \ Fetch the current slot number

 DEX                    \ Decrement to point to the previous slot

 BPL SwitchToSlot       \ If X is positive, then this is a valid ship slot, so
                        \ jump to SwitchToSlot to get the ship's data

                        \ Otherwise we have gone past slot 0, so we need to find
                        \ the last ship slot

 LDX #1                 \ Start at the first ship slot (slot 2) and work forwards
                        \ until we find an empty slot

.prev1

 INX                    \ Increment the slot number

 CPX #NOSH              \ If we haven't reached the last slot, jump to prev2 to
 BCC prev2              \ skip the following

 LDX #NOSH-1            \ There are no empty ship slots, so set X to the last
 BNE SwitchToSlot       \ slot and jump to SwitchToSlot (this BNE is effectively
                        \ a JMP as X is never 0)

.prev2

 LDA FRIN,X             \ If slot X is populated, loop back to move to the next
 BNE prev1              \ slot

                        \ If we get here then we hae found the first empty slot

 DEX                    \ Decrement the slot number to the populated slot before
                        \ the empty one we just found

                        \ If we get here, we have found the correct slot, so
                        \ fall through into SwitchToSlot to get the ship's data

\ ******************************************************************************
\
\       Name: SwitchToSlot
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Switch to a new specific slot, updating the slot number, fetching
\             the ship data and highlighting the ship
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   New slot number
\
\ ******************************************************************************

.SwitchToSlot

 JSR UpdateSlotNumber   \ Store and print the new slot number

 LDX currentSlot        \ Get the ship data for the new slot
 JSR GetShipData

 JMP HighlightShip      \ Highlight the new ship, so we can see which one it is,
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: GetShipData
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Fetch the ship info for a specified ship slot
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Slot number of ship data to fetch
\
\ Returns:
\
\   X                   X is unchanged
\
\ ******************************************************************************

.GetShipData

 LDA FRIN,X             \ Fetch the contents of this slot into A. If it is 0
 BEQ gets2              \ then this slot is empty, so jump to gets2 to return
                        \ from the subroutine

 STA TYPE               \ Store the ship type in TYPE

 JSR GINF               \ Call GINF to fetch the address of the ship data block
                        \ for the ship in slot X and store it in INF. The data
                        \ block is in the K% workspace, which is where all the
                        \ ship data blocks are stored

                        \ Next we want to copy the ship data block from INF to
                        \ the zero-page workspace at INWK, so we can process it
                        \ more efficiently

 LDY #NI%-1             \ There are NI% bytes in each ship data block (and in
                        \ the INWK workspace, so we set a counter in Y so we can
                        \ loop through them

.gets1

 LDA (INF),Y            \ Load the Y-th byte of INF and store it in the Y-th
 STA INWK,Y             \ byte of INWK

 DEY                    \ Decrement the loop counter

 BPL gets1              \ Loop back for the next byte until we have copied the
                        \ last byte from INF to INWK

 LDA TYPE               \ If the ship type is negative then this indicates a
 BMI gets2              \ planet or sun, so jump down to gets2, as the next bit
                        \ sets up a pointer to the ship blueprint, which doesn't
                        \ apply to planets and suns

 ASL A                  \ Set Y = ship type * 2
 TAY

 LDA XX21-2,Y           \ The ship blueprints at XX21 start with a lookup
 STA XX0                \ table that points to the individual ship blueprints,
                        \ so this fetches the low byte of this particular ship
                        \ type's blueprint and stores it in XX0

 LDA XX21-1,Y           \ Fetch the high byte of this particular ship type's
 STA XX0+1              \ blueprint and store it in XX0+1

.gets2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: HighlightShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Highlight the current ship
\
\ ******************************************************************************

.HighlightShip

 JSR MV5                \ Hide the ship on the scanner

 JSR high1              \ Highlight the ship, showing the ship on the scanner

 JSR MV5                \ Hide the ship on the scanner

                        \ Fall through into high1 to highlight the ship, showing
                        \ the ship on the scanner

.high1

 JSR MV5                \ Toggle the ship on the scanner

 LDX #0                 \ Move right
 LDY #0
 JSR MoveShip

 LDX #0                 \ Move right
 LDY #0
 JSR MoveShip

 LDX #0                 \ Move left
 LDY #%10000000
 JSR MoveShip

 LDX #0                 \ Move left
 LDY #%10000000
 JSR MoveShip

 LDX #0                 \ Move left
 LDY #%10000000
 JSR MoveShip

 LDX #0                 \ Move left
 LDY #%10000000
 JSR MoveShip

 LDX #0                 \ Move right
 LDY #0
 JSR MoveShip

 LDX #0                 \ Move right, returning from the subroutine using a tail
 LDY #0                 \ call
 JMP MoveShip

\ ******************************************************************************
\
\       Name: ShowToken
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Print an extended recursive token from the UniverseToken table
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The recursive token to be printed, in the range 0-255
\
\ Returns:
\
\   A                   A is preserved
\
\   Y                   Y is preserved
\
\   V(1 0)              V(1 0) is preserved
\
\ ******************************************************************************

.ShowToken

 PHA                    \ Store A on the stack, so we can retrieve it later

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 LDA #LO(UniverseToken) \ Set V to the low byte of UniverseToken
 STA V

 LDA #HI(UniverseToken) \ Set A to the high byte of UniverseToken

 JMP DTEN               \ Call DTEN to print token number X from the
                        \ UniverseToken table and restore the values of A, Y and
                        \ V(1 0) from the stack, returning from the subroutine
                        \ using a tail call

IF _MASTER_VERSION

\ ******************************************************************************
\
\       Name: EJMP
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for jump tokens in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   EJMP n              Insert a jump to address n in the JMTB table
\
\ See the deep dive on "Printing extended text tokens" for details on how jump
\ tokens are stored in the extended token table.
\
\ Arguments:
\
\   n                   The jump number to insert into the table
\
\ ******************************************************************************

MACRO EJMP n

  EQUB n EOR VE

ENDMACRO

\ ******************************************************************************
\
\       Name: ECHR
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for characters in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   ECHR 'x'            Insert ASCII character "x"
\
\ To include an apostrophe, use a backtick character, as in ECHR '`'.
\
\ See the deep dive on "Printing extended text tokens" for details on how
\ characters are stored in the extended token table.
\
\ Arguments:
\
\   'x'                 The character to insert into the table
\
\ ******************************************************************************

MACRO ECHR x

  IF x = '`'
    EQUB 39 EOR VE
  ELSE
    EQUB x EOR VE
  ENDIF

ENDMACRO

\ ******************************************************************************
\
\       Name: ETOK
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for recursive tokens in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   ETOK n              Insert extended recursive token [n]
\
\ See the deep dive on "Printing extended text tokens" for details on how
\ recursive tokens are stored in the extended token table.
\
\ Arguments:
\
\   n                   The number of the recursive token to insert into the
\                       table, in the range 129 to 214
\
\ ******************************************************************************

MACRO ETOK n

  EQUB n EOR VE

ENDMACRO

\ ******************************************************************************
\
\       Name: ETWO
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for two-letter tokens in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   ETWO 'x', 'y'       Insert two-letter token "xy"
\
\ The newline token can be entered using ETWO '-', '-'.
\
\ See the deep dive on "Printing extended text tokens" for details on how
\ two-letter tokens are stored in the extended token table.
\
\ Arguments:
\
\   'x'                 The first letter of the two-letter token to insert into
\                       the table
\
\   'y'                 The second letter of the two-letter token to insert into
\                       the table
\
\ ******************************************************************************

MACRO ETWO t, k

  IF t = '-' AND k = '-' : EQUB 215 EOR VE : ENDIF
  IF t = 'A' AND k = 'B' : EQUB 216 EOR VE : ENDIF
  IF t = 'O' AND k = 'U' : EQUB 217 EOR VE : ENDIF
  IF t = 'S' AND k = 'E' : EQUB 218 EOR VE : ENDIF
  IF t = 'I' AND k = 'T' : EQUB 219 EOR VE : ENDIF
  IF t = 'I' AND k = 'L' : EQUB 220 EOR VE : ENDIF
  IF t = 'E' AND k = 'T' : EQUB 221 EOR VE : ENDIF
  IF t = 'S' AND k = 'T' : EQUB 222 EOR VE : ENDIF
  IF t = 'O' AND k = 'N' : EQUB 223 EOR VE : ENDIF
  IF t = 'L' AND k = 'O' : EQUB 224 EOR VE : ENDIF
  IF t = 'N' AND k = 'U' : EQUB 225 EOR VE : ENDIF
  IF t = 'T' AND k = 'H' : EQUB 226 EOR VE : ENDIF
  IF t = 'N' AND k = 'O' : EQUB 227 EOR VE : ENDIF

  IF t = 'A' AND k = 'L' : EQUB 228 EOR VE : ENDIF
  IF t = 'L' AND k = 'E' : EQUB 229 EOR VE : ENDIF
  IF t = 'X' AND k = 'E' : EQUB 230 EOR VE : ENDIF
  IF t = 'G' AND k = 'E' : EQUB 231 EOR VE : ENDIF
  IF t = 'Z' AND k = 'A' : EQUB 232 EOR VE : ENDIF
  IF t = 'C' AND k = 'E' : EQUB 233 EOR VE : ENDIF
  IF t = 'B' AND k = 'I' : EQUB 234 EOR VE : ENDIF
  IF t = 'S' AND k = 'O' : EQUB 235 EOR VE : ENDIF
  IF t = 'U' AND k = 'S' : EQUB 236 EOR VE : ENDIF
  IF t = 'E' AND k = 'S' : EQUB 237 EOR VE : ENDIF
  IF t = 'A' AND k = 'R' : EQUB 238 EOR VE : ENDIF
  IF t = 'M' AND k = 'A' : EQUB 239 EOR VE : ENDIF
  IF t = 'I' AND k = 'N' : EQUB 240 EOR VE : ENDIF
  IF t = 'D' AND k = 'I' : EQUB 241 EOR VE : ENDIF
  IF t = 'R' AND k = 'E' : EQUB 242 EOR VE : ENDIF
  IF t = 'A' AND k = '?' : EQUB 243 EOR VE : ENDIF
  IF t = 'E' AND k = 'R' : EQUB 244 EOR VE : ENDIF
  IF t = 'A' AND k = 'T' : EQUB 245 EOR VE : ENDIF
  IF t = 'E' AND k = 'N' : EQUB 246 EOR VE : ENDIF
  IF t = 'B' AND k = 'E' : EQUB 247 EOR VE : ENDIF
  IF t = 'R' AND k = 'A' : EQUB 248 EOR VE : ENDIF
  IF t = 'L' AND k = 'A' : EQUB 249 EOR VE : ENDIF
  IF t = 'V' AND k = 'E' : EQUB 250 EOR VE : ENDIF
  IF t = 'T' AND k = 'I' : EQUB 251 EOR VE : ENDIF
  IF t = 'E' AND k = 'D' : EQUB 252 EOR VE : ENDIF
  IF t = 'O' AND k = 'R' : EQUB 253 EOR VE : ENDIF
  IF t = 'Q' AND k = 'U' : EQUB 254 EOR VE : ENDIF
  IF t = 'A' AND k = 'N' : EQUB 255 EOR VE : ENDIF

ENDMACRO

\ ******************************************************************************
\
\       Name: ERND
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for random tokens in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   ERND n              Insert recursive token [n]
\
\                         * Tokens 0-123 get stored as n + 91
\
\ See the deep dive on "Printing extended text tokens" for details on how
\ random tokens are stored in the extended token table.
\
\ Arguments:
\
\   n                   The number of the random token to insert into the
\                       table, in the range 0 to 37
\
\ ******************************************************************************

MACRO ERND n

  EQUB (n + 91) EOR VE

ENDMACRO

\ ******************************************************************************
\
\       Name: TOKN
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for standard tokens in the extended token table
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the recursive token table:
\
\   TOKN n              Insert recursive token [n]
\
\                         * Tokens 0-95 get stored as n + 160
\
\                         * Tokens 128-145 get stored as n - 114
\
\                         * Tokens 96-127 get stored as n
\
\ See the deep dive on "Printing text tokens" for details on how recursive
\ tokens are stored in the recursive token table.
\
\ Arguments:
\
\   n                   The number of the recursive token to insert into the
\                       table, in the range 0 to 145
\
\ ******************************************************************************

MACRO TOKN n

  IF n >= 0 AND n <= 95
    t = n + 160
  ELIF n >= 128
    t = n - 114
  ELSE
    t = n
  ENDIF

  EQUB t EOR VE

ENDMACRO

ENDIF

\ ******************************************************************************
\
\       Name: UniverseTokens
\       Type: Variable
\   Category: Universe editor
\    Summary: Extended recursive token table for the universe editor
\
\ ******************************************************************************

.UniverseToken

 EQUB VE                \ Token 0:      ""
                        \
                        \ Encoded as:   ""

 EJMP 9                 \ Token 1:      "{clear screen}
 EJMP 11                \                {draw box around title}
IF _6502SP_VERSION
 EJMP 30                \                {white}
ENDIF
 EJMP 1                 \                {all caps}
 EJMP 8                 \                {tab 6} DISK ACCESS MENU{crlf}
 ECHR ' '               \                {lf}
 ETWO 'D', 'I'          \                {sentence case}
 ECHR 'S'               \                1. LOAD UNIVERSE{crlf}
 ECHR 'K'               \                2. SAVE UNIVERSE {commander name}{crlf}
 ECHR ' '               \                3. CATALOGUE{crlf}
 ECHR 'A'               \                4. DELETE A FILE{crlf}
 ECHR 'C'               \                5. PLAY UNIVERSE{crlf}
 ETWO 'C', 'E'          \                6. EXIT{crlf}
 ECHR 'S'               \               "
 ECHR 'S'
 ECHR ' '
 ECHR 'M'
 ECHR 'E'
 ETWO 'N', 'U'
 ETWO '-', '-'
 EJMP 10
 EJMP 2
 ECHR '1'
 ECHR '.'
 ECHR ' '
 ETWO 'L', 'O'
 ECHR 'A'
 ECHR 'D'
 ECHR ' '
 ECHR 'U'
 ECHR 'N'
 ECHR 'I'
 ETWO 'V', 'E'
 ECHR 'R'
 ETWO 'S', 'E'
 ETWO '-', '-'
 ECHR '2'
 ECHR '.'
 ECHR ' '
 ECHR 'S'
 ECHR 'A'
 ETWO 'V', 'E'
 ECHR ' '
 ECHR 'U'
 ECHR 'N'
 ECHR 'I'
 ETWO 'V', 'E'
 ECHR 'R'
 ETWO 'S', 'E'
 ECHR ' '
 EJMP 4
 ETWO '-', '-'
 ECHR '3'
 ECHR '.'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'T'
 ECHR 'A'
 ETWO 'L', 'O'
 ECHR 'G'
 ECHR 'U'
 ECHR 'E'
 ETWO '-', '-'
 ECHR '4'
 ECHR '.'
 ECHR ' '
 ECHR 'D'
 ECHR 'E'
 ECHR 'L'
 ETWO 'E', 'T'
 ECHR 'E'
 ETOK 208
 ECHR 'F'
 ECHR 'I'
 ETWO 'L', 'E'
 ETWO '-', '-'
 ECHR '5'
 ECHR '.'
 ECHR ' '
 ECHR 'P'
 ETWO 'L', 'A'
 ECHR 'Y'
 ECHR ' '
 ECHR 'U'
 ECHR 'N'
 ECHR 'I'
 ETWO 'V', 'E'
 ECHR 'R'
 ETWO 'S', 'E'
 ETWO '-', '-'
 ECHR '6'
 ECHR '.'
 ECHR ' '
 ECHR 'E'
 ECHR 'X'
 ETWO 'I', 'T'
 ETWO '-', '-'
 EQUB VE

\ ******************************************************************************
\
\       Name: DeleteUniverse
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Catalogue a disc, ask for a filename to delete, and delete the
\             file
\
\ ------------------------------------------------------------------------------
\
\ This routine asks for a disc drive number, and if it is a valid number (0-3)
\ it displays a catalogue of the disc in that drive. It then asks for a filename
\ to delete, updates the OS command at DELI so that when that command is run, it
\ it deletes the correct file, and then it does the deletion.
\
\ Other entry points:
\
\   DELT-1              Contains an RTS
\
\ ******************************************************************************

.DeleteUniverse

 JSR CATS               \ Call CATS to ask for a drive number (or a directory
                        \ name on the Master Compact) and catalogue that disc
                        \ or directory

 BCS ShowDiscMenu       \ If the C flag is set then an invalid drive number was
                        \ entered as part of the catalogue process, so jump to
                        \ ShowDiscMenu to display the disc access menu

IF _6502SP_VERSION

 LDA CTLI+1             \ The call to CATS above put the drive number into
 STA DELI+7             \ CTLI+1, so copy the drive number into DELI+7 so that
                        \ the drive number in the "DELETE:0.E.1234567" string
                        \ gets updated (i.e. the number after the colon)

 LDA #9                 \ Print extended token 9 ("{clear bottom of screen}FILE
 JSR DETOK              \ TO DELETE?")

ELIF _MASTER_VERSION

IF _SNG47

 LDA CTLI+4             \ The call to CATS above put the drive number into
 STA DELI+8             \ CTLI+4, so copy the drive number into DELI+8 so that
                        \ the drive number in the "DELETE :1.1234567" string
                        \ gets updated (i.e. the number after the colon)

ENDIF

 LDA #8                 \ Print extended token 8 ("{single cap}COMMANDER'S
 JSR DETOK              \ NAME? ")

ENDIF

 JSR MT26               \ Call MT26 to fetch a line of text from the keyboard
                        \ to INWK+5, with the text length in Y

 TYA                    \ If no text was entered (Y = 0) then jump to
 BEQ ShowDiscMenu       \ ShowDiscMenu to display the disc access menu

                        \ We now copy the entered filename from INWK to DELI, so
                        \ that it overwrites the filename part of the string,
                        \ i.e. the "E.1234567" part of "DELETE:0.E.1234567"

IF _6502SP_VERSION

 LDX #9                 \ Set up a counter in X to count from 9 to 1, so that we
                        \ copy the string starting at INWK+4+1 (i.e. INWK+5) to
                        \ DELI+8+1 (i.e. DELI+9 onwards, or "E.1234567")

ELIF _MASTER_VERSION

IF _SNG47

                        \ We now copy the entered filename from INWK to DELI, so
                        \ that it overwrites the filename part of the string,
                        \ i.e. the "E.1234567" part of "DELETE :1.1234567"

 LDX #9                 \ Set up a counter in X to count from 9 to 1, so that we
                        \ copy the string starting at INWK+4+1 (i.e. INWK+5) to
                        \ DELI+9+1 (i.e. DELI+10 onwards, or "1.1234567")

ELIF _COMPACT

                        \ We now copy the entered filename from INWK to DELI, so
                        \ that it overwrites the filename part of the string,
                        \ i.e. the "1234567890" part of "DELETE 1234567890"

 LDX #8                 \ Set up a counter in X to count from 8 to 0, so that we
                        \ copy the string starting at INWK+5+0 (i.e. INWK+5) to
                        \ DELI+7+0 (i.e. DELI+7 onwards, or "1234567890")

ENDIF

ENDIF

.dele1

IF _6502SP_VERSION

 LDA INWK+4,X           \ Copy the X-th byte of INWK+4 to the X-th byte of
 STA DELI+8,X           \ DELI+8

 DEX                    \ Decrement the loop counter

 BNE dele1              \ Loop back to delt1 to copy the next character until we
                        \ have copied the whole filename

ELIF _MASTER_VERSION

IF _SNG47

 LDA INWK+4,X           \ Copy the X-th byte of INWK+4 to the X-th byte of
 STA DELI+9,X           \ DELI+9

 DEX                    \ Decrement the loop counter

 BNE dele1              \ Loop back to dele1 to copy the next character until we
                        \ have copied the whole filename

 JSR SWAPZP             \ Call SWAPZP to restore the top part of zero page

ELIF _COMPACT

 LDA INWK+5,X           \ Copy the X-th byte of INWK+5 to the X-th byte of
 STA DELI+7,X           \ DELI+7

 DEX                    \ Decrement the loop counter

 BPL dele1              \ Loop back to dele1 to copy the next character until we
                        \ have copied the whole filename

 JSR NMIRELEASE         \ Release the NMI workspace (&00A0 to &00A7)

ENDIF

ENDIF

 LDX #LO(DELI)          \ Set (Y X) to point to the OS command at DELI, which
 LDY #HI(DELI)          \ contains the DFS command for deleting this file

IF _6502SP_VERSION

 JSR SCLI2              \ Call SCLI2 to execute the OS command at (Y X), which
                        \ deletes the file, setting the SVN flag while it's
                        \ running to indicate disc access is in progress

ELIF _MASTER_VERSION

 JSR OSCLI              \ Call OSCLI to execute the OS command at (Y X), which
                        \ catalogues the disc

 JSR SWAPZP             \ Call SWAPZP to restore the top part of zero page

ENDIF

 JMP ShowDiscMenu       \ Jump to ShowDiscMenu to display the disc access menu
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: DiscBreak
\       Type: Subroutine
\   Category: Universe editor
\    Summary: The BRKV handler for disc access operations
\
\ ------------------------------------------------------------------------------
\
\ This routine is used to display error messages from the disc filing system
\ while disc access operations are being performed. When called, it makes a beep
\ and prints the system error message in the block pointed to by (&FD &FE),
\ which is where the disc filing system will put any disc errors (such as "File
\ not found", "Disc error" and so on). It then waits for a key press and returns
\ to the disc access menu.
\
\ BRKV is set to this routine at the start of the SVE routine, just before the
\ disc access menu is shown, and it reverts to BRBR at the end of the SVE
\ routine after the disc access menu has been processed. In other words, BRBR is
\ the standard BRKV handler for the game, and it's swapped out to MEBRK for disc
\ access operations only.
\
\ When it is the BRKV handler, the routine can be triggered using a BRK
\ instruction. The main difference between this routine and the standard BRKV
\ handler in BRBR is that this routine returns to the disc access menu rather
\ than restarting the game, and it doesn't decrement the brkd counter.
\
\ ******************************************************************************

.DiscBreak

 LDX stack              \ Set the stack pointer to the value that we stored in
 TXS                    \ the stack variable, so that's back to the value it had
                        \ before we set BRKV to point to MEBRK in the SVE
                        \ routine

IF _6502SP_VERSION

 JSR backtonormal       \ Disable the keyboard and set the SVN flag to 0

 TAY                    \ The call to backtonormal sets A to 0, so this sets Y
                        \ to 0, which we use as a loop counter below


ELIF _MASTER_VERSION

 JSR SWAPZP             \ Call SWAPZP to restore the top part of zero page

 STZ CATF               \ Set the CATF flag to 0, so the TT26 routine reverts to
                        \ standard formatting

 LDY #0                 \ Set Y to 0, which we use as a loop counter below

ENDIF

 LDA #7                 \ Set A = 7 to generate a beep before we print the error
                        \ message

.dbrk1

IF _6502SP_VERSION

 JSR OSWRCH             \ Print the character in A (which contains a beep on the
                        \ first loop iteration), and then any non-zero
                        \ characters we fetch from the error message

ELIF _MASTER_VERSION

 JSR CHPR               \ Print the character in A, which contains a line feed
                        \ on the first loop iteration, and then any non-zero
                        \ characters we fetch from the error message

ENDIF

 INY                    \ Increment the loop counter

IF _6502SP_VERSION

 BEQ dbrk2              \ If Y = 0 then we have worked our way through a whole
                        \ page, so jump to retry to wait for a key press and
                        \ display the disc access menu (this BEQ is effectively
                        \ a JMP, as we didn't take the BNE branch above)

ENDIF

 LDA (&FD),Y            \ Fetch the Y-th byte of the block pointed to by
                        \ (&FD &FE), so that's the Y-th character of the message
                        \ pointed to by the MOS error message pointer

 BNE dbrk1              \ If the fetched character is non-zero, loop back to the
                        \ JSR OSWRCH above to print the it, and keep looping
                        \ until we fetch a zero (which marks the end of the
                        \ message)

.dbrk2

 JSR t                  \ Scan the keyboard until a key is pressed, returning
                        \ the ASCII code in A and X

                        \ Fall through into ShowDiscMenu to display the disc
                        \ access menu

\ ******************************************************************************
\
\       Name: ShowDiscMenu
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Show the universe disc menu
\
\ ******************************************************************************

.ShowDiscMenu

 LDA #HI(NAME)          \ Change TR1 so it uses the universe name in NAME as the
 STA GTL2+2             \ default when no filename is entered
 LDA #LO(NAME)
 STA GTL2+1

 LDA #&11               \ Change token 8 in TKN1 to "File Name"
 STA token8
 LDA #&1E
 STA token8+1
 LDA #&B2
 STA token8+2

 LDA #'U'               \ Change the directory to U
 STA S1%+3
 STA dirCommand+4

IF _6502SP_VERSION

 STA DELI+9

ENDIF

 LDX #LO(dirCommand)    \ Set (Y X) to point to dirCommand ("DIR U")
 LDY #HI(dirCommand)

 JSR OSCLI              \ Call OSCLI to run the OS command in dirCommand, which
                        \ changes the disc directory to E

 JSR ZEBC               \ Call ZEBC to zero-fill pages &B and &C

 TSX                    \ Transfer the stack pointer to X and store it in stack,
 STX stack              \ so we can restore it in the MEBRK routine

 LDA #LO(DiscBreak)     \ Set BRKV to point to the MEBRK routine, disabling
 SEI                    \ while we make the change and re-enabling them once we
 STA BRKV               \ are done. MEBRK is the BRKV handler for disc access
 LDA #HI(DiscBreak)     \ operations, and replaces the standard BRKV handler in
 STA BRKV+1             \ BRBR while disc access operations are happening
 CLI

 LDA #1                 \ Print extended token 1, the disc access menu, which
 JSR ShowToken          \ presents these options:
                        \
                        \   1. Load Universe
                        \   2. Save Universe {universe name}
                        \   3. Catalogue
                        \   4. Delete A File
                        \   5. Play Universe
                        \   6. Exit

 JSR t                  \ Scan the keyboard until a key is pressed, returning
                        \ the ASCII code in A and X

 CMP #'1'               \ If A < ASCII "1", jump to disc9 to exit as the key
 BCC disc9              \ press doesn't match a menu option

 CMP #'4'               \ If "4" was not pressed, jump to disc1
 BNE disc1

                        \ Option 4: Delete

 JMP DeleteUniverse     \ Delete a file

.disc1

 CMP #'5'               \ If "5" was not pressed, jump to disc2 to skip the
 BNE disc2              \ following

                        \ Option 5: Play universe

 JMP PlayUniverse       \ Play the current universe file

.disc2

 BCS disc9              \ If A >= ASCII "5", jump to disc9 to exit as the key
                        \ press is either option 6 (exit), or it doesn't match a
                        \ menu option (as we already checked for "5" above)

 CMP #'2'               \ If A >= ASCII "2" (i.e. save or catalogue), skip to
 BCS disc8              \ disc8

                        \ Option 1: Load

 JSR GTNMEW             \ If we get here then option 1 (load) was chosen, so
                        \ call GTNMEW to fetch the name of the commander file
                        \ to load (including drive number and directory) into
                        \ INWK

 JSR LoadUniverse       \ Call LoadUniverse to load the commander file

 JSR StoreName          \ Transfer the universe filename from INWK to NAME, to
                        \ set it as the current filename

 JMP disc9              \ Jump to disc9 to return from the subroutine

.disc8

 BEQ disc7              \ We get here following the CMP #'2' above, so this
                        \ jumps to disc7 if option 2 (save) was chosen

                        \ Option 3: Catalogue

 JSR CATS               \ Call CATS to ask for a drive number, catalogue that
                        \ disc and update the catalogue command at CTLI

 JSR t                  \ Scan the keyboard until a key is pressed, returning
                        \ the ASCII code in A and X

 JMP ShowDiscMenu       \ Show the disc menu again

.disc7

                        \ Option 2: Save

 JSR SaveUniverse       \ Save the universe file

 JMP ShowDiscMenu       \ Show the disc menu again

.disc9

                        \ Option 6: Exit

 JSR ExitDiscMenu       \ Clear the screen and reverse all the modifications we
                        \ did above

.disc10

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ExitDiscMenu
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Exit the disc access menu
\
\ ******************************************************************************

.ExitDiscMenu

 LDX #0                 \ Draw the front view, returning from the subroutine
 STX VIEW               \ using a tail call
 JSR ChangeView+8

 LDA #'E'               \ Change the directory back to E
 STA S1%+3
 STA dirCommand+4

IF _6502SP_VERSION

 STA DELI+9

ENDIF

 LDX #LO(dirCommand)    \ Set (Y X) to point to dirCommand ("DIR E")
 LDY #HI(dirCommand)

 JSR OSCLI              \ Call OSCLI to run the OS command in dirCommand, which
                        \ changes the disc directory to E

 LDA #&CD               \ Revert token 8 in TKN1 to "Commander's Name"
 STA token8
 LDA #&70
 STA token8+1
 LDA #&04
 STA token8+2

 LDA #HI(NA%)           \ Revert TR1 so it uses the commander name in NA% as the
 STA GTL2+2             \ default when no filename is entered
 LDA #LO(NA%)
 STA GTL2+1

 JMP BRKBK              \ Jump to BRKBK to set BRKV back to the standard BRKV
                        \ handler for the game, and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: DefaultName
\       Type: Variable
\   Category: Universe editor
\    Summary: The default name for a universe file
\
\ ******************************************************************************

.DefaultName

 EQUS "MyScene"
 EQUB 13

\ ******************************************************************************
\
\       Name: dirCommand
\       Type: Variable
\   Category: Universe editor
\    Summary: The OS command string for changing the disc directory to E
\
\ ******************************************************************************

.dirCommand

 EQUS "DIR E"
 EQUB 13

.endUniverseEditor1
