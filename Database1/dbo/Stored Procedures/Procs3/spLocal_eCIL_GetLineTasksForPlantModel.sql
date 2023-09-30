
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetLineTasksForPlantModel]
/*
Stored Procedure		:		spLocal_eCIL_GetLineTasksForPlantModel
Author					:		Normand Carbonneau (STICorp)
Date Created			:		15-May-2010
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			15-May-2010		Normand Carbonneau		Creation of SP
1.0.1			04-Jun-2010		PD Dubois				Added Level=4 condition when getting variables. Somehow, PUG_Id and PU_Id were identical and causing the resulting tree to be badly shaped.
																		This solved the issue (Tasks showing up incorrectly in Plant Model tree in Task Management screen (http://sticorp.jira.com/browse/ECIL-162))		
1.1.0			17-Jun-2010		Normand Carbonneau		Now retrieves only the Master Units having the eCIL Event Subtype configured.
																		We also display only Slave Units and Groups if there are eCIL variables in those.
1.1.2			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.1.3			20-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
1.1.4			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.1.5 			02-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.1.6			04-Jul-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard
Test Code:
EXEC spLocal_eCIL_GetLineTasksForPlantModel '125, 159'
*/
@LineIds		VARCHAR(7000)

AS
SET NOCOUNT ON;

DECLARE
@eCILDataTypeId		INT,
@eCILDataTypeDesc	VARCHAR(50),
@EventSubTypeId		INT;

DECLARE @PlantModel TABLE
(
Id					INT IDENTITY(1,1),
ParentId			INT,
ItemId				INT,
ItemDesc			VARCHAR(50),
[Level]				INT,
Line				VARCHAR(50),
MasterUnit			VARCHAR(50),
SlaveUnit			VARCHAR(50),
[Group]				VARCHAR(50),
LineId				INT					/* The LineId information is used in the application to be able to delete */
											/* all rows of a DataTable, regardless of the level (Delete an entire Prod Line from Tree) */
);

DECLARE @LinesList	TABLE
(
PKey				INT IDENTITY(1,1),
LineId				INT
);

SET @eCILDataTypeDesc =	'eCIL';

/* Get the eCIL Data Type Id */
SET @eCILDataTypeId =	(
								SELECT	Data_Type_Id
								FROM		dbo.Data_Type WITH (NOLOCK)
								WHERE		Data_Type_Desc = @eCILDataTypeDesc
						);
								
IF @eCILDataTypeId IS NULL
	
		RETURN;
	

SET @EventSubTypeId =
	(
	SELECT	Event_SubType_Id
	FROM		dbo.Event_Subtypes WITH(NOLOCK)
	WHERE		Event_Subtype_Desc LIKE 'eCIL'
	);

IF @EventSubTypeId IS NULL
	
		RETURN;
	

/* Determine the list of lines to include in the Plant Model */
INSERT @LinesList (LineID)
	SELECT	String
	FROM	dbo.fnLocal_STI_Cmn_SplitString(@LineIds, ',');
	

/*We Retrieve Lines Level */
INSERT @PlantModel	(
							ItemId, 
							ItemDesc, 
							[Level],
							LineId
					)
	SELECT		DISTINCT	pl.PL_Id, 
								pl.PL_Desc, 
								1,
								pl.PL_Id
	FROM			dbo.Prod_Lines_Base as pl WITH(NOLOCK)
	JOIN			@LinesList l		ON pl.PL_Id = l.LineId
	ORDER BY		pl.PL_Desc	ASC,
					pl.PL_Id		ASC;

/*This is to make sure that the Line Level has itself as parent */
UPDATE	@PlantModel
SET		ParentId = Id ;

/*We Retrieve Master Units Level */
INSERT @PlantModel	(
							ParentId, 
							ItemId, 
							ItemDesc, 
							[Level],
							LineId
							)

	SELECT	DISTINCT	pm.Id, 
							pum.PU_Id, 
							pum.PU_Desc, 
							2,
							pm.LineId
	FROM		@PlantModel pm
	JOIN		dbo.Prod_Units_Base as pum	WITH(NOLOCK)	ON	(pm.ItemId = pum.PL_Id)
																			AND
																			(pm.[Level] = 1)
	JOIN		dbo.Event_Configuration as ec	WITH(NOLOCK)	ON	pum.Pu_Id =	ec.Pu_Id	
	WHERE		pum.PU_Id > 0
	AND		(pum.Master_unit IS NULL)
	AND		ec.Event_Subtype_Id	= @EventSubTypeId					
	ORDER BY	pum.PU_Desc ASC,
				pum.PU_Id	ASC,
				pm.Id			ASC;
				
