CREATE TABLE [dbo].[SpecPersonnel_PersonnelSpec_ProcSeg] (
    [SpecPersonnel_PersonnelSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                     NVARCHAR (255)   NULL,
    [Version]                               BIGINT           NULL,
    [PersonId]                              UNIQUEIDENTIFIER NULL,
    [PersonnelClassName]                    NVARCHAR (200)   NULL,
    [PersonnelSpec_ProcSegId]               UNIQUEIDENTIFIER NULL,
    [ProcSegId]                             UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecPersonnel_PersonnelSpec_ProcSegId] ASC),
    CONSTRAINT [SpecPersonnel_PersonnelSpec_ProcSeg_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]),
    CONSTRAINT [SpecPersonnel_PersonnelSpec_ProcSeg_PersonnelClass_Relation1] FOREIGN KEY ([PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecPersonnel_PersonnelSpec_ProcSeg_PersonnelSpec_ProcSeg_Relation1] FOREIGN KEY ([PersonnelSpec_ProcSegId], [ProcSegId]) REFERENCES [dbo].[PersonnelSpec_ProcSeg] ([PersonnelSpec_ProcSegId], [ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_PersonnelSpec_ProcSeg_PersonId]
    ON [dbo].[SpecPersonnel_PersonnelSpec_ProcSeg]([PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_PersonnelSpec_ProcSeg_PersonnelClassName]
    ON [dbo].[SpecPersonnel_PersonnelSpec_ProcSeg]([PersonnelClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_PersonnelSpec_ProcSeg_PersonnelSpec_ProcSegId_ProcSegId]
    ON [dbo].[SpecPersonnel_PersonnelSpec_ProcSeg]([PersonnelSpec_ProcSegId] ASC, [ProcSegId] ASC);

