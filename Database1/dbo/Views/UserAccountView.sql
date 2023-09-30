/*==============================================================*/
/* View: dbo.UserAccountView                                    */
/*==============================================================*/
CREATE VIEW dbo.UserAccountView AS
SELECT
       [UserAccountId] AS [Id]
      ,[LoginName]
      ,[PasswordHash]
      ,[PasswordSalt]
      ,[EmailAddress]
      ,[AccountDisabled]
      ,[LastLogin]
      ,[FirstFailedLogin]
      ,[FailedLoginCount]
      ,[LockoutStart]
      ,[IsWindowsDomainUser]
      ,[Version]
      ,[PersonId]
FROM [PR_Authorization].UserAccount
WHERE Deleted != 1
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'View to represent dbo.UserAccount from the pre 3.0 Personnel model using the data from PR_Authorization.UserAccount table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'UserAccountView';

