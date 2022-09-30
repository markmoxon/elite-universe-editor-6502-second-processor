\ ******************************************************************************
\
\       Name: UniverseEditor
\       Type: Subroutine
\   Category: Universe editor
\    Summary: The entry point for the universe editor
\
\ ******************************************************************************

.UniverseEditor

 LDA #&24               \ Disable the TRB XX1+31 instruction in part 9 of LL9
 STA LL74+20            \ that disables the laser once it has fired, so that
                        \ lasers remain on-screen while in the editor

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
 STX XSAV2
 JSR GetShipData

 JSR ZINF2              \ Initialise the sun so it's in front of us
 JSR InitialiseShip

 LDA #%10000001         \ Set x_sign = -1, so the sun is to the left
 STA INWK+2

\ LDA INWK+8             \ Move the sun behind us
\ EOR #%10000000
\ STA INWK+8

 JSR STORE              \ Store the updated sun

 JSR LL9                \ Draw the sun

 LDX #0                 \ Get the details for the planet from slot 0
 STX XSAV2
 JSR GetShipData

 LDA #128               \ Set the planet to a meridian planet
 STA FRIN
 STA TYPE

 JSR ZINF2              \ Initialise the planet so it's in front of us
 JSR InitialiseShip

 LDA #%00000001         \ Set x_sign = 1, so the planet is to the right
 STA INWK+2

 JSR STORE              \ Store the updated planet

 JSR LL9                \ Draw the planet

 LDX #0                 \ Set the current slot to 0 (planet)
 STX XSAV2

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

 LDX XSAV2              \ Get the ship data for the current ship, so we know the
 JSR GetShipData        \ current ship data is always in INWK for the main loop

 LDA YSAV2              \ Fetch the type of key press (0 = non-repeatable,
                        \ 1 = repeatable)

 BNE scen2              \ Loop back to wait for next key press (for repeatable
                        \ keys)

 BEQ scen1              \ Loop back to wait for next key press (non-repeatable
                        \ keys)

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

\ ******************************************************************************
\
\       Name: ProcessKey
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Process key presses
\
\ ******************************************************************************

.ProcessKey

 LDX #1                 \ Set YSAV2 = 1 to indicate that the following keys are
 STX YSAV2              \ repeating keys

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

 CMP #&39               \ Up arrow (move ship up along the y-axis)
 BNE keys3
 LDY #0
 JMP MoveShip

.keys3

 CMP #&29               \ Down arrow (move ship down along the y-axis)
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

 CMP #&46               \ K (rotate ship around the y-axis)
 BNE keys7

 LDX #0                 \ Rotate (sidev, nosev) by a small positive angle (yaw)
 STX RAT2
 LDX #21
 LDY #9
 JMP RotateShip

.keys7

 CMP #&56               \ L (rotate ship around the y-axis)
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

 LDX #0                 \ Set repeat = 0 to indicate that the following keys are
 STX YSAV2              \ non-repeating keys

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

 CMP #&36               \ O pressed (toggle station/sun)
 BNE P%+5
 JMP SwapStationSun

 CMP #&37               \ P pressed (toggle planet type)
 BNE P%+5
 JMP TogglePlanetType

 CMP #&49               \ RETURN pressed (add ship)
 BNE P%+5
 JMP AddShip

 CMP #&21               \ W (next slot)
 BNE P%+5
 JMP NextSlot

 CMP #&10               \ Q (previous slot)
 BNE P%+5
 JMP PreviousSlot

 CMP #&33               \ R (reset current ship)
 BNE P%+5
 JMP ResetShip

                        \ The following controls only apply to ships in slots 2
                        \ and up, and do not apply to the planet, sun or station

 LDX XSAV2              \ Get the current slot number

 CPX #2                 \ If this is the station or planet, do nothing
 BCC pkey1

 CMP #&59               \ DELETE pressed (delete ship)
 BNE P%+5
 JMP DeleteShip

 CMP #&69               \ COPY pressed (copy ship)
 BNE P%+5
 JMP CopyShip

 CMP #&41               \ A (fire laser)
 BNE P%+5
 JMP FireLaser

 CMP #&22               \ E (explode ship)
 BNE P%+5
 JMP ExplodeShip

 CMP #&70               \ If ESCAPE is being pressed, jump to QuitEditor to quit
 BEQ QuitEditor         \ the universe editor

.pkey1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: QuitEditor
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Quit the universe editor
\
\ ******************************************************************************

.QuitEditor

 LDA #&14               \ Re-enable the TRB XX1+31 instruction in part 9 of LL9
 STA LL74+20

 PLA                    \ Quit the scene editor by returning to the caller of
 PLA                    \ UniverseEditor
 RTS

\ ******************************************************************************
\
\       Name: FireLaser
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Fire the current ship's laser
\
\ ******************************************************************************

.FireLaser

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
\ ******************************************************************************

.ExplodeShip

 LDA INWK+31            \ If bit 5 of byte #31 is set, then the ship is already
 AND #%00100000         \ exploding, so jump to expl1 to move the explosion on
 BNE expl1              \ by one step

 LDA INWK+31            \ Set bit 7 and clear bit 5 in byte #31 to denote that
 ORA #%10000000         \ the ship is exploding
 AND #%11101111
 STA INWK+31

 JSR DrawShip+3         \ Draw the ship (but not on the scanner)

