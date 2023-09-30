CREATE PROCEDURE [dbo].[spLocal_eCIL_GetTask]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_eCIL_GetTask
Author				:		Christian Gagnon, System Technologies for Industry inc
Date Created		:		2007-04-04
SP Type				:			
Editor Tab Spacing	:		3
Description:
=========
Get one task by the varid for display in the report :
CALLED BY:  eCIL Web Application
Revision 		Date			Who						What
========		=====			====					=====
1.0.0			10-May-2007		Christian Gagnon		Creation of SP
1.1.0			24-May-2007		Normand Carbonneau		Added PL_Id field at the end of the resultset
1.1.1			25-May-2007		Normand Carbonneau		Added CurrentDueTime for Non-Defect tasks (missing)
																Moved date conversion to Varchar only at the final select
1.1.2			20-Jun-2007		Normand Carbonneau		Uses the fnLocal_eCIL_GetTaskFreqCode to get the Task Freq code (S, D, 28D)
1.1.3			13-Oct-2007		Normand Carbonneau		Added FL3 to the list of fields
1.2.0			23-Nov-2007		Normand Carbonneau		Added code to retrieve the DisplayLink, which is a User-Defined property
																used to display a more meaningful text for document hyperlinks.
2.0.0			11-Apr-2008		Normand Carbonneau		The @VarId parameter has been replaced by @TestId parameter.
																This is to retrieve a single instance of a task.
2.1.0			01-May-2008		Normand Carbonneau		Now retrieving the eCIL variables by their Data_Type instead of
																their Event Subtype no longer used.
																Now retrieves the defects differently (fnLocal_eCIL_GetTestIdFromUDE)
																No longer need to access the Tests table.
																Now retrieves FL3 from fnLocal_eCIL_GetFL3
																Now retrieves FL4 from fnLocal_eCIL_GetFL4
																Also returns FL1 and FL2 (new).
																UDE_Desc is now : VarId-TestId-NotificationNumber.
																Retrieving Notification from new function fnLocal_eCIL_GetNotificationFromUDE
																No more 'WorkOrder' UDP on the UDE.
2.1.1			15-Sep-2008		Normand Carbonneau		Now refers to fnLocal_STI_Cmn_GetRunningProduct instead of fnLocal_GetProdId
2.2.0			04-Oct-2008		Normand Carbonneau		Does not return seconds anymore for CurrentResultTime and CurrentDueTime
2.2.1			29-Oct-2008		Normand Carbonneau		Get the ACTUAL specs instead of the specs at the time of the test.
																At initial startup of the Scheduler, the Result_On of the Test could
																be prior to the Activation_Date of the spec.
																Also, LEFT JOINED on specs to retrieve other info if spec missing.
																Finally, added WITH (NOLOCK).
2.2.2			12-Feb-2009		Alexandre Turgeon		Removed GeneralInfo, redesigned joins and where conditions
2.2.3			16-Feb-2009		Alexandre Turgeon		Added CASE in query to fill information based on TaskFreq
2.2.4			17-Feb-2009		Alexandre Turgeon		Added eCIL UDPs as ouput values
3.0.0			23-Feb-2009		Alexandre Turgeon		Changed call to retrieve current product to use the history table
																to retrieve the product used to create the task instead of the current product at this time
3.0.0			14-Apr-2009		Normand Carbonneau		Now using new nomination for UDPs. All UDPs related to eCIL starts with eCIL_.
3.1.0			28-Apr-2009		Normand Carbonneau		Retrieving next available spec if no spec at test time.
																(Task could have been create based on UDP TestFreq and removed after)
																Also checking for UDP before reading spec of variable.
3.2.0			15-Jun-2009		Normand Carbonneau		Now retrieves the Task Frequency from new Table_Fields_Values_History table, if an
																history exists for this UDP. Uses new fnLocal_STI_Cmn_GetUDPByTime function for this.
3.3.0			21-Feb-2010		Normand Carbonneau		Replaced fnCmn_UDPLookup by fnLocal_STI_Cmn_GetUDP
3.4.0			08-May-2010		Normand Carbonneau		UDP Change :QValue -> Q-Factor Type
																					QPriority -> Primary Q-Factor?
