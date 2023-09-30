

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_CL_SetVariableReadyTest]
/*
--------------------------------------------------------------------------------------------------------
Stored procedure	 :	spLocal_PG_Cmn_CL_SetVariableReadyTest
Author				 :	Alexandre Turgeon, STI
Date created		 :	13-Apr-2006
SP Type				 :	Creates user-defined events
Called by			 :	Called by other SPs by model 602, product change or manual event
Version				 :	1.8
Editor tab spacing :	3
Description			 :	
--------------------------------------------------------------------------------------------------------
Revision 	Date				Who						What
========		=====				====						=====
1.0.0			13-Apr-2006		Alexandre Turgeon		SP Creation
1.1.0			01-Aug-2006		Alexandre Turgeon		Stop cancelling old value by updating the timestamp of the old columns
1.1.1			07-Sep-2006		Ugo Lapierre			Resolve SP bugs.  Make it Clean
1.2.0			05-Jan-2009		Normand Carbonneau	Added WITH (NOLOCK) and reformatting
1.3.0			08-Apr-2009		Normand Carbonneau	Replaced UDP names with official names in configuration.
1.3.1			23-Jul-2010		Humberto Abrah�o		Changed the condition to add an extra day to NextTime (<= instead of <)
1.3		09-Jul-2011		Humberto Abrahao		Fixed value cancel for daily variables by changing to also cancel 
																values that are greater or equal to Test Time.
														
1.4     22-Jul-2016    Megha Lohana (TCS)       Removed the Register SP and update AppVersions section
1.5     18-May-2017    Megha Lohana (TCS)       FO-03011: Update spLocal_PG_Cmn_CL_SetVariableReadyTest for Product change functionality
--------------------------------------------------------------------------------------------------------
1.6		20-Mar-2018	   Fernando Rio				Fixed behaviour on Manual columns, not properly canceling the right cells
1.7		09-Apr-2018	   Fernando Rio				Fixing the Event_id not showing up on the TEst table.
												For that the cells should not be "moved" anymore, just cancelled.
1.8		06-Sep-2020		Santiago Gimenez		Get AuditFreq from Event_Subtypes.
												Identify Daily variables if those have an AuditFreq of S and a TestTime.
1.9		01-Nov-2020	   Carreno Maximiliano		Added functionality for "10.2 Test Frequency every X Days"
2.0		15-Apr-2021		Santiago Gimenez		Do not create tests before due date.
--------------------------------------------------------------------------------------------------------
3.1		24-Jun-2021		Cristian Jianu			Version Control for Centerline 3.1
3.1.1	12-Aug-2021		Cristian Jianu			Defect #15 16 fix
3.1.2	2021-11-19		Camila Olguin			Changes to test PC in pilot sites
3.1.3	2021-11-26		Camila Olguin			Add Logic for Daily variables
xxxxx	2022-05-17		Steven Stier			Copied from spLocal_PG_Cmn_CL_SetVariableReady- added test logic to set 
--------------------------------------------------------------------------------------------------------
*/

-- DECLARE
			@CallerId			varchar(30),
			@PUId				int,
			@EventSubtype		int,
			@Timestamp			datetime

--WITH ENCRYPTION 
AS
SET NOCOUNT ON


BEGIN TRY 

DECLARE
		@RSUserId			int,
		@LastUDETimestamp datetime, 
		@ErrorMessage	nvarchar(4000),


-- FO-03011 Added below two variables

@Now			DATETIME,
-- Aux vars for TF=0
@ProdId				INT,
@Section VARCHAR(20)


IF NOT OBJECT_ID('tempdb..#VarData') IS NULL
BEGIN
    DROP TABLE #VarData
END

--FO-03011 Temporary table for retriving variable data for the Prod unit
Create Table #VarData
	(
	VarId			int,
	PUId			int,
	AuditFreqvalue	varchar(30)
	)

IF NOT OBJECT_ID('tempdb..#TestsData') IS NULL
BEGIN
    DROP TABLE #TestsData
END

--FO-03011  Temporary table for retriving tests data for the variables
create Table #TestsData
	(
	Varid			int,
	Testid			bigint,
	Canceled		int,
	Result			varchar(10),
	LastResultTime	datetime,
	Dummy			int default 0
	)

