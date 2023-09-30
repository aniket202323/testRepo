Create Procedure dbo.spGE_PutSheetPosOption
  @SheetId 	  Int,
  @UnitId 	  Int,
  @SheetPosition Varchar(7000)
  AS
Declare @MU Int
Select @MU = Master_Unit From Sheets Where Sheet_Id = @SheetId
If @UnitId = @MU
  Begin
    Delete From Sheet_Display_Options Where  Sheet_Id = @SheetId and Display_Option_Id = 159
    Insert Into  Sheet_Display_Options (Sheet_Id,Display_Option_Id,Value)
 	  Values (@SheetId,159,@SheetPosition)
  End
Else
  Begin
    Delete From Sheet_Unit Where Sheet_Id = @SheetId and PU_Id = @UnitId
    Insert Into  Sheet_Unit (Sheet_Id,PU_Id,Value)
 	  Values (@SheetId,@UnitId,@SheetPosition)
  End
