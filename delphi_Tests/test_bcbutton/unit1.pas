unit Unit1;

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ActnList,
  Menus, StdCtrls, ExtCtrls, BCButton, BCPanel, Vcl.ImgList, BCBaseCtrls,
  BGRAShape;

type

  { TForm1 }

  TForm1 = class(TForm)
    Action1: TAction;
    Action2: TAction;
    Action3: TAction;
    ActionList1: TActionList;
    BCButton1: TBCButton;
    BCButton10: TBCButton;
    BCButton11: TBCButton;
    BCButton12: TBCButton;
    BCButton13: TBCButton;
    BCButton14: TBCButton;
    BCButton15: TBCButton;
    BCButton16: TBCButton;
    BCButton17: TBCButton;
    BCButton18: TBCButton;
    BCButton2: TBCButton;
    BCButton3: TBCButton;
    BCButton4: TBCButton;
    BCButton5: TBCButton;
    BCButton6: TBCButton;
    BCButton7: TBCButton;
    BCButton8: TBCButton;
    BCButton9: TBCButton;
    BCPanel1: TBCPanel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    CheckBox1: TCheckBox;
    ImageList1: TImageList;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    PopupMenu1: TPopupMenu;
    PopupMenu2: TPopupMenu;
    PopupMenu3: TPopupMenu;
    Shape1: TShape;
    BCPanel11: TPanel;
    Shape11: TShape;
    BCButton21: TBCButton;
    BCButton22: TBCButton;
    BCButton23: TBCButton;
    BCButton24: TBCButton;
    BCButton25: TBCButton;
    BCButton26: TBCButton;
    BCButton27: TBCButton;
    BCButton28: TBCButton;
    BCButton19: TBCButton;
    BCButton20: TBCButton;
    BCPanel2: TBCPanel;
    BGRAShape1: TBGRAShape;
    procedure CheckBox1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ TForm1 }

procedure TForm1.CheckBox1Change(Sender: TObject);
begin
  BCButton1.ShowCaption := CheckBox1.Checked;
  BCButton7.ShowCaption := CheckBox1.Checked;
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  BCButton1.ShowCaption := CheckBox1.Checked;
  BCButton7.ShowCaption := CheckBox1.Checked;
end;

end.

