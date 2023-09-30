
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetPlantModel]
/*
Stored Procedure		:		spLocal_eCIL_GetPlantModel
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
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
1.0.0			17-Sep-2007		Normand Carbonneau		Creation of SP
2.0.0			15-May-2007		Normand Carbonneau		Added @UserId parameter to be able to filter on Line Access Level of security
2.1.0			19-Jun-2007		Normand Carbonneau		Now returns DefectFlag field to indicate if a slave unit contains
																	at least one task with an opened defect.
2.2.0			06-Oct-2007		Normand Carbonneau		Accepts either PL_Id to get the Plant Model of a line, or Route_Id to
																	get the Plant Model for the route.
																	If none of them is supplied, the Plant Model for all lines of that user is returned.
2.3.0			17-Oct-2007		Normand Carbonneau		@UserId parameter is now optional to allow the retrieval of Plant Model regardless
																	of user permissions. Used in Administration screens.
																	Added @IncludeTasks parameter. If set to 1, the Tasks will also be retrieved in
																	the plant model information.
																	All code was rewritten for data retrieval.
2.3.1			14-Nov-2007		Normand Carbonneau		Changed reference from Local_PG_eCIL_RouteUnit to Local_PG_eCIL_RouteTasks
2.4.0			04-May-2008		Normand Carbonneau		Tasks (variables) are now retrieved by their Data Types instead of Event Subtypes.
2.5.0			29-Apr-2010		Normand Carbonneau		The obsoleted tasks are now excluded by their Is_Active field set to 0 instead
																	of checking if the description starts by 'z_obs'																		
2.6.0			04-May-2010		PD Dubois				Modified the SELECT statements that were giving errors with the DISTINCT
																	without ORDER BY IN SQL 2005
2.6.2			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
2.6.3			20-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
2.6.4			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
2.6.5 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
2.6.6			27-Jul-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard															
Test Code:
EXEC spLocal_eCIL_GetPlantModel
EXEC spLocal_eCIL_GetPlantModel 58
EXEC spLocal_eCIL_GetPlantModel 58, NULL, NULL, NULL, 1
EXEC spLocal_eCIL_GetPlantModel 58, 125
EXEC spLocal_eCIL_GetPlantModel 58, NULL, 45, NULL,1
EXEC spLocal_eCIL_GetPlantModel 58, NULL, NULL, 24,1
EXEC spLocal_eCIL_GetPlantModel 58, NULL, NULL, 1, 1
*/
@UserId			INT = 0,
@PLId			INT = 0,
@RouteId		INT = 0,
@TeamId			INT = 0,
@IncludeTasks	BIT = 0

AS
SET NOCOUNT ON;

DECLARE
	@eCILDataTypeId		INT,
	@eCILDataTypeDesc	VARCHAR(50);

DECLARE @PlantModel TABLE
(
	PLId				INT,
	PLDesc				VARCHAR(50),
	MasterUnitId		INT,
	MasterUnitDesc		VARCHAR(50),
	PUId				INT,
	PUDesc				VARCHAR(50),
	VarId				INT,
	VarDesc				VARCHAR(50),
	DefectFlag			BIT
);

DECLARE @EventSubtypes TABLE
(
	EventSubtypeId		int
);

SET @eCILDataTypeDesc =	'eCIL';

/*-- Get the eCIL Data Type Id */
SET @eCILDataTypeId =	(
								SELECT	Data_Type_Id
								FROM		dbo.Data_Type WITH (NOLOCK)
								WHERE		Data_Type_Desc = @eCILDataTypeDesc
						);
								
IF @eCILDataTypeId IS NULL
	BEGIN
		RETURN;
	END

/*-- Get the list of subtypes identifying the defect types */
INSERT @EventSubtypes (EventSubtypeId)
	SELECT	Event_Subtype_Id
	FROM		dbo.Event_Subtypes WITH (NOLOCK)
	WHERE		Extended_Info = 'DefectType';

