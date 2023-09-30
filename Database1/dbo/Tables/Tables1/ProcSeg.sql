CREATE TABLE [dbo].[ProcSeg] (
    [Enabled]               BIT              NULL,
    [PublishedDate]         DATETIME         NULL,
    [DurationUnitOfMeasure] NVARCHAR (255)   NULL,
    [IsMaster]              BIT              NULL,
    [Duration]              FLOAT (53)       NULL,
    [WorkType]              NVARCHAR (25)    NULL,
    [ProcSegId]             UNIQUEIDENTIFIER NOT NULL,
    [S95Id]                 NVARCHAR (50)    NULL,
    [Description]           NVARCHAR (255)   NULL,
    [S95Type]               NVARCHAR (50)    NULL,
    [LastModifiedTime]      DATETIME         NULL,
    [LastModifiedBy]        NVARCHAR (255)   NULL,
    [Version]               BIGINT           NULL,
    [EquipmentId]           UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ProcSegId] ASC),
    CONSTRAINT [ProcSeg_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId])
);


GO
ALTER TABLE [dbo].[ProcSeg] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_ProcSeg_LastModifiedTime]
    ON [dbo].[ProcSeg]([LastModifiedTime] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProcSeg_S95Id]
    ON [dbo].[ProcSeg]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_ProcSeg_EquipmentId]
    ON [dbo].[ProcSeg]([EquipmentId] ASC);

