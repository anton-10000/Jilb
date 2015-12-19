unit unMain_form;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    mmCode: TMemo;
    btnImprtCode: TBitBtn;
    btnRun: TBitBtn;
    Label2: TLabel;
    lblAbsltCL: TLabel;
    Label4: TLabel;
    lblRltvCL: TLabel;
    lblMaxElseIf: TLabel;
    Label7: TLabel;
    lblMaxElse: TLabel;
    Label9: TLabel;
    procedure btnImprtCodeClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
   TarrInteger= array of Integer;

var
  Form1: TForm1;

implementation

uses StrUtils, Math;

{$R *.dfm}
 const

    N=67;//Кол-во операндов языка С++
    cnstOperator='@';//Символ на который заменяются операторы (для удобства подсчёта)

//Операнды языка С++
    arrServiceWords: array[1..N] of string = ('while','for','try','catch',
     'switch','case','default','break','continue','return','struct','class',//12
     'int','char','double','void','bool','goto','new','delete','const',//21
     'enum','sizeof','using namespace','cin','cout','unsigned','throw','endl',//29
     '::','++','--','>>','<<','<=','>=','==','!=','&&','||','?:','*=','/=',//42
     '%=','+=','–=','<<=','>>=','&=','|=','^=','.*','->*',
     '=','+','-','*','/','%','>','<','~','&','|','^','?',';');

 var
  txtFile:TextFile;//Переменная для работы с текстовым файлом

//Вычисляет глубину по ветке
//Входной параметр code содержит анализируемый код
//arr массив позиций else или else if
function CalcInvestment(code:AnsiString;var arr:TarrInteger):Integer;
 var
    sizeCode,N,i,j,saveN,maxN:Integer;
    arrBracket: array of array[0..1] of integer; //Массив скобок '{' '}'
    arrBracketIndex: array of Integer;
begin
   sizeCode:=Length(code);
   maxN:=0;
   saveN:=0;

   N:=1;
//После выполнения цикла, массив arrBracket будет содержать
// позицию открытия скобки (arrBracket[i,0]) и позицию закрытия скобки(arrBracket[i,1]).
   for i:=1 to sizeCode do begin //Ищу скобки
    if code[i]='{'
     then begin
       SetLength(arrBracket,N);
       arrBracket[N-1,0]:=i;//Заношу позицию скобки в тексте
       Inc(N);
     end;

    if code[i]='}'
     then begin
       for j:=High(arrBracket) downto 0 do begin
       if (arrBracket[j,1]=0)
        then begin
          arrBracket[j,1]:=i;//Заношу позицию скобки в тексте
          Break;
        end;
      end;
     end;
   end;

//Т.к. мы нашли все скобки программы, то нам надо определиться,
// какие скобки относятся к данному else или else if
   SetLength(arrBracketIndex,High(arr)+1);

   for i:=0 to High(arr) do begin
    for j:=0 to High(arrBracket) do begin
      if (arrBracket[j,0]>arr[i])
       then begin
        arrBracketIndex[i]:=arrBracket[j,1];
        Break;
        end;
    end;
   end;

//Берём первый else или else if
  for i:=0 to High(arr) do begin
   N:=0;
//Начинаем крутить цикл от начальной скобки пренадлежащей данному оператору
//и до конечной, попутно осуществляя подсчёт скобок
   for j:=arr[i] to arrBracketIndex[i]  do begin
    if (code[j]='{')
     then Inc(N);

    if (code[j]='}')
     then begin
        if (N>saveN)
         then saveN:=N;
       Dec(N);
      end;
   end;
   if maxN<saveN
    then maxN:=saveN;
  end;
  Result:=maxN;//Вывод максимального
end;

//Функция осуществляет подсчёт кол-ва операторов условия
// В С++ это if и switch
function CalcRmfctn(code:AnsiString):Integer;
 var
    N,position:Integer;
    strSearch,strReverse:String;
begin
  N:=0;
  strSearch:='if';
  strReverse:=ReverseString(strSearch);
  position:=Pos(strSearch,code);
  while (position<>0) do begin
    code:=StringReplace(code,strSearch,strReverse,[]);
    Inc(N);
    position:=Pos(strSearch,code);
  end;

  strSearch:='switch';
  strReverse:=ReverseString(strSearch);
  position:=Pos(strSearch,code);
  while (position<>0) do begin
    code:=StringReplace(code,strSearch,strReverse,[]);
    Inc(N);
    position:=Pos(strSearch,code);
  end;
   Result:=N;
end;

//Процедура формирует массив позиций else или else if
procedure CalcEntry(var code:AnsiString; var arr:TarrInteger; strSearch:String);
  var
     N,i,position:Integer;
     strReverse:String;
