/*==============================================================*/
/* View: dbo.PersonView                                         */
/*==============================================================*/
CREATE VIEW [dbo].PersonView AS
SELECT [S95Id]
      ,[LastName] AS [Name] -- don't change this without also updating the Person INSTEAD OF INSERT trigger trg_PersonInsert
      ,[PersonId]
      ,[Description]
      ,[Version]
FROM [PR_Authorization].Person
GO
-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- TRIGGER: trg_PersonInsert

-- INSTEAD OF Trigger for INSERT INTO dbo.Person.

--DROP TRIGGER [dbo].[trg_PersonInsert]
--GO
CREATE TRIGGER [dbo].[trg_PersonInsert]
ON [dbo].PersonView
INSTEAD OF INSERT
AS 
BEGIN

	DECLARE @Routine VARCHAR(100)= 'trg_PersonInsert'
	DECLARE @recordsInserteded  INTEGER
	DECLARE @rowsInserted INTEGER
	DECLARE @TenantId UNIQUEIDENTIFIER
	DECLARE @debug BIT = 0 -- set to 1 to display debug statements

	SET NOCOUNT ON

	SELECT @recordsInserteded = COUNT(*)
	 FROM inserted

	-- check that we really got an insert
	IF (@recordsInserteded = 0)
	BEGIN
		IF (@debug = 1)
		BEGIN
			PRINT @Routine + ': No Person records to insert'
		END
		RETURN
	END

	-- CLAIM: We have valid inserts that we need to process

	SELECT @TenantId = [PR_Authorization].ufn_GetDefaultTenant()

	-- check that we actually got a TenantId
	IF (@TenantId IS NULL)
	BEGIN
		RAISERROR ('50101: TenantId not found.', 11, 1)
		RETURN
	END

	-- insert the record, providing defaults for column missing in the View
	INSERT INTO [PR_Authorization].[Person]
	(
		[TenantId]
		,[PersonId]
		,[S95Id]
		,[LastName]
		,[Description]
	)
	SELECT
		@TenantId
		,[PersonId]
		,[S95Id]
		,[Name]
		,[Description]
	FROM inserted

	SELECT @rowsInserted = @@ROWCOUNT
	IF (@debug = 1)
	BEGIN
		PRINT @Routine + ': Person records inserted: ' + CONVERT(VARCHAR(5),@rowsInserted)
	END
END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'View to represent dbo.Person from the pre 3.0 Personnel model using the data from PR_Authorization.Person table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'PersonView';

