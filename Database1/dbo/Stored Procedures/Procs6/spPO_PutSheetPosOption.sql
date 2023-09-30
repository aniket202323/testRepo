Create Procedure dbo.spPO_PutSheetPosOption
  @LineMode 	  Int,
  @Id 	  Int,
  @SheetPosition Varchar(7000)
  AS
If @LineMode = 0 
  Begin
   Update Prod_Lines set OverView_Positions = @SheetPosition Where PL_Id = @Id
  End
Else
  Begin
    Delete From Sheet_Display_Options Where  Sheet_Id = @Id and Display_Option_Id = 159
    Insert Into  Sheet_Display_Options (Sheet_Id,Display_Option_Id,Value)
 	  Values (@Id,159,@SheetPosition)
  End
