-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: usp_MigratePersonAndGroupData.sql 

-- Copy all rows from dbo.PersonAndGroup to PR_Authorization.UserGroupMember
-- dbo.PersonAndGroup maps 1:1 PR_Authorization.UserGroupMember

-- Note that this also covers off dbo.PersonAndGroup which is just the same data in reverse column order


CREATE PROCEDURE [PR_Personnel].usp_MigratePersonAndGroupData
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
AS 
BEGIN

   DECLARE @routineName  VARCHAR(100) = '[PR_Personnel].usp_MigratePersonAndGroupData: '
	DECLARE @recordsAdded INTEGER

   SET NOCOUNT ON

   IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'entry'
	END

	

   INSERT INTO [PR_Authorization].UserGroupMember
	(
   	UserGroupId
	  ,UserAccountId
	  ,Version
   )
   SELECT
       gap.[IdGroup]
      ,ua.UserAccountId
		 -- if Version is NULL, it will override the PR_Authorization table default, so we must provide it here so that we do not attempt to insert NULL value which will fail
      ,COALESCE(gap.[Version],1)
   FROM [dbo].PersonAndGroup gap 
	INNER JOIN [PR_Authorization].UserAccount ua ON (gap.PersonId = ua.PersonId)

   SET @recordsAdded = @@ROWCOUNT

   IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'PersonAndGroup records added: ' + CONVERT(VARCHAR(5),@recordsAdded)
		PRINT @routineName + 'exit'
	END

END