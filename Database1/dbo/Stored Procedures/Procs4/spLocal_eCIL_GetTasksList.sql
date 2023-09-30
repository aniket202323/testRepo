
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetTasksList]	
/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_eCIL_GetTasksList
Author				:		Christian Gagnon (STICorp)
Date Created		:		04-Apr-2007
SP Type				:			
Description:
=========
Get the list of task(s) for specific slave units and can be filter by :
Optional TaskTypeFilter (Varchar(15)) ('All', 'DownTime', 'UpTime')
Optional TaskToShow (Varchar(10)) ('All', 'Pending', 'Late', 'Defect')
CALLED BY:  eCIL Web Application
Revision 		Date			Who						What
========		=====			====					=====
1.0.0			04-Apr-2007		Christian Gagnon		Creation of SP
1.0.1			27-Apr-2007		Normand Carbonneau		Added External_Link field to the return dataset
1.0.2			01-May-2007		Normand Carbonneau		Added FL4 field to the return dataset
1.0.3			03-May-2007		Normand Carbonneau		SP was returning the closed defects and it should not. Corrected.
1.0.4			10-May-2007		Normand Carbonneau		Added 'Defect' as a new possible filter for @TaskToShow parameter
																Corrected a bug that was causing the final select to look for
																the result of the task based on the English value received in
																@TaskToShow parameter. Now the local value is compared.
1.0.5			11-May-2007		Christian Gagnon		Will now show none closed defect from previous product
																(so it can be closed)
1.0.6			14-May-2007		Normand Carbonneau		Corrected error on JOIN on User_Defined_Events table
																Added JOIN on Table_Fields table where there was JOIN on Table_Fields_Values table
																Refactored SP to get better performance.																
1.0.7			22-May-2007		Christian Gagnon		Removed OK Tasks
1.1.0			24-May-2007		Normand Carbonneau		Added PL_Id field at the end of the resultset
2.0.0			14-Jun-2007		Normand Carbonneau		Added @DeptsList, @LinesList, @MastersList parameters
																Removed @AskDate parameter
																The SP was optimized to read less information by improvimng the filtering of data.
																Now allows to pass a list of Departments, Lines, Master Units, Slave Units,
																or any combination of those lists.
																This will add flexibility, and allow to passs less data when calling the SP.
2.0.1			20-Jun-2007		Normand Carbonneau		Uses the fnLocal_eCIL_GetTaskFreqCode to get the Task Freq code (S, D, 28D)
2.0.2			13-Oct-2007		Normand Carbonneau		Added FL3 to the list of fields
3.0.0			01-Nov-2007		Normand Carbonneau		Added @TeamsList, @RoutesList, @TeamUserId, @RouteUserId parameters
																to be able to retrieve Tasks List based on a list of Teams or
																Routes.
																If a User_Id is specified in @TeamUserId, the list of Tasks associated
																to the team this user is member will be retrieved.
																If a User_Id is specified in @RouteUserId, the list of Tasks associated
																to the Route(s) this user is member will be retrieved.
																Now, all parameters are optional.
3.1.0			23-Nov-2007		Normand Carbonneau		Added code to retrieve the DisplayLink, which is a User-Defined property
																used to display a more meaningful text for document hyperlinks.
3.1.1			24-Nov-2007		Normand Carbonneau		Corrected a bug while retrieving the tasks for MyRoute. (Too many tasks returned).
4.0.0			17-Dec-2007		Normand Carbonneau		Modified for new Team/Routes Structure logic.
																@TeamUserId and @RouteUserId are no longer used.
																My Routes and My Teams are not retrieved by @RoutesList and @TeamsList
4.1.0			03-Apr-2008		Normand Carbonneau		Changed the logic to retrieve the number of defects opened on each task
																instead of just indication a DefectFlag. It is necessary to allow
																multiple defects on a task.
																Added optional parameter @VarId to be able to retrieve the information
																of a single task.
4.2.0			01-May-2008		Normand Carbonneau		Now retrieving the eCIL variables by their Data_Type instead of
																their Event Subtype no longer used.
																Now retrieves the defects differently (fnLocal_eCIL_GetTestIdFromUDE)
																No longer need to access the Tests table.
																Now retrieves FL3 from fnLocal_eCIL_GetFL3
																Now retrieves FL4 from fnLocal_eCIL_GetFL4
																Also returns FL1 and FL2 (new).
																UDE_Desc is now : VarId-TestId-NotificationNumber.
																Retrieving Notification from new function fnLocal_eCIL_GetNotificationFromUDE
																No more 'WorkOrder' UDP on the UDE.
4.2.1			31-Jul-2008		Normand Carbonneau		Compliant with new Prompts Manager v2.0
																Prompts are no longer at fixed range																
4.2.2			10-Sep-2008		Normand Carbonneau		Task Result Prompts are now part of eCIL_DataType Category
																Seconds are no longer returned in Due Time and Result Time
																(Returns 16 characters instead of 19)
4.2.3			15-Sep-2008		Normand Carbonneau		Now refers to fnLocal_STI_Cmn_GetRunningProduct instead of fnLocal_GetProdId
																Now refers to fnLocal_STI_Cmn_SplitString instead of fnLocal_Split
5.0.0			12-Feb-2009		Alexandre Turgeon		Uses specs at the task creation time instead of current specs, added late and missed time,
																uses Fixed/Variable frequency for multiday variables, added team description in output,
																now if a task is in many routes or teams, a copy of the task will be returned for each route or team,
																added variable table for unique var_ids in order to improve retrieval performances