/*-- No Line and no Route specified, we retrieve all lines */
IF ((ISNULL(@PLId, 0) = 0) AND (ISNULL(@RouteId, 0) = 0) AND (ISNULL(@TeamId, 0) = 0))
	BEGIN
		IF ISNULL(@UserId, 0) = 0
			BEGIN
				/*-- Retrieves all lines having eCIL variables regardless of user security*/
				INSERT @PlantModel	(
											PLId,
											PLDesc,
											MasterUnitId,
											MasterUnitDesc,
											PUId,
											PUDesc,
											VarId,
											VarDesc,
											DefectFlag
											)
					SELECT		DISTINCT	pl.PL_Id,
												pl.PL_Desc,
												pum.PU_Id,
												pum.PU_Desc,
												pus.PU_Id,
												pus.PU_Desc,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Id
														ELSE NULL
													END,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Desc
														ELSE NULL
													END,
												CASE 
													WHEN ude.UDE_Id IS NULL THEN 0
														ELSE 1
													END
					FROM			dbo.Prod_Lines_Base as pl				WITH (NOLOCK)
					JOIN			dbo.Prod_Units_Base as pum				WITH (NOLOCK)	ON pl.PL_Id = pum.PL_Id
					JOIN			dbo.Prod_Units_Base as pus				WITH (NOLOCK)	ON pum.PU_Id = pus.Master_Unit
					JOIN			dbo.Variables_Base	as  v				WITH (NOLOCK)	ON pus.PU_Id = v.PU_Id
					LEFT JOIN	dbo.User_Defined_Events as ude			WITH (NOLOCK)	ON (ude.PU_Id = pus.PU_Id)	AND (ude.End_Time IS NULL)
					LEFT JOIN	@EventSubtypes es									ON ude.Event_Subtype_Id = es.EventSubtypeId
					WHERE			v.Data_Type_Id = @eCILDataTypeId
						AND			v.Is_Active = 1
						AND			v.PU_Id > 0
					ORDER BY		pl.PL_Desc	ASC,
									pum.PU_Desc ASC,
									pus.PU_Desc ASC,
									pl.PL_Id	ASC,
									pum.PU_Id	ASC,
									pus.PU_Id	ASC;
			END
		ELSE
			BEGIN
				/*-- Retrieves all lines having eCIL variables and for which the user has at least Read Access (1)*/
				INSERT @PlantModel	(
											PLId,
											PLDesc,
											MasterUnitId,
											MasterUnitDesc,
											PUId,
											PUDesc,
											VarId,
											VarDesc,
											DefectFlag
											)
					SELECT		DISTINCT	pl.PL_Id,
												pl.PL_Desc,
												pum.PU_Id,
												pum.PU_Desc,
												pus.PU_Id,
												pus.PU_Desc,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Id
														ELSE NULL
													END,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Desc
														ELSE NULL
													END,
												CASE 
													WHEN ude.UDE_Id IS NULL THEN 0
														ELSE 1
													END
					FROM			dbo.Prod_Lines_Base as pl				WITH (NOLOCK)
					JOIN			dbo.Prod_Units_Base as pum				WITH (NOLOCK)	ON pl.PL_Id = pum.PL_Id
					JOIN			dbo.Prod_Units_Base as pus				WITH (NOLOCK)	ON pum.PU_Id = pus.Master_Unit
					JOIN			dbo.Variables_Base as v					WITH (NOLOCK)	ON pus.PU_Id = v.PU_Id
					LEFT JOIN	dbo.User_Defined_Events as ude			WITH (NOLOCK)	ON (ude.PU_Id = pus.PU_Id)
																									AND
																									(ude.End_Time IS NULL)
					LEFT JOIN	@EventSubtypes es									ON ude.Event_Subtype_Id = es.EventSubtypeId
					WHERE			v.Data_Type_Id = @eCILDataTypeId
						AND			v.Is_Active = 1
						AND			v.PU_Id > 0
						AND			pl.PL_Id IN (SELECT PL_Id FROM dbo.fnLocal_eCIL_GetProdLinesForUser(@UserId, 1))
					ORDER BY		pl.PL_Desc	ASC,
									pum.PU_Desc ASC,
									pus.PU_Desc ASC,
									pl.PL_Id		ASC,
									pum.PU_Id	ASC,
									pus.PU_Id	ASC;
			END
	END

