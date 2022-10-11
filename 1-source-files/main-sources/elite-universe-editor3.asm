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

\ ******************************************************************************
\
\       Name: EditorDashboard
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Implement the OSWORD 250 command (display the editor dashboard)
\
\ ------------------------------------------------------------------------------
\
\ Row 24 = &7000
\ Row 25 = &7200
\ Row 26 = &7400
\ Row 27 = &7600
\ Row 28 = &7800
\ Row 29 = &7A00
\ Row 30 = &7C00
\
\ ******************************************************************************

.EditorDashboard

 LDA #%00010100         \ Black-cyan

 STA &700B              \ Change F of FS to A
 STA &700C
 STA &700E

 STA &7015              \ Change left edge of S in FS to AC

 LDA #%00000000         \ Black-black

 STA &701C              \ Change right edge of S in FS to AC
 STA &701D

 LDA #CYAN2             \ Cyan-cyan

 STA &700D              \ Horizontal bar of A in FS to A

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

 LDA #%00000000         \ Black-black

 STA &700B              \ Revert F in FS to AC
 STA &700E

 STA &700D              \ Revert horizontal bar of A in FS to A

 STA &7015              \ Revert left edge of S in FS to AC

 LDA #%00101000         \ Cyan-black

 STA &701C              \ Revert right edge of S in FS to AC
 STA &701D

 LDA #CYAN2             \ Cyan-cyan

 STA &700C              \ Revert F in FS to AC

 RTS                    \ Return from the subroutine

.endUniverseEditor3