5.0.1			17-Feb-2009		Alexandre Turgeon		Added eCIL UDPs as ouput values
6.0.0			23-Feb-2009		Alexandre Turgeon		Changed call to retrieve current product to use the history table
																to retrieve the product used to create the task instead of the current product at this time
																Retrieves specs for postponed task based on original Result_On
7.0.0			14-Apr-2009		Normand Carbonneau		Now using new nomination for UDPs. All UDPs related to eCIL starts with eCIL_.		
7.1.0			28-Apr-2009		Normand Carbonneau		Changed the way Prod_Ids are retrieved to improve performance.
																And retrieving next available spec if no spec at test time.
																Also checking for UDP before reading specs of variables.
7.1.1			11-May-2009		Normand Carbonneau		Changed a condition to retrieve the correct Due Date of shiftly tasks.
																Due Date was showing same information as Schedule Date.
8.0.0			28-May-2009		Normand Carbonneau		fnLocal_eCIL_GetLateTime is now expecting a 3rd parameter (MissedTime)
																Now calculates Late Time for Shiftly tasks.
																Long Task Names were limited to 500 characters. Some sites were using more than that.
																The maximum length has been expanded to 2000 characters.
8.1.0			15-Jun-2009		Normand Carbonneau		Now retrieves the Task Frequency from new Table_Fields_Values_History table, if an
																history exists for this UDP. Uses new fnLocal_STI_Cmn_GetUDPByTime function for this.
8.2.0			21-Feb-2010		Normand Carbonneau		Replaced fnCmn_UDPLookup by fnLocal_STI_Cmn_GetUDP
9.0.0			27-Apr-2010		Normand Carbonneau		eCIL_TestTime UDP is now stored as HH:MM instead of HHMM
																Modified the code accordingly.																
