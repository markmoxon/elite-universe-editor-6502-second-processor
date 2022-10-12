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

 EQUB &0B, BLACK_CYAN       \ Right column of A in AC
 EQUB &0C, BLACK_CYAN
 EQUB &0D, CYAN_CYAN
 EQUB &0E, BLACK_CYAN

 EQUB &15, BLACK_CYAN       \ Left column of C in AC

 EQUB &1C, BLACK_BLACK      \ Right column of C in AC
 EQUB &1D, BLACK_BLACK

 EQUB &FF                   \ End row

                            \ &7200

 EQUB &01, YELLOW_MAGENTA   \ Left column of A in AI
 EQUB &02, YELLOW_MAGENTA
 EQUB &03, YELLOW_MAGENTA
 EQUB &04, YELLOW_MAGENTA
 EQUB &05, YELLOW_MAGENTA

 EQUB &09, MAGENTA_MAGENTA  \ Right column of A in AI
 EQUB &0A, BLACK_MAGENTA
 EQUB &0B, BLACK_MAGENTA
 EQUB &0C, MAGENTA_MAGENTA
 EQUB &0D, BLACK_MAGENTA

 EQUB &11, BLACK_MAGENTA    \ Left column of I in AI
 EQUB &12, BLACK_MAGENTA
 EQUB &13, BLACK_MAGENTA
 EQUB &14, BLACK_MAGENTA
 EQUB &15, BLACK_MAGENTA

 EQUB &19, BLACK_BLACK      \ Right column of I in AI
 EQUB &1B, BLACK_BLACK
 EQUB &1C, BLACK_BLACK
 EQUB &1D, BLACK_BLACK

 EQUB &FF                   \ End row

                            \ &7400

 EQUB &01, YELLOW_MAGENTA   \ Left column of I in IB
 EQUB &02, YELLOW_MAGENTA
 EQUB &03, YELLOW_MAGENTA
 EQUB &04, YELLOW_MAGENTA
 EQUB &05, YELLOW_MAGENTA

 EQUB &09, BLACK_MAGENTA    \ Right column of I in IB
 EQUB &0A, BLACK_MAGENTA
 EQUB &0B, BLACK_MAGENTA
 EQUB &0C, BLACK_MAGENTA
 EQUB &0D, BLACK_MAGENTA

 EQUB &11, MAGENTA_BLACK    \ Left column of B in IB
 EQUB &12, BLACK_MAGENTA
 EQUB &13, MAGENTA_MAGENTA
 EQUB &14, BLACK_MAGENTA
 EQUB &15, MAGENTA_BLACK

 EQUB &19, BLACK_BLACK      \ Right column of B in IB
 EQUB &1A, BLACK_BLACK
 EQUB &1B, BLACK_BLACK
 EQUB &1C, BLACK_BLACK

 EQUB &FF                   \ End row

                            \ &7600

 EQUB &11, BLACK_MAGENTA    \ Left column of O in CO
 EQUB &12, MAGENTA_BLACK
 EQUB &13, MAGENTA_BLACK
 EQUB &14, MAGENTA_BLACK
 EQUB &15, BLACK_MAGENTA

 EQUB &19, BLACK_BLACK      \ Right column of O in CO
 EQUB &1A, MAGENTA_BLACK
 EQUB &1B, MAGENTA_BLACK
 EQUB &1C, MAGENTA_BLACK

 EQUB &FF                   \ End row

                            \ &7800

 EQUB &09, BLACK_MAGENTA    \ Right column of H in HS
 EQUB &0A, BLACK_MAGENTA
 EQUB &0B, MAGENTA_MAGENTA
 EQUB &0C, BLACK_MAGENTA
 EQUB &0D, BLACK_MAGENTA

 EQUB &11, BLACK_MAGENTA    \ Left column of S in HS
 EQUB &14, BLACK_BLACK

 EQUB &1B, MAGENTA_BLACK    \ Right column of S in HS
 EQUB &1C, MAGENTA_BLACK
 EQUB &1D, MAGENTA_BLACK

 EQUB &FF                   \ End row

                            \ &7A00

 EQUB &FF                   \ End row

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

 EQUB &0B, BLACK_BLACK      \ Right column of F in FS
 EQUB &0C, CYAN_CYAN
 EQUB &0D, BLACK_BLACK
 EQUB &0E, BLACK_BLACK

 EQUB &15, BLACK_BLACK      \ Left column of F in FS

 EQUB &1C, CYAN_BLACK       \ Right column of F in FS
 EQUB &1D, CYAN_BLACK

 EQUB &FF

                            \ &7200

 EQUB &01, YELLOW_CYAN      \ Left column of A in AS
 EQUB &02, YELLOW_CYAN
 EQUB &03, YELLOW_CYAN
 EQUB &04, YELLOW_CYAN
 EQUB &05, YELLOW_CYAN

 EQUB &09, CYAN_CYAN        \ Right column of A in AS
 EQUB &0A, BLACK_CYAN
 EQUB &0B, BLACK_CYAN
 EQUB &0C, CYAN_CYAN
 EQUB &0D, BLACK_CYAN

 EQUB &11, BLACK_CYAN       \ Left column of S in AS
 EQUB &12, BLACK_CYAN
 EQUB &13, BLACK_CYAN
 EQUB &14, BLACK_BLACK
 EQUB &15, BLACK_CYAN

 EQUB &19, CYAN_BLACK       \ Right column of S in AS
 EQUB &1B, CYAN_BLACK
 EQUB &1C, CYAN_BLACK
 EQUB &1D, CYAN_BLACK

 EQUB &FF                   \ End row

                            \ &7400

 EQUB &01, YELLOW_CYAN      \ Left column of F in FU
 EQUB &02, YELLOW_CYAN
 EQUB &03, YELLOW_CYAN
 EQUB &04, YELLOW_CYAN
 EQUB &05, YELLOW_CYAN

 EQUB &09, CYAN_BLACK       \ Right column of F in FU
 EQUB &0A, BLACK_BLACK
 EQUB &0B, CYAN_BLACK
 EQUB &0C, BLACK_BLACK
 EQUB &0D, BLACK_BLACK

 EQUB &11, CYAN_BLACK       \ Left column of U in FU
 EQUB &12, CYAN_BLACK
 EQUB &13, CYAN_BLACK
 EQUB &14, CYAN_BLACK
 EQUB &15, BLACK_CYAN

 EQUB &19, CYAN_BLACK       \ Right column of U in FU
 EQUB &1A, CYAN_BLACK
 EQUB &1B, CYAN_BLACK
 EQUB &1C, CYAN_BLACK

 EQUB &FF                   \ End row

                            \ &7600

 EQUB &11, MAGENTA_MAGENTA  \ Left column of T in CT
 EQUB &12, BLACK_MAGENTA
 EQUB &13, BLACK_MAGENTA
 EQUB &14, BLACK_MAGENTA

 EQUB &19, MAGENTA_BLACK    \ Right column of T in CT
 EQUB &1A, BLACK_BLACK
 EQUB &1B, BLACK_BLACK
 EQUB &1C, BLACK_BLACK

 EQUB &FF                   \ End row

                            \ &7800

 EQUB &09, BLACK_BLACK      \ Right column of L in LT
 EQUB &0A, BLACK_BLACK
 EQUB &0B, BLACK_BLACK
 EQUB &0C, BLACK_BLACK
 EQUB &0D, MAGENTA_BLACK

 EQUB &11, MAGENTA_MAGENTA  \ Left column of T in LT
 EQUB &14, BLACK_MAGENTA

 EQUB &1B, BLACK_BLACK    \ Right column of T in LT
 EQUB &1C, BLACK_BLACK
 EQUB &1D, BLACK_BLACK

 EQUB &FF                   \ End row

                            \ &7A00

 EQUB &FF                   \ End row

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
\   SC(1 0)             Start address of screen row
\
\   P(1 0)              Table of modifications
\
\ ******************************************************************************