3.5.0			11-May-2010		Normand Carbonneau		Returns IsDefectLocked column to indicate if we can add new defects on this instance
																of the task. We can only add new defects if this is the latest instance of the task.
3.5.1			03-Aug-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
3.5.2           14-Feb-2018     Megha Lohana			FO-03299: Optimize the SP spLocal_eCIL_GetTask to reduce execution time
3.5.3			10-Jan-2018		Ben Lee					Returns HSE Flag UDP
3.5.4			01-Mar-2018		Fran Osorno				moved to base tables
3.5.5			10-Jun-2020     Megha Lohana			FO-04232: CIL task completion window should be extended during PR out line status
3.5.6           1-Jul-2020      Megha Lohana			Added missing nolock on GBDB tables used in SP
3.5.7			18-Feb-2021		Megha Lohana			Updated TestID data type to BIGINT for PPA7
3.5.8			25-Feb-2021		Megha Lohana			eCIL 4.1 SP standardized, added base table and nolock
3.5.9			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
3.5.10 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
3.6.0			02-Aug-2023		Payal Gadhvi			Updated SP to add version management and to meet SP standard
Test Call :
EXEC spLocal_eCIL_GetTask 26409778
*/
@TestId			BIGINT

AS
SET NOCOUNT ON;

DECLARE
@MasterId		INT,
@ResultOn		DATETIME,
@FirstResultOn	DATETIME,
@EntryOn		DATETIME,
@FirstEntryOn	DATETIME,
@ProdId			INT,
@Now			DATETIME,
@TestFreq		VARCHAR(25),
@FixedFrequency INT, /* FO-04232 Added a new paraemeter for Fixed Frequency , Variable frequency or variable frequency with auto postpone */
@VarId			INT,
@MissedTime		DATETIME,
@TaskFreqCode	VARCHAR(4),
@MaxTestId		BIGINT;

/*--FO-03299: Optimize the SP spLocal_eCIL_GetTask to reduce execution time
-- Created a temporary table to store TestIds for concerned Variable */
Create table #TempTests
( 
TestId BIGINT
);

SET @Now = GETDATE();

SET @MasterId =
	(
	SELECT COALESCE(pu.Master_Unit, pu.Pu_Id)
	FROM	dbo.Tests t				WITH (NOLOCK)
	JOIN	dbo.Variables_base v	WITH (NOLOCK) ON t.Var_Id = v.Var_Id
	JOIN	dbo.Prod_Units_base pu	WITH (NOLOCK) ON v.Pu_Id = pu.Pu_Id
	WHERE	t.Test_Id = @TestId
	);

/*-- Retrieve timestamp and var_id
-- FO-03299: Optimize the SP spLocal_eCIL_GetTask to reduce execution time
-- Commented the nested query to descrease the execution time for the SP */
SELECT	@ResultOn		= Result_On,
			@VarId		= Var_Id,
			@EntryOn	= Entry_On
			/*--@MaxTestId	= (
			--					SELECT	MAX(Test_Id)
			--					FROM		dbo.Tests WITH (NOLOCK)
			--					WHERE		Var_Id = t.Var_Id
			--					) */
FROM		dbo.Tests t WITH (NOLOCK) 
WHERE		t.Test_Id = @TestId ;

/*--FO-03299: Optimize the SP spLocal_eCIL_GetTask to reduce execution time
-- Insert all Test_Ids for the concerned variables in #TempTests temporary table */
Insert #TempTests
( 
TestId
)
SELECT Test_Id FROM dbo.Tests WITH (NOLOCK)
WHERE Var_Id = @VarId ;

/* Find the maximum test id for the concerned variable from #TempTests temporary table */
SET @MaxTestId = 
	(
	SELECT MAX(TESTID)
	FROM #TempTests
	) ; 

