CREATE TABLE [dbo].[ServiceNamespace] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [Name]        NVARCHAR (255) NULL,
    [Description] NVARCHAR (255) NULL,
    [Version]     BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ServiceNamespace_Name]
    ON [dbo].[ServiceNamespace]([Name] ASC);

