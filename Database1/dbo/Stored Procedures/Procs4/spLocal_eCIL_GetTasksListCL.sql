
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetTasksListCL]	
/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_eCIL_GetTasksListCL
Author				:		Shashank Das
Date Created		:		10-13-2022
SP Type				:			

Description:
=========
Get the list of Centerline variables(s) for specific route Id(s):


CALLED BY:  OpsHub

Revision 		Date			Who						What
========		=====			====					=====
1.0.0			13-Oct-2022		Shashank Das		Creation of SP
1.0.1			05-Dec-2022		Shashank Das		Added Display link
1.0.2			15-Dec-2022		Shashank Das		Added parameter for Tour Stop Description and Tour Stop Id
1.0.3			02-Jan-2023		Shashank Das		Modify SP to display variables with OOL values.
1.0.4			11-Jan-2022		Shashank Das		Modify SP to convert specification Varchar values to Numeric values to compare the limits in the JOIN condition.
1.0.5			27-Jan-2023		Shashank Das		Added field Result On.
1.0.6			28-Jan-2023		Shashank Das		Updated to grant permissions to role instead of local user
1.0.7			13-Feb-2023		Shashank Das		Removed non-required input parameters
1.0.8			22-Feb-2023		Shashank Das		Code review changes
1.0.9			14-Mar-2023		Shashank Das		Added check for SpecificationSetting Site Parameter
1.0.10			20-Mar-2023		Shashank Das		Added all the specification validations
1.0.11			27-Apr-2023		Shashank Das		Added an upsert operation to the AppVersions table that does a single scan on an update and does two for insert.
1.0.12 			03-May-2023     Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script

*/
@RoutesList			VARCHAR(8000)	= NULL


AS
SET NOCOUNT ON;

/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
  --[]																	[]--
  --[]							SECTION 1 - Variables Declaration		[]--
  --[]																	[]--
  --[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]-- */

DECLARE
@Now					DATETIME=GETDATE(),

@CLEventTypeManual		INT,
@CLEventTypeMonthly		INT,
@CLEventTypeWeekly		INT,
@CLEventTypeQuarterly		INT,
@SpecSetting			VARCHAR(200);

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
VarDataType				VARCHAR(50),
TaskId					VARCHAR(50),	
VarDesc					VARCHAR(50),	
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
TaskType				VARCHAR(15),	
TestTime				VARCHAR(5),		
FixedFrequency			VARCHAR(50)		
);

DECLARE @Results TABLE (
Test_Id					BIGINT,			
Var_Id					INT,
PU_Id					INT,
Master_Unit				INT,
FixedFreq				INT,			
Result_On				DATETIME,		
FirstResultOn			DATETIME,		
Entry_On				DATETIME,		
FirstEntryOn			DATETIME,		
Result					VARCHAR(25),	
Comment_Id				INT,			
Comment_Text			TEXT,			
Entry_By				INT,
ProdId					INT,
PeriodStart				DATETIME,
PeriodEnd				DATETIME,
TestFreq				VARCHAR(7),		
TaskFreq				VARCHAR(50),	
LateTime				DATETIME,
MissedTime				DATETIME,
IsDefectLocked			BIT DEFAULT 0,
TargetLimit					VARCHAR(50),	
L_Rej					VARCHAR(50),	
U_Rej					VARCHAR(50)	
);

/* -- This table will hold the list of products at each distinct time of results of variables */

DECLARE @Products TABLE
(
PU_Id					INT,
Result_On				DATETIME,
Entry_On				DATETIME,
Prod_Id					INT
);

/**************************************************************/

/**************************************************************/


/* -- Get the Event SubType ID for CL Event SubTypes */


SET @CLEventTypeManual = (SELECT Event_Subtype_Id FROM dbo.Event_Subtypes  WHERE Event_Subtype_Desc = 'RTT Manual');
SET @CLEventTypeMonthly = (SELECT Event_Subtype_Id FROM dbo.Event_Subtypes  WHERE Event_Subtype_Desc = 'RTT CPE Monthly');
SET @CLEventTypeWeekly = (SELECT Event_Subtype_Id FROM dbo.Event_Subtypes  WHERE Event_Subtype_Desc = 'RTT CPE Weekly');
SET @CLEventTypeQuarterly = (SELECT Event_Subtype_Id FROM dbo.Event_Subtypes  WHERE Event_Subtype_Desc = 'RTT CPE Quarterly');

