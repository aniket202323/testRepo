-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PR_Utility.usp_AuthorizationPreDeploy
-- Execute any Authorization pre-deploy steps. This will be run prior to the deploy of any other dacpac.

-- 2.5 RTM
-- For the 2.5 release, include steps to alter the Person table by reducing the Description column to 1024 characters.
-- The trg_PersonInsert and PersonView objects must be dropped first for this to work. They will be recreated when
-- the Authorization dacpac is applied.

-- NOTE
-- This procedure exists only to permit upgrade compatibility for developer databases during
-- the development cycle of Proficy SOA/Vision Connect version 2.5
-- This procedure should not be shipped or executed in the final 2.5 release.
-- Any pre-deploy steps to be executed in production should be added to usp_CommonPreDeploy.sql
-- llefebvre Sep 2014
-- END NOTE

 --DROP PROCEDURE [PR_Utility].[usp_AuthorizationPreDeploy]
 --GO
CREATE PROCEDURE [PR_Utility].[usp_AuthorizationPreDeploy]
@Debug	BIT = 0,  -- when 1 print debug statements
@Test		BIT = 0   -- when 1 do not make any changes
AS

	SET NOCOUNT ON

	-- Variables for logging
	DECLARE @ProcedureName		VARCHAR(32)		= 'usp_AuthorizationPreDeploy'
	DECLARE @LoggingPrefix		VARCHAR(100)	=  @ProcedureName + ': '

	IF (@Debug = 1)
	BEGIN
		PRINT @LoggingPrefix + 'Begin'
	END

-- 2.5 RTM ======
	-- DROP the triggers against the Person table so that the upgrade to the Description column can proceed
	-- the triggers will be re-created when the Authorization dacpac is redeployed
	EXEC [PR_Utility].usp_ObjectDrop 'trg_PersonInsert','TRIGGER','PersonView','dbo',@Debug,@Test
	-- DROP the PersonView to avoid a warning when the dacpac is applied
	EXEC [PR_Utility].usp_ObjectDrop 'PersonView','VIEW','','dbo',@Debug,@Test

	-- ALTER the column size by hand, as the dacpac will not truncate a column due to potential loss of data
	IF ([PR_Utility].ufn_ObjectExists('Person', 'TABLE', NULL, 'PR_Authorization') = 1)
	BEGIN
		ALTER TABLE [PR_Authorization].Person ALTER COLUMN [Description] NVARCHAR(1024) NULL
	END
-- ==============


	
	IF (@Debug = 1)
	BEGIN
		PRINT @LoggingPrefix + 'End'
	END

RETURN 0