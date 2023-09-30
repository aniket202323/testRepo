Create Procedure dbo.spFF_LookupGroupIdBySheetName 
@SheetName nvarchar(50),
@Group_Id int OUTPUT
AS
Select @Group_Id = 0
Select @Group_Id = Group_Id From Sheets Where Sheet_desc = @SheetName
Return(100)
