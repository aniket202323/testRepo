
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetPlantModelByFL]
/*
Stored Procedure		:		spLocal_eCIL_GetPlantModelByFL
Author					:		Normand Carbonneau (STICorp)
Date Created			:		18-Aug-2009
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
1.1.0			09-Oct-2009		Linda Hudon				Added Level Type field
1.1.1			11-Dec-2009		Linda Hudon				Added Distinct FL2 from Master Unit List
																	(This was causing a "Subquery returned more than 1 value" error).
2.0.0			06-Jan-2010		Normand Carbonneau		Removed @UserId and @PLId parameters no longer used.
																	Added DISTINCT clause to FL3 retrieval. (This was causing a "Subquery returned more than 1 value" error).
2.1.0			29-Apr-2010		Normand Carbonneau		The obsoleted tasks are now excluded by their Is_Active field set to 0 instead
																	of checking if the description starts by 'z_obs'
2.1.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script																		
2.1.2			8-Feb-2016		Megha Lohana(TCS)		FO-02059- Used temporary tables in SP instead of the table variables to decrease the execution time																		
2.1.3			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
2.1.4			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
2.1.5 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
2.1.6			27-Jul-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard	
SELECT pl_id, pl_desc FROM prod_Lines
Test Code:
EXEC spLocal_eCIL_GetPlantModelByFL
*/

AS
SET NOCOUNT ON;

DECLARE
@eCILDataTypeId		INT,
@eCILDataTypeDesc	VARCHAR(50);

/*--FO-02059- Used temporary tables in SP instead of the table variables to decrease the execution time	*/
/*DECLARE @PlantModel TABLE
(
Id					INT IDENTITY(1,1),
ParentId			INT,
ItemID				INT,
ItemDesc			VARCHAR(50),
FLPath				VARCHAR(255),
LevelType			VARCHAR(50),
DefectFlag			BIT,
[Level]				INT
)
DECLARE @Lines TABLE
(
PLId				INT,
PLDesc				VARCHAR(50),
FL1					VARCHAR(50),
ParentId			INT DEFAULT 0,
ReturnListId		INT
)
DECLARE @MasterUnits TABLE
(
PUId				INT,
PUDesc				VARCHAR(50),
FL2					VARCHAR(50),
PLId				INT,
ParentId			INT,
ReturnListId		INT
)
DECLARE @SlaveUnits TABLE
(
PUId				INT,
PUDesc				VARCHAR(50),
FL3					VARCHAR(50),
MasterUnit			INT,
ParentId			INT,
ReturnListId		INT
)
DECLARE @Groups TABLE
(
PUGId				INT,
PUGDesc				VARCHAR(50),
FL4					VARCHAR(50),
PUId				INT,
ParentId			INT,
ReturnListId		INT
)
DECLARE @Variables TABLE
(
VarId				INT,
VarDesc				VARCHAR(50),
PUGId				INT,
PUId				INT,
ParentId			INT,
[Level]				INT,
ReturnListId		INT
)*/

Create Table #PlantModel
(
Id					INT IDENTITY(1,1),
ParentId			INT,
ItemID				INT,
ItemDesc			VARCHAR(50),
FLPath				VARCHAR(255),
LevelType			VARCHAR(50),
DefectFlag			BIT,
[Level]				INT
);

Create Table #Lines
(
PLId				INT,
PLDesc				VARCHAR(50),
FL1					VARCHAR(50),
ParentId			INT DEFAULT 0,
ReturnListId		INT
);

Create Table #MasterUnits
(
PUId				INT,
PUDesc				VARCHAR(50),
FL2					VARCHAR(50),
PLId				INT,
ParentId			INT,
ReturnListId		INT
);

Create Table #SlaveUnits
(
PUId				INT,
PUDesc				VARCHAR(50),
FL3					VARCHAR(50),
MasterUnit			INT,
ParentId			INT,
ReturnListId		INT
);

Create Table #Groups
(
PUGId				INT,
PUGDesc				VARCHAR(50),
FL4					VARCHAR(50),
PUId				INT,
ParentId			INT,
ReturnListId		INT
);

Create Table #Variables
(
VarId				INT,
VarDesc				VARCHAR(50),
PUGId				INT,
PUId				INT,
ParentId			INT,
[Level]				INT,
ReturnListId		INT
);

