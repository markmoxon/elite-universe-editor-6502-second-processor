\ ******************************************************************************
\
\ ELITE UNIVERSE EDITOR (PART 3)
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

BLACK_BLACK     = %00000000         \ 0, 0          0000, 0000
BLACK_CYAN      = %00010100         \ 0, 6          0000, 0110
CYAN_BLACK      = %00101000         \ 6, 0          0110, 0000
CYAN_CYAN       = %00111100         \ 6, 6          0110, 0110

YELLOW_CYAN     = %00011110         \ 3, 6          0011, 0110
YELLOW_MAGENTA  = %00011011         \ 3, 5          0011, 0101

MAGENTA_MAGENTA = %00110011         \ 5, 5          0101, 0101
BLACK_MAGENTA   = %00010001         \ 0, 5          0000, 0101
MAGENTA_BLACK   = %00100010         \ 5, 0          0101, 0000

\ ******************************************************************************
\
\       Name: rowOffsets
\       Type: Variable
\   Category: Universe editor
\    Summary: Screen modifications to change to the Universe Editor dashboard
\
\ ------------------------------------------------------------------------------
\
\ Each row has a table in the form: offset, screen byte.
\
\ ******************************************************************************

.rowOffsets

                        \ &7000

 EQUB &0B               \ Right column of A in AC
 EQUB &0C
 EQUB &0D
 EQUB &0E

 EQUB &15               \ Left column of C in AC

 EQUB &1C               \ Right column of C in AC
 EQUB &1D

 EQUB &FF               \ End row

                        \ &7200

 EQUB &01               \ Left column of A in AI
 EQUB &02
 EQUB &03
 EQUB &04
 EQUB &05

 EQUB &09               \ Right column of A in AI
 EQUB &0A
 EQUB &0B
 EQUB &0C
 EQUB &0D

 EQUB &11               \ Left column of I in AI
 EQUB &12
 EQUB &13
 EQUB &14
 EQUB &15

 EQUB &19               \ Right column of I in AI
 EQUB &1B
 EQUB &1C
 EQUB &1D

 EQUB &FF               \ End row

                        \ &7400

 EQUB &01               \ Left column of I in IB
 EQUB &02
 EQUB &03
 EQUB &04
 EQUB &05

 EQUB &09               \ Right column of I in IB
 EQUB &0A
 EQUB &0B
 EQUB &0C
 EQUB &0D

 EQUB &11               \ Left column of B in IB
 EQUB &12
 EQUB &13
 EQUB &14
 EQUB &15

 EQUB &19               \ Right column of B in IB
 EQUB &1A
 EQUB &1B
 EQUB &1C

 EQUB &FF               \ End row

                        \ &7600

 EQUB &11               \ Left column of O in CO
 EQUB &12
 EQUB &13
 EQUB &14

 EQUB &19               \ Right column of O in CO
 EQUB &1A
 EQUB &1B
 EQUB &1C

 EQUB &FF               \ End row

                        \ &7800

 EQUB &09               \ Right column of H in HS
 EQUB &0A
 EQUB &0B
 EQUB &0C
 EQUB &0D

 EQUB &11               \ Left column of S in HS
 EQUB &14

 EQUB &1B               \ Right column of S in HS
 EQUB &1C
 EQUB &1D

 EQUB &FF               \ End row


\ ******************************************************************************
\
\       Name: editorRows
\       Type: Variable
\   Category: Universe editor
\    Summary: Screen modifications to change to the Universe Editor dashboard
\
\ ------------------------------------------------------------------------------
\
\ Each row has a table in the form: offset, screen byte.
\
\ ******************************************************************************

