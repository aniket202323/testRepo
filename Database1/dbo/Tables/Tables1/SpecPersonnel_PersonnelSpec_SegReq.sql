CREATE TABLE [dbo].[SpecPersonnel_PersonnelSpec_SegReq] (
    [SpecPersonnel_PersonnelSpec_SegReqId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                    NVARCHAR (255)   NULL,
    [Version]                              BIGINT           NULL,
    [PersonId]                             UNIQUEIDENTIFIER NULL,
    [PersonnelClassName]                   NVARCHAR (200)   NULL,
    [PersonnelSpec_SegReqId]               UNIQUEIDENTIFIER NULL,
    [SegReqId]                             UNIQUEIDENTIFIER NULL,
    [WorkRequestId]                        UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecPersonnel_PersonnelSpec_SegReqId] ASC),
    CONSTRAINT [SpecPersonnel_PersonnelSpec_SegReq_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]),
    CONSTRAINT [SpecPersonnel_PersonnelSpec_SegReq_PersonnelClass_Relation1] FOREIGN KEY ([PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecPersonnel_PersonnelSpec_SegReq_PersonnelSpec_SegReq_Relation1] FOREIGN KEY ([PersonnelSpec_SegReqId], [SegReqId], [WorkRequestId]) REFERENCES [dbo].[PersonnelSpec_SegReq] ([PersonnelSpec_SegReqId], [SegReqId], [WorkRequestId])
);


GO
ALTER TABLE [dbo].[SpecPersonnel_PersonnelSpec_SegReq] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_PersonnelSpec_SegReq_PersonId]
    ON [dbo].[SpecPersonnel_PersonnelSpec_SegReq]([PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_PersonnelSpec_SegReq_PersonnelClassName]
    ON [dbo].[SpecPersonnel_PersonnelSpec_SegReq]([PersonnelClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_PersonnelSpec_SegReq_PersonnelSpec_SegReqId_SegReqId_WorkRequestId]
    ON [dbo].[SpecPersonnel_PersonnelSpec_SegReq]([PersonnelSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC);

