
CREATE PROCEDURE [dbo].[spLocal_eCIL_TasksManagement]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_eCIL_TasksManagement
Author				:		Linda	Hudon (STICorp)
Date Created		:		2009-10-13
SP Type				:			
Editor Tab Spacing	:		3
Description:
=========
Get all eCIL tasks information of the Ids(DepartmentDesc,LineDesc, unit, ProductionGroupDesc) received as parameter.
CALLED BY:  eCIL Web Application
Revision 		Date			Who						What
========		=====			====					=====
1.0.0			2009-10-13		Linda Hudon				SP Creation
1.1.0			2009-10-20		Linda Hudon				Add two new UDPs (eCIL_VMId and eCIL_TaskLocation)
1.1.1			2009-10-20		Linda Hudon				Added isnull for document link path
2.0.0			2009-11-05		Linda Hudon				Changed the name of several fields in the return resultset
2.1.0			2009-12-09		Normand Carbonneau		Added IDs of Plant Model items as they are required in DataSource od ComboBoxes
2.2.0			29-Apr-2010		Normand Carbonneau		The obsoleted tasks are now excluded by their Is_Active field set to 0 instead
																	of checking if the description starts by 'z_obs'
2.3.0			08-May-2010		Normand Carbonneau		UDP Change :	QValue -> Q-Factor Type
																						QPriority -> Primary Q-Factor?																
2.3.1			2010-05-26		Beno�t Saenz de Ugarte	Add LineVersion and ModuleFeatureVersion to the last SELECT
2.4.0			17-Jun-2010		Normand Carbonneau		Now retrieves only the Master Units having the eCIL Event Subtype configured.
2.4.1			03-Aug-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
2.5.0			01-Jan-2018		Ben Lee					Load HSE Flag
2.5.1			17-Oct-2022		Payal Gadhvi			Added condition to get CL/RTT varaibles, update version to app version, instead of drop used alter script
2.5.2			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
2.5.3			13-Feb-2022		Payal Gadhvi			Added condition to not show RTT Auto variables (Task ID- 6934)
2.5.4 			03-May-2023     Aniket B				Remove grant permissions statement from the SP as moving it to permissions grant script
2.5.5			09-May-2023		Payal Gadhvi			Added an upsert operations to the AppVersions table that does a single scan on an update and does 2 for insert, removed WITH encryption, updated to block comments 
Test Call :
select pl_id, pl_desc from prod_Lines
select prop_Id, prop_Desc from product_Properties where prop_Desc like '%eCIL%'
EXEC spLocal_eCIL_TasksManagement null, NULL, 995, NULL,NULL,NULL
*/
@DeptsList		VARCHAR(8000) = NULL,
@LinesList		VARCHAR(8000) = NULL,
@MastersList	VARCHAR(8000) = NULL,
@SlavesList		VARCHAR(8000) = NULL,
@GroupsList		VARCHAR(8000) = NULL,
@VarsList		VARCHAR(8000) = NULL

AS
SET NOCOUNT ON;

/*[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
--[]																	[]--
--[]							SECTION 1 - Variables Declaration		[]--
--[]																	[]--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--*/

DECLARE @TasksList TABLE(
VarID					int PRIMARY KEY,	/*-- Make sure we do not have duplicates*/
TaskDesc				varchar(50),
DepartmentDesc			varchar(50),
DepartmentId			int,
LineDesc				varchar(50),
LineId					int,
MasterUnitDesc			varchar(50),
MasterUnitId			int,
SlaveUnitDesc			varchar(50),
SlaveUnitId				int,
ProductionGroupDesc		varchar(50),
ProductionGroupId		int,
DocumentLinkPath		varchar(255));

/*get ec id for eCIL and RTT Manual, RTT Weekly, RTT Monthly and RTT Quarterly */
DECLARE @EventSubtypes TABLE(
Event_subtype_id INT,
Event_subtype_desc VARCHAR(50)
);

