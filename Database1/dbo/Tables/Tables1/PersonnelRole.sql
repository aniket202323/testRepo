CREATE TABLE [dbo].[PersonnelRole] (
    [IdRoles]       UNIQUEIDENTIFIER NOT NULL,
    [Name]          NVARCHAR (255)   NULL,
    [Description]   NVARCHAR (255)   NULL,
    [Version]       BIGINT           NULL,
    [ParentIdRoles] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([IdRoles] ASC),
    CONSTRAINT [PersonnelRole_PersonnelRole_Relation1] FOREIGN KEY ([ParentIdRoles]) REFERENCES [dbo].[PersonnelRole] ([IdRoles])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PersonnelRole_Name]
    ON [dbo].[PersonnelRole]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelRole_ParentIdRoles]
    ON [dbo].[PersonnelRole]([ParentIdRoles] ASC);

