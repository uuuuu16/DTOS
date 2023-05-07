org 0x7c00

; BS_jmpBoot 字段后面的数据不是可执行程序，而是FAT12文件系统的组成结构信息
; 故此必须跳过。
; BS_jmpBoot字段长度为3个字节，
; nop会生成一个字节的机器码，jmp short start会生成两个字节
jmp short start
nop

define:
    BaseOfStack equ 0x7c00

header:
    BS_OEMName     db "D.T.Soft"
    BPB_BytsPerSec dw 512
    BPB_SecPerClus db 1
    BPB_RsvdSecCnt dw 1
    BPB_NumFATs    db 2
    BPB_RootEntCnt dw 224
    BPB_TotSec16   dw 2880
    BPB_Media      db 0xF0
    BPB_FATSz16    dw 9
    BPB_SecPerTrk  dw 18 ; 每磁道扇区数
    BPB_NumHeads   dw 2
    BPB_HiddSec    dd 0
    BPB_TotSec32   dd 0
    BS_DrvNum      db 0 ; int 13h的驱动器号
    BS_Reserved1   db 0
    BS_BootSig     db 0x29
    BS_VolID       dd 0
    BS_VolLab      db "D.T.OS-0.01"
    BS_FileSysType db "FAT12   "

start:
    mov ax, cs
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, BaseOfStack
    
    mov si, MsgStr
    mov di, DEST
    mov cx, MsgLen
    call MemCmp

    cmp cx, 0
    jz label
    jmp last

label:
    mov bp, MsgStr  ; 打印字符串的内存地址
    mov cx, MsgLen  ; 字符串的长度
    call Print

last:
    hlt
    jmp  last

; ds:si - source
; es:di - destination
; cx - len
; return cx == 0 ? equal : noequal
MemCmp:
    push si
    push di
    push ax
compare:
    cmp cx, 0
    jz equal
    mov al, [si]
    cmp al, byte [di]
    jz goon
    jmp noequal
goon:
    inc si
    inc di
    dec cx
    jmp compare
equal:
noequal:
    pop ax
    pop di
    pop si
    ret

; es:bp --> string addr
; cx --> string length
Print:
    ; 打印参数
    mov ax, 0x1301
    mov bx, 0x0007
    int 0x10    
    ret

; no parameters
ResetFloppy:
    push ax
    push dx

    mov ah, 0x00
    mov dl, [BS_DrvNum]
    int 0x13

    pop dx
    pop ax

    ret

; ax --> 逻辑扇区号
; cx --> 读取多少个扇区
; es:bx --> target address
ReadSector:
    push ax
    push bx
    push cx
    push dx

    call ResetFloppy

    ; push bx
    push cx

    mov bl, [BPB_SecPerTrk] ; 每磁道扇区数
    div bl  ; ax / bl = al...ah
    mov cl, ah
    add cl, 1 ; 起始扇区号
    mov ch, al
    shr ch, 1 ; 除以2，柱面号
    mov dh, al
    and dh, 1 ; 磁头号
    mov dl, [BS_DrvNum]
    
    pop ax
    ; pop bx
    
    mov ah, 0x02
read:
    int 0x13
    jc read

    pop dx
    pop cx
    pop bx
    pop ax

    ret

MsgStr db "Hello, DTOS!"
MsgLen equ ($ - MsgStr)
DEST   db "Hello, DTOS!"
Buf:
    ; 计算当前位置到代码起始位置之间的字节数（也就是程序长度）,
    ; 并将其与 510 进行差值运算，得到一个需要填充的字节数
    ; 即：填写 510-($-$$)个0x00到内存中
    times (510 - ($ - $$)) db 0x00
    db 0x55, 0xaa
