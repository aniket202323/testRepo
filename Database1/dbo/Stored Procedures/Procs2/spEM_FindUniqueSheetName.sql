CREATE   PROCEDURE dbo.spEM_FindUniqueSheetName
@SheetDesc 	 nvarchar(50) Output
AS
Declare  	 @SheetId Int,
 	  	  	 @NewSheetDesc 	 nvarchar(50),
 	  	  	 @Counter 	 Int
Select @Counter = 1
Select @NewSheetDesc = @SheetDesc
Select @SheetId = Sheet_Id from sheets where sheet_Desc = @SheetDesc
While @SheetId is Not null
  Begin
 	 Select @SheetId = Null
 	 Select @NewSheetDesc = @SheetDesc + Convert(nVarChar(10),@Counter)
 	 Select @SheetId = Sheet_Id from sheets where sheet_Desc = @NewSheetDesc
 	 Select @Counter = @Counter + 1
  End
Select @SheetDesc = @NewSheetDesc
