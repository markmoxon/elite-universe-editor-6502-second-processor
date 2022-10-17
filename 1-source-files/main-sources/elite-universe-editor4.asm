\ ******************************************************************************
\
\ ELITE UNIVERSE EDITOR (PART 4)
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
\       Name: ApplyMods
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Apply mods for the universe editor
\
\ ******************************************************************************

.ApplyMods

IF _6502SP_VERSION

 LDA #250               \ Switch to the Universe Editor dashboard
 JSR SwitchDashboard

 LDA #&24               \ Disable the TRB XX1+31 instruction in part 9 of LL9
 STA LL74+20            \ that disables the laser once it has fired, so that
                        \ lasers remain on-screen while in the editor

ELIF _MASTER_VERSION

 JSR EditorDashboard    \ Switch to the Universe Editor dashboard

 LDA #&24               \ Disable the STA XX1+31 instruction in part 9 of LL9
 STA LL74+16            \ that disables the laser once it has fired, so that
                        \ lasers remain on-screen while in the editor

ENDIF

 LDA #%11100111         \ Disable the clearing of bit 7 (lasers firing) in
 STA WS1-3              \ WPSHPS

 LDA #&60               \ Disable DOEXP so that by default it draws an explosion
 STA DOEXP+9            \ cloud but doesn't recalculate it

 LDX #8                 \ The size of the default universe filename

.mods1

 LDA defaultName,X      \ Copy the X-th character of the filename to NAME
 STA NAME,X

 DEX                    \ Decrement the loop counter

 BPL mods1              \ Loop back for the next byte of the universe filename

 STZ showingS           \ Zero the flags that keep track of the bulb indicators
 STZ showingE

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: RevertMods
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Reverse mods for the universe editor
\
\ ******************************************************************************

.RevertMods

 LDA showingS           \ If we are showing the station buld, call SPBLB to
 BEQ P%+5               \ remove it
 JSR SPBLB

 LDA showingE           \ If we are showing the E.C.M. bulb, call ECBLB to
 BEQ P%+5               \ remove it
 JSR ECBLB

IF _6502SP_VERSION

 LDA #&14               \ Re-enable the TRB XX1+31 instruction in part 9 of LL9
 STA LL74+20

ELIF _MASTER_VERSION

 LDA #&85               \ Re-enable the STA XX1+31 instruction in part 9 of LL9
 STA LL74+16

ENDIF

 LDA #%10100111         \ Re-enable the clearing of bit 7 (lasers firing) in
 STA WS1-3              \ WPSHPS

 LDA #&A5               \ Re-enable DOEXP
 STA DOEXP+9

 JSR DFAULT             \ Call DFAULT to reset the current commander data
                        \ block to the last saved commander

IF _6502SP_VERSION

 LDA #251               \ Switch to the main game dashboard, returning from the
 JMP SwitchDashboard    \ subroutine using a tail call

ELIF _MASTER_VERSION

 JMP GameDashboard      \ Switch to the main game dashboard, returning from the
                        \ subroutine using a tail call

ENDIF

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

 JSR PrintShipType      \ Print the current ship type on the screen

 JSR DrawShips          \ Draw all ships

.view1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ConfirmChoice
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Display a prompt and ask for confirmation
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Set if "Y" was pressed, clear if "N" was pressed
\
\
\ ******************************************************************************

.ConfirmChoice

 LDA #5                 \ Print extended token 5 ("ARE YOU SURE?") as a prompt
 JSR PrintPrompt

 JSR GETYN              \ Call GETYN to wait until either "Y" or "N" is pressed

 PHP                    \ Store the response in the C flag on the stack

 LDA #5                 \ Print extended token 5 ("ARE YOU SURE?") as a prompt
 JSR PrintPrompt        \ to remove it

 PLP                    \ Restore the response from the stack

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

 JSR ConfirmChoice      \ Print "Are you sure?" at the bottom of the screen and
                        \ wait for a response

 BCS quit1              \ If "Y" was pressed, jump to quit1 to quit

 JMP edit3              \ Rejoin the main loop after the key has been processed

.quit1

 JSR RevertMods         \ Revert the mods we made when the Universe Editor
                        \ started up

 JMP BR1                \ Quit the scene editor by returning to the start

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
\       Name: PrintPrompt
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Show a prompt on-screen
\
\ ------------------------------------------------------------------------------
\
\ Set up the text cursor and colour for an in-flight message in capitals at the
\ bottom of the space view.
\
\ ******************************************************************************

.PrintPrompt

 PHA                    \ Store the token number on the stack

 LDA #0                 \ Set the delay in DLY to 0, so any new in-flight
 STA DLY                \ messages will be shown instantly

IF _6502SP_VERSION

 LDA #YELLOW            \ Send a #SETCOL YELLOW command to the I/O processor to
 JSR DOCOL              \ switch to colour 1, which is yellow

ELIF _MASTER_VERSION

 LDA #YELLOW            \ Switch to colour 1, which is yellow
 STA COL

ENDIF

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case
 STX QQ17

 LDA #10                \ Move the text cursor to column 10
 JSR DOXC

 LDA #22                \ Move the text cursor to row 22
 JSR DOYC

 PLA                    \ Print the token
 JSR PrintToken

 RTS                    \ Return from the subroutine

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

 BEQ SwitchToSlot       \ Jump to SwitchToSlot to get the planet's data (this
                        \ BEQ is effectively a JMP as X is always 0), returning
                        \ from the subroutine using a tail call

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

 LDX #1                 \ Start at the first ship slot (slot 1) and work
                        \ forwards until we find an empty slot

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

 JSR PrintShipType      \ Remove the current ship type from the screen

 LDX currentSlot        \ Get the ship data for the new slot
 JSR GetShipData

 JSR PrintShipType      \ Print the current ship type on the screen

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
\       Name: HighlightScanner
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Highlight the current ship on the scanner
\
\ ******************************************************************************

.HighlightScanner

 LDX TYPE               \ If this is the sun or planet, give an error beep and
 BPL P%+5               \ return from the subroutine using a tail call, as they
 JMP MakeErrorBeep      \ don't appear on the scanner

 LDX #10                \ Move the ship on the scanner up by up to 10 steps

.hsca1

 PHX                    \ Store the loop counter in X on the stack

 JSR SCAN               \ Draw the ship on the scanner to remove it

 LDA INWK+4             \ Move the ship up/down by 2, applied to y_hi
 CLC
 ADC #2
 STA INWK+4
 BCC P%+4
 INC INWK+5

 JSR SCAN               \ Redraw the ship on the scanner

 LDY #2                 \ Wait for 2/50 of a second (0.04 seconds)
 JSR DELAY

 PLX                    \ Retrieve the loop counter in X and decrement it
 DEX

 BPL hsca1              \ Loop back until we have moved the ship X times

 LDX #10                \ Move the ship on the scanner up by up to 10 steps

