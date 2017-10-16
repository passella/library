unit untMessageExecuter;

interface

uses
   Winapi.Windows, Winapi.Messages, Vcl.Controls, System.Classes;

type
   TMessageExecuterPrc<T: record > = reference to procedure(var msg: T);
   TMessageExecuterFnc<T: record > = reference to function(var msg: T): NativeUInt;

   TMessageExecuterType = (SEND = 0, POST = 1);

   TMessageExecuter = class(TInterfacedObject)
   public
      class procedure Executar<T: record >(const hwd: HWND; const msg: Cardinal; const prc: TMessageExecuterPrc<T> = nil;
         const prcAfter: TMessageExecuterPrc<T> = nil); overload;

      class procedure ExecutarPost<T: record >(const hwd: HWND; const msg: Cardinal; const prc: TMessageExecuterPrc<T> = nil); overload;
      class procedure ExecutarPost(const hwd: HWND; const msg: Cardinal); overload;
      class procedure Executar(const hwd: HWND; const msg: Cardinal); overload;

      class procedure Processar<T: record >(var msg: TMessage; const fnc: TMessageExecuterFnc<T>);

      class function Registrar(const AMethod: TWndMethod): HWND;
      class procedure DesRegistrar(Wnd: HWND);
      class procedure Dispatch(const obj: TObject; var Message: TMessage); reintroduce;
   end;

implementation

{ TMessageExecuter }

class procedure TMessageExecuter.DesRegistrar(Wnd: HWND);
begin
   DeallocateHWnd(Wnd);
end;

class procedure TMessageExecuter.Executar<T>(const hwd: HWND; const msg: Cardinal; const prc: TMessageExecuterPrc<T>;
   const prcAfter: TMessageExecuterPrc<T>);
var
   rec: T;
begin
   if Assigned(prc) then
      prc(rec);
   SendMessage(hwd, msg, NativeUInt(SEND), NativeUInt(@rec));
   if Assigned(prcAfter) then
      prcAfter(rec);
end;

class procedure TMessageExecuter.ExecutarPost(const hwd: HWND; const msg: Cardinal);
begin
   PostMessage(hwd, msg, NativeUInt(POST), 0);
end;

class procedure TMessageExecuter.ExecutarPost<T>(const hwd: HWND; const msg: Cardinal; const prc: TMessageExecuterPrc<T>);
type
   PT = ^T;
var
   prec: PT;
begin
   New(prec);
   if Assigned(prc) then
      prc(prec^);
   PostMessage(hwd, msg, NativeUInt(POST), NativeUInt(prec));
end;

class procedure TMessageExecuter.Dispatch(const obj: TObject; var Message: TMessage);
type
   THandlerProc = procedure(var Message) of object;
var
   MsgID: Word;
   Addr: Pointer;
   ptrLParam: Pointer;
   M: THandlerProc;
begin
   MsgID := Message.msg;
   if (MsgID <> 0) and (MsgID < $C000) then
   begin
      Addr := GetDynaMethod(PPointer(obj)^, MsgID);
      if Assigned(Addr) then
      begin
         ptrLParam := nil;
         try
            ptrLParam := Pointer(Message.LParam);
            TMethod(M).Data := obj;
            TMethod(M).Code := Addr;
            M(ptrLParam^);
         finally

            if Assigned(ptrLParam) then
               Dispose(ptrLParam);
         end;
      end
      else
      begin
         obj.Dispatch(Message);
      end;
   end;
end;

class procedure TMessageExecuter.Executar(const hwd: HWND; const msg: Cardinal);
begin
   SendMessage(hwd, msg, NativeUInt(SEND), 0);
end;

class procedure TMessageExecuter.Processar<T>(var msg: TMessage; const fnc: TMessageExecuterFnc<T>);
type
   PT = ^T;
begin
   try
      msg.Result := fnc(PT(msg.LParam)^);
   finally
      if msg.WParam = NativeUInt(POST) then
         Dispose(PT(msg.LParam));
   end;
end;

class function TMessageExecuter.Registrar(const AMethod: TWndMethod): HWND;
begin
   Result := AllocateHWnd(AMethod);
end;

end.
