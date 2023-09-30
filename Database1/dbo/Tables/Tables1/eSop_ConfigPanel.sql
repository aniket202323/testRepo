CREATE TABLE [dbo].[eSop_ConfigPanel] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [Name]         NVARCHAR (MAX)   NULL,
    [Description]  NVARCHAR (MAX)   NULL,
    [AssemblyName] NVARCHAR (MAX)   NULL,
    [ClassName]    NVARCHAR (MAX)   NULL,
    [Version]      INT              NOT NULL,
    [DisplayId]    UNIQUEIDENTIFIER NOT NULL,
    [LastModified] DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_ConfigPanel] PRIMARY KEY CLUSTERED ([Id] ASC)
);

