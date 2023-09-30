/*==============================================================*/
/* View: dbo.PersonAndGroupView                                 */
/*==============================================================*/
CREATE VIEW dbo.PersonAndGroupView AS
SELECT
	ugm.[Version]
	,ua.[PersonId]      AS [PersonId]
	,ugm.[UserGroupId]  AS [IdGroup]
	,ua.[UserAccountId] AS [UserAccountId]
FROM [PR_Authorization].UserGroupMember ugm 
	INNER JOIN [PR_Authorization].UserAccount ua ON (ugm.UserAccountId = ua.UserAccountId)
WHERE ugm.Deleted != 1
GO
-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- TRIGGER: trg_PersonAndGroupInsert 

-- INSTEAD OF Trigger for INSERT INTO dbo.PersonAndGroup.
-- This trigger INSERTs records into PR_Authorization.UserGroupMember table.

--DROP TRIGGER [dbo].[trg_PersonAndGroupInsert]
--GO
CREATE TRIGGER [dbo].[trg_PersonAndGroupInsert]
ON [dbo].PersonAndGroupView
INSTEAD OF INSERT
AS 
BEGIN
		DECLARE @Routine VARCHAR(100) = 'trg_PersonAndGroupInsert'
		DECLARE @recordsInserted  INTEGER
		DECLARE @rowsInserted INTEGER
		DECLARE @debug BIT = 0 -- set to 1 to display debug statements

	SET NOCOUNT ON

	SELECT @recordsInserted = COUNT(*)
	FROM inserted
	
	-- check that we really got an insert
	IF (@recordsInserted = 0)
	BEGIN
		IF (@debug = 1)
		BEGIN
			PRINT @Routine + ': No PersonAndGroup records to insert'
		END
		RETURN
	END

	-- DOC: The authorization model requires that a person have a user account in
	-- order to be added to a User Group. This is a change from the previous model
	-- which did not enforce that constraint explicitly although the ProficyClient
	-- would not allow the person to be selected into a group unless it had an account.
	-- Check that there is a user account found for each insert of person to group.
	DECLARE @userAccountsFound INTEGER
	SELECT @userAccountsFound = COUNT(ua.UserAccountId)
	FROM inserted i 
	INNER JOIN [PR_Authorization].UserAccount ua 
		ON (i.PersonId = ua.PersonId)

	IF (@debug = 1)
	BEGIN
		PRINT @Routine + ': ' + CONVERT(VARCHAR(5),@userAccountsFound) + ' UserAccounts found for ' + 
			CONVERT(VARCHAR(5),@recordsInserted) + ' inserted records'
	END

	IF (@userAccountsFound != @recordsInserted)
	BEGIN
		-- Gather up the number of user accounts missing and a sample
		-- person without an user account (probably only 1 missing most of the time)
		DECLARE @userAccountsMissing INTEGER = @recordsInserted - @userAccountsFound
		DECLARE @samplePersonId UNIQUEIDENTIFIER

		SELECT TOP 1 @samplePersonId = i.PersonId 
		FROM inserted i
		WHERE NOT EXISTS (
			SELECT ua.PersonId
			FROM [PR_Authorization].UserAccount ua 
			WHERE i.PersonId = ua.PersonId)

		DECLARE @samplePersonIdText   VARCHAR(36) = CONVERT(VARCHAR(36),@samplePersonId)

		IF (@debug = 1)
		BEGIN
			PRINT @Routine + ' raising error: Insert for ' + CONVERT(VARCHAR(5),@userAccountsMissing) +
				' Person records missing UserAccount. First error on Person: ' + @samplePersonIdText
		END
		RAISERROR ('50102: Insert failed. %d Person records do not have a UserAccount. First error on PersonId: %s', 
			11, 1, @userAccountsMissing, @samplePersonIdText)
		RETURN
	END

	-- CLAIM: We have a valid insert that we need to process

	-- insert the record, providing defaults for columns missing in the View
	INSERT INTO [PR_Authorization].[UserGroupMember]
	(
		[UserGroupId]
		,[UserAccountId]
	)
	SELECT
		i.IdGroup
		,ua.UserAccountId
	FROM inserted i 
	INNER JOIN [PR_Authorization].UserAccount ua ON (i.PersonId = ua.PersonId)

	SELECT @rowsInserted = @@ROWCOUNT
	IF (@debug = 1)
	BEGIN
		PRINT @Routine + ': PersonAndGroup records inserted: ' + CONVERT(VARCHAR(5),@rowsInserted)
	END

END
GO
-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- TRIGGER: trg_PersonAndGroupDelete 

-- INSTEAD OF Trigger for DELETE FROM dbo.PersonAndGroupView
-- This trigger removes the corresponding records from the PR_Authorization.UserGroupMember table.

--DROP TRIGGER [dbo].[trg_PersonAndGroupDelete]
--GO
CREATE TRIGGER [dbo].[trg_PersonAndGroupDelete]
ON [dbo].PersonAndGroupView
INSTEAD OF DELETE
AS 
BEGIN
		DECLARE @Routine VARCHAR(100) = 'trg_PersonAndGroupDelete'
		DECLARE @recordsDeleted  INTEGER
		DECLARE @rowsDeleted INTEGER
		DECLARE @debug BIT = 0 -- set to 1 to display debug statements

	SET NOCOUNT ON

	SELECT @recordsDeleted = COUNT(*)
	 FROM deleted

	-- check that we really got a delete
	IF (@recordsDeleted = 0)
	BEGIN
		IF (@debug = 1)
		BEGIN
			PRINT @Routine + ': No PersonAndGroup records to delete'
		END
		RETURN
	END

	-- CLAIM: We have valid delete(s) that we need to process

	-- delete the corresponding UserGroupMember records, using a join to UserAccount to obtain the UserAccountId for the PersonId in the deleted table
	DELETE ugm
	FROM [PR_Authorization].[UserGroupMember] ugm
	INNER JOIN [PR_Authorization].UserAccount ua
		ON (ua.UserAccountId = ugm.UserAccountId)
	INNER JOIN deleted d 
		ON (d.PersonId = ua.PersonId)
	WHERE (ugm.UserGroupId = d.IdGroup)

	SELECT @rowsDeleted = @@ROWCOUNT
	IF (@debug = 1)
	BEGIN
		PRINT @Routine + ': PersonAndGroup records deleted: ' + CONVERT(VARCHAR(5),@rowsDeleted)
	END

END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'View to represent dbo.PersonAndGroup from the pre 3.0 Personnel model using the data from PR_Authorization.UserGroupMember and PR_Authorization.UserAccount tables.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'PersonAndGroupView';

