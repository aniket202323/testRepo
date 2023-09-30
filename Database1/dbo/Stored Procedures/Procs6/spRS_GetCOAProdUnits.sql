CREATE PROCEDURE dbo.spRS_GetCOAProdUnits
@ProdLine int = null,
@Include int = null,
@IncludeStr varchar(1000) = null
AS
Declare @SQLString varchar(7000)
Select @SQLString = 'Select PU_Id, PU_Desc from Prod_Units Where PL_Id <> 0'
If @ProdLine is not null 
  Select @SQLString = @SQLString + ' and PL_Id = ' + Convert(varchar(10), @ProdLine)
If @IncludeStr Is Not Null
  If @Include = 1
    Select @SQLString = @SQLString + ' and pu_id in(' + replace(@IncludeStr, '|',',') + ')'
  Else
    Select @SQLString = @SQLString + ' and pu_id not in(' + replace(@IncludeStr, '|',',') + ')'
--Select @SQLString
Exec (@SQLString)