DECLARE @VarsToAdd Table
(
PKey					int IDENTITY(1,1) PRIMARY KEY NOT NULL,
VarId					int,
PUId 					int,
UserId				int,
Canceled				int,
Result				varchar(10),
TransType			int DEFAULT 1,		-- TransactionType (1=Add 2=Update 3=Delete)
PostDB				int DEFAULT 0,		-- UpdateType (0=PreUpdate 1=PostUpdate)
InsertFlag			int,				-- Set to 1 if we need to be inserted by Result set 2
CancelLastColumn	int,				-- Set to 1 if we need to cancel it from the previous column
TestTimeString		varchar(30),
TestTimeDD			VARCHAR(10),
TestTimeHH			VARCHAR(10),
TestTimeMM			VARCHAR(10),
NextTestTime		datetime,
LastTestTime		datetime,
AuditFreq				varchar(30),
LastResultTime		datetime,
PreviousLastResultTime	datetime,
TestId				bigint,
TestFreq			int,
FromLocalTable		datetime,
LastTestFreq		int
)

SET @Section = 'SetVariableReady'


SET @Now = GETDATE()

-- Retrieve last event timestamp
SET @LastUDETimestamp =
	(
	SELECT	max(End_Time) 
	FROM		dbo.User_Defined_Events WITH (NOLOCK)
	WHERE		(PU_Id = @PUId)
				AND
				(Event_Subtype_Id = @EventSubType)
				AND
				(End_Time < @Timestamp)
				AND
				(End_Time IS NOT NULL)
	)


SET @RSUserId = (SELECT ISNULL([User_Id], 6) FROM dbo.Users WITH (NOLOCK) WHERE UserName = 'RTTSystem')

Insert into #VarData 
	select v.var_id , v.pu_id , tfv.value
	FROM dbo.Variables_base v	WITH (NOLOCK)
	JOIN dbo.Prod_Units_base pu	WITH (NOLOCK) ON pu.PU_Id = v.PU_Id
	JOIN dbo.Table_Fields_Values tfv	WITH (NOLOCK)	ON tfv.KeyId = v.Event_Subtype_Id
	JOIN dbo.Table_Fields tf				WITH (NOLOCK)	ON tf.Table_Field_Id = tfv.Table_Field_Id
	WHERE				(v.Event_Subtype_Id = @EventSubtype)
			AND
			(
			(v.PU_Id = @PUId)
			OR
			(pu.Master_Unit = @PUId)
			)
			AND
			(tf.Table_Field_Desc = 'RTT_AuditFreq' )


	-- Remove Cancel Manual variable from scope.
	DELETE FROM #VarData
	WHERE VarId IN (
						SELECT Member_Var_Id
						FROM dbo.Calculations c WITH (NOLOCK)
						JOIN dbo.Calculation_Inputs i WITH (NOLOCK) ON c.Calculation_Id = i.Calculation_Id
						JOIN dbo.Calculation_Input_Data id WITH (NOLOCK) ON i.Calc_Input_Id = id.Calc_Input_Id
						WHERE Stored_Procedure_Name = 'PG_Cmn_CL_CancelExtraCells'
					)

	
	INSERT INTO #TestsData( Varid , 
							LastResultTime	)

	SELECT		vd.VarId, 
				MAX(t.Result_On)
	FROM #VarData vd WITH (NOLOCK) 
	JOIN dbo.Tests t WITH (NOLOCK) ON t.Var_Id = vd.VarId
	AND t.Canceled = 0
	WHERE Result_On < @Timestamp
	GROUP BY vd.VarId


UPDATE td 
	SET Canceled		= t.Canceled, 
		Result			= t.Result,
		Testid			= t.Test_Id 
	FROM #TestsData td
	JOIN dbo.Tests t WITH (NOLOCK) ON t.var_id = td.varid and t.Result_On = td.LastResultTime

