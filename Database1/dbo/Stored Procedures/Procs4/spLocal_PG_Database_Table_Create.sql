﻿
--==============================================================================================================================================
-- Store Procedure: 	spLocal_PG_Database_Table_Create
-- Author:				Daniel Rodriguez-Demers
-- Date Created:		2016-11-03
-- Sp Type:				Stored Procedure
-- Editor Tab Spacing: 	4	
------------------------------------------------------------------------------------------------------------------------------------------------
-- DESCRIPTION:
-- Stored Procedure verifies if a table exists, if it does not it creates the table with a Unique identifier field
-- and a non-clustered primary key on the id field
------------------------------------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
------------------------------------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who							What
--	========	====		===							====
--	1.0			2016-11-03	Daniel Rodriguez-Demers		Initial Development
------------------------------------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
------------------------------------------------------------------------------------------------------------------------------------------------
/*
EXEC dbo.spLocal_PG_Database_Table_Create
			@p_TableName		= 'Local_Test',
			@p_ColumnName		= 'Id',
			@p_SeedValue		= 1,
			@p_CreateIdentity	= 0
*/
--==============================================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_PG_Database_Table_Create]
	@p_TableName		VARCHAR(128),
	@p_ColumnName		VARCHAR(128),
	@p_SeedValue		INT = 1,
	@p_CreateIdentity	BIT = 1
AS
SET NOCOUNT ON
--==============================================================================================================================================
--	DECLARE Variables
------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE
@SQL	VARCHAR(MAX)
--==============================================================================================================================================
--	Validate input parameters
--==============================================================================================================================================
--	Table name
------------------------------------------------------------------------------------------------------------------------------------------------
IF	@p_TableName IS NULL
BEGIN
	PRINT '@p_TableName cannot be NULL'
	RETURN
END
------------------------------------------------------------------------------------------------------------------------------------------------
--	Identity column name
------------------------------------------------------------------------------------------------------------------------------------------------
IF	@p_ColumnName IS NULL
BEGIN
	PRINT '@p_ColumnName cannot be NULL'
	RETURN
END
------------------------------------------------------------------------------------------------------------------------------------------------
--	Make sure Seed value has a value
------------------------------------------------------------------------------------------------------------------------------------------------
IF	@p_SeedValue IS NULL
BEGIN
	SET @p_SeedValue = 1
END
--==============================================================================================================================================
--	Check if constaint name is less than 128 characters
--==============================================================================================================================================
IF (LEN(@p_TableName) + LEN(@p_ColumnName) + 4) > 128
BEGIN
	PRINT 'Constraint name would contain more than 128 characters, table not created.'
	RETURN
END
------------------------------------------------------------------------------------------------------------------------------------------------
--	Check if table Exits
------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID (@p_TableName, 'U') IS NOT NULL
BEGIN
	PRINT 'EXISTS:  ' + @p_TableName
END
ELSE
BEGIN
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Create table
	--	a.	Create Dynamic SQL
	--	b.	Execute Dynamic SQL
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	a.	Create Dynamic SQL
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET @SQL = 'CREATE TABLE [dbo].[' + @p_TableName + ']('
	
	IF @p_CreateIdentity = 1
	BEGIN
		SET	@SQL = @SQL + '[' + @p_ColumnName + '][INT] IDENTITY(' + CONVERT(VARCHAR(5), @p_SeedValue) + ', 1) NOT NULL'
	END
	ELSE
	BEGIN
		SET	@SQL = @SQL + '[' + @p_ColumnName + '][INT] NOT NULL'
	END
	
	SET	@SQL = @SQL + ' CONSTRAINT [' + REPLACE(@p_TableName, '_', '') + '_PK_' + REPLACE(@p_ColumnName, '_', '') + '] '
			+ 'PRIMARY KEY NONCLUSTERED ([' + @p_ColumnName + '] ASC) ON [PRIMARY]) ON [PRIMARY]'
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	b.	Execute Dynamic SQL
	--------------------------------------------------------------------------------------------------------------------------------------------
	EXECUTE (@SQL)
	PRINT 'TABLE:  ' + @p_TableName + ' created successfully.'
END
--==============================================================================================================================================
SET NOCOUNT OFF
--==============================================================================================================================================
--	END SP
--==============================================================================================================================================
RETURN