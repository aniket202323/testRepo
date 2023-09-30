CREATE TABLE [dbo].[Portal_Statement] (
    [Id]         UNIQUEIDENTIFIER NOT NULL,
    [Path]       NVARCHAR (1024)  NOT NULL,
    [Name]       NVARCHAR (255)   NULL,
    [DataSource] NVARCHAR (255)   NULL,
    [Version]    BIGINT           NULL,
    [PortalId]   UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [Portal_Statement_Portal_Server_Relation1] FOREIGN KEY ([PortalId]) REFERENCES [dbo].[Portal_Server] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_Portal_Statement_Path]
    ON [dbo].[Portal_Statement]([Path] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Portal_Statement_PortalId]
    ON [dbo].[Portal_Statement]([PortalId] ASC);