-- Retrieve all variables of the appropriate event subtype and their variable type
-- FO-03011  Getting data from the temp tables
INSERT INTO @VarsToAdd (
	VarId, PUId, UserId, Canceled, Result, InsertFlag,
	CancelLastColumn, LastResultTime, TestId, AuditFreq
)
	SELECT		vd.VarId,
					vd.PUId,
					@RSUserId,
					0,
					td.Result,
					0,
					0,
					td.LastResultTime,
					td.Testid, 
					vd.AuditFreqvalue
	FROM			#VarData vd (NOLOCK)
	LEFT JOIN #TestsData td (NOLOCK) ON td.Varid = vd.VarId

-- retreive the test time for each of these variables
UPDATE		@VarsToAdd
	SET			TestTimeString = tfv.Value
	FROM			@VarsToAdd v
	LEFT JOIN	dbo.Table_Fields_Values tfv	WITH (NOLOCK)	ON tfv.KeyId = v.VarId
	LEFT JOIN	dbo.Table_Fields tf			WITH (NOLOCK)	ON tf.Table_Field_Id = tfv.Table_Field_Id
	LEFT JOIN	dbo.Tables t				WITH (NOLOCK)	ON tf.TableId = t.TableId
	WHERE			(tf.Table_Field_Desc = 'RTT_TestTime')
	AND			(t.TableName = 'Variables')

UPDATE		@VarsToAdd
	SET			TestTimeDD = substring(TestTimeString,1, 2),
				TestTimeHH = substring(TestTimeString, 3, 2),
				TestTimeMM = substring(TestTimeString, 5, 2)
	FROM			@VarsToAdd v

-- Identify daily variables.
UPDATE		@VarsToAdd
	SET			AuditFreq = 'D'
	WHERE			TestTimeString IS NOT NULL
	  AND			AuditFreq = 'S'

-- Put dummy last test time for variables without any Result yet
UPDATE	@VarsToAdd
	SET		LastResultTime = '2000-01-01 07:00:00.000'
	WHERE		(LastResultTime IS NULL)

---------------------------------------------------------
--------- CALCULATE NextTestTime AND LastTestTime -------
---------------------------------------------------------

UPDATE v
	SET		FromLocalTable = Cycle_Start_Time
	FROM	@VarsToAdd v
	JOIN	dbo.Local_CL_LogLastResultON llr WITH (NOLOCK)
		ON	v.VarId	= llr.Var_Id
	WHERE	v.AuditFreq = 'D'
	
UPDATE v
	SET		FromLocalTable = ISNULL(MaxResultOn, '2000-01-01 07:00:00.000')
	FROM	@VarsToAdd v
	LEFT JOIN	(SELECT Var_Id, MAX(ti.Result_On) AS MaxResultOn 
					FROM	dbo.Tests ti WITH (NOLOCK) 
					WHERE	Var_Id IN (SELECT VarId 
										FROM @VarsToAdd 
										WHERE	FromLocalTable IS NULL)
					AND		ti.Canceled = 0
					AND		ti.Result IS NOT NULL 
						GROUP BY ti.Var_Id) t
			ON	v.VarId	= t.Var_Id
	WHERE	v.AuditFreq = 'D'
	AND		v.FromLocalTable IS NULL
	

UPDATE	@VarsToAdd
	SET		LastTestTime = CONVERT(datetime, 
											CONVERT(VARCHAR(30), CONVERT(DATE,FromLocalTable)) + ' ' +
											TestTimeHH + ':' +
											TestTimeMM + ':00.000')
FROM		@VarsToAdd
WHERE		AuditFreq = 'D'
AND			FromLocalTable IS NOT NULL

UPDATE	@VarsToAdd

SET		NextTestTime = CONVERT(datetime, 
										substring(CONVERT(varchar(30), @Timestamp, 20), 1, 11) + 
										TestTimeHH + ':' +
										TestTimeMM + ':01.000')

FROM		@VarsToAdd
WHERE		AuditFreq = 'D'
AND			FromLocalTable IS NOT NULL

