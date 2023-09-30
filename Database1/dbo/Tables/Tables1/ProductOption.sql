CREATE TABLE [dbo].[ProductOption] (
    [Id]            UNIQUEIDENTIFIER NOT NULL,
    [Name]          NVARCHAR (255)   NULL,
    [MajorVersion]  NVARCHAR (255)   NULL,
    [Description]   NVARCHAR (255)   NULL,
    [DeploymentKey] UNIQUEIDENTIFIER NULL,
    [Version]       BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProductOption_Name_MajorVersion]
    ON [dbo].[ProductOption]([Name] ASC, [MajorVersion] ASC);