.hsca2

 PHX                    \ Store the loop counter in X on the stack

 JSR SCAN               \ Draw the ship on the scanner to remove it

 LDA INWK+4             \ Move the ship down/up by 2, applied to y_hi
 SEC
 SBC #2
 STA INWK+4
 BCS P%+4
 DEC INWK+5

 JSR SCAN               \ Draw the ship on the scanner to remove it

 LDY #2                 \ Wait for 2/50 of a second (0.04 seconds)
 JSR DELAY

 PLX                    \ Retrieve the loop counter in X and decrement it
 DEX

 BPL hsca2              \ Loop back until we have moved the ship X times

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: HighlightShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Highlight the current ship on-screen
\
\ ******************************************************************************

.HighlightShip

 LDX TYPE               \ Get the current ship type

 BMI high2              \ If this is the planet or sun, jump to high2

                        \ If we get here then this is a ship or the station

 LDA INWK+31            \ If bit 5 of byte #31 is set, then the ship is
 AND #%00100000         \ exploding, so return from the subroutine
 BNE HighlightShip-1

 LDA shpcol,X           \ Set A to the ship colour for this type, from the X-th
                        \ entry in the shpcol table

IF _6502SP_VERSION

 JSR DOCOL              \ Send a #SETCOL command to the I/O processor to switch
                        \ to this colour

ELIF _MASTER_VERSION

 STA COL                \ Switch to this colour

ENDIF

 JSR high1              \ Repeat the following subroutine twice

 LDX currentSlot        \ Get the ship data for the current slot, as otherwise
 JSR GetShipData        \ we will leave the wrong axes in INWK, and return from
                        \ the subroutine using a tail call

 LDY #5                 \ Wait for 5/50 of a second (0.1 seconds)
 JSR DELAY

