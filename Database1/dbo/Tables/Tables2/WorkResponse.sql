CREATE TABLE [dbo].[WorkResponse] (
    [WorkDefinitionS95Id]       NVARCHAR (50)    NULL,
    [WorkDefinitionUserVersion] NVARCHAR (255)   NULL,
    [ResponseState]             NVARCHAR (25)    NULL,
    [StartTime]                 DATETIME         NULL,
    [EndTime]                   DATETIME         NULL,
    [OriginWorkRequestId]       UNIQUEIDENTIFIER NULL,
    [WorkType]                  NVARCHAR (25)    NULL,
    [WorkResponseId]            UNIQUEIDENTIFIER NOT NULL,
    [S95Id]                     NVARCHAR (50)    NULL,
    [Description]               NVARCHAR (255)   NULL,
    [S95Type]                   NVARCHAR (50)    NULL,
    [LastModifiedTime]          DATETIME         NULL,
    [LastModifiedBy]            NVARCHAR (255)   NULL,
    [Version]                   BIGINT           NULL,
    [WorkRequestId]             UNIQUEIDENTIFIER NULL,
    [EquipmentId]               UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([WorkResponseId] ASC),
    CONSTRAINT [WorkResponse_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]) ON DELETE SET NULL,
    CONSTRAINT [WorkResponse_WorkRequest_Relation1] FOREIGN KEY ([WorkRequestId]) REFERENCES [dbo].[WorkRequest] ([WorkRequestId])
);


GO
CREATE NONCLUSTERED INDEX [IX_WorkResponse_WorkDefinitionS95Id]
    ON [dbo].[WorkResponse]([WorkDefinitionS95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_WorkResponse_LastModifiedTime]
    ON [dbo].[WorkResponse]([LastModifiedTime] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WorkResponse_S95Id]
    ON [dbo].[WorkResponse]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WorkResponse_WorkRequestId]
    ON [dbo].[WorkResponse]([WorkRequestId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WorkResponse_EquipmentId]
    ON [dbo].[WorkResponse]([EquipmentId] ASC);

