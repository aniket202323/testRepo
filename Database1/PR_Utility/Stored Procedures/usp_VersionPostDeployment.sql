-- Post Deployment for Version schema

-- NOTE
-- This is done in this script from inside the Utility dacpac instead of the Version dacpac because of the 
-- order the dacpacs are deployed.  
-- To perform the post-deploy steps in the Version project, we require the utility functions provided in
-- Utility. But the Utility project has a dependency on the Version project, and we cannot have a circular dependency.
-- The easiest way around this was to task the Utility project with the responsibility of executing any
-- post-deploy steps required by Version dacpac.

--DROP PROCEDURE [PR_Utility].[usp_VersionPostDeployment]
--GO
CREATE PROCEDURE [PR_Utility].[usp_VersionPostDeployment] (
	@Debug	BIT = 0,  -- when 1 print debug statements
	@Test		BIT = 0   -- when 1 do not make any changes
) AS
BEGIN
	-- drop pre 2.5 versions of the Version function and procedure
	EXEC [PR_Utility].usp_ObjectDrop 'spUpdateVersion','PROCEDURE',NULL,'PR_Version',@Debug, @Test
	EXEC [PR_Utility].usp_ObjectDrop 'ReadVersion',    'FUNCTION', NULL,'PR_Version',@Debug, @Test

END