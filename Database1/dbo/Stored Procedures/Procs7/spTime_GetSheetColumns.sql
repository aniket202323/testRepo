
CREATE PROCEDURE dbo.spTime_GetSheetColumns
		 @TimeSelection		Int 
		,@StartTime			DateTime = Null
		,@EndTime			DateTime = Null
		,@Timestamp			DateTime = Null
		,@SheetIds			nVarChar(max) = Null
		,@UserId			Int

 AS


IF NOT EXISTS(SELECT 1 FROM Users WHERE User_id = @UserId )
BEGIN
	SELECT  Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'UnKnownMESUser', PropertyName1 = 'UserId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = @UserId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''

	RETURN
END

DECLARE @AllSheets Table (Sheet_Id Int, PU_Id Int, PL_Id Int, Dept_Id int, DeptTZ NVarchar(500))
DECLARE @OneLineId Int

If @SheetIds is not NULL
BEGIN
	INSERT INTO @AllSheets(Sheet_Id) 
		SELECT Id FROM dbo.fnCMN_IdListToTable('Sheets', @SheetIds, ',')

	-- By Master Unit
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, s.Master_Unit
		FROM Sheets s
		where s.Sheet_Id in (Select Sheet_Id from @AllSheets where PU_Id is null)
		  and s.Master_Unit is not null

	-- By Sheet Units
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, su.PU_Id
		FROM Sheets s
		join Sheet_Unit su on su.Sheet_Id = s.Sheet_Id
		where s.Sheet_Id in (Select Sheet_Id from @AllSheets where PU_Id is null)

	-- By Sheet Display Options
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, do.value
		FROM Sheets s
		join Sheet_Display_options do on do.Sheet_id = s.Sheet_Id and do.Display_Option_Id = 446
		where s.Sheet_Id in (Select Sheet_Id from @AllSheets where PU_Id is null)

	-- By Variables
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, v.PU_Id
		FROM Sheets s
		join Sheet_Variables sv on sv.Sheet_Id = s.Sheet_Id and sv.Var_Id is not null
		join Variables_Base v on v.Var_Id = sv.Var_Id
		where s.Sheet_Id in (Select Sheet_Id from @AllSheets where PU_Id is null)

	delete from @AllSheets where PU_Id is null
END
ELSE
BEGIN
	SELECT  Error = 'ERROR: Valid SheetIds required', Code = 'InvalidData', ErrorType = 'MissingRequiredData', PropertyName1 = 'SheetIds', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = @SheetIds, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

IF NOT EXISTS(SELECT 1 FROM @AllSheets)
BEGIN
	SELECT  Error = 'ERROR:  SheetIds not Valid', Code = 'InvalidData', ErrorType = 'InvalidParameterValue', PropertyName1 = 'SheetIds', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = @SheetIds, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END
-- Eliminate Sheets User is not allowed to see
IF NOT Exists(SELECT 1 FROM User_Security WHERE User_Id = @UserId  AND Group_Id =1 and Access_Level = 4) -- Administrator with admin access, sees everything under the sun
	BEGIN
		;WITH 	AuthorizedSheets AS	(
					-- Display/Sheet level security
				 SELECT s.Sheet_Id FROM Sheets s  
					 JOIN  User_Security us ON us.Group_Id = s.Group_Id AND us.user_id = @UserId  AND s.Is_Active =1
				     WHERE s.Group_Id is Not null
				  	 UNION
				 -- Display Group/Sheet Group level security
				 SELECT s.Sheet_Id FROM Sheets s
				  	 JOIN Sheet_Groups sg ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1
				  	 JOIN  User_Security us ON us.Group_Id = sg.Group_Id AND us.user_id = @UserId
				  	 WHERE s.Group_Id is null AND sg.Group_Id is Not null
				  	 UNION
				 --Display or Display group that is not assigned any security
				 SELECT s.Sheet_Id
				  	 FROM Sheets s  
				  	 JOIN Sheet_Groups sg ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1
					 WHERE s.Group_Id is null AND SG.Group_Id is null
				)
		DELETE FROM  @AllSheets WHERE sheet_id
			NOT IN (
			   SELECT Sheet_Id FROM AuthorizedSheets
			)
	END

IF NOT EXISTS(SELECT 1 FROM @AllSheets)
BEGIN
	SELECT  Error = 'ERROR: Input sheetIds not configured for this user', Code = 'InsufficientPermission', ErrorType = 'NoAuthorizedSheetsConfigured', PropertyName1 = 'SheetIds', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = @SheetIds, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END	

