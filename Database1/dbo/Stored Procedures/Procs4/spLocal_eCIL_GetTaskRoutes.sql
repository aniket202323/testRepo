CREATE PROCEDURE [dbo].[spLocal_eCIL_GetTaskRoutes]

/*
Stored Procedure		:		spLocal_eCIL_GetTaskRoutes
Author					:		Patrick-Daniel Dubois (STICorp)
Date Created			:		25-May-2010
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
The stored procedure returns all routes associated to the given task.
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			05-May-2010		PD Dubois				Creation of SP
1.0.1			03-Aug-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.0.2			18-Feb-2021		Megha Lohana			Update the TaskID to BIGINT for PPA7
1.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.4 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.0.5			03-Aug-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard
Test Code:
EXEC spLocal_eCIL_GetTaskRoutes 79307
*/
@TaskId		BIGINT

AS

SET NOCOUNT ON;

SELECT	r.Route_Desc,
			r.Route_Id
FROM		dbo.Local_PG_eCIL_Routes r		WITH (NOLOCK)
JOIN		dbo.Local_PG_eCIL_RouteTasks rt	WITH (NOLOCK) ON r.Route_Id = rt.Route_Id
WHERE		rt.Var_Id = @TaskId;