INSERT @EventSubtypes(Event_subtype_id ,Event_subtype_desc) SELECT  Event_Subtype_Id,Event_Subtype_Desc 
FROM dbo.Event_Subtypes WHERE Event_Subtype_Desc IN ('RTT Manual','RTT CPE Weekly','RTT CPE Monthly','RTT CPE Quarterly','eCIL');

/*--if there aren't any eCIL or RTT events then exit the SP*/

IF NOT EXISTS (SELECT * FROM @EventSubtypes)

	BEGIN
		RETURN;
	END
	
IF @DeptsList IS NOT NULL
	BEGIN
		INSERT @TasksList	(
								VarId,
								TaskDesc,
								DepartmentDesc,
								DepartmentId,
								LineDesc,
								LineId,
								MasterUnitDesc,
								MasterUnitId,
								SlaveUnitDesc,
								SlaveUnitId,
								ProductionGroupDesc,
								ProductionGroupId,
								DocumentLinkPath
								)
			SELECT			v.Var_Id,
								v.Var_Desc,
								d.Dept_Desc,
								d.Dept_Id,
								pl.pl_Desc,
								pl.PL_Id,
								pum.Pu_Desc,
								pum.PU_Id,
								pus.Pu_Desc,
								pus.PU_Id,
								pug.Pug_Desc,
								pug.PUG_Id,
								v.External_Link		
			FROM				dbo.Variables_Base v		WITH (NOLOCK)	
			JOIN				dbo.Pu_Groups pug	WITH (NOLOCK)	ON v.PUG_Id	= pug.PUG_Id
			JOIN				dbo.Prod_Units_Base pus	WITH (NOLOCK)	ON v.Pu_Id = pus.Pu_Id
			JOIN				dbo.Prod_Units_Base pum	WITH (NOLOCK)	ON pum.Pu_Id = pus.Master_Unit
			JOIN				dbo.Prod_Lines_Base pl	WITH (NOLOCK)	ON pum.Pl_ID =	pl.Pl_ID
			JOIN				dbo.Departments_Base d	WITH (NOLOCK)	ON pl.Dept_Id = d.Dept_Id			
			JOIN				dbo.fnLocal_STI_Cmn_SplitString(@DeptsList, ',') dl ON d.Dept_Id = CONVERT(INT, dl.String)
			WHERE				v.Event_Subtype_Id IN (SELECT Event_Subtype_Id FROM @EventSubtypes)
			AND				v.PU_Id > 0
			AND				v.Is_Active = 1;
END

IF @LinesList IS NOT NULL
	BEGIN
		INSERT @TasksList	(
								VarId,
								TaskDesc,
								DepartmentDesc,
								DepartmentId,
								LineDesc,
								LineId,
								MasterUnitDesc,
								MasterUnitId,
								SlaveUnitDesc,
								SlaveUnitId,
								ProductionGroupDesc,
								ProductionGroupId,
								DocumentLinkPath
								)
				SELECT		v.Var_Id,
								v.Var_Desc,
								d.Dept_Desc,
								d.Dept_Id,
								pl.pl_Desc,
								pl.PL_Id,
								pum.Pu_Desc,
								pum.PU_Id,
								pus.Pu_Desc,
								pus.PU_Id,
								pug.Pug_Desc,
								pug.PUG_Id,
								v.External_Link	
				FROM			dbo.Variables_Base v		WITH (NOLOCK)	
				JOIN			dbo.Pu_Groups pug	WITH (NOLOCK)	ON v.PUG_Id	= pug.PUG_Id
				JOIN			dbo.Prod_Units_Base pus	WITH (NOLOCK)	ON v.Pu_Id = pus.Pu_Id
				JOIN			dbo.Prod_Units_Base pum	WITH (NOLOCK)	ON pum.Pu_Id = pus.Master_Unit
				JOIN			dbo.Prod_Lines_Base pl	WITH (NOLOCK)	ON pum.Pl_ID =	pl.Pl_ID
				JOIN			dbo.Departments_Base d	WITH (NOLOCK)	ON pl.Dept_Id = d.Dept_Id
				JOIN			dbo.fnLocal_STI_Cmn_SplitString(@LinesList, ',') ll ON pl.PL_Id = CONVERT(INT, ll.String)
				WHERE			v.Event_Subtype_Id IN (SELECT Event_Subtype_Id FROM @EventSubtypes)
				AND			v.PU_Id > 0
				AND			v.Is_Active = 1;
	END