9.1.0			06-May-2010		PD Dubois				Added the "IsDefectLocked" returned field to prevent users from clicking during defect creation
																(http://sticorp.jira.com/browse/ECIL-81) for eCIL v.2.3.0
9.2.0			08-May-2010		Normand Carbonneau		UDP Change :	QValue -> Q-Factor Type
																					QPriority -> Primary Q-Factor?
9.2.1			11-May-2010		Normand Carbonneau		The TestFreq column of the @Results table was changed from int to varchar(7).
																When a task was inactive, the TestFreq was skipping leading zeros (because of int data type)
																and this was preventing fnLocal_eCIL_GetLateTime from being able to evaluate the Late Time.
																(http://sticorp.jira.com/browse/ECIL-132) for eCIL v2.3.0
9.2.2			12-May-2010		PD Dubois				Modified the "IsDefectLocked" section
																(http://sticorp.jira.com/browse/ECIL-81) for eCIL v.2.3.0
9.2.3			08-Jun-2010		Normand Carbonneau		Increased the length of TaskId to 50 characters (Jira ECIL-165).
9.2.4			03-Aug-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
9.2.5			10-Jan-2018		Ben Lee					Returns HSE Flag UDP
9.2.6			2-Mar-2020		Megha Lohana			FO-04232: CIL task completion window should be extended during PR out line status
														Additional paramters passed to fnLocal_eCIL_GetMultiDayMissedTime to find the missed time considering the invalid line statuses duration
9.2.7			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables 
9.2.8			18-Feb-2021		Megha Lohana			Updated the TestId to BIGINT datatype for PPA 7
9.2.9			31-Oct-2022		Payal Gadhvi			Added condition for CL variables
9.3.0			13-Dec-2022		Payal Gadhvi			Added parameter for Tour Description and TourId
9.3.1			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
9.3.2 			03-May-2023     Aniket B				Remove grant permissions statement from the SP as moving it to permissions grant script
9.3.3			08-May-2023		Shashank Das			Modified the Stored Procedure as per Code Review- Coding standards
9.3.4			08-May-2023		Shashank Das			Added an upsert operation to the AppVersions table that does a single scan on an update and does two for insert.


Test Call :
EXEC spLocal_eCIL_GetTasksList NULL, NULL, NULL, '1130,1131,1132,1010,1204,1206'
EXEC spLocal_eCIL_GetTasksList '138,143'
EXEC spLocal_eCIL_GetTasksList NULL, NULL, NULL, NULL, NULL, '70, 71'
EXEC spLocal_eCIL_GetTasksList NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL
EXEC spLocal_eCIL_GetTasksList @DeptsList = NULL, @LinesList = '125', @MastersList = NULL, @SlavesList = NULL, @TeamsList = NULL, @RoutesList = NULL, @TaskTypeFilter = NULL, @TaskResultFilter = 'Defect', @VarId = NULL
*/
@DeptsList			VARCHAR(8000)	= NULL,
@LinesList			VARCHAR(8000)	= NULL,
@MastersList		VARCHAR(8000)	= NULL,
@SlavesList			VARCHAR(8000)	= NULL,
@TeamsList			VARCHAR(8000)	= NULL,
@RoutesList			VARCHAR(8000)	= NULL,
@TaskTypeFilter		VARCHAR(15)		= NULL,
@TaskResultFilter	VARCHAR(15)		= NULL,
@VarId				INT				= NULL


AS
SET NOCOUNT ON;

/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
--[]																	[]--
--[]							SECTION 1 - Variables Declaration		[]--
--[]																	[]--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--*/


DECLARE
@eCILDataTypeId			INT,
@Now					DATETIME,
@PendingText			VARCHAR(50),
@DefectText				VARCHAR(50),
@LateText				VARCHAR(50),
@Success				INT,
@PendingPosition		INT,
@DefectPosition			INT,
@LatePosition			INT,
@PromptsCategoryName	VARCHAR(100);

DECLARE @Lines TABLE (
LineId					INT,
LineDesc				VARCHAR(50)
);

DECLARE @MasterUnits TABLE (
MasterUnitId			INT,
MasterUnitDesc			VARCHAR(50),
LineId					INT,
STLSId					INT
);

DECLARE @SlaveUnits TABLE (
SlaveUnitID				INT,
SlaveUnitDesc			VARCHAR(50),
MasterUnitId			INT,
LineId					INT
);

DECLARE @TasksList TABLE (
ItemNo					INT IDENTITY(1,1) PRIMARY KEY,
VarId					INT,
TaskId					VARCHAR(50),	/*-- TaskId of the Task (User-defined Parameter)*/
VarDesc					VARCHAR(50),	/*-- Var_Desc of the Task*/
Duration				VARCHAR(50),
LongTaskName			VARCHAR(2000),
ExternalLink			VARCHAR(255),
DisplayLink				VARCHAR(255),
FL1						VARCHAR(50),
FL2						VARCHAR(50),
FL4						VARCHAR(50),
FL3						VARCHAR(50),
RouteDesc				VARCHAR(150),
TaskOrder				INT,
TeamDesc				VARCHAR(150),
Event_Subtype_Desc		VARCHAR(100),
Tour_Stop_Desc			VARCHAR(100),
Tour_Stop_Id			INT
);

DECLARE @UniqueTasks TABLE (
VarId					INT,
PUId					INT,
Master_Unit				INT,
TaskType				VARCHAR(15),	/*-- Task Type (Anytime, DownTime, Running)*/
TestTime				VARCHAR(5),		/*-- Test Time of the Task (Used for Daily and Multi-Day Tasks)*/
FixedFrequency			VARCHAR(50)		/*-- Scheduling type for multiday tasks, values: Fixed or Variable*/
);

DECLARE @OpenedDefects TABLE (
Test_Id					BIGINT,
NbrDefects				INT				/*-- Number of defects opened on this instance of the task*/
);	

DECLARE @Results TABLE (
Test_Id					BIGINT,				/*-- Will be use when updating*/
Var_Id					INT,
PU_Id					INT,
Master_Unit				INT,
FixedFreq				INT,			/*--FO-04232 : Added FixedFreq column to pass to fnLocal_eCIL_GetMultiDayMissedTime function*/
Result_On				DATETIME,		/*-- The time the last result was entered in the current period*/
FirstResultOn			DATETIME,		/*-- The first time the task was scheduled (if it was postponed)*/
Entry_On				DATETIME,		/*-- The time the task is due in the current period*/
FirstEntryOn			DATETIME,		/*-- The first time the task was scheduled (if it was postponed)*/
Result					VARCHAR(25),	/*-- The last result entered for the task in the current period*/
Comment_Id				INT,				/*-- Comment id for the test result in tests table*/
Comment_Text			TEXT,				/*-- Comment text from the comments table*/
Entry_By				INT,
ProdId					INT,
PeriodStart				DATETIME,
PeriodEnd				DATETIME,
TestFreq				VARCHAR(7),		/*-- Test Frequency (1=Active, 234=Task Frequency, 567=Test Window)*/
TaskFreq				VARCHAR(10),	/*-- Task Frequency ( D = Daily, S = Shiftly, Number of Days & 'D' = MultiDay)*/
LateTime				DATETIME,
MissedTime				DATETIME,
IsDefectLocked			BIT DEFAULT 0	/*--> Added by PD Dubois on May 6th 2010 for eCIL v.2.3.0*/
);

/*-- This table will hold the list of products at each distinct time of results of variables*/
DECLARE @Products TABLE
(
PU_Id					INT,
Result_On				DATETIME,
Entry_On				DATETIME,
Prod_Id					INT
);

/**************************************************************/
/*--> Section added by PD Dubois on May 12th 2010 for eCIL v.2.3.0*/
DECLARE @LastDefectsTests TABLE
(
	Test_Id BIGINT
);
/**************************************************************/

/*-- Set the time where we want to evaluate Tasks*/
SET @Now = GETDATE();

/*-- Get the Event SubType ID for eCIL Event SubType*/
/*-- This is used to retrieve all variables of this Event SubType*/
SET @eCILDataTypeId = (SELECT Data_Type_Id FROM dbo.Data_Type  WHERE Data_Type_Desc = 'eCIL');


/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]								SECTION 2 - Creation of Modules list					 []--
--[]																						 []--
--[]  We can receive a list of Depts, Lines, Master Units or Slave Units as parameter.		 []--
--[]  We have to get the list of all Slave Units being part of any item of this list.		 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[]--*/

IF @TeamsList IS NOT NULL
	BEGIN
		INSERT @TasksList (VarId, TeamDesc)
			SELECT	DISTINCT tt.Var_Id, t.Team_Desc
			FROM		dbo.Local_PG_eCIL_TeamTasks tt	
			JOIN		dbo.Local_PG_eCIL_Teams t		 ON t.Team_Id = tt.Team_Id
			WHERE		tt.Team_Id IN (SELECT String FROM dbo.fnLocal_STI_Cmn_SplitString(@TeamsList, ','));

		INSERT @TasksList (VarId, TeamDesc, RouteDesc, TaskOrder)	
			SELECT	DISTINCT rt.Var_Id, t.Team_Desc, r.Route_Desc, rt.Task_Order
			FROM		dbo.Local_PG_eCIL_TeamRoutes tr	
			JOIN		dbo.Local_PG_eCIL_Teams t		 ON t.Team_Id = tr.Team_Id
			JOIN		dbo.Local_PG_eCIL_RouteTasks rt	 ON rt.Route_Id = tr.Route_Id
			JOIN		dbo.Local_PG_eCIL_Routes r		 ON r.Route_Id = rt.Route_Id
			WHERE		tr.Team_Id IN (SELECT String FROM dbo.fnLocal_STI_Cmn_SplitString(@TeamsList, ','));
	END

IF @RoutesList IS NOT NULL
	
		INSERT @TasksList (VarId, RouteDesc, TaskOrder,Tour_Stop_Desc, Tour_Stop_Id)
			SELECT	DISTINCT rt.Var_Id, r.Route_Desc, rt.Task_Order, ts.Tour_Stop_Desc, ts.Tour_Stop_Id
			FROM		dbo.Local_PG_eCIL_RouteTasks rt	
			JOIN		dbo.Local_PG_eCIL_Routes r		 ON rt.Route_Id = r.Route_Id
			LEFT JOIN	dbo.Local_PG_eCIL_TourStops ts  ON rt.Tour_Stop_Id = ts.Tour_Stop_Id
			WHERE		rt.Route_Id IN (SELECT String FROM dbo.fnLocal_STI_Cmn_SplitString(@RoutesList, ','));
	

IF @DeptsList IS NOT NULL
	
		INSERT @TasksList (VarId)
			SELECT	v.Var_Id
			FROM		dbo.Departments_Base as d	
			JOIN		dbo.Prod_Lines_Base  as pl	 ON d.Dept_Id = pl.Dept_Id
			JOIN		dbo.Prod_Units_Base	 as pu	 ON pl.Pl_Id = pu.Pl_Id
			JOIN		dbo.Variables_Base	 as v		 ON pu.Pu_Id = v.Pu_Id
			WHERE		d.Dept_Id IN (SELECT String FROM dbo.fnLocal_STI_Cmn_SplitString(@DeptsList, ','))
			AND		v.Data_Type_Id = @eCILDataTypeId
			AND		v.PU_Id > 0;
	

IF @LinesList IS NOT NULL
	
		INSERT @TasksList (VarId)
			SELECT	v.Var_Id
			FROM		dbo.Prod_Lines_Base as pl	
			JOIN		dbo.Prod_Units_Base as pu	 ON pl.Pl_Id = pu.Pl_Id
			JOIN		dbo.Variables_Base	as v		 ON pu.Pu_Id = v.Pu_Id
			WHERE		pl.PL_Id IN (SELECT String FROM dbo.fnLocal_STI_Cmn_SplitString(@LinesList, ','))
			AND		v.Data_Type_Id = @eCILDataTypeId
			AND		v.PU_Id > 0;
	

IF @MastersList IS NOT NULL
	
		INSERT @TasksList (VarId)
			SELECT	v.Var_Id
			FROM		dbo.Prod_Units_Base as pu	
			JOIN		dbo.Variables_Base  as  v		 ON pu.Pu_Id = v.Pu_Id
			WHERE		pu.Master_Unit IN (SELECT String FROM dbo.fnLocal_STI_Cmn_SplitString(@MastersList, ','))
			AND		v.Data_Type_Id = @eCILDataTypeId
			AND		v.PU_Id > 0;
	
	
IF @SlavesList IS NOT NULL
	
		INSERT @TasksList (VarId)
			SELECT	v.Var_Id
			FROM		dbo.Prod_Units_Base as pu
			JOIN		dbo.Variables_Base  as  v ON pu.Pu_Id = v.Pu_Id
			WHERE		pu.PU_Id IN (SELECT String FROM dbo.fnLocal_STI_Cmn_SplitString(@SlavesList, ','))
			AND		v.Data_Type_Id = @eCILDataTypeId;
	

IF @VarId IS NOT NULL
	
		INSERT @TasksList (VarId)
			SELECT @VarId;
	

/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]										SECTION 3 - Misc Information					 []--
--[]																						 []--
--[]						Get all information necessary before Tasks selection			 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--*/

/*-- Identify unique tasks to improve task retrieval performances*/
INSERT INTO @UniqueTasks (VarId)
	SELECT	DISTINCT	VarId
	FROM		@TasksList	;

/*-- Identify the master unit for each task*/
UPDATE	ut
SET		PUId = pu.PU_Id,
			Master_Unit = pu.Master_Unit
FROM		@UniqueTasks ut
JOIN		dbo.Variables_Base as v  ON ut.VarId = v.Var_Id
JOIN		dbo.Prod_Units_Base as pu  ON v.PU_Id = pu.PU_Id;

INSERT @SlaveUnits (SlaveUnitID, SlaveUnitDesc, MasterUnitId, LineId)
	SELECT	Pu_Id, Pu_Desc, Master_Unit, Pl_Id
	FROM		dbo.Prod_Units_Base 
	WHERE		PU_Id IN	(SELECT DISTINCT PUId FROM @UniqueTasks);

INSERT @MasterUnits (MasterUnitId, MasterUnitDesc, LineId)
	SELECT	Pu_Id, Pu_Desc, Pl_Id 
	FROM		dbo.Prod_Units_Base 
	WHERE		PU_Id IN	(SELECT DISTINCT MasterUnitId FROM @SlaveUnits);

/*-- Retrieve the STLS unit for each master unit*/
UPDATE	@MasterUnits
SET		STLSId = dbo.fnLocal_PG_Cmn_GetSTLSUnit(MasterUnitId);

INSERT @Lines (LineId, LineDesc)
	SELECT	Pl_Id, Pl_Desc
	FROM		dbo.Prod_Lines_Base 
	WHERE		Pl_Id IN (SELECT DISTINCT LineId FROM @MasterUnits);

/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]									SECTION 4 - Tasks Info Retrieval					 []--
--[]																						 []--
--[]	Get all tasks defined by @SlaveUnits list previously defined by parsing parameters.	 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--*/

