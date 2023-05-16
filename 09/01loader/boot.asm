org 0x7c00

; BS_jmpBoot �ֶκ�������ݲ��ǿ�ִ�г��򣬶���FAT12�ļ�ϵͳ����ɽṹ��Ϣ
; �ʴ˱���������
; BS_jmpBoot�ֶγ���Ϊ3���ֽڣ�
; nop������һ���ֽڵĻ����룬jmp short start�����������ֽ�
jmp short start
nop

define:
    BaseOfStack     equ 0x7c00
    BaseOfLoader    equ 0x9000
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
    EntryItemLength equ 32
    FatEntryOffset  equ 1
    FatEntryLength  equ 9

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
    mov ax, RootEntryOffset ; 19
    mov cx, RootEntryLength ; 14
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

    ; si - src
    ; di - dst
    ; cx - len
    mov si, bx
    mov di, EntryItem
    mov cx, EntryItemLength
    call MemCpy

    ; ����Fat��
    mov ax, FatEntryLength
    mov cx, [BPB_BytsPerSec]
    mul cx
    mov bx, BaseOfLoader ; 0x9000
    sub bx, ax ; ������Fat�������BaseOfLoaderǰ��

    ; ax --> �߼�������
    ; cx --> ��ȡ���ٸ�����
    ; es:bx --> target address
    mov ax, FatEntryOffset ; 1
    mov cx, FatEntryLength ; 9
    call ReadSector

    mov dx, [EntryItem + 0x1A] ; Ŀ¼���У�DIR_FstClus��ƫ�ƣ���ʼ��FAT�����±�
    mov si, BaseOfLoader
loading:
    mov ax, dx
    add ax, 33 - 2
    mov cx, 1
    push dx
    push bx
    mov bx, si
    ; ax --> �߼�������
    ; cx --> ��ȡ���ٸ�����
    ; es:bx --> target address
    call ReadSector
    pop bx
    pop cx
    ; cx - ��ʼ��FAT������±�index
    ; bx - Fat�����ڴ��е���ʼλ��
    ; return dx - fat�����ֵfat[index]
    ; ע��i = j / 2 * 3��j ��Ӧ�ľ���FAT������±�index
    call FatVec
    cmp dx, 0xFF7
    jnb BaseOfLoader ; �޷��Ų�С������ת
    add si, 512
    jmp loading

output:
    mov bp, BaseOfLoader
    mov cx, [EntryItem + 0x1C] ; 0x1C - EntryItem�е�DIR_FileSize
    call Print
last:
    hlt
    jmp  last


; cx - ��ʼ��FAT������±�index
; bx - Fat�����ڴ��е���ʼλ��
; return dx - fat�����ֵfat[index]
; ע��i = j / 2 * 3��j ��Ӧ�ľ���FAT������±�index
FatVec:
    mov ax, cx
    mov cl, 2
    div cl ; ax / cl = al ... ah

    push ax

    mov ah, 0
    mov cx, 3   ; 
    mul cx      ; al*cl=ax,   i = j / 2 * 3���õ�iΪ��ʼ�ֽ�
    mov cx, ax ; �õ� cx = i

    pop ax

    cmp ah, 0
    jz even
    jmp odd

even:   ; FatVec[j] = ( (Fat[i+1] & 0x0F) << 8 ) | Fat[i];
    ; cx����i��ֵ
    mov dx, cx
    add dx, 1
    add dx, bx
    mov bp, dx
    mov dl, byte [bp]
    and dl, 0x0F
    shl dx, 8
    add cx, bx
    mov bp, cx
    or dl, byte [bp] ; dh������8λ��Ľ��û�䣬dl���ϵ�8λ�Ľ��
    jmp return
odd:    ; FatVec[j+1] = (Fat[i+2] << 4) | ( (Fat[i+1] >> 4) & 0x0F );
    mov dx, cx ; cx = i
    add dx, 2
    add dx, bx
    mov bp, dx
    mov dl, byte [bp]
    mov dh, 0
    shl dx, 4
    add cx, 1
    add cx, bx
    mov bp, cx
    mov cl, byte [bp]
    shr cl, 4
    and cl, 0x0F
    mov ch, 0
    or  dx, cx

return:
    ret

; si - src
; di - dst
; cx - len
MemCpy:
    cmp si, di
    ja begintoend
    add si, cx  ; siָ��Դ�ڴ��β��
    add di, cx  ; diָ��Ŀ���ڴ��β��
    dec si  ; siָ��Դ�ڴ�����һ���ֽ�
    dec di  ; diָ��Ŀ���ڴ�����һ���ֽ�
    jmp endtobegin

begintoend:
    cmp cx, 0
    jz done
    mov al, [si]
    mov byte [di], al
    inc si
    inc di
    dec cx
    jmp begintoend

endtobegin:
    cmp cx, 0
    jz done
    mov al, [si]
    mov byte [di], al
    dec si
    dec di
    dec cx
    jmp endtobegin
done:
    ret

; es:bx - ��Ŀ¼����ʼ��ַ��ʼ
; ds:si - Ҫ���ҵ�target string
; cx - target length
; return dx != 0 ? exist : noexist
FindEntry:
    push cx

    mov dx, [BPB_RootEntCnt] ; �����Ҵ�����Ҳ��һ������Ŀ¼��
    mov bp, sp ; ����sp����push��cx

find:
    cmp dx, 0
    jz noexist
    mov di, bx
    mov cx, [bp]
    push si
    call MemCmp
    pop si
    cmp cx, 0
    jz exist
    ; �Ƚ���һ��Ŀ¼��
    add bx, 32
    dec dx
    jmp find

exist:
noexist:
    pop cx
    ret

; ds:si - source
; es:di - destination
; cx - len
; return cx == 0 ? equal : noequal
MemCmp:
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
    mov ah, 0x00
    mov dl, [BS_DrvNum]; ��������
    int 0x13

    ret

; ax --> �߼�������
; cx --> ��ȡ���ٸ�����
; es:bx --> target address
ReadSector:
    call  ResetFloppy

    push bx
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
    pop bx
    
    mov ah, 0x02
read:
    int 0x13
    jc read

    ret

MsgStr db "No LOADER ..."
MsgLen equ ($ - MsgStr)
Target db "LOADER  "
TarLen equ ($ - Target)

EntryItem times EntryItemLength db 0x00

Buf:
    ; ���㵱ǰλ�õ�������ʼλ��֮����ֽ�����Ҳ���ǳ��򳤶ȣ�,
    ; �������� 510 ���в�ֵ���㣬�õ�һ����Ҫ�����ֽ���
    ; ������д 510-($-$$)��0x00���ڴ���
    times (510 - ($ - $$)) db 0x00
    db 0x55, 0xaa
