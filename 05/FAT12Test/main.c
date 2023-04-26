#include <stdio.h>
#include <fcntl.h>

typedef unsigned int uint;
typedef unsigned short ushort;
typedef unsigned char uchar;

#pragma pack (1)

typedef struct {
    char BS_OEMName[8];
    ushort BPB_BytsPerSec;
    uchar BPB_SecPerClus;
    ushort BPB_RsvdSecCnt;
    uchar BPB_NumFATs;
    ushort BPB_RootEntCnt;
    ushort BPB_TotSec16;
    uchar BPB_Media;
    ushort BPB_FATSz16;
    ushort BPB_SecPerTrk;
    ushort BPB_NumHeads;
    uint BPB_HiddSec;
    uint BPB_TotSec32;
    uchar BS_DrvNum;
    uchar BS_Reserved1;
    uchar BS_BootSig;
    uint BS_VolID;
    char BS_VolLab[11];
    char BS_FileSysType[8];
} Fat12Header;

void PrintHeader(Fat12Header* header, int fd)
{
    lseek(fd, 3, SEEK_SET); // 跳过开头三个字节
    read(fd, header, sizeof(Fat12Header));

    header->BS_OEMName[7] = '\0';
    header->BS_VolLab[10] = '\0';
    header->BS_FileSysType[7] = '\0';

    printf("BS_OEMName: %s\n", header->BS_OEMName);
    printf("BPB_BytsPerSec: %x\n", header->BPB_BytsPerSec);
    printf("BPB_SecPerClus: %x\n", header->BPB_SecPerClus);
    printf("BPB_RsvdSecCnt: %x\n", header->BPB_RsvdSecCnt);
    printf("BPB_NumFATs: %x\n", header->BPB_NumFATs);
    printf("BPB_RootEntCnt: %x\n", header->BPB_RootEntCnt);
    printf("BPB_TotSec16: %x\n", header->BPB_TotSec16);
    printf("BPB_Media: %x\n", header->BPB_Media);
    printf("BPB_FATSz16: %x\n", header->BPB_FATSz16);
    printf("BPB_SecPerTrk: %x\n", header->BPB_SecPerTrk);
    printf("BPB_NumHeads: %x\n", header->BPB_NumHeads);
    printf("BPB_HiddSec: %x\n", header->BPB_HiddSec);
    printf("BPB_TotSec32: %x\n", header->BPB_TotSec32);
    printf("BS_DrvNum: %x\n", header->BS_DrvNum);
    printf("BS_Reserved1: %x\n", header->BS_Reserved1);
    printf("BS_BootSig: %x\n", header->BS_BootSig);
    printf("BS_VolID: %x\n", header->BS_VolID);
    printf("BS_VolLab: %s\n", header->BS_VolLab);
    printf("BS_FileSysType: %s\n", header->BS_FileSysType);

    lseek(fd, 510, SEEK_SET);

    uchar b510 = 0;
    uchar b511 = 0;

    read(fd, &b510, 1);
    read(fd, &b511, 1);
    
    printf("Byte 510: 0x%x\n", b510);
    printf("Byte 511: 0x%x\n", b511);
}

int main()
{
    Fat12Header header;

    int fd = open("data.img", O_RDONLY);
    if (fd < 0) {
        printf("open data.img error\n");
        return -1;
    }

    PrintHeader(&header, fd);


    close(fd);

    return 0;
}