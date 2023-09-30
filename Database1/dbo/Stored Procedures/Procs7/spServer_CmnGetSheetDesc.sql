CREATE PROCEDURE dbo.spServer_CmnGetSheetDesc
@Sheet_Id int,
@Sheet_Desc nvarchar(50) OUTPUT
 AS
Select @Sheet_Desc = Sheet_Desc 
 	 From Sheets 
 	 Where (Sheet_Id = @Sheet_Id)
if @Sheet_Desc Is Null
  Select @Sheet_Desc = ''
