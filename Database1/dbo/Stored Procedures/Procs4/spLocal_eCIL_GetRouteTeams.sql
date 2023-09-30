
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetRouteTeams]
/*
Stored Procedure		:		spLocal_eCIL_GetRouteTeams
Author					:		Normand Carbonneau (STICorp)
Date Created			:		24-Apr-2010
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the list of all Teams related to a Route, as well as Teams not related.
Rows having a Team associated to the Route will have Selected = 1.
Rows having a Team not associated to the Route will have Selected = 0
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			24-Apr-2010		Normand Carbonneau		Creation of SP
1.0.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.0.2			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
1.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.4 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.0.5			02-Aug-2023		Payal Gadhvi			Updated SP to add version management and to meet SP standard
Test Code:
EXEC spLocal_eCIL_GetRouteTeams 52
*/
@RouteId		INT	/* The Route for which we want the Teams list */

AS
SET NOCOUNT ON;

DECLARE @Teams TABLE
(
	TeamId			INT,
	TeamDesc		VARCHAR(150),
	Selected		BIT
) ;

/* Retrieves all the Teams already associated to the Route (Selected) */
INSERT @Teams	(
					TeamId,
					TeamDesc,
					Selected
					)
	SELECT		tr.Team_Id,
					t.Team_Desc,
					1
	FROM			dbo.Local_PG_eCIL_Teams t		WITH (NOLOCK)
	JOIN			dbo.Local_PG_eCIL_TeamRoutes tr	WITH (NOLOCK)	ON t.Team_Id = tr.Team_Id
	WHERE			tr.Route_Id = @RouteId ;


/* Retrieves all the Teams not associated to the Route (Available) */
INSERT @Teams	(
					TeamId,
					TeamDesc,
					Selected
					)
	SELECT		Team_Id,
					Team_Desc,
					0
	FROM			dbo.Local_PG_eCIL_Teams WITH (NOLOCK)
	WHERE			Team_Id NOT IN	(
											SELECT	TeamId
											FROM		@Teams
											);
	
/* Returns the list of Teams (Selected and Available) */
SELECT	Selected,
			TeamId,
			TeamDesc
FROM		@Teams
ORDER BY	TeamDesc ASC ;