IF @MastersList IS NOT NULL
	BEGIN
		INSERT @TasksList	(
								VarId,
								TaskDesc,
								DepartmentDesc,
								DepartmentId,
								LineDesc,
								LineId,
								MasterUnitDesc,
								MasterUnitId,
								SlaveUnitDesc,
								SlaveUnitId,
								ProductionGroupDesc,
								ProductionGroupId,
								DocumentLinkPath
								)
				SELECT		v.Var_Id,
								v.Var_Desc,
								d.Dept_Desc,
								d.Dept_Id,
								pl.pl_Desc,
								pl.PL_Id,
								pum.Pu_Desc,
								pum.PU_Id,
								pus.Pu_Desc,
								pus.PU_Id,
								pug.Pug_Desc,
								pug.PUG_Id,
								v.External_Link
				FROM			dbo.Variables_Base v				WITH (NOLOCK)	
				JOIN			dbo.PU_Groups  pug			WITH (NOLOCK)	ON v.PUG_Id = pug.PUG_Id
				JOIN			dbo.Prod_Units_Base pus			WITH (NOLOCK)	ON v.Pu_Id = pus.Pu_Id
				JOIN			dbo.Prod_Units_Base pum			WITH (NOLOCK)	ON pum.Pu_Id = pus.Master_Unit
				JOIN			dbo.Event_Configuration ec	WITH (NOLOCK)	ON	pum.Pu_Id =	ec.Pu_Id
				JOIN			dbo.Prod_Lines_Base pl			WITH (NOLOCK)	ON pum.Pl_ID =	pl.Pl_ID
				JOIN			dbo.Departments_Base d			WITH (NOLOCK)	ON pl.Dept_Id = d.Dept_Id
				JOIN			dbo.fnLocal_STI_Cmn_SplitString(@MastersList, ',') ml ON pum.PU_Id = CONVERT(INT, ml.String)
				WHERE			v.Event_Subtype_Id IN (SELECT Event_Subtype_Id FROM @EventSubtypes) 
				AND			ec.Event_Subtype_Id	IN (SELECT Event_Subtype_Id FROM @EventSubtypes)
				AND			v.PU_Id > 0
				AND			v.Is_Active = 1;
	END

IF @SlavesList IS NOT NULL
	BEGIN
		INSERT @TasksList	(
								VarId,
								TaskDesc,
								DepartmentDesc,
								DepartmentId,
								LineDesc,
								LineId,
								MasterUnitDesc,
								MasterUnitId,
								SlaveUnitDesc,
								SlaveUnitId,
								ProductionGroupDesc,
								ProductionGroupId,
								DocumentLinkPath
								)
				SELECT		v.Var_Id,
								v.Var_Desc,
								d.Dept_Desc,
								d.Dept_Id,
								pl.pl_Desc,
								pl.PL_Id,
								pum.Pu_Desc,
								pum.PU_Id,
								pus.Pu_Desc,
								pus.PU_Id,
								pug.Pug_Desc,
								pug.PUG_Id,
								v.External_Link
				FROM			dbo.Variables_Base v		WITH (NOLOCK)	
				JOIN			dbo.Pu_Groups pug	WITH (NOLOCK)	ON v.PUG_Id	= pug.PUG_Id
				JOIN			dbo.Prod_Units_Base pus	WITH (NOLOCK)	ON v.Pu_Id = pus.Pu_Id
				JOIN			dbo.Prod_Units_Base pum	WITH (NOLOCK)	ON pum.Pu_Id = pus.Master_Unit
				JOIN			dbo.Prod_Lines_Base pl	WITH (NOLOCK)	ON pum.Pl_ID =	pl.Pl_ID
				JOIN			dbo.Departments_Base d	WITH (NOLOCK)	ON pl.Dept_Id = d.Dept_Id
				JOIN			dbo.fnLocal_STI_Cmn_SplitString(@SlavesList, ',') sl ON pus.PU_Id = CONVERT(INT, sl.String)
				WHERE			v.Event_Subtype_Id IN (SELECT Event_Subtype_Id FROM @EventSubtypes)
				AND			v.PU_Id > 0
				AND			v.Is_Active = 1;
	END

