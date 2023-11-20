

.bss
interruptStack: .skip 2048
interruptStackEnd:
programStack: .skip 2048
programStackEnd:

.data
lineCamera: .skip 256


.text

.set GPT, 0xFFFF0100
.set SDCBASE, 0xFFFF0300
.set SERIAL, 0xFFFF0500

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

    # la t0, programStackEnd      #TODO user stack must start at 0x07fffffc
    li t0, 0x07fffffc
    mv sp, t0                   #load programStack adr


    # Write here the code to change to user mode and call the function 
    # user_main (defined in another file). Remember to initialize
    # the user stack so that your program can use it.
    csrr t0, mstatus
    li t1, ~0x1800
    and t0, t1, t0
    csrw mstatus, t0            # Sets user mode


    la t1, main
    csrw mepc, t1               # Sets user function to go

    mret


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
    li t4, 13
    li t5, 15
    li t6, 16
    li s0, 17
    li s1, 18
    li s2, 20

    bne a7, t1, notSycall10
        jal set_engine_and_steering
        j syscallListEnd
    notSycall10:

    bne a7, t2, notSycall11
        jal set_handbrake
        j syscallListEnd
    notSycall11:

    bne a7, t3, notSycall12
        jal read_sensors
        j syscallListEnd
    notSycall12:

    bne a7, t4, notSycall13
        jal read_sensors_distance
        j syscallListEnd
    notSycall13:

    bne a7, t5, notSycall15
        jal get_position
        j syscallListEnd
    notSycall15:

    bne a7, t6, notSycall16
        jal get_rotation
        j syscallListEnd
    notSycall16:

    bne a7, s0, notSycall17
        jal read_serial
        j syscallListEnd
    notSycall17:

    bne a7, s1, notSycall18
        jal write_serial
        j syscallListEnd
    notSycall18:

    bne a7, s2, notSycall20
        jal get_systime
        j syscallListEnd
    notSycall20:



    
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
    


# .globl set_engine_and_steering
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
    engineSteeringFailJump:
    li a0, -1
    j engineSteeringEndJump
    engineSteeringSuccessJump:

    li a2, SDCBASE
    sb a0, 0x21(a2)           #set engine direction
    sb a1, 0x20(a2)           #Set steering angle

    li a0, 0
    engineSteeringEndJump:


    ret

# .globl set_handbrake
set_handbrake:
#void setHandbrake(int handbrake(1-on;0-off))
    li a1, SDCBASE
    addi a1, a1, 0x22
    li a2, 1

    beqz a0, setHandbrakeSuccess
    beq a0, a2, setHandbrakeSuccess
    j setHandbrakeFail

    setHandbrakeSuccess:
        sb a0, (a1)
        li a0, 0
        j setHandbrakeEnd
    setHandbrakeFail:
        li a0, -1
    setHandbrakeEnd:

    ret

# .globl read_sensors
#void readSensors(char* arr[256])
read_sensors:
    li a1, SDCBASE
    li a2, 1
    sb a2, 0x1(a1)

    readSensorsBW:
        lb a2, 0x1(a1)
    bnez a2, readSensorsBW

    # la a3, 0x24(a1)
    addi a3, a1, 0x24
    li a4, 257
    li a5, 0
    readSensorsCpLoop:
        lb a1, (a3)
        sb a1, (a0)

        addi a0, a0, 1
        addi a3, a3, 1

        addi a5, a5, 1
    blt a5, a4, readSensorsCpLoop

    ret

# .globl read_sensors_distance
read_sensors_distance:
#int readSensorDistance()
    li a0, SDCBASE
    li a1, 1
    sb a1, 0x2(a0)

    readSensorDistanceBW:
        lb a2, 0x2(a0)
    bnez a2, readSensorDistanceBW

    lw a0, 0x1C(a0)                 #Retrieves distance value[cm] (-1 if no solid up to 20 m) 

    ret

# .globl get_position
get_position:
#void getPosition(double &x, double &y, double &z)
    li a3, 1
    li a4, SDCBASE
    sb a3, (a4)

    getPositionBW:
        lb a3, (a4)
    bnez a3, getPositionBW

    lw t1, 0x10(a4)
    sw t1, (a0)
    lw t1, 0x14(a4)
    sw t1, (a1)
    lw t1, 0x18(a4)
    sw t1, (a2)


    ret
# .globl get_rotation
get_rotation:
#void getRotation(double &x, double &y, double &z)
    li a3, 1
    li a4, SDCBASE
    sb a3, (a4)

    getRotationBW:
        lb a3, (a4)
    bnez a3, getRotationBW

    lw t1, 0x4(a4)
    sw t1, (a0)
    lw t1, 0x8(a4)
    sw t1, (a1)
    lw t1, 0xC(a4)
    sw t1, (a2)


    ret

# .globl read_serial
read_serial:
#int readSerial(char* buffer, int size)
    mv a3, a0                       #stores pointer to end of string

    li a2, SERIAL
    readSerialLoop:
        li t1, 1
        sb t1, 2(a2)                #Start reading by storing 1 into serial read field
        readSerialBW:
            lb t1, 2(a2)
            # lb t4, 3(a2)
        bnez t1, readSerialBW
        lb t2, 3(a2)                #reads ready serial byte
        beqz t2, readSerialLoopEnd  #if byte == 0 means stdin is empty
        sb t2, 0(a3)                #stores in end of string
        addi a3, a3, 1              #increment eos adr
        sub a4, a3, a0
    blt a4, a1, readSerialLoop
    readSerialLoopEnd:

    sub a0, a3, a0

    ret

# .globl write_serial
write_serial:
#void writeSerial(char* buffer, int size)
    mv a3, a0                       #eos pointer

    li a2, SERIAL
    li a4, 0
    writeSerialLoop:
        lb t1, 0(a3)                #load string char
        # beqz t1, writeSerialLoopEnd
        sb t1, 1(a2)                #stores char on serial buffer
        li t2, 1                    
        sb t2, 0(a2)                #prepares and loads 1 into write register of serial
        writeSerialBW:
            lb t2, 0(a2)            #checks if serial register is 0, meaning byte was written
            # sb t1, 1(a2)
        bnez t2, writeSerialBW
        addi a3, a3, 1              #increments eos adr
        addi a4, a4, 1

    blt a4, a1, writeSerialLoop     #Write bytes until 'size' was reached
    # bnez t1, writeSerialLoop   #if last written byte was != '\0' read next char
    writeSerialLoopEnd:

    # li t5, 10
    # sb t5, 1(a2)

    # li t2, 1
    # sb t2, 0(a2) 
    # writeSerialNewLineBW:
    #     lb t2, 0(a2)
    # bnez t2, writeSerialNewLineBW

    #must not add newline byte at the end

    ret

# .globl get_systime
get_systime:
#int getSystime()
    li a2, GPT
    li a1, 1

    sb a1, 0(a2)
    getSystimeBW:
        lb a1, (a2)
    bnez a1, getSystimeBW

    lw a0, 0x4(a2)

    ret


