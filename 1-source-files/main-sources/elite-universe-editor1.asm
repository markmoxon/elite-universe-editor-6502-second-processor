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

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JMP DrawShip+6         \ Draw the ship (but not on the scanner) and return from
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

.endUniverseEditor1
