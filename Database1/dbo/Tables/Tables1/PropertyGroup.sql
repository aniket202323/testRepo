CREATE TABLE [dbo].[PropertyGroup] (
    [PropertyGroupId] UNIQUEIDENTIFIER NOT NULL,
    [Name]            NVARCHAR (255)   NULL,
    [Description]     NVARCHAR (255)   NULL,
    [Version]         BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([PropertyGroupId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PropertyGroup_Name]
    ON [dbo].[PropertyGroup]([Name] ASC);