.high1

 LDA NEWB               \ Set bit 7 of the ship to indicate it has docked (so
 ORA #%10000000         \ the call to LL9 removes it from the screen)
 STA NEWB

 JSR SCAN               \ Draw the ship on the scanner to remove it

 JSR PLUT               \ Call PLUT to update the geometric axes in INWK to
                        \ match the view (front, rear, left, right)

 JSR LL9                \ Draw the existing ship to erase it

 LDY #5                 \ Wait for 5/50 of a second (0.1 seconds)
 JSR DELAY

 LDX currentSlot        \ Get the ship data for the current slot, as otherwise
 JSR GetShipData        \ we will use the wrong axes in INWK

 JSR SCAN               \ Redraw the ship on the scanner

 JSR PLUT               \ Call PLUT to update the geometric axes in INWK to
                        \ match the view (front, rear, left, right)

 JMP LL9                \ Redraw the existing ship, returning from the
                        \ subroutine using a tail call

.high2

                        \ If we get here then this is the planet or sun

IF _6502SP_VERSION

 LDA #GREEN             \ Send a #SETCOL GREEN command to the I/O processor to
 JSR DOCOL              \ switch to stripe 3-1-3-1, which is cyan/yellow in the
                        \ space view

ELIF _MASTER_VERSION

 LDA #GREEN             \ Switch to stripe 3-1-3-1, which is cyan/yellow in the
 STA COL                \ space view

ENDIF

.high3

 JSR high4              \ Repeat the following subroutine twice

 LDY #5                 \ Wait for 5/50 of a second (0.1 seconds)
 JSR DELAY

.high4

 LDA #48                \ Move the planet or sun far away so it gets erased by
 STA INWK+8             \ the call to LL9

 JSR LL9                \ Redraw the planet or sun, which erases it from the
                        \ screen

 LDY #5                 \ Wait for 5/50 of a second (0.1 seconds)
 JSR DELAY

 LDX currentSlot        \ Get the ship data for the current slot, as otherwise
 JSR GetShipData        \ we will use the wrong axes in INWK

 JSR PLUT               \ Call PLUT to update the geometric axes in INWK to
                        \ match the view (front, rear, left, right)

 JMP LL9                \ Redraw the planet or sun and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: defaultName
\       Type: Variable
\   Category: Universe editor
\    Summary: The default name for a universe file
\
\ ******************************************************************************

.defaultName

 EQUS "MYSCENE"
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

\ ******************************************************************************
\
\       Name: saveCommand
\       Type: Variable
\   Category: Universe editor
\    Summary: The OS command string for saving a universe file
\
\ ******************************************************************************

.saveCommand

IF _MASTER_VERSION

IF _SNG47

 EQUS "SAVE :1.U.MYSCENE  3FF +31E 0 0"
 EQUB 13

ELIF _COMPACT

 EQUS "SAVE MYSCENE  3FF +31E 0 0"
 EQUB 13

ENDIF

ENDIF

\ ******************************************************************************
\
\       Name: deleteCommand
\       Type: Variable
\   Category: Universe editor
\    Summary: The OS command string for deleting a universe file
\
\ ******************************************************************************

.deleteCommand

IF _MASTER_VERSION

 EQUS "DELETE :1.U.MYSCENE"
 EQUB 13

ENDIF

\ ******************************************************************************
\
\       Name: loadCommand
\       Type: Variable
\   Category: Universe editor
\    Summary: The OS command string for loading a universe file
\
\ ******************************************************************************

.loadCommand

IF _MASTER_VERSION

IF _SNG47

 EQUS "LOAD :1.U.MYSCENE  3FF"
 EQUB 13

ELIF _COMPACT

 EQUS "LOAD MYSCENE  3FF"
 EQUB 13

ENDIF

ENDIF

\ ******************************************************************************
\
\       Name: PrintToken
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

.PrintToken

 PHA                    \ Store A on the stack, so we can retrieve it later

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 JSR MT19               \ Call MT19 to capitalise the next letter (i.e. set
                        \ Sentence Case for this word only)

 LDA #LO(UniverseToken) \ Set V to the low byte of UniverseToken
 STA V

 LDA #HI(UniverseToken) \ Set A to the high byte of UniverseToken

 JMP DTEN               \ Call DTEN to print token number X from the
                        \ UniverseToken table and restore the values of A, Y and
                        \ V(1 0) from the stack, returning from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: ShowDiscMenu
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Show the universe disc menu
\
\ ******************************************************************************

.ShowDiscMenu

 TSX                    \ Transfer the stack pointer to X and store it in stack,
 STX stack              \ so we can restore it in the break handler

 LDA #LO(NAME)          \ Change TR1 so it uses the universe name in NAME as the
 STA GTL2+1             \ default when no filename is entered
 LDA #HI(NAME)
 STA GTL2+2

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

 STA DELI+9             \ Change the directory to U

 LDA #&4C               \ Stop MEBRK error handler from returning to the SVE
 STA SVE                \ routine, jump back here instead
 LDA #LO(ReturnToDiscMenu)
 STA SVE+1
 LDA #HI(ReturnToDiscMenu)
 STA SVE+2

ELIF _MASTER_VERSION

 LDA #LO(ReturnToDiscMenu) \ Stop BRBR error handler from returning to the SVE
 STA DEATH-2               \ routine, jump back here instead
 LDA #HI(ReturnToDiscMenu)
 STA DEATH-1

ENDIF

 JSR ChangeDirectory

\ ******************************************************************************
\
\       Name: ReturnToDiscMenu
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Show the universe disc menu
\
\ ******************************************************************************

.ReturnToDiscMenu

                        \ The following is based on the SVE routine for the
                        \ normal disc access menu

IF _6502SP_VERSION

 JSR ZEBC               \ Call ZEBC to zero-fill pages &B and &C

ENDIF

IF _6502SP_VERSION

 LDA #LO(MEBRK)         \ Set BRKV to point to the MEBRK routine, disabling
 SEI                    \ interrupts while we make the change and re-enabling
 STA BRKV               \ them once we are done. MEBRK is the BRKV handler for
 LDA #HI(MEBRK)         \ disc access operations, and replaces the standard BRKV
 STA BRKV+1             \ handler in BRBR while disc access operations are
 CLI                    \ happening

ENDIF

IF _MASTER_VERSION

 JSR TRADE              \ Set the palette for trading screens and switch the
                        \ current colour to white

ENDIF

 LDA #1                 \ Print extended token 1, the disc access menu, which
 JSR PrintToken         \ presents these options:
                        \
                        \   1. Load Universe
                        \   2. Save Universe {universe name}
                        \   3. Catalogue
                        \   4. Delete A File
                        \   5. Play Universe
                        \   6. Exit

 JSR t                  \ Scan the keyboard until a key is pressed, returning
                        \ the ASCII code in A and X

 CMP #'1'               \ If A < ASCII "1", jump to disc5 to exit as the key
 BCC disc5              \ press doesn't match a menu option

 CMP #'4'               \ If "4" was not pressed, jump to disc1
 BNE disc1

                        \ Option 4: Delete

 JSR DeleteUniverse     \ Delete a file

 JMP ReturnToDiscMenu   \ Show disc menu

.disc1

 CMP #'5'               \ If "5" was not pressed, jump to disc2 to skip the
 BNE disc2              \ following

                        \ Option 5: Play universe

 JMP PlayUniverse       \ Play the current universe file

.disc2

 BCS disc5              \ If A >= ASCII "5", jump to disc5 to exit as the key
                        \ press is either option 6 (exit), or it doesn't match a
                        \ menu option (as we already checked for "5" above)

 CMP #'2'               \ If A >= ASCII "2" (i.e. save or catalogue), skip to
 BCS disc3              \ disc3

                        \ Option 1: Load

 JSR GTNMEW             \ If we get here then option 1 (load) was chosen, so
                        \ call GTNMEW to fetch the name of the commander file
                        \ to load (including drive number and directory) into
                        \ INWK

 JSR LoadUniverse       \ Call LoadUniverse to load the commander file

 JSR StoreName          \ Transfer the universe filename from INWK to NAME, to
                        \ set it as the current filename

 JMP disc5              \ Jump to disc5 to return from the subroutine

.disc3

 BEQ disc4              \ We get here following the CMP #'2' above, so this
                        \ jumps to disc4 if option 2 (save) was chosen

                        \ Option 3: Catalogue

 JSR CATS               \ Call CATS to ask for a drive number, catalogue that
                        \ disc and update the catalogue command at CTLI

 JSR t                  \ Scan the keyboard until a key is pressed, returning
                        \ the ASCII code in A and X

 JMP ReturnToDiscMenu   \ Show the disc menu again

.disc4

                        \ Option 2: Save

 JSR SaveUniverse       \ Save the universe file

 JMP ReturnToDiscMenu   \ Show the disc menu again

.disc5

                        \ Option 6: Exit

 JSR RevertDiscMods     \ Reverse all the modifications we did above

 LDX #0                 \ Draw the front view, returning from the subroutine
 STX VIEW               \ using a tail call
 JMP ChangeView+8

\ ******************************************************************************
\
\       Name: RevertDiscMods
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Reverse the mods we added for the disc access menu
\
\ ******************************************************************************

.RevertDiscMods

 LDA #'E'               \ Change the directory back to E
 STA S1%+3
 STA dirCommand+4

IF _6502SP_VERSION

 STA DELI+9             \ Change the directory back to E

ENDIF

 JSR ChangeDirectory

 LDA #&CD               \ Revert token 8 in TKN1 to "Commander's Name"
 STA token8
 LDA #&70
 STA token8+1
 LDA #&04
 STA token8+2

 LDA #LO(NA%)           \ Revert TR1 so it uses the commander name in NA% as the
 STA GTL2+1             \ default when no filename is entered
 LDA #HI(NA%)
 STA GTL2+2

IF _6502SP_VERSION

 LDA #&20               \ Return MEBRK error handler to its default state
 SEI
 STA SVE
 LDA #LO(ZEBC)
 STA SVE+1
 LDA #HI(ZEBC)
 STA SVE+2
 CLI

 JMP BRKBK              \ Jump to BRKBK to set BRKV back to the standard BRKV
                        \ handler for the game, and return from the subroutine
                        \ using a tail call

ELIF _MASTER_VERSION

 LDA #LO(SVE)           \ Return BRBR error handler to default state
 STA DEATH-2
 LDA #HI(SVE)
 STA DEATH-1

 RTS                    \ Return from the subroutine

ENDIF

\ ******************************************************************************
\
\       Name: LoadUniverse
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Load a universe file
\
\ ******************************************************************************

.LoadUniverse

IF _6502SP_VERSION

 JSR ZEBC               \ Call ZEBC to zero-fill pages &B and &C

 LDY #HI(K%-1)          \ Set up an OSFILE block at &0C00, containing:
 STY &0C03              \
 LDY #LO(K%-1)          \ Load address = K%-1 in &0C02 to &0C05
 STY &0C02              \
                        \ Length of file = 1+&2E4+JUNK-FRIN+1 in &0C0A to &0C0D
                        \
                        \ The file is made up of:
                        \
                        \   * The file format (1 byte)
                        \
                        \   * The ship slots at K% (&2E4 bytes)
                        \     20 ships, 37 bytes each, 20 * 37 = 740 = &2E4
                        \
                        \   * FRIN          MANY/SSPR       JUNK (&39 bytes)
                        \     NOSH + 1      NTY + 1         1
                        \     21            35              1
                        \     21 + 35 + 1 = 57 = &39 = JUNK - FRIN + 1

 LDY #HI(1+&2E4+JUNK-FRIN+1)
 STY &0C0B
 LDY #LO(1+&2E4+JUNK-FRIN+1)
 STY &0C0A

ELIF _MASTER_VERSION

 JSR SetFilename        \ Copy the filename to the load and save commands

ENDIF

 LDA #&FF               \ Call SaveLoadFile with A = &FF to load the universe
 JSR SaveLoadFile       \ file to address K%-1

 BCS load1              \ If the C flag is set then an invalid drive number was
                        \ entered during the call to SaveLoadFile and the file
                        \ wasn't loaded, so jump to load1 to skip the following
                        \ and return from the subroutine

 JSR StoreName          \ Transfer the universe filename from INWK to NAME, to
                        \ set it as the current filename

                        \ We now split up the file, by copying the data after
                        \ the end of the K% block into FRIN, MANY and JUNK

 LDA #HI(K%+&2E4)       \ Copy NOSH + 1 bytes from K%+&2E4 to FRIN
 STA P+1
 LDA #LO(K%+&2E4)
 STA P
 LDA #HI(FRIN)
 STA Q+1
 LDA #LO(FRIN)
 STA Q
 LDY #NOSH+1
 JSR CopyBlock

 LDA #HI(K%+&2E4+NOSH+1)  \ Copy NTY + 1 bytes from K%+&2E4+NOSH+1 to MANY
 STA P+1
 LDA #LO(K%+&2E4+NOSH+1)
 STA P
 LDA #HI(MANY)
 STA Q+1
 LDA #LO(MANY)
 STA Q
 LDY #NTY+1
 JSR CopyBlock

 LDA K%+&2E4+NOSH+1+NTY+1 \ Copy 1 byte from K%+&2E4+NOSH+1+NTY+1 to JUNK
 STA JUNK

 LDA K%-1               \ Extract the file format number
 STA K

IF _6502SP_VERSION

 CMP #1                 \ If this is a 6502SP format file, then jump to load1 as
 BEQ load1              \ we don't need to make any changes

                        \ We are loading a Master file into the 6502SP version,
                        \ so we need to make the following changes:
                        \
                        \   * Change any Cougars from type 32 to 33
                        \
                        \   * Fix the ship heap addresses in INWK+33 and INWK+34
                        \     by adding &D000-&0800 (as the ship line heap
                        \     descends from &D000 in the 6502SP version and from
                        \     &0800 in the Master version)

 LDX #32                \ Set K = 32, to act as the search value
 STX K

 INX                    \ Set K+1 = 33, to act as the replacement value
 STX K+1

 STZ K+2                \ Set K+2 = 0, to indicate addition of the ship heap
                        \ addresses

 STZ K+3                \ Set K+3 = 0, so we don't delete any ships

 JSR ConvertFile        \ Convert the file to the correct format

ELIF _MASTER_VERSION

 CMP #2                 \ If this is a Master format file, then jump to load1 as
 BEQ load1              \ we don't need to make any changes

                        \ We are loading a 6502SP file into the Master version,
                        \ so we need to make the following changes:
                        \
                        \   * Change any Cougars from type 33 to 32
                        \
                        \   * Fix the ship heap addresses in INWK+33 and INWK+34
                        \     by subtracting &D000-&0800 (as the ship line heap
                        \     descends from &D000 in the 6502SP version and from
                        \     &0800 in the Master version)

 LDX #33                \ Set K = 33, to act as the search value
 STX K

 DEX                    \ Set K+1 = 32, to act as the replacement value
 STX K+1

 STX K+3                \ Set K+3 = 32, so we delete the Elite logo from the
                        \ 6502SP file (before doing the above search)

 LDX #1                 \ Set K+2 = 1, to indicate subtraction of the ship heap
 STX K+2                \ addresses

 JSR ConvertFile        \ Convert the file to the correct format

ENDIF

.load1

 SEC                    \ Set the C flag

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SaveUniverse
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Save a universe file
\
\ ******************************************************************************

.SaveUniverse

 JSR GTNMEW             \ If we get here then option 2 (save) was chosen, so
                        \ call GTNMEW to fetch the name of the commander file
                        \ to save (including drive number and directory) into
                        \ INWK

 JSR StoreName          \ Transfer the universe filename from INWK to NAME, to
                        \ set it as the current filename

IF _6502SP_VERSION

 JSR ZEBC               \ Call ZEBC to zero-fill pages &B and &C

 LDY #HI(K%-1)          \ Set up an OSFILE block at &0C00, containing:
 STY &0C0B              \
 LDY #LO(K%-1)          \ Start address for save = K%-1 in &0C0A to &0C0D
 STY &0C0A              \
                        \ End address for save = K%+&2E4+JUNK-FRIN+1 in &0C0E
                        \ to &0C11

 LDY #HI(K%+&2E4+JUNK-FRIN+1)
 STY &0C0F
 LDY #LO(K%+&2E4+JUNK-FRIN+1)
 STY &0C0E

ELIF _MASTER_VERSION

 JSR SetFilename        \ Copy the filename to the load and save commands

ENDIF

                        \ We now assemble the file in one place, by copying the
                        \ data from FRIN, MANY and JUNK to the space after the
                        \ end of the K% ship data block

 LDA #HI(FRIN)          \ Copy NOSH + 1 bytes from FRIN to K%+&2E4
 STA P+1
 LDA #LO(FRIN)
 STA P
 LDA #HI(K%+&2E4)
 STA Q+1
 LDA #LO(K%+&2E4)
 STA Q
 LDY #NOSH+1
 JSR CopyBlock

 LDA #HI(MANY)          \ Copy NTY + 1 bytes from MANY to K%+&2E4+20+1 (so we
 STA P+1                \ always save for NOSH = 20, even if NOSH is less)
 LDA #LO(MANY)
 STA P
 LDA #HI(K%+&2E4+20+1)
 STA Q+1
 LDA #LO(K%+&2E4+20+1)
 STA Q
 LDY #NTY+1
 JSR CopyBlock

 LDA JUNK               \ Copy 1 byte from K%+&2E4+20+1+34+1 to JUNK (so we
 STA K%+&2E4+20+1+34+1  \ always save for NOSH = 20 and NTY = 34, even if they
                        \ are less

IF _6502SP_VERSION

 LDA #1                 \ Set file format byte (1 = 6502sp)
 STA K%-1

ELIF _MASTER_VERSION

 LDA #2                 \ Set file format byte (2 = Master)
 STA K%-1

ENDIF

 LDA #0                 \ Call SaveLoadFile with A = 0 to save the universe
 JSR SaveLoadFile       \ file with the filename we copied to INWK at the start
                        \ of this routine

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SetFilename
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Copy the filename from INWK to the save and load commands 
\
\ ******************************************************************************

IF _MASTER_VERSION

.SetFilename

 LDY #0                 \ We start by changing the load and save commands to
                        \ contain the filename that was just entered by the
                        \ user, so we set an index in Y so we can copy the
                        \ filename from INWK+5 into the command

.setf1

 LDA INWK+5,Y           \ Fetch the Y-th character of the filename

 CMP #13                \ If the character is a carriage return then we have
 BEQ setf2             \ reached the end of the filename, so jump to setf2 as
                        \ we have now copied the whole filename

IF _SNG47

 STA loadCommand+10,Y   \ Store the Y-th character of the filename in the Y-th
                        \ character of loadCommand+10, where loadCommand+10
                        \ points to the MYSCENE part of the load command in
                        \ loadCommand:
                        \
                        \   "LOAD :1.U.MYSCENE  3FF"

 STA saveCommand+10,Y   \ Store the Y-th character of the commander name in the
                        \ Y-th character of saveCommand+10, where saveCommand+10
                        \ points to the MYSCENE part of the save command in
                        \ saveCommand:
                        \
                        \   "SAVE :1.U.MYSCENE  3FF +31E 0 0"

ELIF _COMPACT

 STA loadCommand+5,Y    \ Store the Y-th character of the filename in the Y-th
                        \ character of loadCommand+5, where loadCommand+5
                        \ points to the MYSCENE part of the load command in
                        \ loadCommand:
                        \
                        \   "LOAD MYSCENE  3FF"

 STA saveCommand+5,Y    \ Store the Y-th character of the commander name in the
                        \ Y-th character of saveCommand+5, where saveCommand+5
                        \ points to the MYSCENE part of the save command in
                        \ saveCommand:
                        \
                        \   "SAVE MYSCENE  3FF +31E 0 0"
ENDIF

 INY                    \ Increment the loop counter

 CPY #7                 \ If Y < 7 then there may be more characters in the
 BCC setf1              \ name, so loop back to setf1 to fetch the next one

.setf2

 LDA #' '               \ We have copied the name into the loadCommand string,
                        \ but the new name might be shorter then the previous
                        \ one, so we now need to blank out the rest of the name
                        \ with spaces, so we load the space character into A

IF _SNG47

 STA loadCommand+10,Y   \ Store the Y-th character of the filename in the Y-th
                        \ character of loadCommand+10, which will be directly
                        \ after the last letter we copied above

 STA saveCommand+10,Y   \ Store the Y-th character of the commander name in the
                        \ Y-th character of saveCommand+10, which will be
                        \ directly after the last letter we copied above

ELIF _COMPACT

 STA loadCommand+5,Y    \ Store the Y-th character of the filename in the Y-th
                        \ character of loadCommand+5, which will be directly
                        \ after the last letter we copied above

 STA saveCommand+5,Y    \ Store the Y-th character of the commander name in the
                        \ Y-th character of saveCommand+5, which will be 
                        \ directly after the last letter we copied above

ENDIF

 INY                    \ Increment the loop counter

 CPY #7                 \ If Y < 7 then we haven't yet blanked out the whole
 BCC setf2              \ name, so loop back to setf2 to blank the next one
                        \ until the load string is ready for use

 RTS                    \ Return from the subroutine

ENDIF

\ ******************************************************************************
\
\       Name: PlayUniverse
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Play a universe file
\
\ ******************************************************************************

.PlayUniverse

 JSR ConfirmChoice      \ Print "Are you sure?" at the bottom of the screen and
                        \ wait for a response

 BCS play1              \ If "Y" was pressed, jump to play1 to play the universe

 JMP ReturnToDiscMenu   \ Otherwise return to the disc menu

.play1

 JSR RevertDiscMods     \ Revert the mods we made for the disc access menu

 JSR RevertMods         \ Revert the mods we made when the Universe Editor
                        \ started up

 LDX #1                 \ Force-load the front space view
 STX QQ11
 DEX
 JSR LOOK1

                        \ Do the following from DEATH2:

 LDX #&FF               \ Set the stack pointer to &01FF, which is the standard
 TXS                    \ location for the 6502 stack, so this instruction
                        \ effectively resets the stack

 LDA #&60               \ Modify the JSR ZERO in RES2 so it's an RTS, which
 STA yu+3               \ stops RES2 from resetting the ship slots, ship heap
                        \ and dashboard

 JSR RES2               \ Reset a number of flight variables and workspaces, but
                        \ without resetting the ship slots, ship heap or
                        \ dashboard

 LDA #&20               \ Re-enable the JSR ZERO in RES2
 STA yu+3

 LDA #&FF               \ Recharge the forward and aft shields
 STA FSH
 STA ASH

 STA ENERGY             \ Recharge the energy banks

                        \ We now do what ZERO would have done, but leaving
                        \ the ship slots alone, and we then call DIALS and ZINF
                        \ as we disabled them above

 LDX #(de-auto)         \ We're going to zero the UP workspace variables from
                        \ auto to de, so set a counter in X for the correct
                        \ number of bytes

 LDA #0                 \ Set A = 0 so we can zero the variables

.play2

 STA auto,X             \ Zero the X-th byte of FRIN to de

 DEX                    \ Decrement the loop counter

 BPL play2              \ Loop back to zero the next variable until we have done
                        \ them all

 JSR DIALS              \ Update the dashboard to show all the above values

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace

                        \ Do the following from BR1 (part 1):

IF _6502SP_VERSION

 JSR ZEKTRAN            \ Reset the key logger buffer that gets returned from
                        \ the I/O processor

ENDIF

 JSR U%                 \ Clear the key logger

 LDA #3                 \ Move the text cursor to column 3
 JSR DOXC

 LDX #3                 \ Set X = 3 for the call to FX200

IF _6502SP_VERSION

 JSR FX200              \ Disable the ESCAPE key and clear memory if the BREAK
                        \ key is pressed (*FX 200,3)

ELIF _MASTER_VERSION

 LDY #0                 \ Call OSBYTE 200 with Y = 0, so the new value is set to
 LDA #200               \ X, and return from the subroutine using a tail call
 JSR OSBYTE

ENDIF

 JSR DFAULT             \ Call DFAULT to reset the current commander data block
                        \ to the last saved commander

                        \ Do the following from BR1 (part 2):

 JSR msblob             \ Reset the dashboard's missile indicators so none of
                        \ them are targeted

 JSR ping               \ Set the target system coordinates (QQ9, QQ10) to the
                        \ current system coordinates (QQ0, QQ1) we just loaded

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 JSR jmp                \ Set the current system to the selected system

 LDX #5                 \ We now want to copy the seeds for the selected system
                        \ in QQ15 into QQ2, where we store the seeds for the
                        \ current system, so set up a counter in X for copying
                        \ 6 bytes (for three 16-bit seeds)

.play3

 LDA QQ15,X             \ Copy the X-th byte in QQ15 to the X-th byte in QQ2,
 STA QQ2,X

 DEX                    \ Decrement the counter

 BPL play3              \ Loop back to play3 if we still have more bytes to
                        \ copy

 LDA QQ3                \ Set the current system's economy in QQ28 to the
 STA QQ28               \ selected system's economy from QQ3

 LDA QQ5                \ Set the current system's tech level in tek to the
 STA tek                \ selected system's economy from QQ5

 LDA QQ4                \ Set the current system's government in gov to the
 STA gov                \ selected system's government from QQ4

                        \ Do the following from BAY:

 LDA #0                 \ Set QQ12 = 0 (the docked flag) to indicate that we
 STA QQ12               \ are not docked

                        \ We are done setting up, so now we play the game:

 LDA #1                 \ Reset DELTA (speed) to 1, so we go as slowly as
 STA DELTA              \ possible at the start

 JSR M%                 \ Call the M% routine to do the main flight loop once,
                        \ which will display the universe

 LDX #5                 \ Set a countdown timer, counting down from 5 (we can
 STX ECMA               \ use ECMA, as this is only used when E.C.M. is active)