/*We Retrieve Slave Units Level */
INSERT @PlantModel	(
							ParentId, 
							ItemId, 
							ItemDesc, 
							[Level],
							LineId
							)
	SELECT	DISTINCT	pm.Id, 
							pu.PU_Id, 
							pu.PU_Desc, 
							3,
							pm.LineId
	FROM		@PlantModel pm
	JOIN		dbo.Prod_Units_Base as pu WITH(NOLOCK)	ON (pm.ItemId = pu.Master_Unit)
																AND
																(pm.[Level] = 2)
	JOIN		dbo.Variables_Base as v	WITH(NOLOCK)	ON pu.PU_Id = v.PU_Id
	WHERE		pu.PU_Id > 0
	AND		v.Data_Type_Id = @eCILDataTypeId
	AND		v.Is_Active = 1
	ORDER BY	pu.PU_Desc ASC,
				pu.PU_Id	ASC,
				pm.Id			ASC;


/*We Retrieve Production Groups Level */
INSERT @PlantModel	(
							ParentId, 
							ItemId, 
							ItemDesc, 
							[Level],
							LineId
							)
	SELECT	DISTINCT	pm.Id, 
							pug.PUG_Id, 
							pug.PUG_Desc, 
							4,
							pm.LineId
	FROM		@PlantModel pm
	JOIN		dbo.PU_Groups as pug	WITH(NOLOCK)	ON (pm.ItemId = pug.PU_Id)
																AND
																(pm.[Level] = 3)
	JOIN		dbo.Variables_Base as v	WITH(NOLOCK)	ON pug.PUG_Id = v.PUG_Id
	WHERE		v.Data_Type_Id = @eCILDataTypeId
	AND		v.Is_Active = 1
	ORDER BY	pug.PUG_Desc	ASC,
				pug.PUG_Id		ASC,
				pm.Id				ASC;
				
/*We Retrieve Variables Level*/
INSERT @PlantModel	(
							ParentId, 
							ItemId, 
							ItemDesc, 
							[Level],
							Line,
							MasterUnit,
							SlaveUnit,
							[Group],
							LineId
							)
	SELECT	DISTINCT	pm.Id, 
							v.Var_Id, 
							v.Var_Desc, 
							5,
							pl.PL_Desc,
							pum.PU_Desc,
							pus.PU_Desc,
							pug.PUG_Desc,
							pm.LineId
	FROM		@PlantModel pm
	JOIN		dbo.Variables_Base as v		WITH(NOLOCK)	ON pm.ItemId = v.PUG_Id
	JOIN		dbo.PU_Groups as pug		WITH (NOLOCK)	ON v.PUG_Id = pug.PUG_Id
	JOIN		dbo.Prod_Units_Base as pus	WITH (NOLOCK)	ON v.PU_Id = pus.PU_Id
	JOIN		dbo.Prod_Units_Base as pum	WITH (NOLOCK)	ON	pus.Master_Unit = pum.PU_Id
	JOIN		dbo.Prod_Lines_Base as  pl	WITH (NOLOCK)	ON pum.PL_Id = pl.PL_Id
	WHERE		v.Data_Type_Id = @eCILDataTypeId
	AND		v.Is_Active = 1
	AND		v.PU_Id > 0
	AND		(pm.[Level] = 4) /*--> Added by PDD 2010-06-04*/
	ORDER BY	pl.PL_Desc		ASC,
				pum.PU_Desc		ASC,
				pus.PU_Desc		ASC,
				pug.PUG_Desc	ASC,
				v.Var_Desc		ASC,
				v.Var_Id			ASC;
				
SELECT			Id, 
				ParentId, 
				[Level], 
				ItemId,
				ItemDesc, 
				TaskOrder	=	NULL,
				Selected	=	0,
				Line,
				MasterUnit,
				SlaveUnit,
				[Group],
				LineId
FROM			@PlantModel pm ;