/*-- Check the value for Site Parameter SpecificationSetting */

SET @SpecSetting = (SELECT f.field_desc from dbo.site_parameters s
				   JOIN dbo.parameters p on s.parm_id=p.parm_id
                   JOIN dbo.ed_fieldtype_validvalues f on f.ed_field_type_id = p.field_type_id and f.field_id = s.value
				   WHERE p.Parm_Long_Desc like '%spec%');
/* 
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]								SECTION 2 - Creation of Modules list					 []--
--[]																						 []--
--[]  We can receive a list of Depts, Lines, Master Units or Slave Units as parameter.		 []--
--[]  We have to get the list of all Slave Units being part of any item of this list.		 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[]--
 */


IF @RoutesList IS NOT NULL
		INSERT @TasksList (VarId, RouteDesc, TaskOrder,Tour_Stop_Desc,Tour_Stop_Id)
			SELECT	DISTINCT rt.Var_Id, r.Route_Desc, rt.Task_Order,ts.Tour_Stop_Desc,ts.Tour_Stop_Id
			FROM		dbo.Local_PG_eCIL_RouteTasks rt	
			JOIN		dbo.Local_PG_eCIL_Routes r		 ON rt.Route_Id = r.Route_Id
			LEFT JOIN	dbo.Local_PG_eCIL_TourStops ts  ON rt.Tour_Stop_Id = ts.Tour_Stop_Id
			JOIN		dbo.variables_base vb   ON vb.Var_Id=rt.Var_Id
			WHERE		rt.Route_Id IN (SELECT String FROM dbo.fnLocal_STI_Cmn_SplitString(@RoutesList, ','))
			And vb.Event_Subtype_Id in (@CLEventTypeManual,@CLEventTypeMonthly,@CLEventTypeWeekly,@CLEventTypeQuarterly);


/* 
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]										SECTION 3 - Misc Information					 []--
--[]																						 []--
--[]						Get all information necessary before Tasks selection			 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
 */
/* -- Identify unique tasks to improve task retrieval performances */
INSERT INTO @UniqueTasks (VarId)
	SELECT	DISTINCT	VarId
	FROM		@TasksList	;

/* --Remove the duplicate variables FROM @TaskList table */
WITH CTE AS
(
SELECT *,ROW_NUMBER() OVER (PARTITION BY varid ORDER BY varid,RouteDesc desc,TeamDesc desc) AS RN
FROM @TasksList
)
DELETE FROM CTE WHERE RN<>1;

/* -- Identify the master unit for each task */
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

/* -- Retrieve the STLS unit for each master unit */
UPDATE	@MasterUnits
SET		STLSId = dbo.fnLocal_PG_Cmn_GetSTLSUnit(MasterUnitId);

INSERT @Lines (LineId, LineDesc)
	SELECT	Pl_Id, Pl_Desc
	FROM		dbo.Prod_Lines_Base 
	WHERE		Pl_Id IN (SELECT DISTINCT LineId FROM @MasterUnits);


