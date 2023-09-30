CREATE TABLE [dbo].[WorkDataProperty] (
    [UnitOfMeasure]              NVARCHAR (50)    NULL,
    [PublishName]                NVARCHAR (255)   NULL,
    [WorkDataPropertyPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [Name]                       NVARCHAR (255)   NULL,
    [Description]                NVARCHAR (255)   NULL,
    [ValidationPattern]          NVARCHAR (255)   NULL,
    [DataType]                   INT              NULL,
    [Version]                    BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([WorkDataPropertyPropertyId] ASC)
);

