Create Procedure dbo.spAL_GetLastSheetColumn
@Sheet_Id int,
@LastTime datetime OUTPUT
AS
Select @LastTime = NULL
Select @LastTime = max(Result_On)
  From Sheet_Columns
  Where Result_On < dbo.fnServer_CmnGetDate(getutcdate()) and Sheet_Id = @Sheet_Id
If @LastTime Is Null Select @LastTime = dbo.fnServer_CmnGetDate(getutcdate())
return(100)