IF @GroupsList IS NOT NULL
	BEGIN
		INSERT @TasksList	(
								VarId,
								TaskDesc,
								DepartmentDesc,
								DepartmentId,
								LineDesc,
								LineId,
								MasterUnitDesc,
								MasterUnitId,
								SlaveUnitDesc,
								SlaveUnitId,
								ProductionGroupDesc,
								ProductionGroupId,
								DocumentLinkPath
								)
				SELECT		v.Var_Id,
								v.Var_Desc,
								d.Dept_Desc,
								d.Dept_Id,
								pl.pl_Desc,
								pl.PL_Id,
								pum.Pu_Desc,
								pum.PU_Id,
								pus.Pu_Desc,
								pus.PU_Id,
								pug.Pug_Desc,
								pug.PUG_Id,
								v.External_Link
				FROM			dbo.Variables_Base v		WITH (NOLOCK)	
				JOIN			dbo.Pu_Groups pug	WITH (NOLOCK)	ON v.PUG_Id	= pug.PUG_Id
				JOIN			dbo.Prod_Units_Base pus	WITH (NOLOCK)	ON v.Pu_Id = pus.Pu_Id
				JOIN			dbo.Prod_Units_Base pum	WITH (NOLOCK)	ON pum.Pu_Id = pus.Master_Unit
				JOIN			dbo.Prod_Lines_Base pl	WITH (NOLOCK)	ON pum.Pl_ID =	pl.Pl_ID
				JOIN			dbo.Departments_Base d	WITH (NOLOCK)	ON pl.Dept_Id = d.Dept_Id
				JOIN			dbo.fnLocal_STI_Cmn_SplitString(@GroupsList, ',') gl ON pug.PUG_Id = CONVERT(INT, gl.String)
				WHERE			v.Event_Subtype_Id IN (SELECT Event_Subtype_Id FROM @EventSubtypes)
				AND			v.PU_Id > 0
				AND			v.Is_Active = 1;
	END

IF @VarsList IS NOT NULL
	BEGIN
		INSERT @TasksList	(
								VarId,
								TaskDesc,
								DepartmentDesc,
								DepartmentId,
								LineDesc,
								LineId,
								MasterUnitDesc,
								MasterUnitId,
								SlaveUnitDesc,
								SlaveUnitId,
								ProductionGroupDesc,
								ProductionGroupId,
								DocumentLinkPath
								)
				SELECT		v.Var_Id,
								v.Var_Desc,
								d.Dept_Desc,
								d.Dept_Id,
								pl.pl_Desc,
								pl.PL_Id,
								pum.Pu_Desc,
								pum.PU_Id,
								pus.Pu_Desc,
								pus.PU_Id,
								pug.Pug_Desc,
								pug.PUG_Id,
								v.External_Link
				FROM			dbo.Variables_Base v		WITH (NOLOCK)	
				JOIN			dbo.Pu_Groups pug	WITH (NOLOCK)	ON v.PUG_Id = pug.PUG_Id
				JOIN			dbo.Prod_Units_Base pus	WITH (NOLOCK)	ON v.Pu_Id = pus.Pu_Id
				JOIN			dbo.Prod_Units_Base pum	WITH (NOLOCK)	ON pum.Pu_Id = pus.Master_Unit
				JOIN			dbo.Prod_Lines_Base pl	WITH (NOLOCK)	ON pum.Pl_ID =	pl.Pl_ID
				JOIN			dbo.Departments_Base d	WITH (NOLOCK)	ON pl.Dept_Id = d.Dept_Id
				JOIN			dbo.fnLocal_STI_Cmn_SplitString(@VarsList, ',') vl ON v.Var_Id = CONVERT(INT, vl.String)
				WHERE			v.Event_Subtype_Id IN (SELECT Event_Subtype_Id FROM @EventSubtypes)
				AND			v.PU_Id > 0
				AND			v.Is_Active = 1;
		END