/*-- Get the TaskType of each Task*/
UPDATE	@UniqueTasks
SET		TaskType = dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_TaskType', 'Variables');

/*-- Get the TestTime UDP for each variable*/
UPDATE	@UniqueTasks
SET		TestTime = dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_TestTime', 'Variables');

/*-- We can filter here all tasks that do not meet the @TaskTypeFilter if there is one*/
IF @TaskTypeFilter IS NOT NULL
	BEGIN
		DELETE FROM @TasksList 
		WHERE			VarId IN (
									SELECT	VarId 
									FROM		@UniqueTasks 
									WHERE		(TaskType IS NULL) 
									OR			(TaskType <> @TaskTypeFilter) 
									OR			(TaskType = '')
									);

		DELETE FROM @UniqueTasks 
		WHERE			(TaskType IS NULL) 
		OR				(TaskType <> @TaskTypeFilter) 
		OR				(TaskType = '');
	END

/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]											SECTION 5 - Opened Defects					 []--
--[]																						 []--
--[]				Get the previous result for all Tasks having a Defect not closed		 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--*/

/*-- The prompts for eCIL data type are located in this category*/
SET @PromptsCategoryName = 'eCIL_DataType';

/*-- Initialize Position for prompts retrieval in eCIL_DataType category*/
SELECT		@PendingPosition	=	1,
			@DefectPosition		=	3,
			@LatePosition		=	4;

