CREATE TABLE [dbo].[SegmentParameter] (
    [S95Type]                    NVARCHAR (50)    NULL,
    [UnitOfMeasure]              NVARCHAR (50)    NULL,
    [PublishName]                NVARCHAR (255)   NULL,
    [SegmentParameterPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [Name]                       NVARCHAR (255)   NULL,
    [Description]                NVARCHAR (255)   NULL,
    [ValidationPattern]          NVARCHAR (255)   NULL,
    [DataType]                   INT              NULL,
    [Version]                    BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([SegmentParameterPropertyId] ASC)
);


GO
ALTER TABLE [dbo].[SegmentParameter] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