.play4

 JSR ee3                \ Print the 8-bit number in X at text location (0, 1),
                        \ i.e. print the countdown in the top-left corner

 LDY #44                \ Wait for 44/50 of a second (0.88 seconds)
 JSR DELAY

 LDX ECMA               \ Fetch the counter

 JSR ee3                \ Re-print the 8-bit number in X at text location (0, 1)
                        \ to remove it

 DEC ECMA               \ Decrement the counter

 LDX ECMA               \ Fetch the counter

 BNE play4              \ Loop back to keep counting down until we reach zero

 JMP TT100+3            \ Jump to TT100, just after the JSR M%, to join the main
                        \ loop and play the game

\ ******************************************************************************
\
\       Name: UpdateCompass
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Update the compass with the current ship's position
\
\ ******************************************************************************

.UpdateCompass

 JSR DOT                \ Call DOT to redraw (i.e. remove) the current compass
                        \ dot

 JSR GetShipVector      \ Get the vector to the selected ship into XX15

 JMP SP2                \ Draw the dot on the compass

\ ******************************************************************************
\
\       Name: UpdateDashboard
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Update the dashboard with the current ship's details
\
\ ******************************************************************************

.UpdateDashboard

 LDA INWK+27            \ Set DELTA to the ship's energy speed
 STA DELTA

 LDA INWK+28            \ Set FSH to the ship's acceleration, adding 128 so it
 CLC                    \ goes from a signed 8-bit number:
 ADC #128               \
 STA FSH                \   0 to 127, -128 to -1
                        \
                        \ to the range:
                        \
                        \   128 to 255, 0 to 127
                        \
                        \ so positive is in the right half of the indicator, and
                        \ negative is in the left half

 LDA INWK+29            \ Set ALP1 and ALP2 to the magnitude and sign of the
 AND #%10000000         \ roll counter (magnitude of ALP1 is in the range 0-31)
 EOR #%10000000
 STA ALP2
 LDA INWK+29
 AND #%01111111 
 LSR A
 LSR A
 STA ALP1

 LDA INWK+30            \ Set BETA and BET1 to the value and magnitude of the
 AND #%10000000         \ pitch counter (BETA is in the range -8 to +8)
 STA T1
 LDA INWK+30
 AND #%01111111
 LSR A
 LSR A
 LSR A
 LSR A
 STA BET1
 ORA T1
 STA BETA

 LDA INWK+35            \ Set ENERGY to the ship's energy level
 STA ENERGY

 LDX #0                 \ Set ASH to the ship's AI setting (on/off) from bit 7
 BIT INWK+32            \ of INWK+32, reusing the aft shields indicator
 BPL P%+4
 LDX #&FF
 STX ASH

 LDX #0                 \ Set QQ14 to the ship's Innocent Bystander setting
 LDA INWK+36            \ (on/off) from bit 5 of INWK+36 (NEWB), reusing the
 AND #%00100000         \ fuel indicator
 BEQ P%+4
 LDX #70
 STX QQ14

 LDX #0                 \ Set CABTMP to the ship's Cop setting (on/off) from
 BIT INWK+36            \ bit 6 of INWK+36 (NEWB), reusing the cabin temperature
 BVC P%+4               \ indicator
 LDX #&FF
 STX CABTMP

 LDX #0                 \ Set GNTMP to the ship's Cop setting (on/off) from
 BIT INWK+32            \ bit 6 of INWK+32, reusing the laser temperature
 BVC P%+4               \ indicator
 LDX #&FF
 STX GNTMP

 LDA INWK+32            \ Set ALTIT to the ship's Aggression Level setting from
 AND #%00111110         \ bits 1-5 of INWK+32, reusing the altitude indicator
 ASL A
 ASL A
 STA ALTIT

 JSR DIALS              \ Update the dashboard

 LDA INWK+31            \ Get the number of missiles
 AND #%00000111

 CMP #5                 \ If there are 0 to 4 missiles, jump to upda1 to show
 BCC upda1              \ them in green

 LDY #YELLOW2           \ Modify the msblob routine so it shows missiles in
 STY SAL8+1             \ yellow

 SEC                    \ Subtract 4 from the missile count, so we just show the
 SBC #4                 \ missiles in positions 5-7

