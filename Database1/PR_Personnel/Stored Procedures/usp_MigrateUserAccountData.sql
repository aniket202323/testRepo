-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: usp_MigrateUserAccountData.sql 

-- Copy all rows from dbo.UserAccount to PR_Authorization.UserAccount
-- dbo.UserAccount maps 1:1 to PR_Authorization.UserAccount

CREATE PROCEDURE [PR_Personnel].usp_MigrateUserAccountData
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
AS 
BEGIN

	DECLARE @routineName  VARCHAR(100) = '[PR_Personnel].usp_MigrateUserAccountData: '
	DECLARE @recordsAdded INTEGER
	DECLARE @TenantId     UNIQUEIDENTIFIER

   SET NOCOUNT ON

   IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'entry'
	END

	-- Get the GUID of the default tenant
   SELECT @TenantId = [PR_Authorization].ufn_GetDefaultTenant()

   -- check that we actually got a TenantId
   IF (@TenantId IS NULL)
   BEGIN
      RAISERROR ('50101: TenantId not found.', 11, 1)
      RETURN
   END

   -- Id column will be defaulted by the DB ?
   INSERT INTO [PR_Authorization].UserAccount (
       [UserAccountId]
      ,[PersonId]
      ,[LoginName]
      ,[PasswordHash]
      ,[PasswordSalt]
      ,[EmailAddress]
      ,[AccountDisabled]
      ,[LastLogin]
      ,[FirstFailedLogin]
      ,[FailedLoginCount]
      ,[LockoutStart]
      ,[IsWindowsDomainUser]
      ,[Version]
   )
   SELECT
       [Id]
      ,[PersonId]
      ,[LoginName]
      ,[PasswordHash]
      ,[PasswordSalt]
      ,[EmailAddress]
      ,[AccountDisabled]
      ,[LastLogin]
      ,[FirstFailedLogin]
      ,[FailedLoginCount]
      ,[LockoutStart]
      ,[IsWindowsDomainUser]
		 -- if Version is NULL, it will override the PR_Authorization table default, so we must provide it here so that we do not attempt to insert NULL value which will fail
      ,COALESCE([Version],1) 
   FROM [dbo].UserAccount

   SET @recordsAdded = @@ROWCOUNT

   IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'UserAccount records added: ' + CONVERT(VARCHAR(5),@recordsAdded)
		PRINT @routineName + 'exit'
	END

END