.editorRows

                        \ &7000

 EQUB BLACK_CYAN        \ Right column of A in AC
 EQUB BLACK_CYAN
 EQUB CYAN_CYAN
 EQUB BLACK_CYAN

 EQUB BLACK_CYAN        \ Left column of C in AC

 EQUB BLACK_BLACK       \ Right column of C in AC
 EQUB BLACK_BLACK

 EQUB &FF               \ End row

                        \ &7200

 EQUB YELLOW_MAGENTA    \ Left column of A in AI
 EQUB YELLOW_MAGENTA
 EQUB YELLOW_MAGENTA
 EQUB YELLOW_MAGENTA
 EQUB YELLOW_MAGENTA

 EQUB MAGENTA_MAGENTA   \ Right column of A in AI
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA
 EQUB MAGENTA_MAGENTA
 EQUB BLACK_MAGENTA

 EQUB BLACK_MAGENTA     \ Left column of I in AI
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA

 EQUB BLACK_BLACK       \ Right column of I in AI
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK

 EQUB &FF               \ End row

                        \ &7400

 EQUB YELLOW_MAGENTA    \ Left column of I in IB
 EQUB YELLOW_MAGENTA
 EQUB YELLOW_MAGENTA
 EQUB YELLOW_MAGENTA
 EQUB YELLOW_MAGENTA

 EQUB BLACK_MAGENTA     \ Right column of I in IB
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA

 EQUB MAGENTA_BLACK     \ Left column of B in IB
 EQUB BLACK_MAGENTA
 EQUB MAGENTA_BLACK
 EQUB BLACK_MAGENTA
 EQUB MAGENTA_BLACK

 EQUB BLACK_BLACK       \ Right column of B in IB
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK

 EQUB &FF               \ End row

                        \ &7600

 EQUB BLACK_MAGENTA     \ Left column of O in CO
 EQUB MAGENTA_BLACK
 EQUB MAGENTA_BLACK
 EQUB MAGENTA_BLACK

 EQUB BLACK_BLACK       \ Right column of O in CO
 EQUB MAGENTA_BLACK
 EQUB MAGENTA_BLACK
 EQUB MAGENTA_BLACK

 EQUB &FF               \ End row

                        \ &7800

 EQUB BLACK_MAGENTA     \ Right column of H in HS
 EQUB BLACK_MAGENTA
 EQUB MAGENTA_MAGENTA
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA

 EQUB BLACK_MAGENTA     \ Left column of S in HS
 EQUB BLACK_BLACK

 EQUB MAGENTA_BLACK     \ Right column of S in HS
 EQUB MAGENTA_BLACK
 EQUB MAGENTA_BLACK

 EQUB &FF               \ End row


\ ******************************************************************************
\
\       Name: gameRows
\       Type: Variable
\   Category: Universe editor
\    Summary: Screen modifications to change to the main game dashboard
\
\ ------------------------------------------------------------------------------
\
\ Each row has a table in the form: offset, screen byte.
\
\ ******************************************************************************

.gameRows

                        \ &7000

 EQUB BLACK_BLACK       \ Right column of F in FS
 EQUB CYAN_CYAN
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK

 EQUB BLACK_BLACK       \ Left column of F in FS

 EQUB CYAN_BLACK        \ Right column of F in FS
 EQUB CYAN_BLACK

 EQUB &FF               \ End row

                        \ &7200

 EQUB YELLOW_CYAN       \ Left column of A in AS
 EQUB YELLOW_CYAN
 EQUB YELLOW_CYAN
 EQUB YELLOW_CYAN
 EQUB YELLOW_CYAN

 EQUB CYAN_CYAN         \ Right column of A in AS
 EQUB BLACK_CYAN
 EQUB BLACK_CYAN
 EQUB CYAN_CYAN
 EQUB BLACK_CYAN

 EQUB BLACK_CYAN        \ Left column of S in AS
 EQUB BLACK_CYAN
 EQUB BLACK_CYAN
 EQUB BLACK_BLACK
 EQUB BLACK_CYAN

 EQUB CYAN_BLACK        \ Right column of S in AS
 EQUB CYAN_BLACK
 EQUB CYAN_BLACK
 EQUB CYAN_BLACK

 EQUB &FF               \ End row

                        \ &7400

 EQUB YELLOW_CYAN       \ Left column of F in FU
 EQUB YELLOW_CYAN
 EQUB YELLOW_CYAN
 EQUB YELLOW_CYAN
 EQUB YELLOW_CYAN

 EQUB CYAN_BLACK        \ Right column of F in FU
 EQUB BLACK_BLACK
 EQUB CYAN_BLACK
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK

 EQUB CYAN_BLACK        \ Left column of U in FU
 EQUB CYAN_BLACK
 EQUB CYAN_BLACK
 EQUB CYAN_BLACK
 EQUB BLACK_CYAN

 EQUB CYAN_BLACK        \ Right column of U in FU
 EQUB CYAN_BLACK
 EQUB CYAN_BLACK
 EQUB CYAN_BLACK

 EQUB &FF               \ End row

                        \ &7600

 EQUB MAGENTA_MAGENTA   \ Left column of T in CT
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA
 EQUB BLACK_MAGENTA

 EQUB MAGENTA_BLACK     \ Right column of T in CT
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK

 EQUB &FF               \ End row

                        \ &7800

 EQUB BLACK_BLACK       \ Right column of L in LT
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK
 EQUB MAGENTA_BLACK

 EQUB MAGENTA_MAGENTA   \ Left column of T in LT
 EQUB BLACK_MAGENTA

 EQUB BLACK_BLACK       \ Right column of T in LT
 EQUB BLACK_BLACK
 EQUB BLACK_BLACK

 EQUB &FF               \ End row