.upda1

 STA NOMSL              \ Set NOMSL to the number of missiles to show

 JSR msblob             \ Update the dashboard's missile indicators in green so
                        \ none of them are targeted

 LDA #GREEN2            \ Reverse the modification to the msblob routine so it
 STA SAL8+1             \ shows missiles in green once again

 JSR SetEBulb           \ Show or hide the E.C.M. bulb according to the setting
                        \ of bit 0 of INWK+32

 JSR SetSBulb           \ Show or hide the space station bulb according to the
                        \ setting of bit 4 of INWK+36 (NEWB)

.upda2

 JSR UpdateCompass      \ Update the compass

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SetSBulb
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Show or hide the S bulb
\
\ ******************************************************************************

.SetSBulb

 LDA INWK+36            \ If the space station bulb setting in bit 4 of INWK+36
 AND #%00010000         \ (NEWB) matches the display bit in showingS, then the
 EOR showingS           \ bulb is already correct, so jump to sets1 to return
 BEQ sets1              \ from the subroutine

 JSR SPBLB              \ Flip the space station bulb on-screen

 LDA #%00010000         \ Flip bit 4 of the showingS flag
 EOR showingS
 STA showingS

.sets1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SetEBulb
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Show or hide the E bulb
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   sete1               Contains an RTS
\
\ ******************************************************************************

