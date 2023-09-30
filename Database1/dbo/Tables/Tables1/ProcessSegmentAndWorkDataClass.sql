CREATE TABLE [dbo].[ProcessSegmentAndWorkDataClass] (
    [IsRequired]           BIT              NULL,
    [Version]              BIGINT           NULL,
    [ProcSegId]            UNIQUEIDENTIFIER NOT NULL,
    [WorkDataClassClassId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ProcSegId] ASC, [WorkDataClassClassId] ASC),
    CONSTRAINT [ProcessSegmentAndWorkDataClass_ProcSeg_Relation1] FOREIGN KEY ([ProcSegId]) REFERENCES [dbo].[ProcSeg] ([ProcSegId]),
    CONSTRAINT [ProcessSegmentAndWorkDataClass_WorkDataClass_Relation1] FOREIGN KEY ([WorkDataClassClassId]) REFERENCES [dbo].[WorkDataClass] ([WorkDataClassClassId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ProcessSegmentAndWorkDataClass_WorkDataClassClassId]
    ON [dbo].[ProcessSegmentAndWorkDataClass]([WorkDataClassClassId] ASC);

