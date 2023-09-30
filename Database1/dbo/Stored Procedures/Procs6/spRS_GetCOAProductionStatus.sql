CREATE PROCEDURE dbo.spRS_GetCOAProductionStatus 
@Include int = null,
@IncludeStr varchar(1000) = null
AS
Declare @SQLString varchar(7000)
Select @SQLString = 'Select ProdStatus_Id, ProdStatus_Desc from production_status'
If @IncludeStr Is Not Null
  If @Include = 1
    Select @SQLString = @SQLString + ' Where ProdStatus_Id in(' + replace(@IncludeStr, '|',',') + ')'
  Else
    Select @SQLString = @SQLString + ' Where ProdStatus_Id not in(' + replace(@IncludeStr, '|',',') + ')'
Select @SQLString = @SQLString + ' order by ProdStatus_Desc asc'
--Select @SQLString
Exec (@SQLString)
