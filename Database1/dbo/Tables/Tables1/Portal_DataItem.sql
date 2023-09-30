CREATE TABLE [dbo].[Portal_DataItem] (
    [Id]            UNIQUEIDENTIFIER NOT NULL,
    [Name]          NVARCHAR (255)   NOT NULL,
    [SourceAddress] NVARCHAR (512)   NOT NULL,
    [Path]          NVARCHAR (1024)  NOT NULL,
    [DisplayName]   NVARCHAR (255)   NULL,
    [Description]   NVARCHAR (255)   NULL,
    [Version]       BIGINT           NULL,
    [DataSourceId]  UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [Portal_DataItem_Portal_DataSource_Relation1] FOREIGN KEY ([DataSourceId]) REFERENCES [dbo].[Portal_DataSource] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_Portal_DataItem_DataSourceId]
    ON [dbo].[Portal_DataItem]([DataSourceId] ASC);

