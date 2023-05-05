#include <stdio.h>
#include <fcntl.h>
#include <malloc.h>
#include <string.h>
#include <stdlib.h>

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

typedef struct {
    char DIR_Name[11];
    uchar DIR_Attr;
    uchar reserve[10];
    ushort DIR_WrtTime;
    ushort DIR_WrtDate;
    ushort DIR_FstClus;
    uint DIR_FileSize;
} RootEntry;

void PrintHeader(Fat12Header* header, FILE* fp)
{
    fseek(fp, 3, SEEK_SET); // 跳过开头三个字节
    fread(header, sizeof(Fat12Header), 1, fp);

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

    fseek(fp, 510, SEEK_SET);

    uchar b510 = 0;
    uchar b511 = 0;

    fread(&b510, sizeof(uchar), 1, fp);
    fread(&b511, sizeof(uchar), 1, fp);
    
    printf("Byte 510: 0x%x\n", b510);
    printf("Byte 511: 0x%x\n", b511);
}

RootEntry* FindRootEntry(Fat12Header* header, FILE* fp, int idx)
{
    RootEntry* re = (RootEntry*)malloc(sizeof(RootEntry));
    memset(re, 0, sizeof(RootEntry));

    fseek(fp, 19 * header->BPB_BytsPerSec + idx * sizeof(RootEntry), SEEK_SET);
    fread(re, sizeof(RootEntry), 1, fp);

    return re;
}

RootEntry* FindRootEntryByFileName(Fat12Header* header, FILE* fp, char* name)
{
    int i = 0;
    for (i = 0; i < header->BPB_RootEntCnt; i++) {
        RootEntry* re = FindRootEntry(header, fp, i);

        if (re->DIR_Name[0] != '\0') {
            char* pos = strchr(name, '.');
            if (pos) {
                char* prefix = (char*)malloc(pos - name + 1);
                memset(prefix, 0, pos - name + 1);
                strncpy(prefix, name, pos - name);

                char* suffix = (char*)malloc(strlen(name) - (pos - name) + 1);
                memset(suffix, 0, strlen(name) - (pos - name) + 1);
                strncpy(suffix, pos + 1, strlen(name) - (pos - name));

                if (strstr(re->DIR_Name, prefix) != NULL && strstr(re->DIR_Name, suffix) != NULL) {
                    printf("prefix: %s, suffix: %s\n", prefix, suffix);
                    free(prefix);
                    free(suffix);
                    return re;
                }
            } else {
                if(strncmp(re->DIR_Name, name, sizeof(re->DIR_Name)) == 0 ) {
                    return re;
                }
            }
        }
    }

    return NULL;
}

void PrintRootEntry(Fat12Header* header, FILE* fp)
{
    int i = 0;
    for (i = 0; i < header->BPB_RootEntCnt; i++) {
        RootEntry* re = FindRootEntry(header, fp, i);

        if (re->DIR_Name[0] != '\0') {
            printf("i : %d\n", i);
            printf("DIR_Name: %s\n", re->DIR_Name);
            printf("DIR_Attr: 0x%x\n", re->DIR_Attr);
            printf("DIR_WrtDate: 0x%x\n", re->DIR_WrtDate);
            printf("DIR_WrtTime: 0x%x\n", re->DIR_WrtTime);
            printf("DIR_FstClus: 0x%x\n", re->DIR_FstClus);
            printf("DIR_FileSize: 0x%x\n", re->DIR_FileSize);
            printf("\n");
        }

        free(re);
    }
}

ushort* ReadFat(Fat12Header* header, FILE* fp)
{
    int size = header->BPB_BytsPerSec * 9;
    // printf("size = %d, size*2/3 = %d\n", size, size*2/3);
    
    uchar* fat = (uchar*)malloc(size);
    
    fseek(fp, header->BPB_BytsPerSec * 1, SEEK_SET);
    fread(fat, size, 1, fp);

    ushort* ret = (ushort*)malloc(size * 2 / 3);
    memset(ret, 0xffff, size * 2 / 3);

    int i = 0, j = 0;
    for (i = 0, j = 0; i < size; i += 3, j += 2) {
        ret[j] = (ushort)((fat[i + 1] & 0x0f) << 8) | fat[i];
        ret[j + 1] = (ushort)(fat[i + 2] << 4) | ((fat[i + 1] >> 4) & 0x0f);
        // printf("size = %d, i = %d, j = %d, ret[j] = %d, ret[j+1] = %d, fat[i] = %d, fat[i+1] = %d, fat[i+2] = %d\n",
        //         size, i, j, ret[j], ret[j+1], fat[i], fat[i+1], fat[i+2]);
    }
    
    // free(fat);

    return ret;
}

char* ReadFileContent(Fat12Header* header, FILE* fp, char* name)
{
    RootEntry* re = FindRootEntryByFileName(header, fp, name);

    printf("DIR_Name: %s\n", re->DIR_Name);
    printf("name: %s\n", name);

    char* ret = (char*)malloc(re->DIR_FileSize);

    if (re->DIR_Name[0] != '\0') {
        ushort* vec = ReadFat(header, fp);
        int count = 0;
        char buf[512] = {0};

        int i = 0, j = re->DIR_FstClus;
        for (i = 0, j = re->DIR_FstClus; j < 0xff7; i += 512, j = vec[j]) {
            fseek(fp, header->BPB_BytsPerSec * (33 + j - 2), SEEK_SET);
            fread(buf, sizeof(buf), 1, fp);
            
            int k = 0;
            for (k = 0; k < sizeof(buf); k++) {
                ret[i + k] = buf[k];
                count++;
            }
        }

        // free(vec);
    }

    free(re);

    return ret;
}

int main()
{
    Fat12Header header;

    FILE* fp = fopen("data.img", "rb");
    if (fp == NULL) {
        perror("open data.img error\n");
        return -1;
    }

    PrintHeader(&header, fp);

    printf("\n");
    PrintRootEntry(&header, fp);

    char* buf = ReadFileContent(&header, fp, "TEST.TXT");
    printf("%s\n", buf);

    fclose(fp);

    return 0;
}