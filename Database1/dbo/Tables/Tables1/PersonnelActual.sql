CREATE TABLE [dbo].[PersonnelActual] (
    [S95Id]                  NVARCHAR (50)    NULL,
    [QuantityUnitOfMeasure]  NVARCHAR (50)    NULL,
    [Quantity]               FLOAT (53)       NULL,
    [r_Use]                  NVARCHAR (255)   NULL,
    [StartTime]              DATETIME         NULL,
    [EndTime]                DATETIME         NULL,
    [PersonnelActualId]      UNIQUEIDENTIFIER NOT NULL,
    [Description]            NVARCHAR (255)   NULL,
    [S95Type]                NVARCHAR (50)    NULL,
    [LastModifiedTime]       DATETIME         NULL,
    [LastModifiedBy]         NVARCHAR (255)   NULL,
    [Version]                BIGINT           NULL,
    [PersonId]               UNIQUEIDENTIFIER NULL,
    [PersonnelClassName]     NVARCHAR (200)   NULL,
    [SegmentResponseId]      UNIQUEIDENTIFIER NULL,
    [PersonnelSpec_SegReqId] UNIQUEIDENTIFIER NULL,
    [SegReqId]               UNIQUEIDENTIFIER NULL,
    [WorkRequestId]          UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([PersonnelActualId] ASC),
    CONSTRAINT [PersonnelActual_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]),
    CONSTRAINT [PersonnelActual_PersonnelClass_Relation1] FOREIGN KEY ([PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]),
    CONSTRAINT [PersonnelActual_PersonnelSpec_SegReq_Relation1] FOREIGN KEY ([PersonnelSpec_SegReqId], [SegReqId], [WorkRequestId]) REFERENCES [dbo].[PersonnelSpec_SegReq] ([PersonnelSpec_SegReqId], [SegReqId], [WorkRequestId]) ON DELETE SET NULL,
    CONSTRAINT [PersonnelActual_SegmentResponse_Relation1] FOREIGN KEY ([SegmentResponseId]) REFERENCES [dbo].[SegmentResponse] ([SegmentResponseId])
);


GO
CREATE NONCLUSTERED INDEX [IX_PersonnelActual_LastModifiedTime]
    ON [dbo].[PersonnelActual]([LastModifiedTime] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PersonnelActual_S95Id]
    ON [dbo].[PersonnelActual]([S95Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelActual_PersonId]
    ON [dbo].[PersonnelActual]([PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelActual_PersonnelClassName]
    ON [dbo].[PersonnelActual]([PersonnelClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelActual_PersonnelSpec_SegReqId_SegReqId_WorkRequestId]
    ON [dbo].[PersonnelActual]([PersonnelSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelActual_SegmentResponseId]
    ON [dbo].[PersonnelActual]([SegmentResponseId] ASC);

