CREATE PROCEDURE [dbo].[spLocal_eCIL_GetTaskTeams]
/*
Stored Procedure		:		spLocal_eCIL_GetTaskTeams
Author					:		Patrick-Daniel Dubois (STICorp)
Date Created			:		25-May-2010
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
The stored procedure returns all teams associated to the given task.
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			05-May-2010		PD Dubois				Creation of SP
1.0.1			03-Aug-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.0.2			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.3 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.0.4			03-Aug-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard
SELECT * FROM LOCAL_PG_ECIL_TEAMS
Test Code:
EXEC spLocal_eCIL_GetTaskTeams 75398
*/
@TaskId		INT

AS
SET NOCOUNT ON;

SELECT	t.Team_Desc,
			t.Team_Id
FROM		dbo.Local_PG_eCIL_Teams t		WITH (NOLOCK)
JOIN		dbo.Local_PG_eCIL_TeamTasks tt	WITH (NOLOCK) ON t.Team_Id = tt.Team_Id
WHERE		tt.Var_Id = @TaskId ;

