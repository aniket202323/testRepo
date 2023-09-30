-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: usp_MigratePersonnelGroupData.sql 

-- Copy all rows from dbo.PersonnelGroup to PR_Authorization.UserGroup
-- dbo.PersonnelGroup maps 1:1 PR_Authorization.UserGroup

CREATE PROCEDURE [PR_Personnel].usp_MigratePersonnelGroupData
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
AS 
BEGIN

 	DECLARE @routineName  VARCHAR(100) = '[PR_Personnel].usp_MigratePersonnelGroupData: '
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

   INSERT INTO [PR_Authorization].UserGroup 
	(
		UserGroupId
		,TenantId
		,[Name]
		,Description
		,[Type]
		,Version
   )
   SELECT
       [IdGroup]
      ,@TenantId
      ,ISNULL([Name],'undefined') -- Was allowed to be NULL in DMS, but is not allowed to be NULL in Connect
      ,[Description]
      ,[Type]
		 -- if Version is NULL, it will override the PR_Authorication table default, so we must provide it here so that we do not attempt to insert NULL value which will fail
      ,COALESCE([Version],1) 
   FROM [dbo].PersonnelGroup

   SET @recordsAdded = @@ROWCOUNT

   IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'PersonnelGroup records added: ' + CONVERT(VARCHAR(5),@recordsAdded)
		PRINT @routineName + 'exit'
	END

END