/*-- An optional parameter in a function requires DEFAULT to indicate an empty parameter*/
SET @DefectText		=	dbo.fnLocal_STI_Cmn_GetPrompt(@PromptsCategoryName, @DefectPosition, DEFAULT);
SET @PendingText	=	dbo.fnLocal_STI_Cmn_GetPrompt(@PromptsCategoryName, @PendingPosition, DEFAULT);
SET @LateText		=	dbo.fnLocal_STI_Cmn_GetPrompt(@PromptsCategoryName, @LatePosition, DEFAULT);

/*-- If there are no filter selected, then all results will be returned.*/
SET @TaskResultFilter =	ISNULL(@TaskResultFilter, '%');

/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]								SECTION 6 - Retrieve Current Result time				 []--
--[]																						 []--
--[]					Get the Result time of each Task for current period					 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--*/

/*-- Retrieve the value of tasks having Opened Defect(s)*/
/*-- Either because there is no filter and we need them, or because the filter is on Defects only*/
IF (@TaskResultFilter = @DefectText) OR (@TaskResultFilter = '%')
	BEGIN
		-- Get the list of TestId having opened defect(s)
		INSERT @OpenedDefects (Test_Id, NbrDefects)
			SELECT	dbo.fnLocal_eCIL_GetTestIdFromUDE(UDE_Id), COUNT(UDE_Id)
			FROM		dbo.User_Defined_Events ude	
			JOIN		dbo.Event_Subtypes es		 ON ude.Event_Subtype_Id = es.Event_Subtype_Id
			JOIN		@SlaveUnits su	ON ude.Pu_Id = su.SlaveUnitId
			WHERE		es.Extended_Info = 'DefectType'
			AND		ude.End_Time IS NULL
			AND		UDE_Id IS NOT NULL
			GROUP BY	dbo.fnLocal_eCIL_GetTestIdFromUDE(UDE_Id);

		/*-- Get the results of all tasks having a value of Defect*/
		/*-- We discard the milliseconds because they are not required and will cause duplicate rows*/
		/*-- later in the process and would cause a major performance hit*/
		INSERT @Results(Test_Id, Var_Id, Result_On, Entry_On, Result, Comment_Id, Comment_Text, Entry_By)
			SELECT		t.Test_Id,
							t.Var_Id,
							t.Result_On,
							CONVERT(VARCHAR(19), t.Entry_On, 120),
							t.Result,
							t.Comment_Id,
							c.Comment_Text,
							t.Entry_By
			FROM			dbo.Tests t		
			JOIN			@OpenedDefects od ON t.Test_Id = od.Test_Id
			LEFT JOIN	dbo.Comments c		 ON t.Comment_Id = c.Comment_Id
			WHERE			t.Result = @DefectText;
	END

/*-- We now add all the results for tasks not in Defect state*/
/*-- We discard the milliseconds because they are not required and will cause duplicate rows*/
/*-- later in the process and would cause a major performance hit*/
IF (@TaskResultFilter = '%')
	
		INSERT @Results(Test_Id, Var_Id, Result_On, Entry_On, Result, Comment_Id, Comment_Text, Entry_By)
			SELECT		t.Test_Id,
							t.Var_Id,
							t.Result_On,
							CONVERT(VARCHAR(19), t.Entry_On, 120),
							t.Result,
							t.Comment_Id,
							c.Comment_Text,
							t.Entry_By
			FROM			dbo.Tests t		
			JOIN			@UniqueTasks ot ON ot.VarId = t.Var_Id
			LEFT JOIN	dbo.Comments c		 ON c.Comment_Id = t.Comment_Id
			WHERE			t.Result IN (@PendingText, @LateText);
	
