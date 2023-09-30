-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PR_Utility.usp_CommonPreDeploy
-- Execute any common pre-deploy steps. This will be run prior to the deploy of any other dacpac.

-- NOTE
-- Any temporary interim developer pre-deploy steps to be executed should NOT be added here.
-- Use usp_DeveloperCommonPreDeploy.sql instead.
-- llefebvre Sep 2014
-- END NOTE

 --DROP PROCEDURE [PR_Utility].[usp_CommonPreDeploy]
 --GO
CREATE PROCEDURE [PR_Utility].[usp_CommonPreDeploy]
@Debug	BIT = 0,  -- when 1 print debug statements
@Test	BIT = 0   -- when 1 do not make any changes
AS

	SET NOCOUNT ON

	-- Variables for logging
	DECLARE @ProcedureName		VARCHAR(32)		= 'usp_CommonPreDeploy'
	DECLARE @LoggingPrefix		VARCHAR(100)	=  @ProcedureName + ': '

	IF (@Debug = 1)
	BEGIN
		PRINT @LoggingPrefix + 'Begin'
	END

	-- Execute the post-deploy step for the Version dacpac.
	-- DOC: 
	-- This is done in this project instead of Version because of the order the dacpacs are deployed.
	-- To perform the post-deploy steps in the Version project, we require the utility functions provided in
	-- PR_Utility. But the Utility project has a dependency on the Version project, so we cannot have a circular
	-- dependency on the Utility project in the Version project.  The easiest way around this was to task the Utility
	-- dacpac with the responsibility of executing any post-deploy steps required by Version.

	EXEC [PR_Utility].usp_VersionPostDeployment @Debug, @Test

	EXEC [PR_Utility].usp_DropLegacyColumns @Debug, @Test
	
	IF (@Debug = 1)
	BEGIN
		PRINT @LoggingPrefix + 'End'
	END

RETURN 0