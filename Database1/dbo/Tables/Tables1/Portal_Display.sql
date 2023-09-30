CREATE TABLE [dbo].[Portal_Display] (
    [Id]       UNIQUEIDENTIFIER NOT NULL,
    [Path]     NVARCHAR (1024)  NOT NULL,
    [Name]     NVARCHAR (255)   NULL,
    [Document] IMAGE            NULL,
    [Version]  BIGINT           NULL,
    [PortalId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [Portal_Display_Portal_Server_Relation1] FOREIGN KEY ([PortalId]) REFERENCES [dbo].[Portal_Server] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_Portal_Display_Path]
    ON [dbo].[Portal_Display]([Path] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Portal_Display_PortalId]
    ON [dbo].[Portal_Display]([PortalId] ASC);

