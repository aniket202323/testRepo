Create Procedure dbo.spGBS_GetMasterUnit
@SheetName nvarchar(50),
@Master_Id int OUTPUT     
AS
Select @Master_Id = null
Select @Master_Id = master_unit 
  from Sheets 
  Where Sheet_Desc = @SheetName
return(100)
