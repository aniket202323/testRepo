CREATE PROCEDURE [dbo].[spLocal_eCIL_GetTeamRoutes]
/*
Stored Procedure		:		spLocal_eCIL_GetTeamRoutes
Author					:		Normand Carbonneau (STICorp)
Date Created			:		14-Oct-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the list of all Routes related to a Team, as well as Routes not related.
Rows having a Route associated to the Team will have Selected = 1.
Rows having a Route not associated to the route will have Selected = 0
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			05-Dec-2007		Normand Carbonneau		Creation of SP
1.0.1			17-Mar-2010		Normand Carbonneau		RouteDesc was increased to 150 characters in the table, but not in the SP,
																		resulting in [String or binary data would be truncated.] error.
																		Matched the RouteDesc accordingly.
2.0.0			24-Apr-2010		Normand Carbonneau		The InAnotherTeam flag is no longer required.
2.0.1			03-Aug-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
2.0.2			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
2.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
2.0.4			03-Aug-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard	
2.0.5 			08-Aug-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
	
Test Code:
EXEC spLocal_eCIL_GetTeamRoutes 52
*/
@TeamId		INT	/*-- The Team for which we want the Routes list */

AS
SET NOCOUNT ON;

DECLARE @Routes TABLE
(
	RouteId				INT,
	RouteDesc			VARCHAR(150),
	Selected			BIT
);

/*-- Retrieves all the Routes already associated to the Team (Selected)*/
INSERT @Routes	(
					RouteId,
					RouteDesc,
					Selected
					)
	SELECT		tr.Route_Id,
					r.Route_Desc,
					1
	FROM			dbo.Local_PG_eCIL_Routes r			WITH (NOLOCK)
	JOIN			dbo.Local_PG_eCIL_TeamRoutes tr		WITH (NOLOCK)	ON r.Route_Id = tr.Route_Id
	WHERE			tr.Team_Id = @TeamId;


/*-- Retrieves all the Routes not associated to the Team (Available)*/
INSERT @Routes	(
					RouteId,
					RouteDesc,
					Selected
					)
	SELECT		Route_Id,
					Route_Desc,
					0
	FROM			dbo.Local_PG_eCIL_Routes	WITH (NOLOCK)
	WHERE			Route_Id NOT IN	(
											SELECT	RouteId
											FROM		@Routes
											);
	
/*-- Returns the list of Routes (Selected and Available) */
SELECT		Selected,
			RouteId,
			RouteDesc
FROM		@Routes
ORDER BY	RouteDesc ASC;