/*-- A Line was specified, we retrieve the plant model for this line only */
IF ISNULL(@PLId, 0) > 0
	BEGIN
		IF ISNULL(@UserId, 0) = 0
			BEGIN
				/*-- Retrieves info for the line specified and having eCIL variables regardless of user security*/
				INSERT @PlantModel	(
											PLId,
											PLDesc,
											MasterUnitId,
											MasterUnitDesc,
											PUId,
											PUDesc,
											VarId,
											VarDesc,
											DefectFlag
											)
					SELECT		DISTINCT	pl.PL_Id,
												pl.PL_Desc,
												pum.PU_Id,
												pum.PU_Desc,
												pus.PU_Id,
												pus.PU_Desc,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Id
														ELSE NULL
													END,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Desc
														ELSE NULL
													END,
												CASE 
													WHEN ude.UDE_Id IS NULL THEN 0
														ELSE 1
													END
					FROM			dbo.Prod_Lines_Base as pl				WITH (NOLOCK)
					JOIN			dbo.Prod_Units_Base as pum				WITH (NOLOCK)	ON pl.PL_Id = pum.PL_Id
					JOIN			dbo.Prod_Units_Base as pus				WITH (NOLOCK)	ON pum.PU_Id = pus.Master_Unit
					JOIN			dbo.Variables_Base  as v				WITH (NOLOCK)	ON pus.PU_Id = v.PU_Id
					LEFT JOIN	dbo.User_Defined_Events as ude			WITH (NOLOCK)	ON (ude.PU_Id = pus.PU_Id)
																									AND
																									(ude.End_Time IS NULL)
					LEFT JOIN	@EventSubtypes es									ON ude.Event_Subtype_Id = es.EventSubtypeId
					WHERE			pl.PL_Id = @PLId
						AND			v.Data_Type_Id = @eCILDataTypeId
						AND			v.Is_Active = 1
						AND			v.PU_Id > 0
					ORDER BY		pl.PL_Desc	ASC,
									pum.PU_Desc ASC,
									pus.PU_Desc ASC,
									pl.PL_Id	ASC,
									pum.PU_Id	ASC,
									pus.PU_Id	ASC;
			END
		ELSE
			BEGIN
				/*-- Retrieves all lines having eCIL variables and for which the user has at least Read Access (1)*/
				INSERT @PlantModel	(
											PLId,
											PLDesc,
											MasterUnitId,
											MasterUnitDesc,
											PUId,
											PUDesc,
											VarId,
											VarDesc,
											DefectFlag
											)
					SELECT		DISTINCT	pl.PL_Id,
												pl.PL_Desc,
												pum.PU_Id,
												pum.PU_Desc,
												pus.PU_Id,
												pus.PU_Desc,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Id
														ELSE NULL
													END,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Desc
														ELSE NULL
													END,
												CASE 
													WHEN ude.UDE_Id IS NULL THEN 0
														ELSE 1
													END
					FROM			dbo.Prod_Lines_Base as pl				WITH (NOLOCK)
					JOIN			dbo.Prod_Units_Base as pum				WITH (NOLOCK)	ON pl.PL_Id = pum.PL_Id
					JOIN			dbo.Prod_Units_Base as pus				WITH (NOLOCK)	ON pum.PU_Id = pus.Master_Unit
					JOIN			dbo.Variables_Base as v					WITH (NOLOCK)	ON pus.PU_Id = v.PU_Id
					LEFT JOIN	dbo.User_Defined_Events as ude			WITH (NOLOCK)	ON (ude.PU_Id = pus.PU_Id)
																									AND
																									(ude.End_Time IS NULL)
					LEFT JOIN	@EventSubtypes es									ON ude.Event_Subtype_Id = es.EventSubtypeId
					WHERE			v.Data_Type_Id = @eCILDataTypeId
						AND			v.Is_Active = 1
						AND			v.PU_Id > 0
						AND			pl.PL_Id IN (SELECT PL_Id FROM dbo.fnLocal_eCIL_GetProdLinesForUser(@UserId, 1))
						AND			pl.PL_Id = @PLId
					ORDER BY		pl.PL_Desc	ASC,
									pum.PU_Desc ASC,
									pus.PU_Desc ASC,
									pl.PL_Id	ASC,
									pum.PU_Id	ASC,
									pus.PU_Id	ASC;
			END
	END

