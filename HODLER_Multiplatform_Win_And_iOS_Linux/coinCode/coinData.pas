unit coinData;

interface

uses System.IOUtils, sysutils, StrUtils,
  FMX.Graphics, base58, FMX.Dialogs, WalletStructureData;

function CreateCoin(id, x, y: Integer; MasterSeed: AnsiString;
  description: AnsiString = ''): TWalletInfo;
function getCoinIcon(id: Integer): TBitmap;
function isValidForCoin(id: Integer; address: AnsiString): Boolean;
function getURLToExplorer(id: Integer; hash: AnsiString): AnsiString;

type
  coinInfo = record
    id: Integer;
    displayName: AnsiString;
    name: AnsiString;
    shortcut: AnsiString;
    WifByte: AnsiString;
    p2sh: AnsiString;
    p2pk: AnsiString;
    flag: System.UInt32;
    decimals: smallint;
    availableFirstLetter: AnsiString;
    hrp: AnsiString;
    qrname: AnsiString;
  end;

const
  // all supported coin
  availableCoin: array [0 .. 7] of coinInfo = ((id: 0; displayName: 'Bitcoin';
    name: 'bitcoin'; shortcut: 'BTC'; WifByte: '80'; p2sh: '05'; p2pk: '00';

    flag: 0; decimals: 8; availableFirstLetter: '13b'; hrp: 'bc';
    qrname: 'bitcoin';

    ), (id: 1; displayName: 'Litecoin'; name: 'litecoin'; shortcut: 'LTC';
    WifByte: 'B0'; p2sh: '32' { '05' }; p2pk: '30';

    flag: 0; decimals: 8; availableFirstLetter: 'lm'; hrp: 'ltc';
    qrname: 'litecoin';

    ), (id: 2; displayName: 'DASH'; name: 'dash'; shortcut: 'DASH';
    WifByte: 'CC'; p2sh: '10'; p2pk: '4c'; flag: 0; decimals: 8;
    availableFirstLetter: 'X'; qrname: 'dash';

    ), (id: 3; displayName: 'Bitcoin Cash'; name: 'bitcoinabc'; shortcut: 'BCH';
    WifByte: '80'; p2sh: '05'; p2pk: '00';

    flag: 0; decimals: 8; availableFirstLetter: '13pq'; qrname: 'bitcoincash';

    ), (id: 4; displayName: 'Ethereum'; name: 'ethereum'; shortcut: 'ETH';
    WifByte: ''; p2pk: '00'; flag: 1; decimals: 18; availableFirstLetter: '0';
    qrname: 'ethereum';

    ), (id: 5; displayName: 'Ravencoin'; name: 'ravencoin'; shortcut: 'RVN';
    WifByte: '80'; p2sh: '7a'; p2pk: '3c'; flag: 0; decimals: 8;
    availableFirstLetter: 'Rr'; qrname: 'ravencoin';

    ), (id: 6; displayName: 'Digibyte'; name: 'digibyte'; shortcut: 'DGB';
    WifByte: '80'; p2sh: '3f'; p2pk: '1e'; flag: 0; decimals: 8;
    availableFirstLetter: 'SD'; qrname: 'digibyte';

    ), (id: 7; displayName: 'Bitcoin SV'; name: 'bitcoinsv'; shortcut: 'BSV';
    WifByte: '80'; p2sh: '05'; p2pk: '00';

    flag: 0; decimals: 8; availableFirstLetter: '13pq'; qrname: 'bitcoincash';

    )

    );

implementation

uses Bitcoin, Ethereum, misc, UHome;

function getURLToExplorer(id: Integer; hash: AnsiString): AnsiString;
var
  URL: AnsiString;
begin

  case id of
    0:
      URL := 'https://www.blockchain.com/btc/tx/';
    1:
      URL := 'https://chain.so/tx/LTC/';
    2:
      URL := 'https://chainz.cryptoid.info/dash/tx.dws?';
    3:
      URL := 'https://blockchair.com/bitcoin-cash/transaction/';
    4:
      URL := 'https://etherscan.io/tx/';
    5:
      URL := 'https://ravencoin.network/tx/';
    6:
      URL := 'https://digiexplorer.info/tx/';
    7:
      URL := 'https://bsvexplorer.info//#/tx/';
  end;

  result := URL + hash;
end;

function getCoinIcon(id: Integer): TBitmap;
begin
  result := frmhome.coinIconsList.Source[id].MultiResBitmap[0].Bitmap;
end;

function CreateCoin(id, x, y: Integer; MasterSeed: AnsiString;
  description: AnsiString = ''): TWalletInfo;
begin
  case availableCoin[id].flag of
    0:
      result := Bitcoin_createHD(id, x, y, MasterSeed);
    1:
      result := Ethereum_createHD(id, x, y, MasterSeed);
  end;

  // if description <> '' then
  // begin
  result.description := description;
  /// end
  // else
  // result.description := result.addr;

  wipeAnsiString(MasterSeed);
end;

function checkFirstLetter(id: Integer; address: AnsiString): Boolean;
var
  c: Ansichar;
  position: Integer;
begin

  address := removeSpace(address);
  if containsText(address, ':') then
  begin
    position := pos(':', address);
    address := rightStr(address, length(address) - position);
  end;

  for c in availableCoin[id].availableFirstLetter do
  begin

    if lowercase(address[low(address)]) = lowercase(c) then
      exit(true);

  end;

  result := false;
end;

// check if given address is of given coin
function isValidForCoin(id: Integer; address: AnsiString): Boolean;
var
  str: AnsiString;
  x: Integer;
  info: TAddressInfo;
begin
  result := false;
  if availableCoin[id].flag = 0 then
  begin

    if (id in [3, 7]) then
    begin

      str := StringReplace(address, ' ', '', [rfReplaceAll]);
      str := StringReplace(str, 'bitcoincash:', '', [rfReplaceAll]);

      if (str[low(str)] = 'q') or (str[low(str)] = 'p') then
      begin
        // isValidBCHCashAddress(Address)
        result := true;
      end
      else
      begin
        info := decodeAddressInfo(address, id);
        if info.scriptType >= 0 then
          result := true;
      end;

    end
    else
    begin

      try
        info := decodeAddressInfo(address, id);
      except
        on E: Exception do
        begin

          exit(false);
        end;
      end;

      if info.scriptType >= 0 then
        result := true;

    end;

    // showmessage(str + '  sh  ' + availablecoin[id].p2sh + '  pk  ' + availablecoin[id].p2pk);
  end
  else if availableCoin[id].flag = 1 then
  begin
    // showmessage(inttostr(length(address)));
    result := ((isHex(rightStr(address, 40))) and (length(address) = 42));
  end;

  result := result and checkFirstLetter(id, address);

end;

end.