ELSE IF (@TaskResultFilter <> @DefectText)
	
		INSERT @Results(Test_Id, Var_Id, Result_On, Entry_On, Result, Comment_Id, Comment_Text, Entry_By)
			SELECT		t.Test_Id,
							t.Var_Id,
							t.Result_On,
							CONVERT(VARCHAR(19), t.Entry_On, 120),
							t.Result,
							t.Comment_Id,
							c.Comment_Text,
							t.Entry_By
			FROM			dbo.Tests t		
			JOIN			@UniqueTasks ut ON ut.VarId = t.Var_Id
			LEFT JOIN	dbo.Comments c		 ON c.Comment_Id = t.Comment_Id
			WHERE			t.Result = @TaskResultFilter;
	

/*-- Retrieve the original Result_On when the task was created*/
/*-- If FirstResultOn is different than ResultOn, the task was postponed*/
/*-- We discard the milliseconds because they are not required and will cause duplicate rows*/
/*-- later in the process and would cause a major performance hit*/
UPDATE	r
SET		FirstResultOn =	(
									SELECT	CONVERT(VARCHAR(19), MIN(th.Result_On), 120)
									FROM		dbo.Test_History th	
									WHERE		th.Test_Id = r.Test_Id
									AND		th.Result_On IS NOT NULL
									)
FROM		@Results r ;

/*-- Retrieve the original Entry_On when the task was created*/
/*-- We discard the milliseconds because they are not required and will cause duplicate rows*/
/*-- later in the process and would cause a major performance hit*/
UPDATE	r
SET		FirstEntryOn =	(
								SELECT	CONVERT(VARCHAR(19), MIN(th.Entry_On), 120)
								FROM		dbo.Test_History th	
								WHERE		th.Test_Id = r.Test_Id
								AND		th.Result_On = r.Result_On
								AND		th.Entry_On IS NOT NULL
								)
FROM		@Results r ;

/*-- Verify if there are some tasks having Test Frequency information stored in UDP instead of specs*/
/*-- Get the UDP value from new UDP History table to have the value at time of task creation*/
UPDATE	@Results
SET		TestFreq = dbo.fnLocal_STI_Cmn_GetUDPByTime(Var_Id, 'eCIL_TaskFrequency', 'Variables', FirstResultOn);

/*-- If there is a TestFreq, it means there is a UDP for scheduling. Products not required for those tasks.*/
INSERT @Products(PU_Id, Result_On, Entry_On)
	SELECT	DISTINCT	ut.Master_Unit,
				r.FirstResultOn,
				r.FirstEntryOn
	FROM		@Results r
	JOIN		@UniqueTasks ut ON ut.VarId = r.Var_Id
	WHERE		r.TestFreq IS NULL ;

/*-- Retrieve the product that was running on each Master Unit at the creation time of each task*/
UPDATE	@Products
SET		Prod_Id = dbo.fnLocal_eCIL_GetCurrentProductFromHistory(PU_Id, Result_On, Entry_On);

/*-- Transfer the ProdIDs found for each Master Unit and assign it to all corresponding tasks*/
UPDATE	r
SET		ProdId = p.Prod_Id
FROM		@Results r
JOIN		@UniqueTasks ut ON r.Var_Id = ut.VarId
JOIN		@Products p ON (ut.Master_Unit = p.PU_Id) AND (p.Result_On = r.FirstResultOn) AND (p.Entry_On = r.FirstEntryOn)
WHERE		r.TestFreq IS NULL ;

/*-- Get the TestFreq that was effective at the time of the task creation*/
/*-- If there is no spec available at that time, we retrieve the first one available after that time*/
/*-- Only for tasks not having a UDP for their test frequency*/
UPDATE	r
SET		TestFreq =	(
							SELECT	TOP 1 vs.Test_Freq
							FROM		dbo.Var_Specs vs 
							WHERE		Var_Id = r.Var_Id
								AND		Prod_Id = r.ProdId
								AND		(
											(Expiration_Date IS NULL)
											OR
											(Expiration_Date > r.FirstResultOn)
										)
							ORDER BY	Effective_Date ASC
							)
FROM		@Results r
WHERE		r.TestFreq IS NULL ;

/*-- Get the TaskFreq Properties for each result*/
UPDATE	@Results
SET		TaskFreq = dbo.fnLocal_eCIL_GetTaskFreqCode (TestFreq) ;

/*-- Manage shiftly tasks*/
IF EXISTS(SELECT 1 FROM @Results WHERE TaskFreq = 'S')
	BEGIN
		/*-- Retrieve the beginning of the current shift for each shiftly result*/
		UPDATE	r
		SET		PeriodStart = (SELECT MAX(Start_Time) FROM dbo.Crew_Schedule cs  WHERE (cs.PU_Id = mu.STLSId) AND (Start_Time <= r.FirstResultOn))
		FROM		@Results r
		JOIN		@UniqueTasks ut ON ut.VarId = r.Var_Id
		JOIN		@SlaveUnits su ON su.SlaveUnitId = ut.PUId
		JOIN		@MasterUnits mu ON mu.MasterUnitId = su.MasterUnitId
		WHERE		r.TaskFreq = 'S';

		/*--Retrieve the beginning of the next shift for each each shiftly result*/
		UPDATE	r
		SET		MissedTime = (SELECT MIN(Start_Time) FROM dbo.Crew_Schedule cs  WHERE (cs.PU_Id = mu.STLSId) AND (Start_Time > r.PeriodStart))
		FROM		@Results r
		JOIN		@UniqueTasks ut ON ut.VarId = r.Var_Id
		JOIN		@SlaveUnits su ON su.SlaveUnitId = ut.PUId
		JOIN		@MasterUnits mu ON mu.MasterUnitId = su.MasterUnitId
		WHERE		r.TaskFreq = 'S';
	END