.expl1

 JSR DrawShip+3         \ Draw the ship (but not on the scanner)

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

 LDA #26                \ Modify ZINF2 so it only resets the coordinates and
 STA ZINF2+3            \ orientation vectors (and keeps other ship settings)

 JSR ZINF2              \ Reset the coordinates and orientation vectors

 LDA #NI%-1             \ Undo the modification
 STA ZINF2+3

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

 JSR DrawShip           \ Draw the ship

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

 LDX XSAV2              \ Get the ship data for the current slot, as otherwise
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

 JSR MV5                \ Draw the current ship on the scanner to remove it

 LDY XSAV2              \ Get the current ship type
 LDX FRIN,Y

 LDA shpcol,X           \ Set A to the ship colour for this type, from the X-th
                        \ entry in the shpcol table

 JSR DOCOL              \ Send a #SETCOL command to the I/O processor to switch
                        \ to this colour

 JMP LL14               \ Draw the existing ship to erase it and mark it as gone
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: SwapStationSun
\    Summary: Swap the sun for a station
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

 JSR ZINF2              \ Reset the sun's data block

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

 JSR ZINF2              \ Reset the station coordinates

 JSR NWSPS              \ Add a new space station to our local bubble of
                        \ universe

 LDX #10                \ Flip the station around nosev to reverse the flip
 JSR FlipShip           \ that's done in NWSPS

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

 JSR DKS4               \ Call DKS4 with X = 0 to check whether the SHIFT key is
                        \ being pressed

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

                        \ This routine is called following ZINF2, so the
                        \ orientation vectors are set as follows:
                        \
                        \   sidev = (1,  0,  0)
                        \   roofv = (0,  1,  0)
                        \   nosev = (0,  0,  1)

 LDA TYPE               \ If this is a ship or station, jump to init3 to set a
 BPL init3              \ distance of 2 or 5

 LDA #0                 \ Pitch the planet so the crater is visible (in case we
 JSR TWIST2             \ switch planet types straight away)
 LDA #0
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

                        \ This routine is called following ZINF2, so the
                        \ orientation vectors are set as follows:
                        \
                        \   sidev = (1,  0,  0)
                        \   roofv = (0,  1,  0)
                        \   nosev = (0,  0,  1)

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
                        \   sidev = (0,  0,  1)
                        \   roofv = (0,  1,  0)
                        \   nosev = (-1, 0,  0)

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

 LDX TYPE               \ If this is not the station, jump to init9
 CPX #SST
 BNE init9

                        \ This is the station, so flip it around so the slot is
                        \ pointing at us

 LDX #10                \ Flip the station around nosev to point it towards us
 JSR FlipShip

 BNE init9              \ Jump to init9 (this BNE is effectively a JMP as X is
                        \ never zero)

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

 CMP #'a'               \ If key is less than 'A', it is invalid, so jump to
 BCC add4               \ add4 to return from the subroutine

 CMP #'y'               \ If key is 'Y or greater, it is invalid, so jump to
 BCS add4               \ add4  to return from the subroutine

                        \ Key is 'A' to 'X'

 SBC #'a'-11            \ Otherwise calculate ship type with 'A' = 10 (the C
                        \ flag is clear for this calculation)

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

 JSR ZINF2              \ Call ZINF2 to reset INWK and the orientation vectors,
                        \ with nosev pointing into the screen

 JSR InitialiseShip     \ Initialise the ship coordinates

 JSR CreateShip         \ Create the new ship

.add4

 LDA #185               \ Print text token 25 ("SHIP") followed by a question
 JMP ShowPrompt         \ mark to remove it from the screen, and return from the
                        \ subroutine using a tail call

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

 BCC crea1              \ If ship was not added, make an error beep and return
                        \ from the subroutine

 JSR GetCurrentSlot     \ Set X to the slot number of the new ship

 BCS crea1              \ If we didn't find the slot, make an error beep and
                        \ return from the subroutine

 JSR UpdateSlotNumber   \ Store and print the new slot number in X

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JMP DrawShip           \ Draw the ship, returning from the subroutine using a
                        \ tail call

.crea1

 LDA #40                \ Call the NOISE routine with A = 40 to make a low,
 JMP NOISE              \ long beep to indicate the missile is now disarmed,
                        \ returning from the subroutine using a tail call

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

 LDA #YELLOW            \ Send a #SETCOL YELLOW command to the I/O processor to
 JSR DOCOL              \ switch to colour 1, which is yellow

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
\ ******************************************************************************

.CopyShip

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
\ ******************************************************************************

.DeleteShip

 JSR EraseShip          \ Erase the current ship from the screen

 LDX XSAV2              \ Delete the current ship, shuffling the slots down
 JSR KILLSHP

 LDX XSAV2              \ If the current slot is still full, jump to delt1 to
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
\   XSAV2               Slot number for ship currently in INF
\
\ ******************************************************************************

.UpdateSlotNumber

 PHX                    \ Store the new slot number on the stack

 JSR PrintSlotNumber    \ Erase the current slot number from screen

 PLX                    \ Retrieve the new slot number from the stack

 STX XSAV2              \ Set the current slot number to the new slot number

 JMP PrintSlotNumber    \ Print new slot number and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: PrintSlotNumber
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Print the slot number in XSAV2 on-screen
\
\ ******************************************************************************

.PrintSlotNumber

 LDX XSAV2              \ Print the current slot number at text location (0, 1)
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

 LDX XSAV2              \ Fetch the current slot number

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

 LDX XSAV2              \ Fetch the current slot number

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

 LDX XSAV2              \ Get the ship data for the new slot
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

.endUniverseEditor
