CREATE TABLE [dbo].[DataSource] (
    [DataSource_Id] INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [DataSource]    [dbo].[Varchar_Long_Desc] NULL,
    [Node]          [dbo].[Varchar_Long_Desc] NULL,
    CONSTRAINT [DataSource_PK_DataSourceId] PRIMARY KEY NONCLUSTERED ([DataSource_Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [DataSource_UC_DataSourceDesc]
    ON [dbo].[DataSource]([DataSource] ASC);