/*-- Retrieve the original Result_On when the task was created
-- If FirstResultOn is different than ResultOn, the task was postponed
-- We discard the milliseconds because they are not required and will cause duplicate rows
-- later in the process and would cause a major performance hit */
SET @FirstResultOn =
	(
	SELECT	CONVERT(VARCHAR(19), MIN(Result_On), 120)
	FROM		dbo.Test_History WITH(NOLOCK)
	WHERE		Test_Id = @TestId
		AND		Result_On IS NOT NULL
	) ;

/*-- Retrieve the original Entry_On when the task was created
-- We discard the milliseconds because they are not required and will cause duplicate rows
-- later in the process and would cause a major performance hit */
SET @FirstEntryOn =
	(
	SELECT	CONVERT(VARCHAR(19), MIN(@EntryOn), 120)
	FROM		dbo.Test_History WITH(NOLOCK)
	WHERE		Test_Id = @TestId
		AND		Result_On = @ResultOn
		AND		Entry_On IS NOT NULL
	) ;

SET @EntryOn =
	(
	SELECT	MIN(Entry_On)
	FROM		dbo.Test_History WITH(NOLOCK)
	WHERE		Test_Id = @TestId
		AND		Entry_On IS NOT NULL
	);

/*-- Verify if the task have Test Frequency information stored in UDP instead of specs
-- Get the UDP value from new UDP History table to have the value at time of task creation */
SET @TestFreq = dbo.fnLocal_STI_Cmn_GetUDPByTime(@VarId, 'eCIL_TaskFrequency', 'Variables', @FirstEntryOn);

/*-- No UDP detected. Retrieve specs */
IF (@TestFreq IS NULL) OR (LEN(@TestFreq) < 7)
	BEGIN
		/* Retrieve the product that was running when the task was created */
		SET @ProdId = dbo.fnLocal_eCIL_GetCurrentProductFromHistory(@MasterId, @FirstResultOn, @FirstEntryOn) ;

		/* Retrieve the Test Frequency at Task creation or the first next spec available */
		SET @TestFreq =	(
								SELECT	TOP 1 vs.Test_Freq
								FROM		dbo.Var_Specs vs WITH (NOLOCK)
								WHERE		Var_Id = @VarId
									AND		Prod_Id = @ProdId
									AND		(
												(Expiration_Date IS NULL)
												OR
												(Expiration_Date > @FirstResultOn)
											)
								ORDER BY	Effective_Date ASC
								);
	END

SET @TaskFreqCode = dbo.fnLocal_eCIL_GetTaskFreqCode(@TestFreq) ;

/*--FO-04232: CIL task completion window should be extended during PR out line status
-- Find the Fixed Frequency value */
SET @FixedFrequency = dbo.fnLocal_STI_Cmn_GetUDP(@VarId, 'eCIL_FixedFrequency', 'Variables') ;

IF @TaskFreqCode = 'S'
	
		SET @MissedTime = CONVERT(CHAR(16), (SELECT MIN(Start_Time) FROM dbo.Crew_Schedule cs WITH (NOLOCK) WHERE (cs.PU_Id = @MasterId) AND (Start_Time > @FirstResultOn)), 120);
	
ELSE IF @TaskFreqCode = 'D'
	
		SET @MissedTime = CONVERT(CHAR(16), DATEADD(HOUR, 24, @FirstResultOn), 120);
	
/*--FO-04232: CIL task completion window should be extended during PR out line status
-- Update the parameters passed to the function for calculating Missed Time */
ELSE IF @TaskFreqCode LIKE '%D'
	
		SET @MissedTime = CONVERT(CHAR(16), dbo.fnLocal_eCIL_GetMultiDayMissedTime(@FirstResultOn, @TestFreq, @FixedFrequency, @MasterId), 120);
	
ELSE
	
		SET @MissedTime = CONVERT(CHAR(16), dbo.fnLocal_eCIL_GetMinuteMissedTime(@FirstResultOn, @TestFreq), 120);
	

