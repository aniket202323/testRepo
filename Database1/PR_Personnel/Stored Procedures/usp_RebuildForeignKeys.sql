-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: [PR_Personnel].usp_RebuildForeignKeys

 -- Re-map Foreign keys from the following reference Personnel tables to their PR_Authorization counterparts
 --   Person              -> [PR_Authorization].Person
 --   PersonnelGroup      -> [PR_Authorization].UserGroup
 --   PersonnelPrivileges -> [PR_Authorization].Privilege
 --   UserAccount         -> [PR_Authorization].UserAccount
 --   PersonAndGroup      -> [PR_Authorization].UserGroupMember
 --   GroupAndPerson      -> [PR_Authorization].UserGroupMember


CREATE PROCEDURE [PR_Personnel].usp_RebuildForeignKeys
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @routineName VARCHAR(100) = '[PR_Personnel].usp_RebuildForeignKeys: '
	DECLARE @return_value INT

	IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'entry'
	END

	-- table variable to hold a list of table names to process
	DECLARE @tableNames AS TABLE (
		rowNumber               INT IDENTITY(1,1),
		PersonnelTableName      SYSNAME,
		AuthorizationTableName  SYSNAME,
		AuthorizationColumnName SYSNAME
	)

	INSERT INTO @tableNames 
		(PersonnelTableName,AuthorizationTableName,AuthorizationColumnName)
		VALUES ('Person','Person','PersonId')
	INSERT INTO @tableNames 
			(PersonnelTableName,AuthorizationTableName,AuthorizationColumnName)
		VALUES ('UserAccount','UserAccount','UserAccountId')
	INSERT INTO @tableNames 
			(PersonnelTableName,AuthorizationTableName,AuthorizationColumnName)
		VALUES ('PersonnelPrivileges','Privilege','PrivilegeId')
	INSERT INTO @tableNames 
		(PersonnelTableName,AuthorizationTableName,AuthorizationColumnName)
		VALUES ('PersonnelGroup','UserGroup','UserGroupId')
	INSERT INTO @tableNames 
		(PersonnelTableName,AuthorizationTableName,AuthorizationColumnName)
		VALUES ('PersonAndGroup','UserGroupMember','UserGroupId')
	INSERT INTO @tableNames 
		(PersonnelTableName,AuthorizationTableName,AuthorizationColumnName)
		VALUES ('GroupAndPerson','UserGroupMember','UserGroupId')
	
	DECLARE @tableCount INT = (SELECT COUNT(*) FROM @tableNames)
	DECLARE @tableIndex INT = 0

	-- rebuild foreign keys from Personnel table to Authorization table
	WHILE (@tableIndex < @tableCount)
	BEGIN

		SET @tableIndex = @tableIndex + 1
		DECLARE @PersonnelTableName SYSNAME
		DECLARE @AuthorizationTableName SYSNAME
		DECLARE @AuthorizationColumnName SYSNAME

		SELECT
			@PersonnelTableName      = PersonnelTableName,
			@AuthorizationTableName  = AuthorizationTableName,
			@AuthorizationColumnName = AuthorizationColumnName
		FROM @tableNames 
		WHERE rowNumber = @tableIndex

		IF (@debug = 1)
		BEGIN
			PRINT @routineName + 'Moving foreign keys from table ' + @PersonnelTableName + ' to table ' + @AuthorizationTableName
		END

		EXEC	[PR_Personnel].[usp_MoveForeignKeys]
			@originalReferenceTableName = @PersonnelTableName,
			@newReferenceTableName = @AuthorizationTableName,
			@newReferenceColumnName = @AuthorizationColumnName,
			@debug = @debug,
			@test = @test

	END

	IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'exit'
	END
END