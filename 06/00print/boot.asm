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
    BPB_SecPerTrk  dw 18
    BPB_NumHeads   dw 2
    BPB_HiddSec    dd 0
    BPB_TotSec32   dd 0
    BS_DrvNum      db 0
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

    mov bp, MsgStr  ; ��ӡ�ַ������ڴ��ַ
    mov cx, MsgLen  ; �ַ����ĳ���
    call Print

last:
    hlt
    jmp  last

Print:
    ; ��ӡ����
    mov ax, 0x1301
    mov bx, 0x0007
    int 0x10    
    ret

MsgStr db "Hello, DTOS!"
MsgLen equ ($ - MsgStr)
Buf:
    ; ���㵱ǰλ�õ�������ʼλ��֮����ֽ�����Ҳ���ǳ��򳤶ȣ�,
    ; �������� 510 ���в�ֵ���㣬�õ�һ����Ҫ�����ֽ���
    ; ������д 510-($-$$)��0x00���ڴ���
    times (510 - ($ - $$)) db 0x00
    db 0x55, 0xaa
