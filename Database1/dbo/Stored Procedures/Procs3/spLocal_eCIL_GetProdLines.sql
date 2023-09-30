
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetProdLines]
/*
Stored Procedure		:		spLocal_eCIL_GetProdLines
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
Date Created			:		15-May-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the list of Production Line(s) on which the User received as parameter has rights at least of 2 (Read/Write)
Lines with no access or Read access for this user will not be returned.
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			15-May-2007		Normand Carbonneau		Creation of SP
1.0.1			23-May-2007		Christian Gagnon		Using a function to retrieved the pl_id list with specific access level
1.0.2			18-Sep-2007		Normand Carbonneau		Detection of Dept_Id = 0 instead of just Dept_Id = NULL
1.1.0			26-Jun-2009		Normand Carbonneau		Excluded obsoleted lines from Tasks Selection list.
1.1.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.1.2			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
1.1.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.1.4			22-Mar-2023		Payal Gadhvi			Added new parameters to identify call from Routes Management and then add CL task
1.1.5 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
Test Code:
EXEC spLocal_eCIL_GetProdLines 58, 1
*/
@UserId					INT,	-- This is the User_Id for which we get the lines 
@MinimumAccessLevel		INT,	-- Lines where the user has at least this Minimum Access Level will be returned
@Dept_Id				INT		= NULL,
@IsRouteManagement		INT		= NULL

AS
SET NOCOUNT ON;

IF (@IsRouteManagement = 1)
	BEGIN
	SELECT	pl.PL_Id, pl.PL_Desc
		FROM		dbo.Prod_Lines_Base AS pl WITH (NOLOCK)
		WHERE		pl.PL_Id IN (SELECT PL_Id FROM dbo.fnLocal_eCIL_GetProdLinesForUser(@UserId, @MinimumAccessLevel))
			AND		pl.PL_Desc NOT LIKE 'z_obs%'		
		UNION
		SELECT	pl.PL_Id, pl.PL_Desc
		FROM		dbo.Prod_Lines_Base AS pl WITH (NOLOCK)
		WHERE		pl.PL_Id IN (SELECT DISTINCT PL_Id  FROM dbo.Prod_Units_Base pu WITH (NOLOCK)
		JOIN dbo.Event_Configuration ec	WITH (NOLOCK)	ON	pu.Pu_Id =	ec.Pu_Id
		JOIN dbo.Event_Subtypes es WITH (NOLOCK) ON ec.Event_Subtype_Id = es.Event_Subtype_Id
		WHERE es.Event_Subtype_Desc LIKE 'RTT%' AND dbo.fnLocal_eCIL_Is_eCIL_Line(PL_Id) = 0)
		AND		pl.PL_Desc NOT LIKE 'z_obs%'
		ORDER BY	pl.PL_Desc ASC;
	END
ELSE
BEGIN
	IF (@Dept_Id IS NULL) OR (@Dept_Id = 0)
	BEGIN
		SELECT	pl.PL_Id, pl.PL_Desc
		FROM		dbo.Prod_Lines_Base AS pl WITH (NOLOCK)
		WHERE		pl.PL_Id IN (SELECT PL_Id FROM dbo.fnLocal_eCIL_GetProdLinesForUser(@UserId, @MinimumAccessLevel))
			AND		pl.PL_Desc NOT LIKE 'z_obs%'
		ORDER BY	pl.PL_Desc ASC;
	END
	ELSE
	BEGIN
		SELECT	pl.PL_Id, pl.PL_Desc
		FROM		dbo.Prod_Lines_Base AS pl WITH (NOLOCK)
		WHERE		pl.PL_Id IN (SELECT PL_Id FROM dbo.fnLocal_eCIL_GetProdLinesForUser(@UserId, @MinimumAccessLevel))
			AND		pl.Dept_Id = @Dept_Id
			AND		pl.PL_Desc NOT LIKE 'z_obs%'
		ORDER BY	pl.PL_Desc ASC;
	END
END

