

.data

interruptStack: .skip 2048
interruptStackEnd:
programStack: .skip 2048
programStackEnd:

.text
.set SDCBASE, 0xFFFF0100
.set STATUSSTEER, 0xFFFF0120
.set ENGINEDIR, 0xFFFF0121

.align 4

int_handler:
  ###### Syscall and Interrupts handler ######
    csrr t0, mstatus
    li t1, 0x1800
    and t0, t1, t0
    csrw mstatus, t0            # Sets machine mode

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

    li t1, 10
    li t2, 11
    li t3, 12
    li t4, 15

    bne a7, t1, notSycall10
        jal set_engine_and_steering
        j syscallListEnd
    notSycall10:


    
    syscallListEnd:
  # <= Implement your syscall handler here 

    csrr t0, mepc  # load return address (address of the instruction that invoked the syscall)
    addi t0, t0, 4 # adds 4 to the return address (to return after ecall) 
    csrw mepc, t0  # stores the return address back on mepc

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
    # lw a0, 4(sp) 
    lw ra, (sp) 
    addi sp, sp, 60
    csrrw sp, mscratch, sp      #after retrieving context switch back to program stack

    csrr t0, mstatus
    li t1, ~0x1800
    and t0, t1, t0
    csrw mstatus, t0            # Sets user mode


    mret           # Recover remaining context (pc <- mepc)
    

.globl _start
_start:

    csrr t1, mie
    li t2, 0x800
    or t1, t1, t2
    csrw mie, t1                #enables external interrupts

    csrr t1, mstatus
    ori t1, t1, 0x8             #enables global interruptions by seting MIE field of mstatus to 1
    csrw mstatus, t1


    la t0, int_handler          # Load the address of the routine that will handle interrupts
    csrw mtvec, t0              # (and syscalls) on the register MTVEC to set the interrupt array.

    la t0, interruptStackEnd
    csrw mscratch, t0           #Load interruptStack adr

    la t0, programStackEnd
    mv sp, t0                   #load programStack adr


    # Write here the code to change to user mode and call the function 
    # user_main (defined in another file). Remember to initialize
    # the user stack so that your program can use it.
    csrr t0, mstatus
    li t1, ~0x1800
    and t0, t1, t0
    csrw mstatus, t0            # Sets user mode


    la t1, user_main
    csrw mepc, t1               # Sets user function to go

    mret

    

.globl control_logic
control_logic:
  # implement your control logic here, using only the defined syscalls
    # li a0, -1
    # li a1, 0
    # li a7, 10
    # ecall

    li a3, 480
    bge a4, a3, turnLeftLoopEnd
    turnLeftLoop:
        li a0, 1
        li a1, -127
        li a7, 10
        ecall
        addi a4, a4, 1
    blt a4, a3, turnLeftLoop
    turnLeftLoopEnd:

    li a0, 1
    li a1, 0
    li a7, 10
    ecall



    j control_logic



set_engine_and_steering:
#int setEngineSteering(int engineDir (1;0;-1), int steering (-127;127))
#ret 0 if success, -1 if some parameter is invalid
    li t1, 1
    li t2, -1
    li t3, 128
    li t4, -127

    blt a1, t4, engineSteeringFailJump
    bge a1, t3, engineSteeringFailJump

    beq a0, t1, engineSteeringSuccessJump
    beq a0, t2, engineSteeringSuccessJump
    beq a0, zero, engineSteeringSuccessJump
    li a0, -1
    j engineSteeringFailJump
    engineSteeringSuccessJump:

    li a2, ENGINEDIR
    sb a0, 0(a2)           #set engine direction
    li a2, STATUSSTEER
    sb a1, 0(a2)           #Set steering angle

    li a0, 0
    engineSteeringFailJump:


    ret

set_handbrake:
#void setHandbrake(int handbrake(1-on;0-off))
    li a1, SDCBASE
    lw a0, 22(a2)
    
    ret

read_sensors:
#void readSensor(double &x, double &y, double &z)
    li a3, 1
    li a4, SDCBASE
    sb a3, (a4)

    readSensorBW:
        lb a3, (a4)
    bnez a3, readSensorBW

    lw a0, 4(a4)
    lw a1, 8(a4)
    lw a2, 12(a4)

    ret

