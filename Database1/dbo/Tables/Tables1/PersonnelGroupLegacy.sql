CREATE TABLE [dbo].[PersonnelGroupLegacy] (
    [IdGroup]     UNIQUEIDENTIFIER NOT NULL,
    [Name]        NVARCHAR (255)   NULL,
    [Description] NVARCHAR (255)   NULL,
    [Type]        NVARCHAR (255)   NULL,
    [Version]     BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([IdGroup] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PersonnelGroup_Name]
    ON [dbo].[PersonnelGroupLegacy]([Name] ASC);

