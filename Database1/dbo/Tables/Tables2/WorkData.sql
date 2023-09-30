CREATE TABLE [dbo].[WorkData] (
    [Name]              NVARCHAR (50)    NOT NULL,
    [ClassName]         NVARCHAR (50)    NOT NULL,
    [Description]       NVARCHAR (255)   NULL,
    [DataType]          INT              NULL,
    [Value]             SQL_VARIANT      NULL,
    [UnitOfMeasure]     NVARCHAR (50)    NULL,
    [LastModifiedTime]  DATETIME         NULL,
    [Version]           BIGINT           NULL,
    [SegmentResponseId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([SegmentResponseId] ASC, [Name] ASC, [ClassName] ASC),
    CONSTRAINT [WorkData_SegmentResponse_Relation1] FOREIGN KEY ([SegmentResponseId]) REFERENCES [dbo].[SegmentResponse] ([SegmentResponseId])
);


GO
CREATE NONCLUSTERED INDEX [IX_WorkData_ClassName]
    ON [dbo].[WorkData]([ClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_WorkData_LastModifiedTime]
    ON [dbo].[WorkData]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PFM_Name_ClassName_Value_SegmentResponseId]
    ON [dbo].[WorkData]([Name] ASC, [ClassName] ASC)
    INCLUDE([Value], [SegmentResponseId]);

