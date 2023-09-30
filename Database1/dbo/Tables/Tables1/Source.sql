CREATE TABLE [dbo].[Source] (
    [Source_Id]          INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Application]        [dbo].[Varchar_Long_Desc] NULL,
    [ApplicationVersion] [dbo].[Varchar_Long_Desc] NULL,
    [DataSource_Id]      INT                       NOT NULL,
    [Device]             [dbo].[Varchar_Long_Desc] NULL,
    [Node]               [dbo].[Varchar_Long_Desc] NULL,
    [OPCItemID]          VARCHAR (255)             NULL,
    [OPCSource]          VARCHAR (255)             NOT NULL,
    [Process]            [dbo].[Varchar_Long_Desc] NULL,
    [Tag]                [dbo].[Varchar_Long_Desc] NULL,
    CONSTRAINT [Source_PK_SourceId] PRIMARY KEY CLUSTERED ([Source_Id] ASC),
    CONSTRAINT [Source_FK_DataSourceID] FOREIGN KEY ([DataSource_Id]) REFERENCES [dbo].[DataSource] ([DataSource_Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Source_UC_DatasourceIdOPCSource]
    ON [dbo].[Source]([DataSource_Id] ASC, [OPCSource] ASC);