UPDATE	@VarsToAdd
	SET		LastTestTime = CASE WHEN DATEADD(DD,
									ROUND(DATEDIFF(DAY, LastTestTime, @TimeStamp) / CONVERT(FLOAT,TestTimeDD), 0,1) * CONVERT(FLOAT,TestTimeDD),
									LastTestTime) > @Timestamp
							THEN DATEADD(DD,
									(ROUND(DATEDIFF(DAY, LastTestTime, @TimeStamp) / CONVERT(FLOAT,TestTimeDD), 0,1)-1) * CONVERT(FLOAT,TestTimeDD),
									LastTestTime)
							ELSE DATEADD(DD,
									ROUND(DATEDIFF(DAY, LastTestTime, @TimeStamp) / CONVERT(FLOAT,TestTimeDD), 0,1) * CONVERT(FLOAT,TestTimeDD),
									LastTestTime)
						END
	WHERE	AuditFreq = 'D'
	AND		DATEADD (DAY,CONVERT(FLOAT,TestTimeDD),LastTestTime) < @Timestamp
	AND  TestTimeDD <> '00'


UPDATE	@VarsToAdd
	SET		NextTestTime =	DATEADD	(DAY, CONVERT(FLOAT,TestTimeDD), LastTestTime)								
	WHERE	AuditFreq = 'D'
	

UPDATE	@VarsToAdd
	SET		NextTestTime = CONVERT(datetime, 
											CONVERT(VARCHAR(30), CONVERT(DATE,NextTestTime)) + ' ' +
											TestTimeHH + ':' +
											TestTimeMM + ':00.000')
	FROM		@VarsToAdd
	WHERE		TestTimeString IS NOT NULL

-- Adjust next test time for test time already past (daily)
UPDATE	@VarsToAdd
SET		NextTestTime = dateadd(dd, CONVERT(INT,TestTimeDD), NextTestTime)
FROM		@VarsToAdd
WHERE		(NextTestTime <= @Timestamp)
			AND
			(AuditFreq = 'D')

-- update the last test time (daily)
UPDATE	@VarsToAdd
	SET		LastTestTime = dateadd(dd, -CONVERT(int, TestTimeDD), NextTestTime)
	FROM		@VarsToAdd
	WHERE		(AuditFreq = 'D')


-- Do not add into scope if TF=0
SET @ProdId = (SELECT Prod_Id FROM Production_Starts WITH (NOLOCK) WHERE PU_Id = @PUId AND Start_Time <= @Timestamp AND End_Time IS NULL)

UPDATE va
SET TestFreq = Test_Freq
FROM @VarsToAdd va
JOIN dbo.Var_Specs vs WITH (NOLOCK) ON va.VarId = vs.Var_Id AND Expiration_Date IS NULL AND Prod_Id = @ProdId

UPDATE va
SET TestFreq = Sampling_Interval
FROM @VarsToAdd va
JOIN dbo.Variables_Base v WITH (NOLOCK) ON va.VarId = v.Var_Id
WHERE TestFreq IS NULL

IF @CallerId != 'Shift Change'
	BEGIN
		--------------------------------------SHIFTLY------------------------------------
		--If Result is before beginning of shift
		UPDATE	@VarsToAdd 
		SET		Result = NULL,
					LastResultTime = @Timestamp,
					TestId = NULL,
					CancelLastColumn = 0,
					InsertFlag = 1
		WHERE		(AuditFreq = 'S')
					 AND
					(LastResultTime <	(
											SELECT	max(Start_Time) 
											FROM		dbo.Crew_Schedule WITH (NOLOCK)
											WHERE		(Start_Time <= @Timestamp)
														AND
														(PU_Id = @PUId)
											)
					)
		
		--If Result is null
		UPDATE	@VarsToAdd 
		SET		CancelLastColumn = 0,
					InsertFlag = 1
		WHERE		(AuditFreq = 'S')
					AND
					(isnull(Result, '') = '')
					AND
					(TestId IS NOT NULL)

		-- cancel values from last column
		UPDATE	@VarsToAdd
		SET		CancelLastColumn = 1
		WHERE		(AuditFreq = 'S')
					AND
					(isnull(Result, '') = '')
	END
ELSE
	BEGIN
		UPDATE	@VarsToAdd 
		SET		CancelLastColumn = 0,
					InsertFlag = 1
		WHERE		(AuditFreq = 'S')
	END