/*-- Manage daily tasks*/
IF EXISTS(SELECT 1 FROM @Results WHERE TaskFreq = 'D')
	BEGIN
		/*-- DateDiff(day, 0, @CurrentTime) will remove the time from @Now variable*/
		UPDATE	@Results
		SET		PeriodStart = DATEDIFF(DAY, 0, FirstResultOn)
		WHERE		TaskFreq = 'D';

		/*-- Retrieve the beginning of the current day, including Test Time*/
		UPDATE	r
		SET		PeriodStart = dbo.fnLocal_eCIL_GetDailyDueTime(r.PeriodStart, ut.TestTime)
		FROM		@Results r
		JOIN		@UniqueTasks ut ON ut.VarId = r.Var_Id
		WHERE		r.TaskFreq = 'D';

		/*-- Calculate PreviousMissedTime for each opened daily task*/
		UPDATE	@Results
		SET		MissedTime = DATEADD(HOUR, 24, PeriodStart)
		WHERE		TaskFreq = 'D';
	END

/*-- Manage Multi-Day tasks*/
IF EXISTS(SELECT 1 FROM @Results WHERE TaskFreq LIKE '%[0-9]D')
	BEGIN
		/*-- Get the FixedFrequency Properties for each variable*/
		UPDATE	@UniqueTasks
		SET		FixedFrequency = dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_FixedFrequency', 'Variables');

		/*--FO-04232: CIL task completion window should be extended during PR out line status*/
		/*-- Updated master unit and Fixed Freq to pass to function fnLocal_eCIL_GetMultiDayMissedTime for calculating the Missed time*/
		Update r 
		set Master_Unit = ot.Master_Unit
		FROM @Results r
		join @UniqueTasks ot on ot.VarId = r.Var_Id
		WHERE r.TaskFreq LIKE '%[0-9]D';

		Update r 
		set FixedFreq = ot.FixedFrequency
		FROM @Results r
		join @UniqueTasks ot on ot.VarId = r.Var_Id
		WHERE r.TaskFreq LIKE '%[0-9]D';

		/*--FO-04232: CIL task completion window should be extended during PR out line status*/
		/*-- Added new parameters to fnlocal_eCIL_GetMultiDayMissedTime*/
		/*-- Calculate the missed time*/
		UPDATE	@Results
		SET		MissedTime = dbo.fnLocal_eCIL_GetMultiDayMissedTime(FirstResultOn, TestFreq, FixedFreq, Master_Unit)
		WHERE		TaskFreq LIKE '%[0-9]D';

		/*--FO-04232: CIL task completion window should be extended during PR out line status*/
		/*-- Commented the below as it does not have required parameters for functionfnLocal_eCIL_GetMultiDayMissedTime*/
		/*-- Calculate missed time*/
		/*--UPDATE	@Results*/
		/*--SET		MissedTime = dbo.fnLocal_eCIL_GetMultiDayMissedTime(FirstResultOn, TestFreq)*/
		/*--WHERE		TaskFreq LIKE '%[0-9]D'--*/
	END

/*-- Manage Minutely tasks*/
IF EXISTS(SELECT 1 FROM @Results WHERE TaskFreq LIKE '%[0-9]M')
	BEGIN
		/*-- Get the FixedFrequency Properties for each variable*/
		UPDATE	@UniqueTasks
		SET		FixedFrequency = dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_FixedFrequency', 'Variables');

		/*-- Calculate missed time*/
		UPDATE	@Results
		SET		MissedTime = dbo.fnLocal_eCIL_GetMinuteMissedTime(FirstResultOn, TestFreq)
		WHERE		TaskFreq LIKE '%[0-9]M';
	END

/*-- Calculate LateTime for each task*/
UPDATE	@Results
SET		LateTime = dbo.fnLocal_eCIL_GetLateTime(FirstResultOn, TestFreq, MissedTime);

/*-- We don't need Tasks that are current and not due during the current shift*/
DELETE FROM @TasksList WHERE (VarId NOT IN (SELECT DISTINCT Var_Id FROM @Results));

/*-- Get misc information for the tasks to display*/
UPDATE		tl
SET			TaskId = dbo.fnLocal_STI_Cmn_GetUDP(tl.VarId, 'eCIL_TaskId', 'Variables'),
				VarDesc = v.Var_Desc,
				Duration = dbo.fnLocal_STI_Cmn_GetUDP(tl.VarId, 'eCIL_Duration', 'Variables'),
				LongTaskName = dbo.fnLocal_STI_Cmn_GetUDP(tl.VarId, 'eCIL_LongTaskName', 'Variables'),
				ExternalLink = v.External_Link,
				DisplayLink = COALESCE(dbo.fnLocal_STI_Cmn_GetUDP(tl.VarId, 'eCIL_DocumentLinkTitle', 'Variables'), v.External_Link),
				FL1 = dbo.fnLocal_eCIL_GetFL1(tl.VarId),
				FL2 = dbo.fnLocal_eCIL_GetFL2(tl.VarId),
				FL4 = dbo.fnLocal_eCIL_GetFL4(tl.VarId),
				FL3 = dbo.fnLocal_eCIL_GetFL3(tl.VarId),
				Event_Subtype_Desc=es.Event_Subtype_Desc
