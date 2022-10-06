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

 JMP afterBrk           \ Jump to afterBrk to display the disc access menu

\ ******************************************************************************
\
\       Name: ShowDiscMenu
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Show the universe disc menu
\
\ ******************************************************************************

.ShowDiscMenu

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
 LDA #LO(ShowDiscMenu)
 STA SVE+1
 LDA #HI(ShowDiscMenu)
 STA SVE+2

ELIF _MASTER_VERSION

 LDA #LO(afterBrk)      \ Stop BRBR error handler from returning to the SVE
 STA DEATH-2            \ routine, jump back here instead
 LDA #HI(afterBrk)
 STA DEATH-1

ENDIF

IF _MASTER_VERSION

IF _SNG47

 JSR SWAPZP             \ Call SWAPZP to restore the top part of zero page

ELIF _COMPACT

 JSR NMIRELEASE         \ Release the NMI workspace (&00A0 to &00A7)

ENDIF

ENDIF

 LDX #LO(dirCommand)    \ Set (Y X) to point to dirCommand ("DIR U")
 LDY #HI(dirCommand)

 JSR OSCLI              \ Call OSCLI to run the OS command in dirCommand, which
                        \ changes the disc directory to E

IF _MASTER_VERSION

 JSR SWAPZP             \ Call SWAPZP to restore the top part of zero page

ENDIF

.afterBrk

                        \ The following is based on the SVE routine for the
                        \ normal disc access menu

IF _6502SP_VERSION

 JSR ZEBC               \ Call ZEBC to zero-fill pages &B and &C

ENDIF

 TSX                    \ Transfer the stack pointer to X and store it in stack,
 STX stack              \ so we can restore it in the MEBRK routine

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

 LDA #'E'               \ Change the directory back to E
 STA S1%+3
 STA dirCommand+4

IF _6502SP_VERSION

 STA DELI+9             \ Change the directory back to E

ELIF _MASTER_VERSION

IF _SNG47

 JSR SWAPZP             \ Call SWAPZP to restore the top part of zero page

ELIF _COMPACT

 JSR NMIRELEASE         \ Release the NMI workspace (&00A0 to &00A7)

ENDIF

ENDIF

 LDX #LO(dirCommand)    \ Set (Y X) to point to dirCommand ("DIR E")
 LDY #HI(dirCommand)

 JSR OSCLI              \ Call OSCLI to run the OS command in dirCommand, which
                        \ changes the disc directory to E

IF _MASTER_VERSION

 JSR SWAPZP             \ Call SWAPZP to restore the top part of zero page

ENDIF

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

 JSR BRKBK              \ Jump to BRKBK to set BRKV back to the standard BRKV
                        \ handler for the game, and return from the subroutine
                        \ using a tail call

ELIF _MASTER_VERSION

 LDA #LO(SVE)           \ Return BRBR error handler to default state
 STA DEATH-2
 LDA #HI(SVE)
 STA DEATH-1

ENDIF

 LDX #0                 \ Draw the front view, returning from the subroutine
 STX VIEW               \ using a tail call
 JMP ChangeView+8

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
\       Name: LoadUniverse
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Load a universe file
\
\ ******************************************************************************

.LoadUniverse

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

 LDA #&FF               \ Call SaveLoadFile with A = &FF to load the universe
 JSR SaveLoadFile       \ file to address K%

 BCS load1              \ If the C flag is set then an invalid drive number was
                        \ entered during the call to QUS1 and the file wasn't
                        \ loaded, so jump to LOR to return from the subroutine

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

 JSR ZEBC               \ Call ZEBC to zero-fill pages &B and &C

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

IF _MASTER_VERSION

IF _SNG47

 JSR SWAPZP             \ Call SWAPZP to restore the top part of zero page

ELIF _COMPACT

 JSR NMIRELEASE         \ Release the NMI workspace (&00A0 to &00A7)

ENDIF

ENDIF

 JSR OSFILE             \ Call OSFILE to do the file operation specified in
                        \ &0C00 (i.e. save or load a file depending on the value
                        \ of A)

IF _MASTER_VERSION

 JSR SWAPZP             \ Call SWAPZP to restore the top part of zero page

ENDIF

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

IF _6502SP_VERSION

 LDA #&60               \ Turn JSR DIALS in RES2 into an RTS
 STA yu+16

ELIF _MASTER_VERSION

 LDA #&60               \ Turn ZINF fallthrough into an RTS
 STA ZINF

ENDIF

 JSR RES2               \ Reset a number of flight variables and workspaces

 LDA #&20               \ Re-enable JSR ZERO and JSR DIALS in RES2
 STA yu+3

IF _6502SP_VERSION

 STA yu+16              \ Re-enable JSR DIALS in RES2

ELIF _MASTER_VERSION

 LDA #&A0               \ Re-enable ZINF fallthrough
 STA ZINF

ENDIF
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

\ ******************************************************************************
\
\       Name: STORE
\       Type: Subroutine
\   Category: Universe
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
\   Category: Utility routines
\    Summary: Zero-fill pages &B and &C
\
\ ******************************************************************************

.ZEBC

 LDX #&C                \ Call ZES1 with X = &C to zero-fill page &C
 JSR ZES1

 DEX                    \ Decrement X to &B

 JMP ZES1               \ Jump to ZES1 to zero-fill page &B

ENDIF

.endUniverseEditor2