INSERT @Results(Test_Id, Var_Id, Result_On, Entry_On, Result, Comment_Id, Comment_Text, Entry_By,TargetLimit,L_Rej,U_Rej)
			SELECT		t.Test_Id,
						t.Var_Id,
						t.Result_On,
						CONVERT(VARCHAR(19), t.Entry_On, 120),
						t.Result,
						t.Comment_Id,
						c.Comment_Text,
						t.Entry_By,
						vs.Target,
						vs.L_Reject,
						vs.U_Reject
							
						FROM			dbo.Tests t		
						JOIN			@TasksList tl ON tl.VarId=t.Var_Id
						LEFT JOIN	dbo.Comments c		 ON t.Comment_Id = c.Comment_Id
						JOIN			@UniqueTasks ut ON ut.VarId = tl.VarId
						JOIN			@SlaveUnits su ON su.SlaveUnitId = ut.PUId
						JOIN			@MasterUnits mu ON mu.MasterUnitId = su.MasterUnitId
						JOIN			dbo.Var_Specs vs  ON  vs.Var_Id=tl.VarId
						JOIN			dbo.Production_Starts ps  ON ut.Master_Unit=ps.PU_Id
						WHERE t.Result_On in (Select max(scc.Result_On) FROM  dbo.Sheet_Columns scc 
						JOIN dbo.sheets s ON s.Sheet_Id=scc.Sheet_Id
						WHERE  s.Sheet_Id in (Select Distinct sv.sheet_id FROM dbo.Sheet_Variables sv 
						JOIN @TasksList tl ON tl.VarId=sv.Var_Id
						JOIN dbo.sheets s ON sv.Sheet_Id=s.sheet_id
						WHERE s.Event_Subtype_Id in (@CLEventTypeManual,@CLEventTypeMonthly,@CLEventTypeWeekly,@CLEventTypeQuarterly))
						GROUP BY scc.Sheet_Id) and (t.Result is null or (t.Result is not null and vs.Target is not null and t.Result<>vs.Target and vs.L_Reject is null and vs.U_Reject is null) or (t.Result is not null and vs.L_Reject is not null and vs.U_Reject is not null ) or (t.Result is not null and (vs.L_Reject is not null or vs.U_Reject is not null) ))
						and t.Canceled=0	and vs.Expiration_Date is null and  ps.End_Time is null and vs.Prod_Id=ps.Prod_Id ;				 
		
	IF CHARINDEX('=', @SpecSetting) >0
		BEGIN
			DELETE FROM  @Results
			WHERE ISNUMERIC(Result)=1 and  ISNUMERIC(L_Rej)=1 and  ISNUMERIC(U_Rej)=1  and Convert(Float,Result) >Convert(Float,L_Rej) and Convert(Float,Result) <Convert(Float,U_Rej);
			DELETE FROM  @Results
			WHERE ISNUMERIC(Result)=1 and  ISNUMERIC(L_Rej)=1 and  U_Rej is null  and Convert(Float,Result) >Convert(Float,L_Rej);
			DELETE FROM  @Results
			WHERE ISNUMERIC(Result)=1 and  ISNUMERIC(U_Rej)=1 and  L_Rej is null  and Convert(Float,Result) <Convert(Float,U_Rej);
			DELETE FROM  @Results
			WHERE Result=TargetLimit and TargetLimit is not null and L_Rej is not null and U_Rej is not null;
		END 
	ELSE
	BEGIN
			DELETE FROM  @Results
			WHERE ISNUMERIC(Result)=1 and  ISNUMERIC(L_Rej)=1 and  ISNUMERIC(U_Rej)=1  and Convert(Float,Result) >=Convert(Float,L_Rej) and Convert(Float,Result) <=Convert(Float,U_Rej);
			DELETE FROM  @Results
			WHERE ISNUMERIC(Result)=1 and  ISNUMERIC(L_Rej)=1 and  U_Rej is null  and Convert(Float,Result) >=Convert(Float,L_Rej);
			DELETE FROM  @Results
			WHERE ISNUMERIC(Result)=1 and  ISNUMERIC(U_Rej)=1 and  L_Rej is null  and Convert(Float,Result) <=Convert(Float,U_Rej);
			DELETE FROM  @Results
			WHERE Result=TargetLimit and TargetLimit is not null and L_Rej is not null and U_Rej is not null;
		END 

	UPDATE r 
	SET TaskFreq='Daily'
	FROM @Results r
	JOIN dbo.Table_Fields_Values tfv 
	ON tfv.KeyId=r.Var_Id
	JOIN  dbo.Table_Fields tf on tf.Table_Field_Id =tfv.Table_Field_Id
	JOIN dbo.Variables_Base vb  on vb.Var_Id=r.Var_Id
    WHERE tf.Table_Field_Desc='RTT_TestTime' and vb.Event_Subtype_Id=@CLEventTypeManual ;

	UPDATE r 
	SET TaskFreq='Quarterly'
	FROM @Results r
	JOIN dbo.Variables_Base vb  on vb.Var_Id=r.Var_Id
    WHERE vb.Event_Subtype_Id=@CLEventTypeQuarterly ;

	UPDATE r 
	SET TaskFreq='Weekly'
	FROM @Results r
	JOIN dbo.Variables_Base vb  on vb.Var_Id=r.Var_Id
    WHERE vb.Event_Subtype_Id=@CLEventTypeWeekly	;

	UPDATE r 
	SET TaskFreq='Monthly'
	FROM @Results r
	JOIN dbo.Variables_Base vb  on vb.Var_Id=r.Var_Id
    WHERE vb.Event_Subtype_Id=@CLEventTypeMonthly	;

	UPDATE r 
	SET TaskFreq='Shiftly Manual'
	FROM @Results r
	WHERE TaskFreq is null ;
	
