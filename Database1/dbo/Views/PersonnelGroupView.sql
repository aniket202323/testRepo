/*==============================================================*/
/* View: dbo.PersonnelGroupView                                 */
/*==============================================================*/
CREATE VIEW dbo.PersonnelGroupView AS
SELECT
	[UserGroupId] AS [IdGroup]
	,[Name]
	,[Description]
	,[Type]
	,[Version]
FROM [PR_Authorization].UserGroup
WHERE Deleted != 1
GO
-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- TRIGGER: trg_PersonnelGroupInsert 

-- INSTEAD OF Trigger for INSERT INTO dbo.PersonnelGroup.

--DROP TRIGGER [dbo].[trg_PersonnelGroupInsert]
--GO
CREATE TRIGGER [dbo].[trg_PersonnelGroupInsert]
ON [dbo].PersonnelGroupView
INSTEAD OF INSERT
AS 
BEGIN

	DECLARE @recordsInserted  INTEGER
	DECLARE @Routine VARCHAR(100) = 'trg_PersonnelGroupInsert'
	DECLARE @rowsInserted INTEGER
	DECLARE @TenantId UNIQUEIDENTIFIER
	DECLARE @debug BIT = 0 -- set to 1 to display debug statements

	SET NOCOUNT ON

	SELECT @recordsInserted = COUNT(*)
	FROM inserted

	-- check that we really got an insert
	IF (@recordsInserted = 0)
	BEGIN
		IF (@debug = 1) PRINT @Routine + ': No PersonnelGroup records to insert'
		RETURN
	END

	-- CLAIM: We have a valid insert that we need to process

	SELECT @TenantId = [PR_Authorization].ufn_GetDefaultTenant()

	-- check that we actually got a TenantId
	IF (@TenantId IS NULL)
	BEGIN
		RAISERROR ('50101: TenantId not found.', 11, 1)
		RETURN
	END
	-- insert the record, providing defaults for columns missing in the View
	INSERT INTO [PR_Authorization].[UserGroup]
	(
		[TenantId]
		,[UserGroupId]
		,[Name]
		,[Description]
		,[Type]
	)
	SELECT
		@TenantId
		,[IdGroup]
		,[Name]
		,[Description]
		,[Type]
	FROM inserted

	SELECT @rowsInserted = @@ROWCOUNT
	IF (@debug = 1)
	BEGIN
		PRINT @Routine + ': PersonnelGroup records inserted: ' + CONVERT(VARCHAR(5),@rowsInserted)
	END

END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'View to represent dbo.PersonnelGroup from the pre 3.0 Personnel model using the data from PR_Authorization.UserGroup table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'PersonnelGroupView';

