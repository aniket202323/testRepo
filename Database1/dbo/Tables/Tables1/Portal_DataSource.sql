CREATE TABLE [dbo].[Portal_DataSource] (
    [Id]            UNIQUEIDENTIFIER NOT NULL,
    [Name]          NVARCHAR (255)   NOT NULL,
    [Configuration] NVARCHAR (1024)  NULL,
    [Type]          NVARCHAR (255)   NULL,
    [Version]       BIGINT           NULL,
    [PortalId]      UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [Portal_DataSource_Portal_Server_Relation1] FOREIGN KEY ([PortalId]) REFERENCES [dbo].[Portal_Server] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_Portal_DataSource_Name]
    ON [dbo].[Portal_DataSource]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Portal_DataSource_PortalId]
    ON [dbo].[Portal_DataSource]([PortalId] ASC);