.ModifyDashboard

 LDY #0                 \ Set Y to use as an index into the byte table

.mod1

 LDA (P),Y              \ Set R to the offset within the screen row for this
 STA R                  \ byte

 BMI mod2               \ If this is the last entry, then the offset will be
                        \ &FF, so jump to mod2 to return from the subroutine

 INY                    \ Increment the index to point to the next byte, which
                        \ is the value to poke into screen memory

 STY K                  \ Store the index in K so we can retrieve it below

 LDA (P),Y              \ Set A to the byte we need to poke into screen memory

 LDY R                  \ Store the byte in screen memory at the offset we
 STA (SC),Y             \ stored in R

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

 LDA #LO(editorRows)    \ Set P(1 0) = editorRows
 STA P
 LDA #HI(editorRows)
 STA P+1

 JSR ModifyDashboard    \ Modify row 0 of the dashboard

 JSR ModifyDashboard    \ Modify row 1 of the dashboard

 JSR ModifyDashboard    \ Modify row 2 of the dashboard

 JSR ModifyDashboard    \ Modify row 3 of the dashboard

 JSR ModifyDashboard    \ Modify row 4 of the dashboard

 JSR ModifyDashboard    \ Modify row 5 of the dashboard

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

 LDA #LO(gameRows)      \ Set P(1 0) = gameRows
 STA P
 LDA #HI(gameRows)
 STA P+1

 JSR ModifyDashboard    \ Modify row 0 of the dashboard

 JSR ModifyDashboard    \ Modify row 1 of the dashboard

 JSR ModifyDashboard    \ Modify row 2 of the dashboard

 JSR ModifyDashboard    \ Modify row 3 of the dashboard

 JSR ModifyDashboard    \ Modify row 4 of the dashboard

 JSR ModifyDashboard    \ Modify row 5 of the dashboard

 RTS                    \ Return from the subroutine

.endUniverseEditor3
