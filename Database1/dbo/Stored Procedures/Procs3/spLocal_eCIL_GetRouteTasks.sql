
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetRouteTasks]
/*
Stored Procedure		:		spLocal_eCIL_GetRouteTasks
Author					:		Normand Carbonneau (STICorp)
Date Created			:		17-Sep-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the list of Line(s), Master Unit(s) and Slave Unit(s) having eCIL Tasks
If we receive Pl_Id AS parameter, returns for one line only.
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
1.3.1			05-May-2010		PD Dubois				Modified the SELECT statements that were giving errors with the DISTINCT
																		without ORDER BY IN SQL 2005
1.3.2			04-Jun-2010		PD Dubois				Added Level=4 condition when getting variables. Somehow, PUG_Id and PU_Id were identical and causing the resulting tree to be badly shaped.
																		This solved the issue (Tasks showing up incorrectly IN Plant Model tree IN Task Management screen (http://sticorp.jira.com/browse/ECIL-162))		
1.4.0			17-Jun-2010		Normand Carbonneau		Now retrieves only the Master Units having the eCIL Event Subtype configured.
																		We also display only Slave Units and Groups if there are eCIL variables IN those.
1.5.0			16-Aug-2010		Normand Carbonneau		Obsoleted tasks will now be displayed AS part of the route, allowing the user to remove them.
																		ECIL-226.
1.5.1			27-Oct-2010     Nilesh Panpaliya		Uncommented is_active condition when fetching data at variables level.
                                                                        This solved the issue (Obsoleted tasks are showing up IN Route Task Association screen.)
1.5.2			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.5.3			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
1.5.4			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables 
1.5.5			18-Oct-2022		Payal Gadhvi			Added condition to consider CL variables based on event subtype,Added app versions update,  ANSI_NULL OFF
1.5.6			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.5.7 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.5.8			09-May-2023		Payal Gadhvi			Added an upsert operations to the AppVersions table that does a single scan on an update and does 2 for insert, removed WITH encryption, updated to block comments 
Test Code:
EXEC spLocal_eCIL_GetRouteTasks 75
EXEC spLocal_eCIL_GetRouteTasks 51, '125, 159'
*/
@RouteId		INT,
@LineIds		VARCHAR(7000) = NULL
AS
SET NOCOUNT ON;

/*--get ec id for eCIL and RTT events */
DECLARE @EventSubtypes TABLE(
EventSubTypeId INT,
EventSubTypeDesc VARCHAR(50)
);

INSERT @EventSubtypes(EventSubTypeId ,EventSubTypeDesc) SELECT  Event_Subtype_Id,Event_Subtype_Desc 
FROM Event_Subtypes WHERE Event_Subtype_Desc like '%RTT%' OR Event_Subtype_Desc like 'eCIL';

/*--if there aren't any eCIL or RTT events then exit the SP */

IF NOT EXISTS (SELECT * FROM @EventSubtypes)

	BEGIN
		RETURN;
	END


DECLARE @PlantModel TABLE
(
Id						INT IDENTITY(1,1),
ParentId				INT,
ItemId					INT,
ItemDesc				VARCHAR(50),
[Level]					INT,
Line					VARCHAR(50),
MasterUnit				VARCHAR(50),
SlaveUnit				VARCHAR(50),
[Group]					VARCHAR(50),
LineId					INT					/*-- The LineId information is used IN the application to be able to delete
											-- all rows of a DataTable, regardless of the level (Delete an entire Prod Line from Tree)*/
);

DECLARE @LinesList	TABLE
(
PKey					INT IDENTITY(1,1),
LineId					INT
);

/*-- Determine the list of lines to include IN the Plant Model */
INSERT @LinesList (LineID)
	SELECT	String
	FROM		dbo.fnLocal_STI_Cmn_SplitString(@LineIds, ',');

INSERT @LinesList (LineId)
	SELECT		pl.PL_Id
	FROM			dbo.Prod_Lines_Base AS pl						WITH (NOLOCK)
	JOIN			dbo.Prod_Units_Base AS pu						WITH (NOLOCK)	ON pl.PL_Id = pu.PL_Id
	JOIN			dbo.Variables_Base AS v							WITH (NOLOCK)	ON pu.PU_Id = v.PU_Id
	JOIN			dbo.Local_PG_eCIL_RouteTasks AS rt			WITH (NOLOCK)	ON v.Var_Id = rt.Var_Id
	WHERE			rt.Route_Id = @RouteId
	AND			pl.PL_Id NOT IN	(
											SELECT	LineId
											FROM		@LinesList
											)
	GROUP BY		pl.PL_Id;
	
