CREATE PROCEDURE [dbo].[spActivities_GetVariableCounts]
    @ActivityIds    NVARCHAR(max) =NULL,
    @EventNums		NVARCHAR(max) =NULL
    /*all parametes are comma separated strings

    Sample Procedure calls:
Exec spActivities_GetVariableCount '497,498,499,500',NULL
go
Exec spActivities_GetVariableCounts NULL,'DISC:519:519,DISC:520:520' 
    */
As

CREATE TABLE #ActivitiesTableTemp(Activity_Id BIGINT, Activity_Desc NVARCHAR(max),KeyId1 BIGINT, Sheet_Id BIGINT);
CREATE TABLE #UDETableTemp (ROWID BIGINT, UDE_Id BIGINT)
BEGIN

INSERT INTO #UDETableTemp  SELECT ROW_NUMBER() OVER(ORDER BY UDE_ID ASC) AS ROWID, UDE_Id UDE_ID FROM User_defined_Events ude where UDE.UDE_DESC IN (SELECT * FROM dbo.fnCMN_SplitString(@EventNums, ',')) 
END


DECLARE @Counter INT, @numrows INT, @Activity_Id BIGINT, @Activity_Desc NVARCHAR(max) , @KeyId1 BIGINT, @Sheet_Id BIGINT;
SET @numrows = (SELECT COUNT(*) FROM #UDETableTemp)
SET @Counter=1

WHILE ( @Counter <= @numrows)
BEGIN

	INSERT INTO #ActivitiesTableTemp SELECT TOP 1  A.Activity_Id,A.Activity_Desc, A.KeyId1,A.Sheet_Id FROM Activities A 
	WHERE A.KeyId1 = (SELECT UDE_Id FROM #UDETableTemp  WHERE ROWID=@Counter)
	ORDER BY Activity_Id DESC

SET @Counter  = @Counter  + 1
END

Begin

    Declare @sql NVARCHAR(max)
    Select @sql =
           'Select
               A.Activity_Id,A.Activity_Desc,A.KeyId1 Event_Id,
               SUM(Case when Sv.Var_Id IS NOT NULL THEN 1 ELSE 0 END) TotalVariablesCount,
               SUM(Case when ISNULL(T.IsVarMandatory,0) = 1 THEN 1 ELSE 0 END) TotalMandatoryVariablesCount,
               SUM(Case when ISNULL(T.IsVarMandatory,0) = 1 AND T.Result IS NULL AND (CASE WHEN v.Data_Type_Id > 50 THEN 1 eLSE V.Data_Type_Id End) in (1,2,3,4,6,7) THEN 1 When v.Data_Type_Id = 5 AND t.Comment_Id is null and ISNULL(T.IsVarMandatory,0) = 1 Then 1 ELSE 0 END) RemainingMandatoryVariablesCount
           from
               '+ Case when @EventNums is not null then ' #ActivitiesTableTemp A' else ' Activities A' end +' 
                JOIN Sheet_Variables Sv on Sv.Sheet_Id = A.Sheet_Id
                JOIN Variables_Base v on v.Var_Id = Sv.Var_Id ' +
           Case when @EventNums is not null then ' Join User_defined_Events UDE on UDE.UDE_Id = A.KeyId1 AND UDE.UDE_DESC IN ('''+REPLACE(@EventNums,',',''',''')+''')' else '' end
               +'
		Left Join Tests T on T.Var_Id = Sv.Var_Id AND A.KeyId1 = T.Event_Id'

    SELECT @sql=@sql+' Where 1=1 '

    IF @ActivityIds IS NOT NULL
        SELECT @sql=@sql+' AND A.Activity_Id in ('+@ActivityIds+')'

    SELECT @sql=@sql+' Group By Activity_Id,A.KeyId1,A.Activity_Desc '
	
    EXEC (@sql)

End

DROP TABLE IF EXISTS #ActivitiesTableTemp;
DROP TABLE IF EXISTS #UDETableTemp;

