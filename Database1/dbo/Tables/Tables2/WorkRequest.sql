CREATE TABLE [dbo].[WorkRequest] (
    [WorkDefinitionS95Id]             NVARCHAR (50)    NULL,
    [WorkDefinitionUserVersion]       NVARCHAR (255)   NULL,
    [Status]                          NVARCHAR (25)    NULL,
    [ScheduledStartTime]              DATETIME         NULL,
    [ScheduledEndTime]                DATETIME         NULL,
    [CreationDate]                    DATETIME         NULL,
    [Priority]                        INT              NULL,
    [WorkType]                        NVARCHAR (25)    NULL,
    [SegmentRequirementMasterSegment] UNIQUEIDENTIFIER NULL,
    [WorkRequestId]                   UNIQUEIDENTIFIER NOT NULL,
    [S95Id]                           NVARCHAR (50)    NULL,
    [Description]                     NVARCHAR (255)   NULL,
    [S95Type]                         NVARCHAR (50)    NULL,
    [LastModifiedTime]                DATETIME         NULL,
    [LastModifiedBy]                  NVARCHAR (255)   NULL,
    [Version]                         BIGINT           NULL,
    [WorkDefinitionId]                UNIQUEIDENTIFIER NULL,
    [EquipmentId]                     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([WorkRequestId] ASC),
    CONSTRAINT [WorkRequest_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [WorkRequest_WorkDefinition_Relation1] FOREIGN KEY ([WorkDefinitionId]) REFERENCES [dbo].[WorkDefinition] ([WorkDefinitionId])
);


GO
ALTER TABLE [dbo].[WorkRequest] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_WorkRequest_WorkDefinitionS95Id]
    ON [dbo].[WorkRequest]([WorkDefinitionS95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_WorkRequest_LastModifiedTime]
    ON [dbo].[WorkRequest]([LastModifiedTime] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WorkRequest_S95Id]
    ON [dbo].[WorkRequest]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WorkRequest_WorkDefinitionId]
    ON [dbo].[WorkRequest]([WorkDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WorkRequest_EquipmentId]
    ON [dbo].[WorkRequest]([EquipmentId] ASC);

