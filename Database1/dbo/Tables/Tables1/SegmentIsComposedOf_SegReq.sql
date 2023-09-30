CREATE TABLE [dbo].[SegmentIsComposedOf_SegReq] (
    [Name]                       NVARCHAR (50)    NOT NULL,
    [r_Order]                    INT              NULL,
    [Version]                    BIGINT           NULL,
    [ParentSegmentSegReqId]      UNIQUEIDENTIFIER NOT NULL,
    [ParentSegmentWorkRequestId] UNIQUEIDENTIFIER NOT NULL,
    [ChildSegmentSegReqId]       UNIQUEIDENTIFIER NULL,
    [ChildSegmentWorkRequestId]  UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ParentSegmentSegReqId] ASC, [ParentSegmentWorkRequestId] ASC, [Name] ASC),
    CONSTRAINT [SegmentIsComposedOf_SegReq_SegReq_Relation1] FOREIGN KEY ([ParentSegmentSegReqId], [ParentSegmentWorkRequestId]) REFERENCES [dbo].[SegReq] ([SegReqId], [WorkRequestId]),
    CONSTRAINT [SegmentIsComposedOf_SegReq_SegReq_Relation2] FOREIGN KEY ([ChildSegmentSegReqId], [ChildSegmentWorkRequestId]) REFERENCES [dbo].[SegReq] ([SegReqId], [WorkRequestId])
);


GO
ALTER TABLE [dbo].[SegmentIsComposedOf_SegReq] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentIsComposedOf_SegReq_Name]
    ON [dbo].[SegmentIsComposedOf_SegReq]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentIsComposedOf_SegReq_ChildSegmentSegReqId_ChildSegmentWorkRequestId]
    ON [dbo].[SegmentIsComposedOf_SegReq]([ChildSegmentSegReqId] ASC, [ChildSegmentWorkRequestId] ASC);

