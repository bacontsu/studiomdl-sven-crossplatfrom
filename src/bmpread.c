#if defined( _WIN32 )
#include <windows.h>
#include <STDIO.H>
#else
#include <stdio.h>
#include <stdlib.h>
// bacontsu: memmove() needs string.h, windows.h used to pull it in on the other branch
#include <string.h>

typedef int LONG;
typedef unsigned int ULONG;	// bacontsu: Win32 ULONG is 32 bit, not the LP64 8 byte long
typedef unsigned char BYTE;
typedef unsigned char byte;
typedef unsigned int DWORD;
typedef unsigned short WORD;

// __attribute__((packed)) on non-Intel arch may cause some unexpected error, plz be informed.

typedef struct tagBITMAPFILEHEADER
{
    WORD    bfType; // 2  /* Magic identifier */
    DWORD   bfSize; // 4  /* File size in bytes */
    WORD    bfReserved1; // 2
    WORD    bfReserved2; // 2
    DWORD   bfOffBits; // 4 /* Offset to image data, bytes */
} __attribute__((packed)) BITMAPFILEHEADER;

typedef  enum
{
  BI_RGB = 0x0000,
  BI_RLE8 = 0x0001,
  BI_RLE4 = 0x0002,
  BI_BITFIELDS = 0x0003,
  BI_JPEG = 0x0004,
  BI_PNG = 0x0005,
  BI_CMYK = 0x000B,
  BI_CMYKRLE8 = 0x000C,
  BI_CMYKRLE4 = 0x000D
} Compression;

typedef struct tagBITMAPINFOHEADER
{
    DWORD    biSize; // 4 /* Header size in bytes */
    LONG     biWidth; // 4 /* Width of image */
    LONG     biHeight; // 4 /* Height of image */
    WORD     biPlanes; // 2 /* Number of colour planes */
    WORD     biBitCount; // 2 /* Bits per pixel */
    DWORD    biCompression; // 4 /* Compression type */
    DWORD    biSizeImage; // 4 /* Image size in bytes */
    LONG     biXPelsPerMeter; // 4
    LONG     biYPelsPerMeter; // 4 /* Pixels per meter */
    DWORD    biClrUsed; // 4 /* Number of colours */
    DWORD    biClrImportant; // 4 /* Important colours */
} __attribute__((packed)) BITMAPINFOHEADER;

typedef struct tagRGBQUAD
{
  BYTE rgbBlue;
  BYTE rgbGreen;
  BYTE rgbRed;
  BYTE rgbReserved;
} RGBQUAD;
// for biBitCount is 16/24/32, it may be useless

typedef struct
{
        BYTE    b;
        BYTE    g;
        BYTE    r;
} RGB_data; // RGB TYPE, plz also make sure the order
#endif

