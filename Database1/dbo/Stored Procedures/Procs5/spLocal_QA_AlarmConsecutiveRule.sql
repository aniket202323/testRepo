
CREATE   PROCEDURE dbo.spLocal_QA_AlarmConsecutiveRule
/*
Stored procedure: dbo.spLocal_QA_AlarmConsecutiveRule
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-09-27
Version		:	4.0.0
Purpose		: 	Added input to specify the number of consecutive columns to look at,
					renamed stored procedure to be more descriptive.
					Must populate temporary table because of query scripting
-------------------------------------------------------------------------------------------------
splocal_QA_TAMU_Rule3
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-09-07
Version		:	3.0.0
Purpose		: 	Added input to indicate the number of M value to look for
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2005-12-22
Version		:	2.3.3
Purpose		: 	Added end_time is null to production_starts queries
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date		:	2005-12-12
Version		:	2.3.2
Purpose		: 	Query on production_starts was returning more than one value
				added restriction on pi_id
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date		:	2005-11-23
Version		:	2.3.1
Purpose		: 	Query on production_starts was returning more than one value
				added a SELECT TOP 1 with ORDER BY DESC to fix it
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date		:	2005-11-17
Version		:	2.3.0
Purpose		: 	Compliant with Proficy 3 and 4.
				Added [dbo] template when referencing objects.
				Added registration of SP Version into AppVersions table.
				PSMT Version 4.0.0
--------------------------------------------------------------------------------------------------------------------------------------------------------
Altered by :	David Lemire, Solutions et Technologies Industrielles inc.
On 21-Apr-05	Version 2.2.0
Purpose : 		(1) Corrected a bug WHERE OutputValue wouldn't be incremented in the cursor loop.
					(2) Consider the product when counting for Rule3. In fact, if the product has been changed, the count
						 would reset to 0.
--------------------------------------------------------------------------------------------------------------------------------------------------------
Altered by :	Ugo Lapierre, Solutions et Technologies Industrielles inc.
On 8-Mar-05	Version 2.1.0
Purpose : 		Rule 2 of of 3 was changed to 3 consecutive value with at least 1 M
------------------------------------------------------------------------------------------------------------------------------------------------------------------
Altered by :	Normand Carbonneau, Solutions et Technologies Industrielles inc.
On 18-Jan-05	Version 2.0.1
Purpose : 		1. Modified the way that the sheet_id was retrieved. Previous way was looking in Calculation_Instance_Dependencies and
					   it was not working because there was no dependency for the current calculation in that table. The dependency is in
						Calculation_Dependency_Data and the Var_Id we can get there doesn't allow to retrieve the sheet_id because that
						dependant variable is not on a sheet.
					2. When filling @TS temporary table, added a condition to check for Sheet_Id.
------------------------------------------------------------------------------------------------------------------------------------------------------------------
Altered by Ugo Lapierre, Solutions et Technologies Industrielles inc.
On 18-Nov-04							Version 2.0.0
Purpose : 		Trigger on ZPV_Check_data_Entry and verify value.
------------------------------------------------------------------------------------------------------------------------------------------------------------------
Created by 	Marc Charest, Solutions et Technologies Industrielles inc.
On 		04-Nov-04							
Version 	1.0.0
Purpose : 	Verify for TAMU alarm rule 3
------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
@OutputValue 		varchar(30) OUTPUT,
@dtmTimestamp 		datetime,
@intVarId			integer,
@strEiTamuM			varchar(30),
@intNbMinM			int,
@intNbColumns		int

AS
DECLARE
@intPuId			int,
@intSheetId			int,
@intAttributeVarID	int, 
@intCount			int,
@intDependancyId	int,
@strDependancyVal	varchar(30),
@MaxResultOn		datetime,
@MinResultOn		datetime,
@StartProduct		int,
@EndProduct			int,
@RowNum				int,
@RowCount			int,
@strSQL				nvarchar(500)

CREATE TABLE #TS (result_on datetime)

DECLARE @VarIDs TABLE (var_id integer)

DECLARE @Results TABLE (
	RowNum 	int IDENTITY(1,1),
	Varid 	int,
	Qty		int)

SET NOCOUNT ON

IF @strEiTamuM is null 
BEGIN
	SET @OutputValue = ''
	SET NOCOUNT OFF
	RETURN
END


-- get the dependancy variable id and the value
SET @intDependancyId = (SELECT var_id FROM dbo.calculation_dependency_data WHERE result_var_id = @intVarId)
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_SetInitialValNO','@intDependancyId',@intDependancyId)

SET @strDependancyVal = (SELECT result FROM dbo.tests WHERE var_id = @intDependancyId and result_on = @dtmTimestamp)
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_SetInitialValNO','@strDependancyVal',@strDependancyVal)

IF @strDependancyVal <> 'OK, data complete'
BEGIN
	SET NOCOUNT OFF
	RETURN
END


-- Find the pu_id of the units WHERE TAMU is on
SET @intPuId = (SELECT pu_id FROM dbo.variables WHERE var_id = @intVarId)

-- Find sheet_id
SET @intSheetID = (SELECT S.Sheet_Id 
				   FROM dbo.Sheet_Variables SV
				     JOIN dbo.Sheets S ON SV.Sheet_Id = S.Sheet_Id
				   WHERE (SV.var_id = @intVarId) and (S.sheet_type = 1)) --sheet_type = 1 (Autolog Time-Based)
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_SetInitialValNO','@intSheetID',@intSheetID)

--want to keep TAMU's var IDs only when actual result is greater than 0
INSERT INTO @VarIDs(var_id)
  SELECT v.var_id 
  FROM dbo.variables v
	join dbo.tests t on (v.var_id = t.var_id)
  WHERE v.pu_id = @intPuId and v.extended_info like '%' + @strEiTamuM + '%' and	t.result_on = @dtmTimestamp and	t.result > 0

--SET @intNbColumns = 3

--want to look only for 3 latest TAMU columns
SET @strSQL = 'INSERT INTO #TS(result_on) SELECT TOP ' + convert(nvarchar(10), @intNbColumns) + ' result_on '
SET @strSQL = @strSQL + 'FROM dbo.sheet_columns '
SET @strSQL = @strSQL + 'WHERE result_on <= ''' + convert(nvarchar(30), @dtmTimestamp,20) + ''' AND '
SET @strSQL = @strSQL + 'Sheet_Id = ' + convert(nvarchar(10), @intSheetId) + ' ORDER BY Result_On DESC'

EXEC sp_ExecuteSQL @strSQL

SET @OutputValue = 0
-- check to see if there was a product change
-- If a product change is found, the count is not considered and we exit SP
SET @MaxResultOn = (SELECT MAX(result_on) FROM #TS)
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_SetInitialValNO','@MaxResultOn',convert(varchar(30), @MaxResultOn, 20))

SET @MinResultOn = (SELECT MIN(result_on) FROM #TS)
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_SetInitialValNO','@MinResultOn',convert(varchar(30), @MinResultOn, 20))

SET @StartProduct = (SELECT prod_id FROM dbo.production_starts WHERE start_time <= @MinResultOn and (end_time > @MinResultOn or end_time is null) and pu_id = @intPuId)
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_SetInitialValNO','@StartProduct',@StartProduct)

SET @EndProduct = (SELECT prod_id FROM dbo.production_starts WHERE start_time <= @MaxResultOn and (end_time > @MaxResultOn or end_time is null) and pu_id = @intPuId)
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_SetInitialValNO','@EndProduct',@EndProduct)

IF @EndProduct is null
	SET @EndProduct = (SELECT TOP 1 prod_id FROM dbo.production_starts WHERE start_time <= @MaxResultOn and pu_id = @intPuId ORDER BY start_time DESC)
	--SET @EndProduct = (SELECT prod_id FROM dbo.production_starts WHERE start_time <= @MaxResultOn)

IF @StartProduct <> @EndProduct
BEGIN
	DROP TABLE #TS
	SET @outputvalue = 0
	SET NOCOUNT OFF
	RETURN
END

---------------------------------------------------
------ counting 2 out of 3 greater than zero ------
---------------------------------------------------
INSERT INTO @Results (Varid, Qty)
  SELECT v.var_id, SUM(1) as flag 
  FROM dbo.tests t
	join #TS ts on (t.result_on = ts.result_on)
	join @VarIDs v on (t.var_id = v.var_id)
  WHERE result >= @intNbMinM
  GROUP BY v.var_id

SET @RowNum = 1
SET @RowCount = (SELECT COUNT(*) FROM @Results)

WHILE @RowNum <= @RowCount
BEGIN
	SET @intCount = (SELECT Qty FROM @Results WHERE RowNum = @RowNum)

	--if 2 out of @intNbColumns, flag 
	IF @intCount >= @intNbColumns
	BEGIN
		SET @OutputValue = cast(@OutputValue as int) + 1
	END	

	SET @RowNum = @RowNum + 1
END

DROP TABLE #TS

SET NOCOUNT OFF


