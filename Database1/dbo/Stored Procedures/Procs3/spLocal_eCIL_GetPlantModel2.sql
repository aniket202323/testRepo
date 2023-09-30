
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetPlantModel2]
/*
Stored Procedure		:		spLocal_eCIL_GetPlantModel2
Author					:		Normand Carbonneau (STICorp)
Date Created			:		17-Sep-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the list of Line(s), Master Unit(s) and Slave Unit(s) having eCIL Tasks
If we receive Pl_Id as parameter, returns for one line only.
If no parameter received, returns for all lines
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			27-Mar-2009		Normand Carbonneau		Creation of SP
1.1.0			27-Mar-2009		Linda Hudon				Added 2 new UDPs : LineVersion, ModuleFeature
1.1.1			11-Dec-2009		Linda Hudon				Retrieves all groups under a slave unit. Not only groups that contain variables
1.2.0			21-Feb-2010		Normand Carbonneau		Replaced fnCmn_UDPLookup by fnLocal_STI_Cmn_GetUDP
1.3.0			29-Apr-2010		Normand Carbonneau		The obsoleted tasks are now excluded by their Is_Active field set to 0 instead
																	of checking if the description starts by 'z_obs'
1.3.1			05-May-2010		PD Dubois				Modified the SELECT statements that were giving errors with the ORDER BY
1.3.2			04-Jun-2010		PD Dubois				Added Level=4 condition when getting variables. Somehow, PUG_Id and PU_Id were identical and causing the resulting tree to be badly shaped.
																	This solved the issue (Tasks showing up incorrectly in Plant Model tree in Task Management screen (http://sticorp.jira.com/browse/ECIL-162))		
1.4.0			17-Jun-2010		Normand Carbonneau		Now retrieves only the Master Units having the eCIL Event Subtype configured.
1.4.2			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.4.3			21-Oct-2010		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables 
1.4.4			19-April-2022		Megha Lohana                    Reverted back from Base table to view where necessary, since views have the local desc required
1.4.5			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.4.6 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.4.7			27-Jul-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard															
Test Code:
EXEC spLocal_eCIL_GetPlantModel2
EXEC spLocal_eCIL_GetPlantModel2 74
EXEC spLocal_eCIL_GetPlantModel2 74,145
EXEC spLocal_eCIL_GetPlantModel2 74,145,NULL
EXEC spLocal_eCIL_GetPlantModel2 NULL,NULL,3
*/
@UserId			INT = NULL,
@PLId			INT = NULL,
@LowerLevel		INT = NULL  /*--Area =0 , Line =1, Master =2, Slave =3 , Group=4, Variables =5 */

AS
SET NOCOUNT ON;

DECLARE
@eCILDataTypeId		INT,
@eCILDataTypeDesc	VARCHAR(50),
@EventSubTypeId		INT;

DECLARE @PlantModel TABLE
(
Id						INT IDENTITY(1,1),
ParentId				INT,
ItemId					INT,
ItemDesc				VARCHAR(50),
PLId					INT,
PLDesc					VARCHAR(50),
MasterUnitId			INT,
MasterUnitDesc			VARCHAR(50),
PUId					INT,
PUDesc					VARCHAR(50),
VarId					INT,
VarDesc					VARCHAR(50),
/*--DefectFlag			BIT,*/
Level					INT,
FL1						VARCHAR(30),
FL2						VARCHAR(30),
FL3						VARCHAR(30),
FL4						VARCHAR(30),
LocalDesc				VARCHAR(50),
GlobalDesc				VARCHAR(50),
LineVersion				VARCHAR(255),
ModuleFeature			VARCHAR(255)
);

DECLARE @LineList	TABLE
(
LineID					INT
);

DECLARE @EventSubtypes TABLE
(
EventSubtypeId			INT
);

SET @eCILDataTypeDesc =	'eCIL';

/*-- Get the eCIL Data Type Id */
SET @eCILDataTypeId =	(
								SELECT	Data_Type_Id
								FROM	dbo.Data_Type WITH (NOLOCK)
								WHERE	Data_Type_Desc = @eCILDataTypeDesc
						);
								
IF @eCILDataTypeId IS NULL
	
		RETURN ;


SET @EventSubTypeId =
	(
	SELECT	Event_SubType_Id
	FROM	dbo.Event_Subtypes WITH(NOLOCK)
	WHERE	Event_Subtype_Desc LIKE 'eCIL'
	);

IF @EventSubTypeId IS NULL

		RETURN;

	
SET @LowerLevel =  coalesce(@LowerLevel, 5);


