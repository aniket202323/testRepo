CREATE TABLE [dbo].[SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg] (
    [SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                                              NVARCHAR (255)   NULL,
    [Version]                                                        BIGINT           NULL,
    [PersonId]                                                       UNIQUEIDENTIFIER NULL,
    [PersonnelClassName]                                             NVARCHAR (200)   NULL,
    [ProdSegId]                                                      UNIQUEIDENTIFIER NULL,
    [ProcSegId]                                                      UNIQUEIDENTIFIER NULL,
    [PersonnelSpec_ProcSegId]                                        UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSegId] ASC),
    CONSTRAINT [SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]),
    CONSTRAINT [SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_PersonnelClass_Relation1] FOREIGN KEY ([PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_Relation1] FOREIGN KEY ([ProdSegId], [ProcSegId], [PersonnelSpec_ProcSegId]) REFERENCES [dbo].[SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg] ([ProdSegId], [ProcSegId], [PersonnelSpec_ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_PersonId]
    ON [dbo].[SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg]([PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_PersonnelClassName]
    ON [dbo].[SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg]([PersonnelClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg_ProdSegId_ProcSegId_PersonnelSpec_ProcSegId]
    ON [dbo].[SpecPersonnel_SyncPersonnel_ProductToProcess_ProdSeg_ProcSeg]([ProdSegId] ASC, [ProcSegId] ASC, [PersonnelSpec_ProcSegId] ASC);

