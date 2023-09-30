-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: usp_PersonnelMigration

-- Execute the Personnel migration to the PR_Authorization tables.
-- This routine is run from the PersonnelMigration post-deploy script.

CREATE PROCEDURE [PR_Personnel].[usp_PersonnelMigration] (
@debug  BIT = 1,                    -- if 1, print out all statements before executing
@test   BIT = 0        ,            -- if 1, do not make any changes
@introduceError BIT = 0
) WITH EXECUTE AS OWNER
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @returnValue INT = 0
	
	-- reverse rename of tables and drop foriegn keys (in case of a re-run after a failed deployment)
	EXEC [PR_Personnel].usp_ReverseRenameTables @debug, @test

	-- do data migration
	EXEC [PR_Personnel].usp_MigrateData @debug,@test

	-- back up foreign keys which are going to be rebuilt
	EXEC [PR_Personnel].usp_LoadPersonnelForeignKeys

	-- move foreign keys
   EXEC [PR_Personnel].usp_RebuildForeignKeys @debug, @test

	-- rename tables, and create synonyms
	EXEC [PR_Personnel].usp_RenameTables @debug, @test

	IF @introduceError = 1
	BEGIN
		INSERT 
		INTO dbo.Person
		VALUES
		('a','a',NEWID(),'desc',1)
	END

	-- Verify Migration
	EXEC [PR_Personnel].usp_VerifyMigration @debug, @test

END