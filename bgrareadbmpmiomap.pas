{ ***************************************************************************
 *                                                                          *
 *  This file is part of BGRABitmap library which is distributed under the  *
 *  modified LGPL.                                                          *
 *                                                                          *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,   *
 *  for details about the copyright.                                        *
 *                                                                          *
 *  This program is distributed in the hope that it will be useful,         *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    *
 *                                                                          *
 ************************* BGRABitmap library  ******************************

 - Drawing routines with transparency and antialiasing with Lazarus.
   Offers also various transforms.
 - These routines allow to manipulate 32bit images in BGRA format or RGBA
   format (depending on the platform).
 - This code is under modified LGPL (see COPYING.modifiedLGPL.txt).
   This means that you can link this library inside your programs for any purpose.
   Only the included part of the code must remain LGPL.

 - If you make some improvements to this library, please notify here:
   http://www.lazarus.freepascal.org/index.php/topic,12037.0.html

   ********************* Contact : Circular at operamail.com *******************


   ******************************* CONTRIBUTOR(S) ******************************
   - Edivando S. Santos Brasil | mailedivando@gmail.com
     (Compatibility with FPC ($Mode objfpc/delphi) and delphi VCL 11/2018)

   ***************************** END CONTRIBUTOR(S) *****************************}


Unit BGRAReadBmpMioMap;

{$i bgrabitmap.inc}{$H+}

interface

uses
  Classes, SysUtils, BGRATypes,{$IFNDEF FPC}Types, GraphType, BGRAGraphics,{$ENDIF} FPImage, BGRABitmapTypes;

const
  MioMapMagicValue = 'RL';
  MioMapTransparentColor = $F81F;

type
  TMioHeader = packed record
    magic: packed array[1..2] of {$IFDEF FPC}Char{$ELSE}AnsiChar{$ENDIF};
    format: BGRAWord;
    width,height,nbColors,nbChunks: BGRAWord;
  end;

  TPixelArray = array of TBGRAPixel;

  { TBGRAReaderBmpMioMap }

  TBGRAReaderBmpMioMap = class(TFPCustomImageReader)
  private
    function ReadHeader(Stream: TStream; out header: TMioHeader): boolean;
    function ReadPalette(Stream: TStream; nbColors: integer; alphaChannel: boolean): TPixelArray;
    procedure UncompressChunks(Stream: TStream; nbChunks: integer; palette: TPixelArray; img: TFPCustomImage);
  public
    procedure InternalRead  (Stream:TStream; Img:TFPCustomImage); override;
    function  InternalCheck (Stream:TStream) : boolean; override;
  end;

function MioMapToBGRA(AColor: BGRAWord): TBGRAPixel;
function BGRAToMioMap(const AColor: TBGRAPixel): BGRAWord;
function MioMapToAlpha(AValue: Byte): Byte;
function AlphaToMioMap(AValue: Byte): Byte;

implementation

{$IFDEF FPC}//#
uses bufstream;
{$ENDIF}

function MioMapToBGRA(AColor: BGRAWord): TBGRAPixel;
begin
  if AColor = MioMapTransparentColor then
    result := BGRAPixelTransparent
  else
    result := Color16BitToBGRA(AColor);
end;

function BGRAToMioMap(const AColor: TBGRAPixel): BGRAWord;
begin
  if AColor.alpha < 7 then
    result := MioMapTransparentColor
  else
  begin
    result := BGRAToColor16Bit(AColor);
    if result = MioMapTransparentColor then dec(result);
  end;
end;

function MioMapToAlpha(AValue: Byte): Byte;
begin
  result := AValue*255 div 32;
end;

function AlphaToMioMap(AValue: Byte): Byte;
begin
  result := (AValue*32 + 64) div 255;
end;

{ TBGRAReaderBmpMioMap }

function TBGRAReaderBmpMioMap.ReadHeader(Stream: TStream; out header: TMioHeader
  ): boolean;
begin
  result := false;
  fillchar({%H-}header,sizeof(header),0);
  if stream.Read(header, sizeof(header))<> sizeof(header) then exit;
  if header.magic <> MioMapMagicValue then exit;
  {$IFNDEF BDS}header.format:= LEtoN(header.format);{$ENDIF}
  {$IFNDEF BDS}header.width:= LEtoN(header.width);{$ENDIF}
  {$IFNDEF BDS}header.height:= LEtoN(header.height);{$ENDIF}
  {$IFNDEF BDS}header.nbColors:= LEtoN(header.nbColors);{$ENDIF}
  {$IFNDEF BDS}header.nbChunks:= LEtoN(header.nbChunks);{$ENDIF}
  if header.format > 1 then exit;
  result := true;
end;

function TBGRAReaderBmpMioMap.ReadPalette(Stream: TStream; nbColors: integer;
  alphaChannel: boolean): TPixelArray;
var mioPalette: packed array of BGRAWord;
  nbColorsRead,i: integer;
  colorValue: BGRAWord;
  alphaPalette: packed array of byte;
