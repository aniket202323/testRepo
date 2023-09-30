CREATE TABLE [dbo].[PersonnelPrivilegesLegacy] (
    [IdPrivileges] UNIQUEIDENTIFIER NOT NULL,
    [Name]         NVARCHAR (255)   NULL,
    [Description]  NVARCHAR (255)   NULL,
    [Type]         NVARCHAR (255)   NULL,
    [TypeName]     NVARCHAR (255)   NULL,
    [OperationId]  NVARCHAR (255)   NULL,
    [Version]      BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([IdPrivileges] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PersonnelPrivileges_Name]
    ON [dbo].[PersonnelPrivilegesLegacy]([Name] ASC);