/* Return Resultset */
SELECT			SlaveUnitId			=	v.Pu_Id,
				TestId				=	@TestId,
				NbrDefects			=	dbo.fnLocal_eCIL_GetNbrOpenedDefectsOnInstance(@TestId),
				VarId				=	v.Var_Id,
				SlaveUnitDesc		=	pus.Pu_Desc,
				MasterUnitDesc		=	pum.Pu_Desc,
				TaskId				=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_TaskId', 'Variables'),
				VarDesc				=	v.Var_Desc,
				TaskFreq			=	dbo.fnLocal_eCIL_GetTaskFreqCode (@TestFreq),
				TaskType			=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_TaskType', 'Variables'),
				CurrentResult		=	t.Result,
				CommentId			=	t.Comment_Id,
				CommentInfo			=	c.Comment_Text,
				LineDesc			=	pl.Pl_Desc,
				UserNameTest		=	u.Username,
				Duration			=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_Duration', 'Variables'),
				LongTaskName		=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_LongTaskName', 'Variables'),
				ExternalLink		=	v.External_Link,
				DisplayLink			=	COALESCE(dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_DocumentLinkTitle', 'Variables'), v.External_Link),
				FL1					=	dbo.fnLocal_eCIL_GetFL1(v.Var_Id),
				FL2					=	dbo.fnLocal_eCIL_GetFL2(v.Var_Id),
				FL3					=	dbo.fnLocal_eCIL_GetFL3(v.Var_Id),
				FL4					=	dbo.fnLocal_eCIL_GetFL4(v.Var_Id),
				PL_Id				=	pl.Pl_Id,
				FixedFreq			=	CASE dbo.fnLocal_eCIL_GetTaskFreqCode (@TestFreq)
												WHEN 'D' THEN NULL
												WHEN 'S' THEN NULL
												ELSE dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_FixedFrequency', 'Variables')
											END,
				ScheduleTime		=	CONVERT(CHAR(16), @ResultOn, 120),
				LateTime			=	CONVERT(CHAR(16), dbo.fnLocal_eCIL_GetLateTime(@FirstResultOn, @TestFreq, @MissedTime), 120),
				DueTime				=	CONVERT(CHAR(16), @MissedTime, 120),
				TaskAction			=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_TaskAction', 'Variables'),
				Criteria			=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_Criteria', 'Variables'),
				Hazards				=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_Hazards', 'Variables'),
				Method				=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_Method', 'Variables'),
				PPE					=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_PPE', 'Variables'),
				Tools				=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_Tools', 'Variables'),
				Lubricant			=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_Lubricant', 'Variables'),
				QFactorType			=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'Q-Factor Type', 'Variables'),
				PrimaryQFactor		=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'Primary Q-Factor?', 'Variables'),
				NbrPeople			=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_NbrPeople', 'Variables'),
				NbrItems			=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_NbrItems', 'Variables'),
				HSEFlag				=	dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'HSE Flag', 'Variables'),
				ShiftOffset			=	CASE
											WHEN dbo.fnLocal_eCIL_GetTaskFreqCode (@TestFreq) LIKE '%M'
												THEN dbo.fnLocal_STI_Cmn_GetUDP(v.Var_Id, 'eCIL_ShiftOffset', 'Variables')
											ELSE 0
										END,
				IsDefectLocked		=	CASE
												WHEN @MaxTestId <> @TestId THEN 1
												ELSE 0
											END
FROM			dbo.Tests t					WITH (NOLOCK)
JOIN			dbo.Variables_base v		WITH (NOLOCK) ON (t.Var_Id = v.Var_Id) 
JOIN			dbo.Prod_Units_base pus		WITH (NOLOCK) ON v.Pu_Id = pus.Pu_Id
JOIN			dbo.Prod_Units_base pum		WITH (NOLOCK) ON pus.Master_Unit = pum.Pu_Id
JOIN			dbo.Prod_Lines_base pl		WITH (NOLOCK) ON pus.Pl_Id = pl.Pl_Id
JOIN			dbo.Users_base u			WITH (NOLOCK) ON t.[Entry_By] = u.[User_Id]
LEFT JOIN		dbo.Comments c				WITH (NOLOCK) ON t.Comment_Id = c.Comment_Id
WHERE			(t.Test_Id = @TestId)
ORDER BY		t.Result_On ASC, pum.Pu_Desc, pus.Pu_Desc, v.Var_Id ;

Drop table #TempTests;

