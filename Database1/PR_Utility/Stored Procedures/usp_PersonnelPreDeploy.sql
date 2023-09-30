-- ©2015 GE Intelligent Platforms, Inc. All rights reserved.

-- PR_Utility.usp_PersonnelPreDeploy
-- Execute any Personnel pre-deploy steps. This will be run prior to the deploy of any other dacpac.

CREATE PROCEDURE [PR_Utility].[usp_PersonnelPreDeploy]
@Debug	BIT = 0,  -- when 1 print debug statements
@Test		BIT = 0   -- when 1 do not make any changes
AS

	SET NOCOUNT ON

	-- Variables for logging
	DECLARE @ProcedureName		VARCHAR(32)		= 'usp_PersonnelPreDeploy'
	DECLARE @LoggingPrefix		VARCHAR(100)	=  @ProcedureName + ': '


	IF (@Debug = 1)
	BEGIN
		PRINT @LoggingPrefix + 'Begin'
	END

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'Person' AND TABLE_SCHEMA = 'dbo') AND
		EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'UserAccount' AND TABLE_SCHEMA = 'dbo')
	BEGIN
		DECLARE @userAccountRecordsAdded INT 
		--	To create UserAccounts for those Person records which do not already have them:
		IF (@Test = 0)
		BEGIN
			INSERT INTO 
				dbo.UserAccount (Id, PersonId, LoginName) 
			SELECT 
				NEWID(),
				p.PersonId,
				convert(nvarchar(255), NEWID()) -- To guarantee uniqueness of the LoginName we create, we just create a new id.
			FROM dbo.Person p
			WHERE p.PersonId NOT IN (SELECT PersonId FROM dbo.UserAccount)

			SET @userAccountRecordsAdded = @@ROWCOUNT
		END
		ELSE
		BEGIN
			SELECT @userAccountRecordsAdded = COUNT(*)
			FROM dbo.Person p
			WHERE p.PersonId NOT IN (SELECT PersonId FROM dbo.UserAccount)
		END

		IF (@debug = 1)
		BEGIN
			PRINT @LoggingPrefix + 'Placeholder dbo.UserAccount records added: ' + CONVERT(VARCHAR(5),@userAccountRecordsAdded)
		END
	END
   
	IF (@Debug = 1)
	BEGIN
		PRINT @LoggingPrefix + 'End'
	END

RETURN 0