FROM			@TasksList tl
JOIN			dbo.Variables_Base v  ON v.Var_Id = tl.VarId
JOIN			dbo.Event_Subtypes es  ON v.Event_Subtype_Id=es.Event_Subtype_Id
JOIN			@Results r ON r.Var_Id = tl.VarId;

/**************************************************************/
/*--> Section modified by PD Dubois on May 12th 2010 for eCIL v.2.3.0*/
INSERT INTO @LastDefectsTests(Test_Id)
	SELECT	MAX(T.Test_Id) AS Test_Id
	FROM		dbo.Tests T 
	JOIN		@Results Res ON Res.Var_Id=T.Var_Id
	GROUP BY T.Var_Id;
				
UPDATE	r   
SET		IsDefectLocked = 1
FROM		@Results r
JOIN		@OpenedDefects od ON od.Test_Id = r.Test_Id
WHERE		r.Test_Id NOT IN (
									SELECT	Test_Id 
									FROM		@LastDefectsTests
									);

/**************************************************************/

/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]												SECTION 7 - Result				 		 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--*/

SELECT			tl.Event_Subtype_Desc,
				tl.ItemNo,
				su.SlaveUnitId,
				TestId = r.Test_Id,
				NbrDefects = ISNULL(od.NbrDefects, 0),
				tl.VarId,
				su.SlaveUnitDesc,
				mu.MasterUnitDesc,
				tl.TaskId,
				tl.VarDesc,
				r.TaskFreq,
				ut.TaskType,
				CurrentResult = r.Result,
				CommentId = r.Comment_Id,
				CommentInfo = r.Comment_Text,
				l.LineDesc,
				UserNameTest = u.Username,
				tl.Duration,
				tl.LongTaskName,
				tl.ExternalLink,
				tl.DisplayLink,
				tl.FL1,
				tl.FL2,
				tl.FL3,
				tl.FL4,
				l.LineId AS Pl_Id,
				tl.RouteDesc,
				tl.Tour_Stop_Desc,
				tl.Tour_Stop_Id,
				tl.TaskOrder AS TaskOrder,
				tl.TeamDesc,
				ut.FixedFrequency AS FixedFreq,
				ScheduleTime = CONVERT(CHAR(16), r.Result_On, 120),
				LateTime = CONVERT(CHAR(16), r.LateTime, 120),
				DueTime = CONVERT(CHAR(16), r.MissedTime, 120),
				TaskAction			=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_TaskAction', 'Variables'),
				Criteria			=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_Criteria', 'Variables'),
				Hazards				=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_Hazards', 'Variables'),
				Method				=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_Method', 'Variables'),
				PPE					=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_PPE', 'Variables'),
				Tools				=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_Tools', 'Variables'),
				Lubricant			=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_Lubricant', 'Variables'),
				QFactorType			=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'Q-Factor Type', 'Variables'),
				PrimaryQFactor		=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'Primary Q-Factor?', 'Variables'),
				NbrPeople			=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_NbrPeople', 'Variables'),
				NbrItems			=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_NbrItems', 'Variables'),
				HSEFlag				=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'HSE Flag', 'Variables'),
				ShiftOffset			=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'eCIL_ShiftOffset', 'Variables'),
				r.IsDefectLocked /*--> Added by PD Dubois on May 6th 2010 for eCIL v.2.3.0*/
FROM			@TasksList tl
JOIN			@UniqueTasks ut ON ut.VarId = tl.VarId
JOIN			@SlaveUnits su ON su.SlaveUnitId = ut.PUId
JOIN			@MasterUnits mu ON mu.MasterUnitId = su.MasterUnitId
JOIN			@Lines l ON l.LineId = mu.LineId
JOIN			@Results r ON r.Var_Id = ut.VarId
JOIN			dbo.Users_Base u  ON u.[User_Id] = r.[Entry_By]
LEFT JOIN	@OpenedDefects od ON od.Test_Id = r.Test_Id
WHERE			r.Test_Id IS NOT NULL
ORDER BY		NbrDefects DESC, r.MissedTime ASC, mu.MasterUnitDesc, su.SlaveUnitDesc, tl.TaskId ;

SET @Success = 1;

/* ----------------------------------------------------------------------------------------------------------------------
-- Version Management
---------------------------------------------------------------------------------------------------------------------- */
DECLARE @SP_Name	NVARCHAR(200) = 'spLocal_eCIL_GetTasksList',	
		@Version	NVARCHAR(20) = '9.3.4' ,
		@AppId		INT
 

UPDATE dbo.AppVersions 
       SET App_Version = @Version,
              Modified_On = GETDATE() 
       WHERE App_Name = @SP_Name;
IF @@ROWCOUNT = 0
BEGIN
       SELECT @AppId = ISNULL(MAX(App_Id) + 1 ,1) FROM dbo.AppVersions WITH(NOLOCK);
       INSERT INTO dbo.AppVersions (App_Id, App_name, App_version )
              VALUES (@AppId, @SP_Name, @Version);
END