\ ******************************************************************************
\
\       Name: ModifyDashboard
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Poke to the screen to modify the dashboard
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   P(1 0)              The starting point in the table of offsets
\
\   R(1 0)              The starting point in the table of pokes
\
\   SC(1 0)             Start address of screen row
\
\ ******************************************************************************

.ModifyDashboard

 LDY #0                 \ Set Y to use as an index into the byte tables

.mod1

 LDA (P),Y              \ Set T to the offset within the screen row for this
 STA T                  \ byte

 BMI mod2               \ If this is the last entry, then the offset will be
                        \ &FF, so jump to mod2 to return from the subroutine

 STY K                  \ Store the index in K so we can retrieve it below

 LDA (R),Y              \ Set A to the byte we need to poke into screen memory

 LDY T                  \ Store the byte in screen memory at the offset we
 STA (SC),Y             \ stored in T

 LDY K                  \ Retrieve the index from K

 INY                    \ Increment the index to point to the next entry in the
                        \ table

 BNE mod1               \ Loop back for the next byte (this BNE is effectively a
                        \ JMP as Y is never zero)

.mod2

 INY                    \ Set P(1 0) = P(1 0) + Y + 1
 TYA                    \
 CLC                    \ so P(1 0) points to the next table
 ADC P
 STA P
 BCC mod3
 INC P+1

.mod3

 TYA                    \ Set R(1 0) = R(1 0) + Y + 1
 CLC                    \
 ADC R                  \ so R(1 0) points to the next table
 STA R
 BCC mod4
 INC R+1

.mod4

 INC SCH                \ Set SC(1 0) = SC(1 0) + 2, to point to the next screen
 INC SCH                \ row

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: EditorDashboard
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Implement the OSWORD 250 command (display the editor dashboard)
\
\ ******************************************************************************

.EditorDashboard

 LDA #0                 \ Set SC(1 0) = &7000
 STA SC
 LDA #&70
 STA SC+1

 LDA #LO(rowOffsets)    \ Set P(1 0) = rowOffsets
 STA P
 LDA #HI(rowOffsets)
 STA P+1

 LDA #LO(editorRows)    \ Set R(1 0) = editorRows
 STA R
 LDA #HI(editorRows)
 STA R+1

 JSR ModifyDashboard    \ Modify row 0 of the dashboard

 JSR ModifyDashboard    \ Modify row 1 of the dashboard

 JSR ModifyDashboard    \ Modify row 2 of the dashboard

 JSR ModifyDashboard    \ Modify row 3 of the dashboard

 JSR ModifyDashboard    \ Modify row 4 of the dashboard

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GameDashboard
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Implement the OSWORD 251 command (display the game dashboard)
\
\ ******************************************************************************

.GameDashboard

 LDA #0                 \ Set SC(1 0) = &7000
 STA SC
 LDA #&70
 STA SC+1

 LDA #LO(rowOffsets)    \ Set P(1 0) = rowOffsets
 STA P
 LDA #HI(rowOffsets)
 STA P+1

 LDA #LO(gameRows)      \ Set R(1 0) = gameRows
 STA R
 LDA #HI(gameRows)
 STA R+1

 JSR ModifyDashboard    \ Modify row 0 of the dashboard

 JSR ModifyDashboard    \ Modify row 1 of the dashboard

 JSR ModifyDashboard    \ Modify row 2 of the dashboard

 JSR ModifyDashboard    \ Modify row 3 of the dashboard

 JSR ModifyDashboard    \ Modify row 4 of the dashboard

 RTS                    \ Return from the subroutine

.endUniverseEditor3