/*-- A Route was specified, we retrieve the plant model for this Route only*/
IF ISNULL(@RouteId, 0) > 0
	BEGIN
		IF ISNULL(@UserId, 0) = 0
			BEGIN
			/*-- Retrieves info for the Route specified and having eCIL variables regardless of user security*/
				INSERT @PlantModel	(
											PLId,
											PLDesc,
											MasterUnitId,
											MasterUnitDesc,
											PUId,
											PUDesc,
											VarId,
											VarDesc,
											DefectFlag
											)
					SELECT		DISTINCT	pl.PL_Id,
												pl.PL_Desc,
												pum.PU_Id,
												pum.PU_Desc,
												pus.PU_Id,
												pus.PU_Desc,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Id
														ELSE NULL
													END,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Desc
														ELSE NULL
													END,
												CASE 
													WHEN ude.UDE_Id IS NULL THEN 0
														ELSE 1
													END
					FROM			dbo.Local_PG_eCIL_Routes as r		WITH (NOLOCK)
					JOIN			dbo.Local_PG_eCIL_RouteTasks as rt	WITH (NOLOCK)	ON r.Route_Id = rt.Route_Id
					JOIN			dbo.Variables_Base as v					WITH (NOLOCK)	ON rt.Var_Id = v.Var_Id
					JOIN			dbo.Prod_Units_Base as pus				WITH (NOLOCK)	ON v.PU_Id = pus.PU_Id
					JOIN			dbo.Prod_Units_Base as pum				WITH (NOLOCK)	ON pus.Master_Unit = pum.PU_Id
					JOIN			dbo.Prod_Lines_Base as pl				WITH (NOLOCK)	ON pus.PL_Id = pl.PL_Id
					LEFT JOIN	dbo.User_Defined_Events as ude			WITH (NOLOCK)	ON (ude.PU_Id = pus.PU_Id)
																										AND
																										(ude.End_Time IS NULL)
					LEFT JOIN	@EventSubtypes es									ON ude.Event_Subtype_Id = es.EventSubtypeId
					WHERE			v.Data_Type_Id = @eCILDataTypeId
						AND			v.Is_Active = 1
						AND			v.PU_Id > 0
						AND			r.Route_Id = @RouteId
					ORDER BY		pl.PL_Desc	ASC,
									pum.PU_Desc ASC,
									pus.PU_Desc ASC,
									pl.PL_Id		ASC,
									pum.PU_Id	ASC,
									pus.PU_Id	ASC;
			END
		ELSE
			BEGIN
				/*-- Retrieves all lines included in Route specified, and having eCIL variables and for which the user has at least Read Access (1)*/
				INSERT @PlantModel	(
											PLId,
											PLDesc,
											MasterUnitId,
											MasterUnitDesc,
											PUId,
											PUDesc,
											VarId,
											VarDesc,
											DefectFlag
											)
					SELECT		DISTINCT	pl.PL_Id,
												pl.PL_Desc,
												pum.PU_Id,
												pum.PU_Desc,
												pus.PU_Id,
												pus.PU_Desc,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Id
														ELSE NULL
													END,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Desc
														ELSE NULL
													END,
												CASE 
													WHEN ude.UDE_Id IS NULL THEN 0
														ELSE 1
													END
					FROM			dbo.Local_PG_eCIL_Routes as r			WITH (NOLOCK)
					JOIN			dbo.Local_PG_eCIL_RouteTasks as rt		WITH (NOLOCK)	ON r.Route_Id = rt.Route_Id
					JOIN			dbo.Variables_Base as v						WITH (NOLOCK)	ON rt.Var_Id = v.Var_Id
					JOIN			dbo.Prod_Units_Base as pus					WITH (NOLOCK)	ON v.PU_Id = pus.PU_Id
					JOIN			dbo.Prod_Units_Base as pum					WITH (NOLOCK)	ON pus.Master_Unit = pum.PU_Id
					JOIN			dbo.Prod_Lines_Base as pl					WITH (NOLOCK)	ON pus.PL_Id = pl.PL_Id
					LEFT JOIN	dbo.User_Defined_Events as ude				WITH (NOLOCK)	ON (ude.PU_Id = pus.PU_Id)
																										AND
																										(ude.End_Time IS NULL)
					LEFT JOIN	@EventSubtypes es										ON ude.Event_Subtype_Id = es.EventSubtypeId
					WHERE			v.Data_Type_Id = @eCILDataTypeId
						AND			v.Is_Active = 1
						AND			v.PU_Id > 0
						AND			r.Route_Id = @RouteId
						AND			pl.PL_Id IN (SELECT PL_Id FROM dbo.fnLocal_eCIL_GetProdLinesForUser(@UserId, 1))
					ORDER BY		pl.PL_Desc	ASC,
									pum.PU_Desc ASC,
									pus.PU_Desc ASC,
									pl.PL_Id	ASC,
									pum.PU_Id	ASC,
									pus.PU_Id	ASC;
			END
	END

