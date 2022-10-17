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

.name1

 LDA INWK+5,X           \ Copy the X-th byte of INWK+5 to the X-th byte of NA%
 STA NAME,X

 DEX                    \ Decrement the loop counter

 BPL name1              \ Loop back until we have copied all 8 bytes

 RTS                    \ Return from the subroutine

.endUniverseEditor1
