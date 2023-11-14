.globl _start
.globl _system_time
.globl play_note

.data
_system_time: .word 0

interStack: .skip 1028
interStackEnd:
progStack: .skip 1028
progStackEnd:

.text

.set GPT_ADR, 0xFFFF0100
.set MIDI_ADR, 0xFFFF0300

.align 2
_start:
    la a0, interStackEnd
    csrw mscratch, a0           #initialize mscratch with interruptStack

    la a0, progStackEnd
    mv sp, a0                   #initialize stack pointer to program stack

    li a0, GPT_ADR
    li a1, 100
    sw a1, 8(a0)                #sets GPT to generate interrupt
    
    csrr t1, mie
    li t2, 0x800
    or t1, t1, t2
    csrw mie, t1

    csrr t1, mstatus
    ori t1, t1, 0x8             #enables external interruptions by seting MIE field of mstatus to 1
    csrw mstatus, t1

    la a0, interuptHandler
    csrw mtvec, a0              #Sets interrupt handle mode to direct and defines "interruptHandler" as handler funct

    jal main

.align 4
interuptHandler:
#since only the GPT is causing interruptions, succintly treat
    csrrw sp, mscratch, sp      #Switch stack pointer to interruption stack
    addi sp, sp, -60
    sw ra, (sp) 
    sw a0, 4(sp) 
    sw a1, 8(sp) 
    sw a2, 12(sp)
    sw a3, 16(sp) 
    sw a4, 20(sp) 
    sw a5, 24(sp) 
    sw a6, 28(sp) 
    sw a7, 32(sp)
    sw t0, 36(sp) 
    sw t1, 40(sp) 
    sw t2, 44(sp) 
    sw s0, 48(sp) 
    sw s1, 52(sp) 
    sw s2, 56(sp) 


    li a0, GPT_ADR
    la a1, _system_time 

    lw a2, (a1)                 #_system time value
    addi a2, a2, 100            
    sw a2, 0(a1)                #stores the time at global var


    #Check if i dont have to increment this as well
    li a2, 100
    sw a2, 8(a0)                #Set next interruption to 100ms from now


    lw s2, 56(sp) 
    lw s1, 52(sp) 
    lw s0, 48(sp) 
    lw t2, 44(sp) 
    lw t1, 40(sp) 
    lw t0, 36(sp) 
    lw a7, 32(sp) 
    lw a6, 28(sp) 
    lw a5, 24(sp) 
    lw a4, 20(sp) 
    lw a3, 16(sp) 
    lw a2, 12(sp) 
    lw a1, 8(sp) 
    lw a0, 4(sp) 
    lw ra, (sp) 
    addi sp, sp, 60
    csrrw sp, mscratch, sp      #after retrieving context switch back to program stack

    mret

play_note:
# void play_note(
#     int ch, 
#     int instId,
#     int note, 
#     int nodeSp, 
#     int notLen
# )
    li a6, MIDI_ADR

    sh a1, 2(a6)
    sb a2, 4(a6)
    sb a3, 5(a6)
    sh a4, 6(a6)

    sb a0, 0(a6)                #triggers note play

    ret