DECLARE @EventSubtypes TABLE
(
EventSubtypeId	INT
) ;

SET @eCILDataTypeDesc =	'eCIL' ;

/*-- Get the eCIL Data Type Id */
SET @eCILDataTypeId =	(
								SELECT	Data_Type_Id
								FROM		dbo.Data_Type WITH (NOLOCK)
								WHERE		Data_Type_Desc = @eCILDataTypeDesc
								) ;
								
IF @eCILDataTypeId IS NULL
	
		RETURN ;


/*-- Get the list of subtypes identifying the defect types */
INSERT @EventSubtypes (EventSubtypeId)
	SELECT	Event_Subtype_Id
	FROM		dbo.Event_Subtypes WITH (NOLOCK)
	WHERE		Extended_Info = 'DefectType' ;

INSERT #Lines		(
						PLId, 
						PLDesc, 
						FL1
						)
	SELECT	DISTINCT	PL_Id, 
							PL_Desc, 
							dbo.fnLocal_STI_Cmn_GetUDP(PL_Id, 'FL1', 'Prod_Lines')
	FROM		dbo.Prod_Lines_Base	WITH(NOLOCK)
	WHERE		dbo.fnLocal_eCIL_Is_eCIL_Line(PL_Id) = 1 ;

DELETE FROM #Lines WHERE FL1 IS NULL ;

INSERT #MasterUnits (
							PUId, 
							PUDesc, 
							FL2, 
							PLId
							)
	SELECT	DISTINCT	pum.PU_Id, 
							pum.PU_Desc, 
							dbo.fnLocal_STI_Cmn_GetUDP(pum.PU_Id, 'FL2', 'Prod_Units'), 
							pl.PLId
	FROM		dbo.Prod_Units_Base as pum WITH(NOLOCK)
	JOIN		#Lines pl ON pum.PL_Id = pl.PLId
	WHERE		Master_Unit IS NULL ;

DELETE FROM #MasterUnits WHERE FL2 IS NULL ;

INSERT #SlaveUnits (
							PUId, 
							PUDesc, 
							FL3, 
							MasterUnit
							)
	SELECT	DISTINCT	pus.PU_Id, 
							pus.PU_Desc, 
							dbo.fnLocal_STI_Cmn_GetUDP(pus.PU_Id, 'FL3', 'Prod_Units'), 
							pum.PUId
	FROM		dbo.Prod_Units_Base as pus	WITH(NOLOCK)
	JOIN		#MasterUnits pum ON pus.Master_Unit = pum.PUId
	WHERE		Master_Unit IS NOT NULL ;

DELETE FROM #SlaveUnits WHERE FL3 IS NULL ;

/*-- We only want groups having eCIL variables in them */
INSERT #Groups (
					PUGId, 
					PUGDesc, 
					FL4, 
					PUId
					)
	SELECT	pug.PUG_Id, 
				PUG_Desc, 
				dbo.fnLocal_STI_Cmn_GetUDP(pug.PUG_Id, 'FL4', 'PU_Groups'), 
				pus.PUId
	FROM		dbo.PU_Groups pug	WITH(NOLOCK)
	JOIN		#SlaveUnits pus ON pug.PU_Id = pus.PUId
	WHERE		EXISTS(	SELECT	1 
							FROM		dbo.Variables_Base WITH(NOLOCK)
							WHERE		(PUG_Id = pug.PUG_Id)
							AND		(Data_Type_Id = @eCILDataTypeId)
							AND		Is_Active = 1
						) ;

INSERT #Variables (
						VarId, 
						VarDesc, 
						PUGId, 
						PUId
						)
	SELECT	v.Var_Id, 
				v.Var_Desc, 
				v.PUG_Id, 
				v.PU_Id
	FROM		dbo.Variables_Base as v	WITH(NOLOCK)
	JOIN		#SlaveUnits s ON v.PU_Id = s.PUId
	WHERE		(v.Data_Type_Id = @eCILDataTypeId)
	AND			v.Is_Active = 1 ;


/*-- Insert the Lines information in the Return Table */
INSERT #PlantModel (
							ParentId,
							ItemDesc, 
							[Level],
							LevelType
						)
	SELECT DISTINCT	0,
							FL1,
							0,
							'FL1'
	FROM	#Lines ;