/**************************************************************/

	UPDATE tl
	SET VarDesc=vb.Var_Desc,
	Event_Subtype_Desc=es.Event_Subtype_Desc,
	ExternalLink = vb.External_Link,
	DisplayLink = vb.External_Link,
	FL1 = dbo.fnLocal_eCIL_GetFL1(tl.VarId),
	FL2 = dbo.fnLocal_eCIL_GetFL2(tl.VarId),
	FL4 = dbo.fnLocal_eCIL_GetFL4(tl.VarId),
	FL3 = dbo.fnLocal_eCIL_GetFL3(tl.VarId),
	VarDataType=dt.Data_Type_Desc
	FROM @TasksList tl
	JOIN dbo.variables_base vb  ON  vb.Var_Id=tl.VarId
	JOIN dbo.Event_Subtypes es  ON vb.Event_Subtype_Id=es.Event_Subtype_Id
	JOIN @Results r ON r.Var_Id = tl.VarId
	JOIN dbo.Data_Type dt  ON vb.Data_Type_Id=dt.Data_Type_Id ;
/* 
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]												SECTION 7 - Result				 		 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
 */
SELECT		tl.Event_Subtype_Desc,
			tl.ItemNo,
			su.SlaveUnitId,
			TestId = r.Test_Id,
			NbrDefects = Null,
			tl.VarId,
			tl.VarDataType,
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
			ScheduleTime=CONVERT(CHAR(16), r.Entry_On, 120),
			LateTime =NULL,
			DueTime =NULL,
			TaskAction	=NULL,
			Criteria	=NULL,
			Hazards		=NULL,
			Method	=NULL	,
			PPE			=NULL,
			Tools		=NULL,
			Lubricant	=NULL,
			
			QFactorType			=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'Q-Factor Type', 'Variables'),
			PrimaryQFactor		=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'Primary Q-Factor?', 'Variables'),
			NbrPeople	=NULL,
			NbrItems	=NULL,
			HSEFlag				=	dbo.fnLocal_STI_Cmn_GetUDP(ut.VarId, 'HSE Flag', 'Variables'),
			ShiftOffset=NULL,
			r.IsDefectLocked, 
			vs.Test_Freq,
			vs.L_Reject,
			vs.Target,
			vs.U_Reject ,
			ResultOn=DateAdd(second,DATEDIFF(second, GETDATE(), GETUTCDATE()), r.Result_On)

			FROM			@TasksList tl
			JOIN			@UniqueTasks ut ON ut.VarId = tl.VarId
			JOIN			@SlaveUnits su ON su.SlaveUnitId = ut.PUId
			JOIN			@MasterUnits mu ON mu.MasterUnitId = su.MasterUnitId
			JOIN			@Lines l ON l.LineId = mu.LineId
			JOIN			@Results r ON r.Var_Id = ut.VarId
			JOIN			dbo.Users_Base u  ON u.[User_Id] = r.[Entry_By]
			JOIN			dbo.Variables_Base vb  ON  tl.VarId=vb.Var_Id
			JOIN			dbo.Var_Specs vs  ON  vs.Var_Id=vb.Var_Id
			JOIN			dbo.Production_Starts ps  ON ut.Master_Unit=ps.PU_Id
			WHERE           r.Test_Id IS NOT NULL and vs.Expiration_Date is null and  ps.End_Time is null and vs.Prod_Id=ps.Prod_Id
			ORDER BY		tl.TaskId ;