begin
  N:=1;
  i:=0;
  strReverse:=ReverseString(strSearch);
  position:=Pos(strSearch,code);//Нахожу позицию
  while (position<>0) do begin
//Заменяю первое вхождение на реверс строки
// для того чтобы в след. итерации взять второе вхождение если оно есть.
   code:=StringReplace(code,strSearch,strReverse,[]);
    SetLength(arr,N);
     arr[i]:=position;
    Inc(N);
    Inc(i);
    position:=Pos(strSearch,code);
  end;
end;

//Процедура осуществляет подсчёт операндов  (Абсолютная и относительная сложность)
procedure CalcOperand(var code:AnsiString; var AbsltCL:Integer; var RltvCL:Real);
 var
    sizeCode,i,NOperand:Integer;
begin
  sizeCode:=Length(code);
  NOperand:=0;
  for i:=1 to sizeCode do begin
//Все операнды заменялись на этот симвл для простоты подсчёта (см.Parse)
    if (code[i]='@')  //Кол-во операндов
     then Inc(NOperand);
  end;
   AbsltCL:=CalcRmfctn(code);
   RltvCL:=AbsltCL/NOperand;
end;

//Парсер кода
//Затирает строки и коментарии C++
//Заменяет операнды языка С++ на символ @
procedure Parse(var code:AnsiString);
 var
  sizeCode,i:Integer;
  IsComment,IsStr,IsCommentMltln:Boolean;
begin
  sizeCode:=Length(code);
  IsStr:=False;
  IsComment:=False;
  IsCommentMltln:=False;
  for i:=1 to sizeCode do begin
//Нахожу ковычку и эта ковычка не в коментарии, значит затираю её
    if (code[i]='"') and (IsComment=False) and (IsCommentMltln=false)
     then begin
      if (IsStr=True)
       then begin
        code[i]:=' ';
        IsStr:=False
        end
       else IsStr:=True;
      end;

     if (IsStr=True) //Режим строки True, значит затираю символ
      then code[i]:=' ';

     if ((code[i]='/') and (code[i+1]='/') and (IsStr=False) and (IsCommentMltln=false))//Начало коментария
        or ((code[i]=''#$D'') and  (code[i+1]=''#$A'') and (IsComment=True))//Конец коментария
     then begin
      if (IsComment=True)
       then IsComment:=False
       else IsComment:=True;
      end;

     if (IsComment=True)
      then code[i]:=' ';

      if ((code[i]='/') and (code[i+1]='*') and (IsStr=False) and (IsComment=false))
        or ((code[i]='*') and  (code[i+1]='/') and (IsCommentMltln=True))
      then begin
       if (IsCommentMltln=True)
       then begin
        IsCommentMltln:=False;
        code[i]:=' ';
        code[i+1]:=' ';
        end
       else IsCommentMltln:=True;
      end;

      if (IsCommentMltln=True)
       then code[i]:=' ';
   end;

 //Замена операндов на @ 
  for i:=1 to N do begin
   code:=StringReplace(code,arrServiceWords[i],cnstOperator,[rfReplaceAll]);
  end;
end;


procedure TForm1.btnImprtCodeClick(Sender: TObject);
 var
    lineRead:String;
begin
 mmCode.Clear; //Чищу поле перед чтением из файла
  AssignFile(txtFile,'fileCode.txt');//Связываю переменную с файлом
   Reset(txtFile);  //Открываю на чтение
   while not EOF(txtFile) do begin //Читаю пока не достигнут конец файла
    Readln(txtFile,lineRead); //Читаю строку
    mmCode.Lines.Add(lineRead);//Добавляю её в Memo
   end;
  CloseFile(txtFile);//Закрываю файл
end;

procedure TForm1.btnRunClick(Sender: TObject);
 var
  code:AnsiString;
  AbsltCL,NElse,NElseIf:Integer;
  RltvCL:Real;
  arrElse,arrElseIf:TarrInteger;
begin
  code:=mmCode.Text;//Записываю анализируемый код в переменную
  Parse(code);//Удаляю коментарии, строки, заменяю операнды на @
  CalcOperand(code,AbsltCL,RltvCL); //Расчитываю Абсолютную и Относительную сложность
  CalcEntry(code,arrElseIf,'else if');//Ищу позиции else if
  CalcEntry(code,arrElse,'else');//Ищу позиции else

  NElse:=CalcInvestment(code,arrElse);//Ищу максимальную вложенность else
  NElseIf:=CalcInvestment(code,arrElseIf);//Ищу максимальную вложенность else if

//Заношу расчёты в label  
  lblAbsltCL.Caption:=IntToStr(AbsltCL);
  lblRltvCL.Caption:=FloatToStrF(RltvCL,ffFixed,10,5);
  lblMaxElse.Caption:=IntToStr(NElse);
  lblMaxElseIf.Caption:=IntToStr(NElseIf);
end;



end.