--------------------------------------DAILY---------------------------------
-- If the last Result is before the previous test time (don't have value yet for current period)
UPDATE	@VarsToAdd
SET		Result = NULL,
		CancelLastColumn = 0,
		InsertFlag = 1
WHERE		(
				(LastResultTime < LastTestTime
				OR
				LastResultTime IS NULL)
				OR
				(LastResultTime > LastTestTime AND LastResultTime <= NextTestTime
				AND Result IS NULL)
			)
			AND
			(AuditFreq = 'D')

-- cancel values not entered in the last columns
UPDATE	@VarsToAdd 
SET		CancelLastColumn = 1
WHERE		(AuditFreq = 'D')
			AND
				(
					(LastResultTime >= LastTestTime) -- Change from > to >= to include when it is equal
					OR
					(LastTestTime > @Timestamp)
				)
			AND
			(Result IS NULL)


UPDATE llr
	SET  Cycle_Start_Time = v.LastTestTime
	FROM	dbo.Local_CL_LogLastResultON llr
	JOIN	@VarsToAdd v 
		ON	v.VarId = llr.Var_Id
		AND llr.Cycle_Start_Time <> v.LastTestTime
	WHERE v.AuditFreq = 'D'
	AND LastTestTime IS NOT NULL

INSERT INTO dbo.Local_CL_LogLastResultON (	Cycle_Start_Time , Var_Id )
	SELECT		LastTestTime, VarId			
	FROM	@VarsToAdd vd 
	WHERE vd.VarId NOT IN (SELECT Var_ID FROM dbo.Local_CL_LogLastResultON WITH(NOLOCK))
	AND vd.AuditFreq = 'D'
	AND LastTestTime IS NOT NULL

	--------------------------------------Defect #15 #16------------------------------------------------------
--Force shiftly variables not to cancel the product change column when transitioning from TF = 0 to TF = 1
--Needs to be updated in the future, window function down below to select the 2nd prod_id
SET @ProdId = (SELECT TOP 1 Prod_Id FROM Production_Starts WITH (NOLOCK) WHERE PU_Id = @PUId AND Start_Time <= @Timestamp AND End_Time IS NOT NULL ORDER BY Start_Time DESC)

UPDATE va
SET LastTestFreq = Test_Freq
FROM @VarsToAdd va
JOIN dbo.Var_Specs vs WITH (NOLOCK) ON va.VarId = vs.Var_Id AND Expiration_Date IS NULL AND Prod_Id = @ProdId

UPDATE va
SET TestFreq = Sampling_Interval
FROM @VarsToAdd va
JOIN dbo.Variables_Base v WITH (NOLOCK) ON va.VarId = v.Var_Id
WHERE TestFreq IS NULL

UPDATE @VarsToAdd
SET CancelLastColumn = 0
WHERE AuditFreq = 'S'
AND CancelLastColumn = 1
AND LastTestFreq = 0
AND TestFreq = 1
----------------------------------------------------------------------------------------------------------

-- The ones that are not going to be inserted needs to be canceled:
SELECT	2,													-- Resultset Type
			VarId,											-- Var_Id
			PUId,												-- PU_Id
			UserId,											-- User_Id
			1,												-- Canceled 0=No 1=Yes
			NULL,											-- Result
			LastResultTime,									-- Result_On
			TransType,										-- Transaction Type 1=Add 2=Update 3=Delete
			PostDB,											-- Pre=0 Post=1
			NULL,												-- Second_User_Id
			2,													-- Transaction Number  0=Update fields that are not null 2=Update all fields
			NULL,												-- Event_Id
			NULL,												-- Array_Id
			NULL,												-- Comment_Id
			NULL,												-- ESigId
			@Now,												-- EntryOn
			NULL,												-- TestId
			NULL,												-- ShouldArchive
			NULL,												-- HasHistory
			NULL												-- IsLocked
FROM		@VarsToAdd
WHERE		(CancelLastColumn = 1)
----------------------------------------------------------------------------------------------------------
-- Set the isVarMandatory Field back to 0 for the tests that are canceled -Start 
-- S.Stier(Stier Automation)  5/17/2022
----------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	-- This  cursor will go through each row in @VarsToAdd table and  one by
	-- by one update test table setting the isVarMandatory field to 0 if it is canceled
	-------------------------------------------------------------------------------------------
	DECLARE @@VarId int,
			@@LastResultTime datetime

	DECLARE	Vars_Cursor CURSOR FOR

	(SELECT	VarId,	LastResultTime FROM	@VarsToAdd WHERE CancelLastColumn = 1)

		FOR READ ONLY
	OPEN	Vars_Cursor
	FETCH	NEXT FROM Vars_Cursor INTO @@VarId, @@LastResultTime

	WHILE	@@Fetch_Status = 0

	BEGIN
		UPDATE tests SET isVarMandatory = 0 where var_id = @@VarId and result_on = @@LastResultTime
		FETCH	NEXT FROM Vars_Cursor INTO @@VarId, @@LastResultTime
	END
	CLOSE 	Vars_Cursor
	DEALLOCATE Vars_Cursor

----------------------------------------------------------------------------------------------------------
-- Set the isVarMandatory Field back to 0 for the tests that are canceled - End
----------------------------------------------------------------------------------------------------------

IF @LastUDETimestamp IS NOT NULL
	BEGIN
		SELECT	7,																--Sheet Column Resultset
					Sheet_Id,													--SheetId
					@RSUserId,													--UserId
					3,																--TransType (1=Add, 2=Update, 3=Delete)
					convert(varchar(25), @LastUDETimestamp, 120),	--TimeStamp
					1,																--PostDB
					NULL,															--ApprovedUserId
					NULL,															--ApprovedReasonId
					NULL,															--UserReasonId
					NULL,															--UserSignOffId
					NULL, 															-- ES ig Id
					NULL, 															-- Trans Num
					NULL 															-- Comment Id
		FROM		dbo.Sheets WITH (NOLOCK)
		WHERE		(Master_Unit = @PUId)
					AND
					(Event_Subtype_Id = @EventSubtype)

		-- A sheet column Resultset to recreate the preceding column
		SELECT	7,																--Sheet Column Resultset
					Sheet_Id,													--SheetId
					@RSUserId,													--UserId
					1,																--TransType (1=Add, 2=Update, 3=Delete)
					convert(varchar(25), @LastUDETimestamp, 120),	--TimeStamp
					1,																--PostDB
					NULL,															--ApprovedUserId
					NULL,															--ApprovedReasonId
					NULL,															--UserReasonId
					NULL,															--UserSignOffId
					NULL, 															-- ES ig Id
					NULL, 															-- Trans Num
					NULL 															-- Comment Id
		FROM		dbo.Sheets WITH (NOLOCK)
		WHERE		(Master_Unit = @PUId)
					AND
					(Event_Subtype_Id = @EventSubtype)
	END

--Clear Canceled values
UPDATE	@VarsToAdd
SET		Result = NULL,
			LastResultTime = @Timestamp,
			TestId = NULL,
			CancelLastColumn = 0 
WHERE		CancelLastColumn = 1

-- The ones that are not going to be inserted needs to be canceled:
SELECT	2,													-- Resultset Type
			VarId,											-- Var_Id
			PUId,												-- PU_Id
			UserId,											-- User_Id
			1,										-- Canceled 0=No 1=Yes
			NULL,												-- Result
			convert(varchar(25), @Timestamp, 120),	-- Result_On
			TransType,										-- Transaction Type 1=Add 2=Update 3=Delete
			PostDB,											-- Pre=0 Post=1
			NULL,												-- Second_User_Id
			2,													-- Transaction Number  0=Update fields that are not null 2=Update all fields
			NULL,												-- Event_Id
			NULL,												-- Array_Id
			NULL,												-- Comment_Id
			NULL,												-- ESigId
			@Now,												-- EntryOn
			NULL,												-- TestId
			NULL,												-- ShouldArchive
			NULL,												-- HasHistory
			NULL												-- IsLocked
FROM		@VarsToAdd
WHERE		(InsertFlag = 0)

		SET @Section = 'SUCCESS StubVariablesReady'

DROP TABLE #Vardata
DROP TABLE #TestsData


END TRY
BEGIN CATCH
	SELECT @ErrorMessage = ERROR_MESSAGE()
	RAISERROR (@ErrorMessage,16,1)
END CATCH


SET NOCOUNT OFF