.SetEBulb

 LDA INWK+32            \ If the E.C.M. bulb setting in bit 0 of INWK+32 matches
 AND #%00000001         \ the display bit in showingE, then the bulb is already
 EOR showingE           \ correct, so jump to sete1 to return from the
 BEQ sete1              \ subroutine

 JSR ECBLB              \ Flip the E.C.M. bulb on-screen

 LDA #%00000001         \ Flip bit 0 of the showingE flag
 EOR showingE
 STA showingE

.sete1

 RTS                    \ Return from the subroutine

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
\       Name: ToggleValue
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Toggle one of the ship's details
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Offset of INWK byte within INWK block
\
\   A                   Mask containing bits to toggle
\
\ ******************************************************************************

.ToggleValue

 STA P                  \ Store the bit mask in P

 LDA INWK,X             \ Flip the corresponding bits in INWK+X
 EOR P
 STA INWK,X

 JMP StoreValue         \ Store the updated results and update the dashboard,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PrintShipType
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Print the trader/bounty hunter/pirate flag
\
\ ******************************************************************************

.PrintShipType

IF _6502SP_VERSION

 LDA #RED               \ Send a #SETCOL RED command to the I/O processor to
 JSR DOCOL              \ switch to colour 2, which is red in the space view

ELIF _MASTER_VERSION

 LDA #RED               \ Switch to colour 2, which is red
 STA COL

