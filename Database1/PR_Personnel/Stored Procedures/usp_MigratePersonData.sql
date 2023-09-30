-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- MODULE: usp_MigratePersonData.sql 

-- Copy all rows from dbo.Person to PR_Authorization.Person
-- dbo.Person maps 1:1  PR_Authorization.Person

CREATE PROCEDURE [PR_Personnel].usp_MigratePersonData
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
AS 
BEGIN

	DECLARE @routineName VARCHAR(100) = '[PR_Personnel].usp_MigratePersonData: '
	DECLARE @recordsAdded INTEGER
   DECLARE @TenantId  UNIQUEIDENTIFIER

   SET NOCOUNT ON


   IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'entry'
	END

	-- Get the GUID of the default tenant
   SELECT @TenantId = [PR_Authorization].ufn_GetDefaultTenant()

   --  make sure we actually got a TenantId
   IF (@TenantId IS NULL)
   BEGIN
      RAISERROR ('50101: Default TenantId not found.', 11, 1)
      RETURN
   END

   INSERT INTO [PR_Authorization].Person
	(
		TenantId,
		PersonId,
		S95Id,
		Description,
		LastName,
		Version
	)
   SELECT
      @TenantId
      ,[PersonId]
      ,[S95Id]  
      ,[Description]
      ,[Name] --  Note:  we would like to be smarter and split the Name by comma (,) or space into First/Last but not sure this is doable
 		 -- if Version is NULL, it will override the PR_Authorization table default, so we must provide it here so that we do not attempt to insert NULL value which will fail
      ,COALESCE([Version],1) 
   FROM [dbo].Person

   SET @recordsAdded = @@ROWCOUNT

   IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'Person records added: ' + CONVERT(VARCHAR(5),@recordsAdded)
		PRINT @routineName + 'exit'
	END

END

-- END MODULE: usp_MigratePersonData 