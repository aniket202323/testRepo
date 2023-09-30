CREATE TABLE [dbo].[RoleAndPrivileges] (
    [Version]      BIGINT           NULL,
    [IdRoles]      UNIQUEIDENTIFIER NOT NULL,
    [IdPrivileges] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([IdRoles] ASC, [IdPrivileges] ASC),
    CONSTRAINT [RoleAndPrivileges_PersonnelPrivileges_Relation1] FOREIGN KEY ([IdPrivileges]) REFERENCES [PR_Authorization].[Privilege] ([PrivilegeId]),
    CONSTRAINT [RoleAndPrivileges_PersonnelRole_Relation1] FOREIGN KEY ([IdRoles]) REFERENCES [dbo].[PersonnelRole] ([IdRoles])
);


GO
CREATE NONCLUSTERED INDEX [NC_RoleAndPrivileges_IdPrivileges]
    ON [dbo].[RoleAndPrivileges]([IdPrivileges] ASC);