ENDIF

 LDA #1                 \ Move the text cursor to column 24 on row 1
 JSR DOYC
 LDA #24
 JSR DOXC

 LDA TYPE               \ If this is not a missile, jump to ptyp0
 CMP #MSL
 BNE ptyp0

 LDA INWK+32            \ Extract the target number from bits 1-5 into X
 LSR A
 AND #%00011111
 TAX

 LDY #0                 \ Set Y = 0 for the high byte in pr6

 JMP pr6                \ Print the number in (Y X) and return from the
                        \ subroutine using a tail call

.ptyp0

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case
 STA QQ17

 LDA INWK+36            \ Set A to the NEWB flag in INWK+36

 LSR A                  \ Set the C flag to bit 0 of NEWB (trader)

 BCC ptyp1              \ If bit 0 is clear, jump to ptyp1

                        \ Bit 0 is set, so the ship is a trader

 LDA #2                 \ Print extended token 2 ("TRADER"), returning from the
 JMP PrintToken         \ subroutine using a tail call

.ptyp1

 LSR A                  \ Set the C flag to bit 1 of NEWB (bounty hunter)

 BCC ptyp2              \ If bit 1 is clear, jump to ptyp2

                        \ Bit 1 is set, so the ship is a bounty hunter

 LDA #3                 \ Print extended token 3 ("BOUNTY"), returning from the
 JMP PrintToken         \ subroutine using a tail call

.ptyp2

 LSR A                  \ Set the C flag to bit 3 of NEWB (pirate)
 LSR A

 BCC sete1              \ If bit 3 is clear, jump to sete1 to return from the
                        \ subroutine without printing anything (as sete1
                        \ contains an RTS)

 LDA #4                 \ Print extended token 4 ("PIRATE"), returning from the
 JMP PrintToken         \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: ToggleShipType
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Toggle the trader/bounty hunter/pirate flag
\
\ ******************************************************************************

.ToggleShipType

 JSR PrintShipType      \ Remove the current ship type from the screen

 LDA INWK+36            \ Set X and A to the NEWB flag
 TAX

 LSR A                  \ Set the C flag to bit 0 of NEWB (trader)

 BCC styp1              \ If bit 0 is clear, jump to styp1

                        \ Bit 0 is set, so we are already a trader, and we move
                        \ on to bounty hunter

 LDA #%00000010         \ Set bit 1 of A (bounty hunter) and jump to styp4
 BNE styp4

.styp1

 LSR A                  \ Set the C flag to bit 1 of NEWB (bounty hunter)

 BCC styp2              \ If bit 1 is clear, jump to styp2

                        \ Bit 1 is set, so we are already a bounty hunter, and
                        \ we move on to pirate

 LDA #%00001000         \ Set bit 3 of A (pirate) and jump to styp4
 BNE styp4

.styp2

 LSR A                  \ Set the C flag to bit 3 of NEWB (pirate)
 LSR A

 BCC styp3              \ If bit 3 is clear, jump to styp3

                        \ Bit 3 is set, so we are already a pirate, and we move
                        \ on to no status

 LDA #%00000000         \ Clear all bits of T (no status) and jump to styp4
 BEQ styp4

.styp3

 LDA #%00000001         \ Set bit 0 of A (trader)

.styp4

 STA T                  \ Store the bits we want to set in T

 TXA                    \ Set the bits in T in NEWB (which we fetch from X)
 AND #%11110100
 ORA T
 STA INWK+36

 JSR PrintShipType      \ Print the current ship type on the screen

 JMP StoreValue         \ Store the updated results and update the dashboard,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: ChangeMissiles
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Update the ship's missile count
\
\ ******************************************************************************

.ChangeMissiles

 LDA INWK+31            \ Extract the missile count from bits 0-2 of INWK+31
 AND #%00000111         \ into X
 TAX

 BIT shiftCtrl          \ If SHIFT is being held, jump to cham1 to reduce the
 BMI cham1              \ value

 INX                    \ Increment the number of missiles

 CPX #%00001000         \ If we didn't go past the maximum value, jump to cham3
 BCC cham3              \ to store the value

 BCS cham2              \ Jump to cham2 to beep (this BCS is effectively a JMP
                        \ as we just passed through a BCC)


.cham1

 DEX                    \ Decrement the number of missiles

 CPX #255               \ If we didn't wrap around to 255, jump to cham3
 BNE cham3              \ to store the value

.cham2

                        \ If we get here then we already reached the minimum or
                        \ maximum value, so we make an error beep and do not
                        \ update the value

 JMP BEEP               \ Beep to indicate we have reached the maximum and
                        \ return from the subroutine using a tail call

.cham3

 STX P                  \ Stick the new missile count into P

 LDA INWK+31            \ Insert the new missile count into bits 0-2 of
 AND #%11111000         \ INWK+31
 ORA P
 STA INWK+31

 JMP StoreValue         \ Store the updated results and update the dashboard,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: ChangeAggression
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Update the ship's aggression level
\
\ ******************************************************************************

.ChangeAggression

 LDA INWK+32            \ Extract the aggression level from bits 1-5 of INWK+32
 AND #%00111110         \ into X
 LSR A
 TAX

 BIT shiftCtrl          \ If SHIFT is being held, jump to chag1 to reduce the
 BMI chag1              \ value

 INX                    \ Increment the aggression level

 CPX #%00100000         \ If we didn't reach the maximum value, jump to chag3 
 BCC chag3              \ to store the value

 BCS chag2              \ Jump to chag2 to beep (this BCS is effectively a JMP
                        \ as we just passed through a BCC)

.chag1

 DEX                    \ Decrement the aggression level

 CPX #255               \ If we didn't wrap around to 255, jump to chag3
 BNE chag3              \ to store the value

.chag2

                        \ If we get here then we already reached the minimum or
                        \ maximum value, so we make an error beep and do not
                        \ update the value

 JMP BEEP               \ Beep to indicate we have reached the maximum and
                        \ return from the subroutine using a tail call

.chag3

 TXA                    \ Stick the new aggression level into P, shifted left
 ASL A                  \ by one place so we can OR it into the correct place in
 STA P                  \ INWK+32 (i.e. into bits 1-5)

 LDA INWK+32            \ Insert the new aggression level into bits 1-5 of
 AND #%11000001         \ INWK+32
 ORA P
 STA INWK+32

 JMP StoreValue         \ Store the updated results and update the dashboard,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: ChangeCounter
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Update one of the ship's counters
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Offset of INWK byte within INWK block
\
\ ******************************************************************************