UPDATE @AllSheets SET DeptTZ = d.Time_Zone, PL_Id = b.PL_Id, Dept_Id = d.Dept_Id
		FROM @AllSheets a
		JOIN Prod_Units_Base b on b.PU_Id = a.PU_Id 
		JOIN Prod_Lines_Base c on c.PL_Id = b.PL_Id 
		JOIN Departments_Base d on d.Dept_Id = c.Dept_Id 
IF (SELECT COUNT(Distinct DeptTZ) FROM @AllSheets) <= 1
BEGIN
	SELECT @OneLineId  = MIN(PL_Id) FROM @AllSheets
END

IF @Timestamp is Null
BEGIN
	IF @StartTime Is Null or @EndTime Is Null
	BEGIN
		EXECUTE dbo.spBF_CalculateOEEReportTime @OneLineId, @TimeSelection, @StartTime Output, @EndTime Output, 1
	END
	IF @StartTime Is Null OR @EndTime Is Null
	BEGIN 
		SELECT Error ='ERROR: Could not Calculate Date from the time selection or not valid startTime and endTime passed', Code = 'InvalidData', ErrorType = 'InvalidParameterValue', PropertyName1 = 'TimeSelection', PropertyName2 = 'StartTime', PropertyName3 = 'EndTime', PropertyName4 = '', 
			PropertyValue1 = @TimeSelection, PropertyValue2 = @StartTime, PropertyValue3 = @EndTime, PropertyValue4 = ''
		RETURN
	END
END

Declare @SheetCols Table (Approver_Reason_Id int, Approver_User_Id int, Comment_Id int, Result_On datetime, Sheet_Id int, Signature_Id int, User_Reason_Id int, User_Signoff_Id int)
if (@Timestamp is Null)
BEGIN
  Insert Into @SheetCols (Approver_Reason_Id, Approver_User_Id, Comment_Id, Result_On, Sheet_Id, Signature_Id, User_Reason_Id, User_Signoff_Id)
  Select  sc.Approver_Reason_Id, sc.Approver_User_Id, sc.Comment_Id, sc.Result_On, sc.Sheet_Id, sc.Signature_Id, sc.User_Reason_Id, sc.User_Signoff_Id
    from Sheet_Columns sc
    join sheets s on s.Sheet_Id = sc.Sheet_Id
    where sc.Result_On > @StartTime and sc.Result_On <= @EndTime and sc.Sheet_Id in (Select Distinct Sheet_Id from @AllSheets)
END
ELSE
BEGIN
  Insert Into @SheetCols (Approver_Reason_Id, Approver_User_Id, Comment_Id, Result_On, Sheet_Id, Signature_Id, User_Reason_Id, User_Signoff_Id)
  Select  sc.Approver_Reason_Id, sc.Approver_User_Id, sc.Comment_Id, sc.Result_On, sc.Sheet_Id, sc.Signature_Id, sc.User_Reason_Id, sc.User_Signoff_Id
    from Sheet_Columns sc
    join sheets s on s.Sheet_Id = sc.Sheet_Id
    where sc.Result_On = @Timestamp and sc.Sheet_Id in (Select Distinct Sheet_Id from @AllSheets)
END

SELECT DISTINCT
               sc.Sheet_Id,
               Result_On = dbo.fnserver_CmnConvertFromDbTime(sc.Result_On,'UTC'),
               sc.Approver_Reason_Id,
               Approver_Reason = aer.Event_Reason_Name,
               sc.Approver_User_Id,
               Approver_User = au.Username,
               sc.Comment_Id,
               sc.Signature_Id,
               sc.User_Reason_Id,
               User_Reason = uer.Event_Reason_Name,
               sc.User_Signoff_Id,
               User_Signoff_User = usu.Username
               FROM @SheetCols AS sc
                    JOIN sheets AS s ON s.Sheet_Id = sc.Sheet_Id
                    LEFT JOIN Users AS au ON au.User_Id = sc.Approver_User_Id
                    LEFT JOIN Users AS usu ON usu.User_Id = sc.User_Signoff_Id
                    LEFT JOIN Event_Reasons AS aer ON aer.Event_Reason_Id = sc.Approver_Reason_Id
                    LEFT JOIN Event_Reasons AS uer ON uer.Event_Reason_Id = sc.User_Reason_Id
               ORDER BY sc.Sheet_Id,
                        Result_On

