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

\ LDA #HI(FRIN)          \ Copy JUNK-FRIN bytes from FRIN to K%+&2E4
\ STA P+1
\ LDA #LO(FRIN)
\ STA P
\ LDA #HI(K%+&2E4)
\ STA Q+1
\ LDA #LO(K%+&2E4)
\ STA Q
\ LDY #JUNK-FRIN
\ JSR CopyBlock

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

 PHA                    \ Store A on the stack so we can restore it after the
                        \ call to DODOSVN

 LDA #255               \ Set the SVN flag to 255 to indicate that disc access
 JSR DODOSVN            \ is in progress

 PLA                    \ Restore A from the stack

 LDX #INWK              \ Store a pointer to INWK at the start of the block at
 STX &0C00              \ &0C00, storing #INWK in the low byte because INWK is
                        \ in zero page

 LDX #0                 \ Set (Y X) = &0C00
 LDY #&C

 JSR OSFILE             \ Call OSFILE to do the file operation specified in
                        \ &0C00 (i.e. save or load a file depending on the value
                        \ of A)

 JSR CLDELAY            \ Pause for 1280 empty loops

 LDA #0                 \ Set the SVN flag to 0 indicate that disc access has
 JSR DODOSVN            \ finished

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

 RTS                    \ Return from the subroutine

.endUniverseEditor2