.ChangeCounter

 LDA INWK,X             \ Extract the sign (bit 7) of the counter and store
 AND #%10000000         \ it in T
 STA T

 LDA INWK,X             \ Extract the magnitude of the counter into A
 AND #%01111111
 TAY

 BIT shiftCtrl          \ If SHIFT is being held, jump to chav5 to reduce the
 BMI chav5              \ value

 LDA T                  \ If the counter is negative, we need to decrease the
 BMI chav2              \ magnitude in Y, so jump to the DEY below

.chav1

 INY                    \ Otherwise increment the magnitude in Y

 EQUB &24               \ Skip the next instruction by turning it into &24 &88,
                        \ or BIT &0088, which does nothing apart from affect the
                        \ flags

.chav2

 DEY                    \ Decrement the magnitude in Y

 CPY #128               \ If Y has not yet overflowed, jump to chav3
 BNE chav3

 JMP BEEP               \ Beep to indicate we have reached the maximum and
                        \ return from the subroutine using a tail call

.chav3

 TYA                    \ If the magnitude is still positive, jump to chav4 to
 BPL chav4              \ skip the following

 LDA T                  \ Flip the sign in T, so we go past the middle point
 EOR #%10000000
 STA T

 LDY #0                 \ Set the counter magnitude to 0

.chav4

 TYA                    \ Copy the updated magnitude into A

 ORA T                  \ Put the sign back

 STA INWK,X             \ Updated the counter with the new value

 JMP StoreValue         \ Store the updated results and update the dashboard,
                        \ returning from the subroutine using a tail call

.chav5

 LDA T                  \ If the counter is positive, we need to decrease the
 BPL chav2              \ magnitude in Y, so jump to the DEY above

 BMI chav1              \ Jump up to chav1 to store the new value (this BMI is
                        \ effectively a JMP as we just passed through a BPL)

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
\       Name: GetShipVector
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Calculate the vector to the selected ship into XX15
\
\ ******************************************************************************

.GetShipVector

 LDY #8                 \ First we need to copy the ship's coordinates
                        \ into K3, so set a counter to copy the first 9 bytes
                        \ (the 3-byte x, y and z coordinates) from the ship's
                        \ data block in K% (pointed to by INF) into K3

.svec1

 LDA (INF),Y            \ Copy the X-th byte from the ship's data block at
 STA K3,Y               \ INF to the X-th byte of K3

 DEY                    \ Decrement the loop counter

 BPL svec1              \ Loop back to svec1 until we have copied all 9 bytes

 JMP TAS2               \ Call TAS2 to build XX15 from K3, returning from the
                        \ subroutine using a tail call

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

 ECHR 'T'               \ Token 2:    "TRADER"
 ETWO 'R', 'A'
 ECHR 'D'
 ETWO 'E', 'R'
 EQUB VE

 ECHR 'B'               \ Token 3:    "BOUNTY"
 ETWO 'O', 'U'
 ECHR 'N'
 ECHR 'T'
 ECHR 'Y'
 EQUB VE

 ECHR 'P'               \ Token 4:    "PIRATE"
 ECHR 'I'
 ETWO 'R', 'A'
 ECHR 'T'
 ECHR 'E'
 EQUB VE

 ECHR 'A'               \ Token 5:    "ARE YOU SURE?"
 ETWO 'R', 'E'
 ECHR ' '
 ETOK 179
 ECHR ' '
 ECHR 'S'
 ECHR 'U'
 ETWO 'R', 'E'
 ECHR '?'
 EQUB VE

 ECHR 'U'               \ Token 6:    "UNIVERSE EDITOR"
 ECHR 'N'
 ECHR 'I'
 ETWO 'V', 'E'
 ECHR 'R'
 ETWO 'S', 'E'
 ECHR ' '
 ETWO 'E', 'D'
 ETWO 'I', 'T'
 ETWO 'O', 'R'
 EQUB VE

 ECHR 'S'               \ Token 7:    "SLOT?"
 ETWO 'L', 'O'
 ECHR 'T'
 ECHR '?'
 EQUB VE

 ECHR 'T'               \ Token 8:    "TYPE?"
 ECHR 'Y'
 ECHR 'P'
 ECHR 'E'
 ECHR '?'
 EQUB VE

IF _MASTER_VERSION

\ ******************************************************************************
\
\       Name: TWIST
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Pitch the current ship by a small angle in a positive direction
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   TWIST2              Pitch in the direction given in A
\
\ ******************************************************************************

.TWIST2

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &00, or BIT &00A9, which does nothing apart
                        \ from affect the flags

.TWIST

 LDA #0                 \ Set A = 0

 STA RAT2               \ Set the pitch direction in RAT2 to A

 LDX #15                \ Rotate (roofv_x, nosev_x) by a small angle (pitch)
 LDY #9                 \ in the direction given in RAT2
 JSR MVS5

 LDX #17                \ Rotate (roofv_y, nosev_y) by a small angle (pitch)
 LDY #11                \ in the direction given in RAT2
 JSR MVS5

 LDX #19                \ Rotate (roofv_z, nosev_z) by a small angle (pitch)
 LDY #13                \ in the direction given in RAT2 and return from the
 JMP MVS5               \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: STORE
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Copy the ship data block at INWK back to the K% workspace
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   INF                 The ship data block in the K% workspace to copy INWK to
\
\ ******************************************************************************

.STORE

 LDY #(NI%-1)           \ Set a counter in Y so we can loop through the NI%
                        \ bytes in the ship data block

.DML2

 LDA INWK,Y             \ Load the Y-th byte of INWK and store it in the Y-th
 STA (INF),Y            \ byte of INF

 DEY                    \ Decrement the loop counter

 BPL DML2               \ Loop back for the next byte, until we have copied the
                        \ last byte from INWK back to INF

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ZEBC
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Zero-fill pages &B and &C
\
\ ******************************************************************************

.ZEBC

 LDX #&C                \ Call ZES1 with X = &C to zero-fill page &C
 JSR ZES1

 DEX                    \ Decrement X to &B

 JMP ZES1               \ Jump to ZES1 to zero-fill page &B

ENDIF

IF _6502SP_VERSION

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

\ ******************************************************************************
\
\       Name: dashboardBuff
\       Type: Variable
\   Category: Universe editor
\    Summary: Buffer for changing the dashboard
\
\ ******************************************************************************

.dashboardBuff

 EQUB 2                 \ The number of bytes to transmit with this command

 EQUB 2                 \ The number of bytes to receive with this command

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

.SwitchDashboard

 LDX #LO(dashboardBuff) \ Set (Y X) to point to the dashboardBuff parameter
 LDY #HI(dashboardBuff) \ block

 JMP OSWORD             \ Send an OSWORD command to the I/O processor to
                        \ draw the dashboard, returning from the subroutine
                        \ using a tail call

ENDIF

.endUniverseEditor4
