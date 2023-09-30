CREATE TABLE [dbo].[SegmentResponseWorkDataClass] (
    [WorkDataClassName] NVARCHAR (50)    NOT NULL,
    [Version]           BIGINT           NULL,
    [SegmentResponseId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([SegmentResponseId] ASC, [WorkDataClassName] ASC),
    CONSTRAINT [SegmentResponseWorkDataClass_SegmentResponse_Relation1] FOREIGN KEY ([SegmentResponseId]) REFERENCES [dbo].[SegmentResponse] ([SegmentResponseId])
);

