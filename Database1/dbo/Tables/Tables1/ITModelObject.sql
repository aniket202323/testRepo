CREATE TABLE [dbo].[ITModelObject] (
    [Type]           NVARCHAR (255) NOT NULL,
    [Name]           NVARCHAR (255) NOT NULL,
    [Id]             NVARCHAR (255) NULL,
    [Classification] NVARCHAR (255) NULL,
    [Description]    NVARCHAR (255) NULL,
    [IconID]         NVARCHAR (255) NULL,
    [Version]        BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Type] ASC, [Name] ASC)
);

