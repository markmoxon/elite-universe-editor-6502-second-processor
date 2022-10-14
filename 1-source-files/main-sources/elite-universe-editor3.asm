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

 JSR DFAULT             \ Restore correct commander name to NAME

IF _6502SP_VERSION

 LDA #251               \ Switch to the main game dashboard, returning from the
 JMP SwitchDashboard    \ subroutine using a tail call

ELIF _MASTER_VERSION

 JMP GameDashboard      \ Switch to the main game dashboard, returning from the
                        \ subroutine using a tail call

ENDIF

.endUniverseEditor3