SELECT	VarId,
			DepartmentDesc,
			DepartmentId,
			LineDesc,
			LineId,
			MasterUnitDesc,
			MasterUnitId,
			SlaveUnitDesc,
			SlaveUnitId,
			ProductionGroupDesc,
			ProductionGroupId,
			TaskDesc,
			FL1						=	dbo.fnLocal_eCIL_GetFL1(VarId),
			FL2						=	dbo.fnLocal_eCIL_GetFL2(VarId),
			FL3						=	dbo.fnLocal_eCIL_GetFL3(VarId),
			FL4						=	dbo.fnLocal_eCIL_GetFL4(VarId),
			LongTaskName			=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_LongTaskName', 'Variables'),
			TaskId					=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_TaskId', 'Variables'),
			TaskAction				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_TaskAction', 'Variables'),
			KeyId					=	'',
			TaskType				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_TaskType', 'Variables'),
			NbrItems				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_NbrItems', 'Variables'),
			Duration				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_Duration', 'Variables'),
			NbrPeople				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_NbrPeople', 'Variables'),
			Criteria				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_Criteria', 'Variables'),
			Hazards					=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_Hazards', 'Variables'),
			Method					=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_Method', 'Variables'),
			PPE						=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_PPE', 'Variables'),
			Tools					=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_Tools', 'Variables'),
			Lubricant				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_Lubricant', 'Variables'),
			DocumentLinkPath,
			DocumentLinkTitle		=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_DocumentLinkTitle', 'Variables'),
			QFactorType				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'Q-Factor Type', 'Variables'),
			PrimaryQFactor			=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'Primary Q-Factor?', 'Variables'),
			FixedFrequency			=  dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_FixedFrequency', 'Variables'),
			TaskFrequency			=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_TaskFrequency', 'Variables'),
			/*-- Returned only for Raw Data Export --*/
			ScheduleScope			=	NULL,
			/*---------------------------------------*/
			StartDate				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_StartDate', 'Variables'),
			/*-- Returned only for Raw Data Export --*/
			LineVersion				=	dbo.fnLocal_STI_Cmn_GetUDP(LineID, 'eCIL_LineVersion', 'Prod_Lines'),
			ModuleFeatureVersion	=	dbo.fnLocal_STI_Cmn_GetUDP(SlaveUnitId, 'eCIL_ModuleFeatureVersion', 'Prod_Units'),
			/*---------------------------------------*/
			TestTime				=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_TestTime', 'Variables'),
			VMId					=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_VMId', 'Variables'),
			TaskLocation			=	dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_TaskLocation', 'Variables'),
			HSEFlag					=   dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'HSE Flag', 'Variables'),
			ShiftOffset				=   dbo.fnLocal_STI_Cmn_GetUDP(VarId, 'eCIL_ShiftOffset', 'Variables')
FROM		@TasksList	tl				
ORDER BY	DepartmentDesc ASC,
			LineDesc ASC,
			MasterUnitDesc ASC,
			SlaveUnitDesc ASC,
			ProductionGroupDesc ASC,
			TaskDesc ASC;

/* -------------------------------------------------------------------------------------------------------------------
-- Version Management
---------------------------------------------------------------------------------------------------------------------- */
DECLARE @SP_Name	NVARCHAR(200) = 'spLocal_eCIL_TasksManagement',	
		@Version	NVARCHAR(20) = '2.5.5' ,
		@AppId		INT = 0;

UPDATE dbo.AppVersions 
       SET App_Version = @Version,
              Modified_On = GETDATE() 
       WHERE App_Name = @SP_Name;
IF @@ROWCOUNT = 0
BEGIN
       SELECT @AppId = ISNULL(MAX(App_Id) + 1 ,1) FROM dbo.AppVersions WITH(NOLOCK);
       INSERT INTO dbo.AppVersions (App_Id, App_name, App_version)
              VALUES (@AppId, @SP_Name, @Version);
END