/*--We Retrieve Lines Level */
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
	FROM			dbo.Prod_Lines_Base AS pl	WITH(NOLOCK)
	JOIN			@LinesList l		ON pl.PL_Id = l.LineId
	ORDER BY		pl.PL_Desc		ASC,
					pl.PL_Id		ASC;

/*-- This is to make sure that the Line Level has itself AS parent*/
UPDATE	@PlantModel
SET		ParentId = Id;

/*--We Retrieve Master Units Level */
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
	JOIN		dbo.Prod_Units_Base AS pum			WITH(NOLOCK)	ON	(pm.ItemId = pum.PL_Id)
																			AND
																			(pm.[Level] = 1)
	JOIN		dbo.Event_Configuration AS ec	WITH(NOLOCK)	ON	pum.Pu_Id =	ec.Pu_Id
	WHERE		pum.PU_Id > 0
	AND		(pum.Master_unit IS NULL)
	AND		ec.Event_Subtype_Id	IN (SELECT EventSubtypeId FROM @EventSubtypes)				
	ORDER BY	pum.PU_Desc ASC,
				pum.PU_Id	ASC,
				pm.Id		ASC;
				
/*--We Retrieve Slave Units Level */
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
	JOIN		dbo.Prod_Units_Base AS pu	WITH(NOLOCK)	ON (pm.ItemId = pu.Master_Unit)
																AND
																(pm.[Level] = 2)
	JOIN		dbo.Variables_Base AS v		WITH(NOLOCK)	ON pu.PU_Id = v.PU_Id
	WHERE		pu.PU_Id > 0
	AND		v.Event_Subtype_Id IN (SELECT EventSubtypeId FROM @EventSubtypes)
	AND		v.Is_Active = 1
	ORDER BY	pu.PU_Desc	ASC,
				pu.PU_Id	ASC,
				pm.Id		ASC;


/*--We Retrieve Production Groups Level*/
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
	JOIN		dbo.PU_Groups pug	WITH(NOLOCK)	ON (pm.ItemId = pug.PU_Id)
																AND
																(pm.[Level] = 3)
	JOIN		dbo.Variables_Base AS v		WITH(NOLOCK)	ON pug.PUG_Id = v.PUG_Id
	WHERE		v.Event_Subtype_Id IN (SELECT EventSubtypeId FROM @EventSubtypes)
	AND		v.Is_Active = 1
	ORDER BY	pug.PUG_Desc	ASC,
				pug.PUG_Id		ASC,
				pm.Id			ASC;
				
/*--We Retrieve Variables Level*/
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
	JOIN		dbo.Variables_Base AS v		WITH(NOLOCK)	ON pm.ItemId = v.PUG_Id
	JOIN		dbo.PU_Groups AS pug		WITH (NOLOCK)	ON v.PUG_Id = pug.PUG_Id
	JOIN		dbo.Prod_Units_Base AS pus	WITH (NOLOCK)	ON v.PU_Id = pus.PU_Id
	JOIN		dbo.Prod_Units_Base AS pum	WITH (NOLOCK)	ON	pus.Master_Unit = pum.PU_Id
	JOIN		dbo.Prod_Lines_Base AS pl	WITH (NOLOCK)	ON pum.PL_Id = pl.PL_Id
	WHERE		v.Event_Subtype_Id IN (SELECT EventSubtypeId FROM @EventSubtypes)
	AND		v.Is_Active = 1 /* --> Uncommented by Nilesh 2010-10-27*/
	AND		v.PU_Id > 0
	AND		(pm.[Level] = 4) /*--> Added by PDD 2010-06-04*/
	ORDER BY	pl.PL_Desc		ASC,
				pum.PU_Desc		ASC,
				pus.PU_Desc		ASC,
				pug.PUG_Desc	ASC,
				v.Var_Desc		ASC,
				v.Var_Id		ASC;
				
SELECT		Id, 
				ParentId, 
				[Level], 
				ItemId,
				ItemDesc, 
				TaskOrder	=	rt.Task_Order,
				Selected		=	CASE 
										WHEN rt.Task_Order IS NULL THEN 0
										ELSE 1
									END,
				Line,
				MasterUnit,
				SlaveUnit,
				[Group],
				LineId
FROM			@PlantModel pm
LEFT JOIN	dbo.Local_PG_eCIL_RouteTasks rt WITH (NOLOCK)	ON		(pm.ItemId = rt.Var_Id)
																				AND	(pm.[Level] = 5)
																				AND	(rt.Route_Id = @RouteId);