int LoadBMP (const char* szFile, byte** ppbBits, byte** ppbPalette, int *width, int *height )
{
	int i, rc = 0;
	FILE *pfile = NULL;
	BITMAPFILEHEADER bmfh;
	BITMAPINFOHEADER bmih;
	RGBQUAD rgrgbPalette[256];
	ULONG cbBmpBits;
	BYTE* pbBmpBits = NULL;
	BYTE* pbData = NULL;
	byte  *pb, *pbPal = NULL;
	ULONG cbPalBytes;
	ULONG biTrueWidth;

	// Bogus parameter check
	if (!(ppbPalette != NULL && ppbBits != NULL))
		{ fprintf(stderr, "invalid BMP file\n"); rc = -1000; goto GetOut; }

	// File exists?
	if ((pfile = fopen(szFile, "rb")) == NULL)
		{ fprintf(stderr, "unable to open BMP file\n"); rc = -1; goto GetOut; }

	// Read file header
	if (fread(&bmfh, sizeof bmfh, 1/*count*/, pfile) != 1)
		{ rc = -2; goto GetOut; }

	// Bogus file header check
	if (!(bmfh.bfReserved1 == 0 && bmfh.bfReserved2 == 0))
		{ rc = -2000; goto GetOut; }

	// Read info header
	if (fread(&bmih, sizeof bmih, 1/*count*/, pfile) != 1)
		{ rc = -3; goto GetOut; }

	// Bogus info header check
	if (!(bmih.biSize == sizeof bmih && bmih.biPlanes == 1))
		{ fprintf(stderr, "invalid BMP file header\n");  rc = -3000; goto GetOut; }

	// Bogus bit depth?  Only 8-bit supported.
	if (bmih.biBitCount != 8)
		{ fprintf(stderr, "BMP file not 8 bit\n");  rc = -4; goto GetOut; }

	// Bogus compression?  Only non-compressed supported.
	if (bmih.biCompression != BI_RGB)
		{ fprintf(stderr, "invalid BMP compression type\n"); rc = -5; goto GetOut; }

	// bacontsu: bogus dimensions, a malformed header must not turn into a negative/huge row stride
	if (bmih.biWidth <= 0 || bmih.biHeight <= 0 || bmih.biWidth > 4096 || bmih.biHeight > 4096)
		{ fprintf(stderr, "invalid BMP dimensions\n"); rc = -9; goto GetOut; }

	// Figure out how many entires are actually in the table
	if (bmih.biClrUsed == 0)
		{
		bmih.biClrUsed = 256;
		cbPalBytes = (ULONG)( ( 1 << bmih.biBitCount ) * (int)sizeof( RGBQUAD ) );
		}
	else
		{
		cbPalBytes = bmih.biClrUsed * sizeof( RGBQUAD );
		}

	// Read palette (bmih.biClrUsed entries)
	if (fread(rgrgbPalette, cbPalBytes, 1/*count*/, pfile) != 1)
		{ rc = -6; goto GetOut; }

	// convert to a packed 768 byte palette
	pbPal = malloc(768);
	if (pbPal == NULL)
		{ rc = -7; goto GetOut; }

	pb = pbPal;

	// Copy over used entries
	for (i = 0; i < (int)bmih.biClrUsed; i++)
	{
		*pb++ = rgrgbPalette[i].rgbRed;
		*pb++ = rgrgbPalette[i].rgbGreen;
		*pb++ = rgrgbPalette[i].rgbBlue;
	}

	// Fill in unused entires will 0,0,0
	for (i = bmih.biClrUsed; i < 256; i++)
	{
		*pb++ = 0;
		*pb++ = 0;
		*pb++ = 0;
	}

	// Read bitmap bits (remainder of file)
	cbBmpBits = bmfh.bfSize - ftell(pfile);
	if (cbBmpBits == 0 || cbBmpBits > 0x10000000)
		{ fprintf(stderr, "invalid BMP data size\n"); rc = -8; goto GetOut; }
	pbData = malloc(cbBmpBits);
	if (pbData == NULL)
		{ rc = -7; goto GetOut; }
	if (fread(pbData, cbBmpBits, 1/*count*/, pfile) != 1)
		{ rc = -7; goto GetOut; }

	pbBmpBits = calloc(1, cbBmpBits);
	if (pbBmpBits == NULL)
		{ rc = -7; goto GetOut; }

	// data is actually stored with the width being rounded up to a multiple of 4
	biTrueWidth = (bmih.biWidth + 3) & ~3;

	// bacontsu: the row stride must actually be present in the data we read, otherwise the
	// flip below reads past the end of the buffer
	if ((ULONG)biTrueWidth * (ULONG)bmih.biHeight > cbBmpBits)
		{ fprintf(stderr, "invalid BMP data size\n"); rc = -8; goto GetOut; }

	// reverse the order of the data.
	pb = pbData + (bmih.biHeight - 1) * biTrueWidth;
	for(i = 0; i < bmih.biHeight; i++)
	{
		memmove(&pbBmpBits[biTrueWidth * i], pb, biTrueWidth);
		pb -= biTrueWidth;
	}

	// bacontsu: pb is advanced above so the original allocation has to be released
	free(pbData);
	pbData = NULL;

	*width = (WORD)bmih.biWidth;
	*height = (WORD)bmih.biHeight;
	// Set output parameters
	*ppbPalette = pbPal;
	*ppbBits = pbBmpBits;

GetOut:
	if (pfile)
		fclose(pfile);

	// bacontsu: only hand out/free the buffers on success, the caller owns them from here on
	if (rc != 0)
	{
		free(pbPal);
		free(pbBmpBits);
		free(pbData);
	}

	return rc;
}
