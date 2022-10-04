\ ******************************************************************************
\
\ ELITE UNIVERSE EDITOR (PART 2)
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

 LDA #1                 \ Set file format byte (1 = 6502sp)
 STA K%-1

 LDA #0                 \ Call SaveLoadFile with A = 0 to save the universe
 JSR SaveLoadFile       \ file with the filename we copied to INWK at the start
                        \ of this routine

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CopyBlock
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Copy a small block of memory
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   Y                   Number of bytes to copy - 1
\
\   P(1 0)              From address
\
\   Q(1 0)              To address
\
\ ******************************************************************************

.CopyBlock

 LDA (P),Y              \ Copy byte X from P(1 0) to Q(1 0)
 STA (Q),Y

 DEY                    \ Decrement the counter

 BPL CopyBlock          \ Loop back until all X bytes are copied

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: StoreName
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Store the name of the current universe file
\
\ ******************************************************************************

.StoreName

 LDX #7                 \ The universe's name can contain a maximum of 7
                        \ characters, and is terminated by a carriage return,
                        \ so set up a counter in X to copy 8 characters

.snam1

 LDA INWK+5,X           \ Copy the X-th byte of INWK+5 to the X-th byte of NA%
 STA NAME,X

 DEX                    \ Decrement the loop counter

 BPL snam1              \ Loop back until we have copied all 8 bytes

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SaveLoadFile
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Save or load a universe file
\
\ ------------------------------------------------------------------------------
\
\ The filename should be stored at INWK, terminated with a carriage return (13).
\ The routine asks for a drive number and updates the filename accordingly
\ before performing the load or save.
\
\ Arguments:
\
\   A                   File operation to be performed. Can be one of the
\                       following:
\
\                         * 0 (save file)
\
\                         * &FF (load file)
\
\ Returns:
\
\   C flag              Set if an invalid drive number was entered
\
\ ******************************************************************************

.SaveLoadFile

 PHA                    \ Store A on the stack so we can restore it after the
                        \ call to GTDRV

 JSR GTDRV              \ Get an ASCII disc drive drive number from the keyboard
                        \ in A, setting the C flag if an invalid drive number
                        \ was entered

 STA INWK+1             \ Store the ASCII drive number in INWK+1, which is the
                        \ drive character of the filename string ":0.E."

 PLA                    \ Restore A from the stack

 BCS slod1              \ If the C flag is set, then an invalid drive number was
                        \ entered, so jump to slod1 to return from the subroutine

IF _6502SP_VERSION

 PHA                    \ Store A on the stack so we can restore it after the
                        \ call to DODOSVN

 LDA #255               \ Set the SVN flag to 255 to indicate that disc access
 JSR DODOSVN            \ is in progress

 PLA                    \ Restore A from the stack

ENDIF

 LDX #INWK              \ Store a pointer to INWK at the start of the block at
 STX &0C00              \ &0C00, storing #INWK in the low byte because INWK is
                        \ in zero page

 LDX #0                 \ Set (Y X) = &0C00
 LDY #&C

 JSR OSFILE             \ Call OSFILE to do the file operation specified in
                        \ &0C00 (i.e. save or load a file depending on the value
                        \ of A)

IF _6502SP_VERSION

 JSR CLDELAY            \ Pause for 1280 empty loops

 LDA #0                 \ Set the SVN flag to 0 indicate that disc access has
 JSR DODOSVN            \ finished

ENDIF

 CLC                    \ Clear the C flag

.slod1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PlayUniverse
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Play a universe file
\
\ ******************************************************************************

.PlayUniverse

 JSR ExitDiscMenu       \ Revert the changes made for the disc access menu

                        \ Do the following from DEATH2:

 LDA #&2C               \ Disable JSR ZERO and JSR DIALS in RES2
 STA yu+3

 LDA #&60               \ Turn JSR DIALS in RES2 into an RTS
 STA yu+16

 JSR RES2               \ Reset a number of flight variables and workspaces

 LDA #&20               \ Re-enable JSR ZERO and JSR DIALS in RES2
 STA yu+3

 STA yu+16              \ Re-enable JSR DIALS in RES2

                        \ We now do what ZERO would have done, but leaving
                        \ the ship slots alone, and we then call DIALS and ZINF
                        \ as we disabled them above

 LDX #(de-auto)         \ We're going to zero the UP workspace variables from
                        \ auto to de, so set a counter in X for the correct
                        \ number of bytes

 LDA #0                 \ Set A = 0 so we can zero the variables

.play1

 STA auto,X             \ Zero the X-th byte of FRIN to de

 DEX                    \ Decrement the loop counter

 BPL play1              \ Loop back to zero the next variable until we have done
                        \ them all

 JSR DIALS              \ Update the dashboard to zero all the above values

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace

                        \ Do the following from BR1 (part 1):

IF _6502SP_VERSION

 JSR ZEKTRAN            \ Reset the key logger buffer that gets returned from
                        \ the I/O processor

ENDIF

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

.play2

 LDA QQ15,X             \ Copy the X-th byte in QQ15 to the X-th byte in QQ2,
 STA QQ2,X

 DEX                    \ Decrement the counter

 BPL play2              \ Loop back to play2 if we still have more bytes to
                        \ copy

 INX                    \ Set X = 0 (as we ended the above loop with X = &FF)

 STX EV                 \ Set EV, the extra vessels spawning counter, to 0, as
                        \ we are entering a new system with no extra vessels
                        \ spawned

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

 LDX #0                 \ Force-load the front space view
 JSR LOOK1+14

 LDA #1                 \ Reset DELTA (speed) to 1, so we go as slowly as
 STA DELTA              \ possible at the start

 JMP TT100              \ Jump to TT100 to restart the main loop from the start

IF _MASTER_VERSION

\ ******************************************************************************
\
\       Name: TWIST
\       Type: Subroutine
\   Category: Demo
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

ENDIF

.endUniverseEditor2
