/* 
 Re-enable a person's membership in a Group

 If the Person was a member of this group before, but was 'removed' in Vision by setting the 
 PR_Authorization.UserGroupMember.Deleted = 1, this procedure will 'flip the bit' to reenable the 
 Person's membership in this group.
*/
CREATE PROCEDURE [PR_Authorization].[usp_ReAddPersonToGroup](
	@personId UNIQUEIDENTIFIER,
	@groupId UNIQUEIDENTIFIER,
	@debug BIT = 0,
	@test BIT = 0
)
AS
BEGIN

	DECLARE @userAccountId UNIQUEIDENTIFIER = NULL

	SELECT @userAccountId = ua.UserAccountId
	FROM [PR_Authorization].[UserGroupMember] ugm
	INNER JOIN [PR_Authorization].UserAccount ua ON ugm.UserAccountId = ua.UserAccountId
	INNER JOIN [PR_Authorization].Person p ON ua.PersonId = p.PersonId
	WHERE ugm.UserGroupId = @groupId 
		AND p.PersonId = @personId
		AND ugm.Deleted = 1
	
	-- The record was not found, nothing to do
	IF (@userAccountId IS NULL)
	BEGIN
		IF (@debug = 1)
			PRINT 'Person with Id = ''' + CONVERT(VARCHAR(36),@personId) + ''' not a deleted member of user group ''' + CONVERT(VARCHAR(36),@groupId) + ''''
		RETURN 0
	END

	-- The record exists, and is marked as Deleted, update it
	IF (@debug = 1) 
		PRINT 'Updating person with Id = ''' + CONVERT(VARCHAR(36),@personId) + ''' as a member of user group ''' + CONVERT(VARCHAR(36),@groupId) + ''''
	IF (@test = 0) 
	BEGIN
		UPDATE [PR_Authorization].[UserGroupMember]
		SET Deleted = 0
		WHERE UserGroupId = @groupId
		AND UserAccountId = @userAccountId
		AND Deleted = 1
	END

	RETURN 1
END