/*-- Update the Lines table with the unique ID coming from the Return Table */
UPDATE	l
SET		ReturnListId =	(
								SELECT	Id
								FROM		#PlantModel
								WHERE		([Level] = 0)
								AND		(ItemDesc = FL1)
								AND		(ParentId = l.ParentId)
								)
FROM		#Lines l ;

/*-- Indicates the ParentId for each row of the Master Units table */
UPDATE	mu
SET		ParentId =	l.ReturnListId
FROM		#MasterUnits mu
JOIN		#Lines l ON mu.PLId = l.PLId ;

/* -- Insert the Master Units information in the Return Table */
INSERT #PlantModel (
							ParentId, 
							ItemDesc, 
							[Level],
							LevelType
						  )
	SELECT DISTINCT	ParentId,
							FL2,
							1,
							'FL2'
	FROM	#MasterUnits ;

/*-- Update the Master Units table with the unique ID coming from the Return Table */
UPDATE	mu
SET		ReturnListId =	(
								SELECT	Id
								FROM		#PlantModel
								WHERE		([Level] = 1)
								AND		(ItemDesc = FL2)
								AND		(ParentId = mu.ParentId)
								)
FROM		#MasterUnits mu ;

/*-- Indicates the ParentId for each row of the Slave Units table */
UPDATE	su
SET		ParentId =	mu.ReturnListId
FROM		#SlaveUnits su
JOIN		#MasterUnits mu ON su.MasterUnit = mu.PUId ;

/*-- Insert the Slave Units information in the Return Table */
INSERT #PlantModel (
							ParentId, 
							ItemDesc, 
							[Level],
							LevelType
						 )
	SELECT DISTINCT	ParentId,
							FL3,
							2,
							'FL3'
	FROM	#SlaveUnits ;

/*-- Update the Slave Units table with the unique ID coming from the Return Table */
UPDATE	su
SET		ReturnListId = (
								SELECT	Id
								FROM		#PlantModel
								WHERE		([Level] = 2)
								AND		(ItemDesc = FL3)
								AND		(ParentId = su.ParentId)
								)
FROM		#SlaveUnits su ;

/*-- Indicates the ParentId for each row of the Production Groups table */
UPDATE	pug
SET		ParentId =	su.ReturnListId
FROM		#Groups pug
JOIN		#SlaveUnits su ON pug.PUId = su.PUId ;

/*-- Insert the Production Groups information in the Return Table
-- Groups having no FL4 should not appear in the TreeView
-- But we cannot delete them because there could be variables under those groups
-- Those variables will be added directly under the Slave Unit level (FL1-FL2-FL3)*/
INSERT #PlantModel	(
							ParentId, 
							ItemDesc, 
							[Level],
							LevelType
							)
	SELECT DISTINCT	ParentId,
							FL4,
							3,
							'FL4'
	FROM	#Groups
	WHERE	FL4 IS NOT NULL ;

/*-- Update the Production Groups table with the unique ID coming from the Return Table*/
UPDATE	pug
SET		ReturnListId =	(
								SELECT	Id
								FROM		#PlantModel
								WHERE		([Level] = 3)
								AND		(ItemDesc = FL4)
								AND		(ParentId = pug.ParentId)
								)
FROM		#Groups pug ;

/*-- Indicates the ParentId for each row of the Variables table */
UPDATE		v
SET			ParentId =	CASE
									WHEN	pug.FL4 IS NOT NULL	THEN pug.ReturnListId
									WHEN	su.FL3 IS NOT NULL	THEN su.ReturnListId
									ELSE	su.ReturnListId
								END,
				[Level]		=	4								
FROM			#Variables v
LEFT JOIN	#Groups pug ON v.PUGId = pug.PUGId
JOIN			#SlaveUnits su ON v.PUId = su.PUId;

/*-- Insert the Variables information in the Return Table */
INSERT #PlantModel (
							ParentId, 
							ItemDesc, 
							[Level],
							LevelType
					)
	SELECT	ParentId,
				VarDesc,
				[Level],
				'Variable'
	FROM		#Variables

SELECT		Id, 
				ParentId, 
				ItemDesc, 
				FLPath, 
				[Level], 
				LevelType 
FROM			#PlantModel 
ORDER BY		[Level] ASC, 
				ItemDesc ASC ;
				
				
Drop table #PlantModel;
Drop table #Lines;
Drop table #MasterUnits;
Drop table #SlaveUnits;
Drop table #Groups;
Drop table #Variables;

