CREATE PROCEDURE dbo.spRS_GetCOADataSources
@Include int = null,
@IncludeStr varchar(1000) = null
 AS
Declare @SQLString varchar(7000)
Select @SQLString = 'Select Var_Id, Var_Desc, Eng_Units, Var_Precision, Test_name From Variables where var_id <> 0'
If @IncludeStr Is Not Null
  If @Include = 1
    Select @SQLString = @SQLString + ' and Var_id in(' + @IncludeStr + ')'
  Else
    Select @SQLString = @SQLString + ' and Var_id not in(' + @IncludeStr + ')'
Exec (@SQLString)
