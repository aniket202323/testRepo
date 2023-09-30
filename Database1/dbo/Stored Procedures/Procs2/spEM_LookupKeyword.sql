CREATE PROCEDURE dbo.spEM_LookupKeyword
  @Keyword_Id    int,
  @Keyword_Value nvarchar(25) OUTPUT
  AS
  --
  SELECT @Keyword_Value = spKW_Key FROM spCalc_KeyWord WHERE spKW_Id = @KeyWord_Id
