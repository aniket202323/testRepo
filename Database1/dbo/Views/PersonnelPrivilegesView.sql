/*==============================================================*/
/* View: dbo.PersonnelPrivilegesView                                 */
/*==============================================================*/
CREATE VIEW dbo.PersonnelPrivilegesView AS
SELECT
      [PrivilegeId] AS [IdPrivileges]
      ,[Name]
      ,[Description]
      ,[Type]
      ,[TypeName]
      ,[OperationId]
      ,[Version]
FROM [PR_Authorization].Privilege
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'View to represent dbo.PersonnelPrivileges from the pre 3.0 Personnel model using the data from PR_Authorization.Privilege table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'PersonnelPrivilegesView';

