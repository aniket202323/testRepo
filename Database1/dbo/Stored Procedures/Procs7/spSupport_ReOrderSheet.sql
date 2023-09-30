CREATE PROCEDURE dbo.spSupport_ReOrderSheet
@SheetName Varchar(50)
AS
Declare @SheetId int
Declare @VarId int
Declare @VarOrder int
Declare @PrevVarId int
Select @SheetId = Null
Select @SheetId = Sheet_Id
  From Sheets Where Sheet_Desc = @SheetName
Declare S_Cursor INSENSITIVE CURSOR
  For Select Var_Id 
         From Sheet_Variables
   	  Where Sheet_Id = @SheetId
         order by Var_order ASC
  For Read Only
Open S_Cursor  
begin transaction
Select @VarOrder = 0
Select @PrevVarId = 0
Fetch_Loop:
  Fetch Next From S_Cursor Into @VarId
  If (@@Fetch_Status = 0)
    Begin
      if @VarId <> @PrevVarId 
        begin
          Select @VarOrder = @VarOrder + 1
          Update Sheet_Variables 
             Set Var_Order = @VarOrder
             Where Sheet_Id = @SheetId and
                   Var_Id = @VarId
        end
      else
        begin
          Delete From Sheet_Variables 
             Where Sheet_Id = @SheetId and
                   Var_Id = @VarId
        end
      Select @PrevVarId = @VarId
      Goto Fetch_Loop
    End
Close S_Cursor
Deallocate S_Cursor
commit transaction
