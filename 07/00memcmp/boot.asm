org 0x7c00

; BS_jmpBoot �ֶκ�������ݲ��ǿ�ִ�г��򣬶���FAT12�ļ�ϵͳ����ɽṹ��Ϣ
; �ʴ˱���������
; BS_jmpBoot�ֶγ���Ϊ3���ֽڣ�
; nop������һ���ֽڵĻ����룬jmp short start�����������ֽ�
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
    BPB_SecPerTrk  dw 18 ; ÿ�ŵ�������
    BPB_NumHeads   dw 2
    BPB_HiddSec    dd 0
    BPB_TotSec32   dd 0
    BS_DrvNum      db 0 ; int 13h����������
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
    mov bp, MsgStr  ; ��ӡ�ַ������ڴ��ַ
    mov cx, MsgLen  ; �ַ����ĳ���
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
    ; ��ӡ����
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

; ax --> �߼�������
; cx --> ��ȡ���ٸ�����
; es:bx --> target address
ReadSector:
    push ax
    push bx
    push cx
    push dx

    call ResetFloppy

    ; push bx
    push cx

    mov bl, [BPB_SecPerTrk] ; ÿ�ŵ�������
    div bl  ; ax / bl = al...ah
    mov cl, ah
    add cl, 1 ; ��ʼ������
    mov ch, al
    shr ch, 1 ; ����2�������
    mov dh, al
    and dh, 1 ; ��ͷ��
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
    ; ���㵱ǰλ�õ�������ʼλ��֮����ֽ�����Ҳ���ǳ��򳤶ȣ�,
    ; �������� 510 ���в�ֵ���㣬�õ�һ����Ҫ�����ֽ���
    ; ������д 510-($-$$)��0x00���ڴ���
    times (510 - ($ - $$)) db 0x00
    db 0x55, 0xaa