/*-- Get the list of subtypes identifying the defect types */
INSERT @EventSubtypes	(
								EventSubtypeId
						)
	SELECT	Event_Subtype_Id 
	FROM	dbo.Event_Subtypes WITH(NOLOCK)
	WHERE	Extended_Info = 'DefectType';

/*-- Determine which we can show */
IF ISNULL(@PLId, 0) = 0
	BEGIN
		IF ISNULL(@UserId, 0) = 0
			BEGIN
				INSERT @LineList (
										LineID
								 )
						SELECT	Pl_Id
						FROM	dbo.Prod_Lines_Base	WITH(NOLOCK)
						WHERE	dbo.fnLocal_eCIL_Is_eCIL_Line(PL_Id) = 1;
			END
		ELSE
			BEGIN
				INSERT @LineList (
									LineID
								  )
					SELECT	PL_Id 
					FROM		dbo.fnLocal_eCIL_GetProdLinesForUser(@UserId, 1);
			END
	END

IF ISNULL(@PLId, 0) > 0
BEGIN
	IF ISNULL(@UserId, 0) = 0
			BEGIN
				INSERT @LineList (
										LineID
										)
					SELECT	@PLId;
			END
		ELSE
			BEGIN
				INSERT @LineList (
										LineID
										)
					SELECT	PL_Id 
					FROM		dbo.fnLocal_eCIL_GetProdLinesForUser(@UserId, 1)
					WHERE		PL_ID = @PLId ;
			END
END

/*--We Retrieve department for each Level */
IF	@LowerLevel <=5 
	BEGIN
		INSERT @PlantModel (
									ParentId, 
									ItemId, 
									ItemDesc, 
									[Level], 
									LocalDesc, 
									GlobalDesc
							)

			SELECT		DISTINCT 0, 
							d.Dept_Id, 
							d.Dept_Desc, 
							0, 
							d.Dept_Desc_Local, 
							d.Dept_Desc_Global
			FROM			dbo.Departments as d		WITH(NOLOCK)
			JOIN			dbo.Prod_Lines_Base as pl		WITH(NOLOCK)	ON d.Dept_Id = pl.Dept_Id
			JOIN			@LineList l								ON pl.PL_Id = l.LineId
			ORDER BY		d.Dept_Desc ASC,
							d.Dept_Id	ASC ;
	END

/*--We Retrieve Line For Line, Master, slave, group and Variables Level */
IF	@LowerLevel >=1 AND @LowerLevel <=5
	BEGIN
		INSERT @PlantModel	(
									ParentId, 
									ItemId, 
									ItemDesc, 
									[Level], 
									FL1, 
									LocalDesc, 
									GlobalDesc,	
									PlId,
									PlDesc
									)
			SELECT		DISTINCT	pm.Id, 
										pl.PL_Id, 
										pl.PL_Desc, 
										1, 
										dbo.fnLocal_STI_Cmn_GetUDP(pl.PL_Id, 'FL1', 'Prod_Lines'), 
										pl.PL_Desc_Local, 
										pl.PL_Desc_Global,
										pl.PL_Id, 
										pl.PL_Desc
			FROM			@PlantModel pm
			JOIN			dbo.Prod_Lines as pl	WITH(NOLOCK)ON (pm.ItemId = pl.Dept_Id)
																		AND
																		(pm.[Level] = 0)
			JOIN			@LineList l						ON pl.PL_Id = l.LineId
			ORDER BY		pl.PL_Desc		ASC,
							pl.PL_Id		ASC,
							pm.Id			ASC ;
	END

/*--We Retrieve Master Unit for  Master, slave, group and Variables  Level */
IF	@LowerLevel >=2 AND @LowerLevel <=5
	BEGIN
		INSERT @PlantModel	(
									ParentId, 
									ItemId, 
									ItemDesc, 
									[Level], 
									FL2, 
									LocalDesc, 
									GlobalDesc,
									MasterUnitId,
									MasterUnitDesc
									)

			SELECT	DISTINCT	pm.Id, 
									pum.PU_Id, 
									pum.PU_Desc, 
									2, 
									dbo.fnLocal_STI_Cmn_GetUDP(pum.PU_Id, 'FL2', 'Prod_Units'), 
									pum.PU_Desc_Local, 
									pum.PU_Desc_Global,
									pum.PU_Id, 
									pum.PU_Desc 
			FROM		@PlantModel pm
			JOIN		dbo.Prod_Units as pum			WITH(NOLOCK)	ON	(pm.ItemId = pum.PL_Id)
																					AND
																					(pm.[Level] = 1)
			JOIN		dbo.Event_Configuration as ec	WITH(NOLOCK)	ON	pum.Pu_Id =	ec.Pu_Id
			WHERE		pum.PU_Id > 0
			AND		(pum.Master_unit IS NULL)
			AND		ec.Event_Subtype_Id	= @EventSubTypeId					
			ORDER BY	pum.PU_Desc ASC,
						pum.PU_Id	ASC,
						pm.Id		ASC ;
	END