begin
  setlength(mioPalette, nbColors);
  setlength(result,nbColors);
  nbColorsRead:= Stream.Read({%H-}mioPalette[0], nbColors*2) div 2;
  for i := 0 to nbColorsRead-1 do
  begin
    colorValue := {$IFNDEF BDS}LEtoN{$ENDIF}(mioPalette[i]);
    result[i] := MioMapToBGRA(colorValue);
  end;
  for i := nbColorsRead to nbColors-1 do
    result[i] := BGRAPixelTransparent;
  if alphaChannel then
  begin
    setlength(alphaPalette,nbColors);
    Stream.Read(alphaPalette[0],nbColors);
    for i := 0 to nbColors-1 do
      if mioPalette[i] <> MioMapTransparentColor then
        result[i].alpha := MioMapToAlpha(alphaPalette[i]);
  end;
end;

procedure TBGRAReaderBmpMioMap.UncompressChunks(Stream: TStream; nbChunks: integer;
  palette: TPixelArray; img: TFPCustomImage);
var i,maxChunkSize: integer;
  chunkSizes: array of integer;
  chunkData: packed array of byte;
  pos,bytesRead: integer;
  palLen: integer;
  x,y: integer;
  p: PBGRAPixel;
  colorOffset: integer;
  b: byte;
  w,h: integer;

  procedure UncompressPixel(colorNumber, repeatCount: integer);
  var
    c: TBGRAPixel;
  begin
    if colorNumber >= palLen then
      c := BGRAPixelTransparent
    else
      c := palette[colorNumber];
    while (repeatCount > 0) and (y < h) do
    begin
      if p <> nil then
      begin
        p^ := c;
        inc(p);
      end else
        img.Colors[x,y] := BGRAToFPColor(c);
      inc(x);
      if x = w then
      begin
        x := 0;
        inc(y);
        if p <> nil then
        begin
          if y >= h then p := nil
          else
            p := TBGRACustomBitmap(Img).ScanLine[y];
        end;
      end;
      dec(repeatCount);
    end;
  end;

begin
  palLen := length(palette);
  if (img.Width = 0) or (img.Height = 0) or (palLen = 0) then exit;

  maxChunkSize := 1;
  setlength(chunkSizes, nbChunks);
  for i := 0 to nbChunks-1 do
  begin
    if stream.read({%H-}b,1)=0 then b := 0;
    if b < 255 then
    begin
      chunkSizes[i] := b;
    end else
    begin
      if stream.read(b,1)=0 then b := 0;
      chunkSizes[i] := b shl 8;
      if stream.read(b,1)=0 then b := 0;
      chunkSizes[i] := chunkSizes[i] +b;
    end;
    if chunkSizes[i]>maxChunkSize then
      maxChunkSize := chunkSizes[i];
  end;

  setlength(chunkData, maxChunkSize);
  x := 0;
  y := 0;
  w := img.Width;
  h := img.Height;
  colorOffset:= 0;
  if Img is TBGRACustomBitmap then
  begin
    p := TBGRACustomBitmap(Img).ScanLine[y];
    TBGRACustomBitmap(Img).FillTransparent;
  end
  else
    p := nil;
  for i:= 0 to nbChunks-1 do
  begin
    bytesRead := Stream.Read(chunkData[0], chunkSizes[i]);
    pos := 0;
    while pos < bytesRead do
    begin
      if (chunkData[pos] = $FE) and (pos+2 < bytesRead) then
      begin
        UncompressPixel(chunkData[pos+1]+colorOffset,chunkData[pos+2]);
        inc(pos,3);
      end else
      if (chunkData[pos] = $ff) and (pos+1 < bytesRead) then
      begin
        UncompressPixel(0,chunkData[pos+1]);
        inc(pos,2);
      end else
      if (chunkData[pos] = $fd) and (pos+2 < bytesRead) then
      begin
        colorOffset:= chunkData[pos+1] + (chunkData[pos+2] shl 8);
        inc(pos,3);
      end else
      if chunkData[pos] = 0 then
      begin
        UncompressPixel(0,1);
        inc(pos);
      end else
      begin
        UncompressPixel(chunkData[pos]+colorOffset,1);
        inc(pos);
      end;
    end;
  end;
end;

procedure TBGRAReaderBmpMioMap.InternalRead(Stream: TStream; Img: TFPCustomImage);
{$IFDEF FPC}//#
var header: TMioHeader;
  palette: TPixelArray;
  buf: TReadBufStream;
{$ENDIF}
begin
{$IFDEF FPC}//#
  if not ReadHeader(stream, header) then exit;
  buf := TReadBufStream.Create(Stream,1024);
  Img.SetSize(header.width,header.height);
  palette := ReadPalette(stream, header.nbColors, header.format = 1);
  UncompressChunks(stream,header.nbChunks, palette, Img);
  buf.Free;
{$ENDIF}
end;

function TBGRAReaderBmpMioMap.InternalCheck(Stream: TStream): boolean;
var OldPosition : BGRAInt64;
  dummy: TMioHeader;
begin
  OldPosition:= stream.Position;
  result := ReadHeader(stream, dummy);
  stream.Position:= OldPosition;
end;

initialization

  DefaultBGRAImageReader[ifBmpMioMap] := TBGRAReaderBmpMioMap;

end.