/*-- A Team was specified, we retrieve the plant model for this Team only */
IF ISNULL(@TeamId, 0) > 0
	BEGIN
		IF ISNULL(@UserId, 0) = 0
			BEGIN
				/*-- Retrieves info for the Team specified and having eCIL variables regardless of user security*/
				INSERT @PlantModel	(
											PLId,
											PLDesc,
											MasterUnitId,
											MasterUnitDesc,
											PUId,
											PUDesc,
											VarId,
											VarDesc,
											DefectFlag
											)
					SELECT		DISTINCT	pl.PL_Id,
												pl.PL_Desc,
												pum.PU_Id,
												pum.PU_Desc,
												pus.PU_Id,
												pus.PU_Desc,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Id
														ELSE NULL
													END,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Desc
														ELSE NULL
													END,
												CASE 
													WHEN ude.UDE_Id IS NULL THEN 0
														ELSE 1
													END
					FROM			dbo.Local_PG_eCIL_Teams as t			WITH (NOLOCK)
					JOIN			dbo.Local_PG_eCIL_TeamTasks as tt		WITH (NOLOCK)	ON t.Team_Id = tt.Team_Id
					JOIN			dbo.Variables_Base as v						WITH (NOLOCK)	ON tt.Var_Id = v.Var_Id
					JOIN			dbo.Prod_Units_Base as pus					WITH (NOLOCK)	ON v.PU_Id = pus.PU_Id
					JOIN			dbo.Prod_Units_Base as pum					WITH (NOLOCK)	ON pus.Master_Unit = pum.PU_Id
					JOIN			dbo.Prod_Lines_Base as pl					WITH (NOLOCK)	ON pus.PL_Id = pl.PL_Id
					LEFT JOIN	dbo.User_Defined_Events as ude				WITH (NOLOCK)	ON (ude.PU_Id = pus.PU_Id)
																										AND
																										(ude.End_Time IS NULL)
					LEFT JOIN	@EventSubtypes es						ON ude.Event_Subtype_Id = es.EventSubtypeId
					WHERE			v.Data_Type_Id = @eCILDataTypeId
						AND			v.Is_Active = 1
						AND			v.PU_Id > 0
						AND			t.Team_Id = @TeamId
					ORDER BY		pl.PL_Desc	ASC,
									pum.PU_Desc ASC,
									pus.PU_Desc ASC,
									pl.PL_Id	ASC,
									pum.PU_Id	ASC,
									pus.PU_Id	ASC;
			END
		ELSE
			BEGIN
				-- Retrieves all lines included in Team specified, and having eCIL variables and for which the user has at least Read Access (1)
				INSERT @PlantModel (PLId, PLDesc, MasterUnitId, MasterUnitDesc, PUId, PUDesc, VarId, VarDesc, DefectFlag)
					SELECT		DISTINCT	pl.PL_Id,
												pl.PL_Desc,
												pum.PU_Id,
												pum.PU_Desc,
												pus.PU_Id,
												pus.PU_Desc,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Id
														ELSE NULL
													END,
												CASE @IncludeTasks
													WHEN 1 THEN v.Var_Desc
														ELSE NULL
													END,
												CASE 
													WHEN ude.UDE_Id IS NULL THEN 0
														ELSE 1
													END
					FROM			dbo.Local_PG_eCIL_Teams as t			WITH (NOLOCK)
					JOIN			dbo.Local_PG_eCIL_TeamTasks as tt		WITH (NOLOCK)	ON t.Team_Id = tt.Team_Id
					JOIN			dbo.Variables_Base as v						WITH (NOLOCK)	ON tt.Var_Id = v.Var_Id
					JOIN			dbo.Prod_Units_Base as pus					WITH (NOLOCK)	ON v.PU_Id = pus.PU_Id
					JOIN			dbo.Prod_Units_Base as pum					WITH (NOLOCK)	ON pus.Master_Unit = pum.PU_Id
					JOIN			dbo.Prod_Lines_Base as pl					WITH (NOLOCK)	ON pus.PL_Id = pl.PL_Id
					LEFT JOIN	dbo.User_Defined_Events as ude				WITH (NOLOCK)	ON (ude.PU_Id = pus.PU_Id) AND (ude.End_Time IS NULL)
					LEFT JOIN	@EventSubtypes es											ON ude.Event_Subtype_Id = es.EventSubtypeId
					WHERE			v.Data_Type_Id = @eCILDataTypeId
						AND			v.Is_Active = 1
						AND			v.PU_Id > 0
						AND			t.Team_Id = @TeamId
						AND			pl.PL_Id IN (SELECT PL_Id FROM dbo.fnLocal_eCIL_GetProdLinesForUser(@UserId, 1))
					ORDER BY		pl.PL_Desc	ASC,
									pum.PU_Desc ASC,
									pus.PU_Desc ASC,
									pl.PL_Id	ASC,
									pum.PU_Id	ASC,
									pus.PU_Id	ASC ;
			END
	END

SELECT	PL_Id					=	PLId,
			PL_Desc				=	PLDesc,
			Master_Unit_Id		=	MasterUnitId,
			Master_Unit_Desc	=	MasterUnitDesc,
			PU_Id				=	PUId,
			PU_Desc				=	PUDesc,
			Var_Id				=	VarId,
			Var_Desc			=	VarDesc,
			DefectFlag
FROM		@PlantModel
ORDER BY	PLDesc			ASC,
			MasterUnitDesc	ASC,
			PUDesc			ASC,
			VarDesc			ASC ;

