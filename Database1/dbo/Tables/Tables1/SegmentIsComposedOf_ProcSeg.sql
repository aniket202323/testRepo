CREATE TABLE [dbo].[SegmentIsComposedOf_ProcSeg] (
    [Name]                   NVARCHAR (50)    NOT NULL,
    [r_Order]                INT              NULL,
    [Version]                BIGINT           NULL,
    [ParentSegmentProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [ChildSegmentProcSegId]  UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ParentSegmentProcSegId] ASC, [Name] ASC),
    CONSTRAINT [SegmentIsComposedOf_ProcSeg_ProcSeg_Relation1] FOREIGN KEY ([ParentSegmentProcSegId]) REFERENCES [dbo].[ProcSeg] ([ProcSegId]),
    CONSTRAINT [SegmentIsComposedOf_ProcSeg_ProcSeg_Relation2] FOREIGN KEY ([ChildSegmentProcSegId]) REFERENCES [dbo].[ProcSeg] ([ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentIsComposedOf_ProcSeg_Name]
    ON [dbo].[SegmentIsComposedOf_ProcSeg]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SegmentIsComposedOf_ProcSeg_ChildSegmentProcSegId]
    ON [dbo].[SegmentIsComposedOf_ProcSeg]([ChildSegmentProcSegId] ASC);

