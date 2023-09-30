CREATE PROCEDURE [dbo].[spLocal_eCIL_GetRoutes]
/*
Stored Procedure		:		spLocal_eCIL_GetRoutes
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
Date Created			:		17-Sep-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the list of all Routes.
If a User_Id is supplied, returns all routes including units on lines where the user has access,
and at least the kind of access is determined by the @MinimumAccessLevel parameter
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			17-Sep-2007		Normand Carbonneau		Creation of SP
2.0.0			15-Nov-2007		Normand Carbonneau		Now refers to RouteUsers instead of RouteUnit
																	Removed @MinimumAccessLevel parameter
3.0.0			11-Dec-2007		Normand Carbonneau		Now get the Routes for a user based on Team-Users and Team-Routes associations.
																	The Route-Users association no longer exists.
3.0.1			16-Dec-2008		Normand Carbonneau		Added a DISTINCT clause to avoid returning twice the same route
																	for example when a user is associated to several teams which are
																	themselves associated to the same route.
																	Also added WITH (NOLOCK)
3.0.2			03-Aug-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
3.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
3.0.4 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
3.0.5			02-Aug-2023		Payal Gadhvi			Updated SP to add version management and to meet SP standard
Test Code:
EXEC spLocal_eCIL_GetRoutes 58
EXEC spLocal_eCIL_GetRoutes
*/
@UserId				INT = NULL	/* This is the User_Id for which we get the lines */

AS
SET NOCOUNT ON;

IF (@UserId IS NULL) OR (@UserId = 0)
	
		SELECT Route_Id, Route_Desc FROM dbo.Local_PG_eCIL_Routes WITH (NOLOCK) ORDER BY Route_Desc ASC;
	
ELSE
	
		SELECT DISTINCT	r.Route_Id, r.Route_Desc
		FROM					dbo.Local_PG_eCIL_Routes r WITH (NOLOCK)
		JOIN					dbo.Local_PG_eCIL_TeamRoutes tr WITH (NOLOCK)	ON r.Route_Id = tr.Route_Id
		JOIN					dbo.Local_PG_eCIL_TeamUsers tu WITH (NOLOCK)	ON tr.Team_Id = tu.Team_Id
		WHERE					tu.[User_Id] = @UserId
		ORDER BY				Route_Desc ASC ;
	
