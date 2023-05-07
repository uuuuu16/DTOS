org 0x7c00

; BS_jmpBoot �ֶκ�������ݲ��ǿ�ִ�г��򣬶���FAT12�ļ�ϵͳ����ɽṹ��Ϣ
; �ʴ˱���������
; BS_jmpBoot�ֶγ���Ϊ3���ֽڣ�
; nop������һ���ֽڵĻ����룬jmp short start�����������ֽ�
jmp short start
nop

define:
    BaseOfStack     equ 0x7c00
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; ����λ��	    ����	      ����
    ;   0	    1��512Bytes��	��������
    ;   1	    9��4608Bytes��	FAT��1
    ;   10	    9��4608Bytes��	FAT��2
    ;   19	    14��9728Bytes��	��Ŀ¼����Ŀ¼�ļ��
    ;   33	    ......	        �ļ�����
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    RootEntryOffset equ 19
    RootEntryLength equ 14

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
    
    ; ax --> �߼�������
    ; cx --> ��ȡ���ٸ�����
    ; es:bx --> target address
    mov ax, RootEntryOffset
    mov cx, RootEntryLength
    mov bx, Buf
    call ReadSector

    ; es:bx - ��Ŀ¼����ʼ��ַ��ʼ
    ; ds:si - Ҫ���ҵ�target string
    ; cx - target length
    ; return dx != 0 ? exist : noexist
    mov si, Target
    mov cx, TarLen
    mov dx, 0
    call FindEntry

    cmp dx, 0
    jz output
    jmp last

output:
    mov bp, MsgStr
    mov cx, MsgLen
    call Print
last:
    hlt
    jmp  last

; es:bx - ��Ŀ¼����ʼ��ַ��ʼ
; ds:si - Ҫ���ҵ�target string
; cx - target length
; return dx != 0 ? exist : noexist
FindEntry:
    push di
    push bp
    push cx

    mov dx, [BPB_RootEntCnt] ; �����Ҵ�����Ҳ��һ������Ŀ¼��
    mov bp, sp ; ����sp����push��cx

find:
    cmp dx, 0
    jz noexist
    mov di, bx
    mov cx, [bp]
    call MemCmp
    cmp cx, 0
    jz exist
    ; �Ƚ���һ��Ŀ¼��
    add bx, 32
    dec dx
    jmp find

exist:
noexist:
    pop cx
    pop bp
    pop di
    ret

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
    push bx
    push cx
    push dx
    push ax

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

    pop ax
    pop dx
    pop cx
    pop bx
    
    ret

MsgStr db "No LOADER ..."
MsgLen equ ($ - MsgStr)
Target db "LOADER"
TarLen equ ($ - Target)
Buf:
    ; ���㵱ǰλ�õ�������ʼλ��֮����ֽ�����Ҳ���ǳ��򳤶ȣ�,
    ; �������� 510 ���в�ֵ���㣬�õ�һ����Ҫ�����ֽ���
    ; ������д 510-($-$$)��0x00���ڴ���
    times (510 - ($ - $$)) db 0x00
    db 0x55, 0xaa