/*--We Retrieve Slave Unit for slave, group and Variables  Level */
IF	@LowerLevel >=3 AND @LowerLevel <=5
	BEGIN
			INSERT @PlantModel	(
										ParentId, 
										ItemId, 
										ItemDesc, 
										[Level], 
										FL3, 
										LocalDesc, 
										GlobalDesc,
										PuId,
										PuDesc
										)
				SELECT	DISTINCT	pm.Id, 
										pu.PU_Id, 
										pu.PU_Desc, 
										3, 
										dbo.fnLocal_STI_Cmn_GetUDP(pu.PU_Id, 'FL3', 'Prod_Units'), 
										pu.PU_Desc_Local, 
										pu.PU_Desc_Global,
										pu.PU_Id, 
										pu.PU_Desc
				FROM		@PlantModel pm
				JOIN		dbo.Prod_Units as pu	WITH(NOLOCK)ON (pm.ItemId = pu.Master_Unit)
																		AND
																		(pm.[Level] = 2)
				WHERE		pu.PU_Id > 0
				ORDER BY	pu.PU_Desc		ASC,
							pu.PU_Id		ASC,
							pm.Id			ASC ;
	END

/*--We Retrieve Group for group and Variables  Level */
IF	@LowerLevel >=4 AND @LowerLevel <=5
	BEGIN
		INSERT @PlantModel	(
									ParentId, 
									ItemId, 
									ItemDesc, 
									[Level], 
									FL4, 
									LocalDesc, 
									GlobalDesc
									)
			SELECT	DISTINCT	pm.Id, 
									pug.PUG_Id, 
									pug.PUG_Desc, 
									4, 
									dbo.fnLocal_STI_Cmn_GetUDP(pug.PUG_Id, 'FL4', 'PU_Groups'), 
									pug.PUG_Desc_Local, 
									pug.PUG_Desc_Global
			FROM		@PlantModel pm
			JOIN		dbo.PU_Groups pug	WITH(NOLOCK)ON (pm.ItemId = pug.PU_Id)
																	AND
																	(pm.[Level] = 3)
			ORDER BY	pug.PUG_Desc	ASC,
						pug.PUG_Id		ASC, 
						pm.Id			ASC ;
	END

/*--We Retrieve Variables only for variables level */
IF	@LowerLevel =5
	BEGIN
		INSERT @PlantModel	(
									ParentId, 
									ItemId, 
									ItemDesc, 
									[Level],
									VarId,
									VarDesc
									)
			SELECT	DISTINCT	pm.Id, 
									v.Var_Id, 
									v.Var_Desc, 
									5,
									v.Var_Id, 
									v.Var_Desc
			FROM		@PlantModel pm
			JOIN		dbo.Variables_Base as v	WITH(NOLOCK)	ON pm.ItemId = v.PUG_Id
			WHERE		(v.Data_Type_Id = @eCILDataTypeId)
			AND		v.Is_Active = 1
			AND		(v.PU_Id > 0)
			AND		(pm.[Level] = 4) /*--> Added by PDD 2010-06-04 */
			ORDER BY	v.Var_Desc		ASC,
						v.Var_Id		ASC, 
						pm.Id			ASC ;
	END
		
/*-- Update eCIL_LineVersion */
UPDATE	@PlantModel
SET		LineVersion	= dbo.fnLocal_STI_Cmn_GetUDP(ItemId, 'eCIL_LineVersion', 'Prod_Lines')
WHERE		[Level] = 1;


/*-- Update eCIL_ModuleFeatureVersion */
UPDATE	@PlantModel
SET		ModuleFeature = dbo.fnLocal_STI_Cmn_GetUDP(ItemId, 'eCIL_ModuleFeatureVersion', 'Prod_Units')
WHERE		[Level] = 3;

SELECT	Id, 
			ParentId, 
			[Level], 
			ItemId,
			ItemDesc, 
			PLId, 
			PLDesc, 
			MasterUnitId, 
			MasterUnitDesc, 
			PUId, 
			PUDesc, 
			VarId, 
			VarDesc, 
			/*--DefectFlag,  */
			FL1, 
			FL2, 
			FL3, 
			FL4, 
			LocalDesc, 
			GlobalDesc,
			LineVersion,
			ModuleFeature
FROM		@PlantModel;

