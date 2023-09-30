-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: [PR_Personnel].usp_VerifyPersonAndGroupMigration

-- Stored procedure to perform a simple check that the migration of PersonAndGroup data 
-- succeeded.

CREATE PROCEDURE [PR_Personnel].[usp_VerifyPrivilegeMigration]
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0              -- if 1, do not make any changes
AS
BEGIN
	DECLARE @routineName VARCHAR(100)		= '[PR_Personnel].[usp_VerifyPrivilege]'
	DECLARE @targetTableName VARCHAR(100)	= '[PR_Authorization].Privilege'
	DECLARE @sourceTableName VARCHAR(100)	= '[dbo].PersonnelPrivilegesLegacy'

	--Get the number of original records
	DECLARE @originalRecordCount INT
	SELECT @originalRecordCount = COUNT (*) FROM [dbo].PersonnelPrivilegesLegacy

	--Get the number of migrated records
	DECLARE @recordsAdded INT
	SELECT @recordsAdded = COUNT (*) FROM [PR_Authorization].Privilege

	-- If the number of old records do not match the number of new records then we have a problem
	IF (@recordsAdded != @originalRecordCount)
	BEGIN
		DECLARE @errorMessage VARCHAR(200) = 
		@targetTableName + ' records migrated (' + CONVERT(VARCHAR(5),@recordsAdded) + ') does not match original number of ' + @sourceTableName + ' records (' + CONVERT(VARCHAR(5),@originalRecordCount) + ')'
		IF (@debug = 1)
		BEGIN
			PRINT @routineName + @errorMessage;
		END
		RAISERROR('%s: %s',16,1, @routineName, @errorMessage)
	END
	ELSE
	BEGIN
		RETURN
	END
END