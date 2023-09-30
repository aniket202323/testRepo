-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: usp_MigratePersonnelPrivilegesData.sql 

-- Copy all rows from dbo.PersonnelPrivileges to PR_Authorization.Privilege
-- dbo.PersonnelPrivileges maps 1:1 to PR_Authorization.Privilege

CREATE PROCEDURE [PR_Personnel].usp_MigratePersonnelPrivilegesData
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
AS 
BEGIN

   DECLARE @routineName  VARCHAR(100) = '[PR_Personnel].usp_MigratePersonnelPrivilegesData: '
	DECLARE @recordsAdded INTEGER

   SET NOCOUNT ON

   IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'entry'
	END

   INSERT INTO [PR_Authorization].Privilege
	(
       [PrivilegeId]
      ,[Name]
      ,[Description]
      ,[Type]
      ,[TypeName]
      ,[OperationId]
      ,[Version]
   )
   SELECT
      [IdPrivileges]
      ,ISNULL([Name],'undefined') -- Was allowed to be NULL in DMS, but is not allowed to be NULL in Connect
      ,[Description]
      ,[Type]
      ,[TypeName]
      ,[OperationId]
		 -- if Version is NULL, it will override the PR_Authorication table default, so we must provide it here so that we do not attempt to insert NULL value which will fail
      ,COALESCE([Version],1) 
   FROM [dbo].PersonnelPrivileges 

   SET @recordsAdded = @@ROWCOUNT

   IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'PersonnelPrivileges records added: ' + CONVERT(VARCHAR(5),@recordsAdded)
		PRINT @routineName + 'exit'
	END

END