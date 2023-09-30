CREATE TABLE [dbo].[SpecPersonnel_PersonnelSpec_ProdSeg] (
    [SpecPersonnel_PersonnelSpec_ProdSegId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                     NVARCHAR (255)   NULL,
    [Version]                               BIGINT           NULL,
    [PersonId]                              UNIQUEIDENTIFIER NULL,
    [PersonnelClassName]                    NVARCHAR (200)   NULL,
    [PersonnelSpec_ProdSegId]               UNIQUEIDENTIFIER NULL,
    [ProdSegId]                             UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecPersonnel_PersonnelSpec_ProdSegId] ASC),
    CONSTRAINT [SpecPersonnel_PersonnelSpec_ProdSeg_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]),
    CONSTRAINT [SpecPersonnel_PersonnelSpec_ProdSeg_PersonnelClass_Relation1] FOREIGN KEY ([PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecPersonnel_PersonnelSpec_ProdSeg_PersonnelSpec_ProdSeg_Relation1] FOREIGN KEY ([PersonnelSpec_ProdSegId], [ProdSegId]) REFERENCES [dbo].[PersonnelSpec_ProdSeg] ([PersonnelSpec_ProdSegId], [ProdSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_PersonnelSpec_ProdSeg_PersonId]
    ON [dbo].[SpecPersonnel_PersonnelSpec_ProdSeg]([PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_PersonnelSpec_ProdSeg_PersonnelClassName]
    ON [dbo].[SpecPersonnel_PersonnelSpec_ProdSeg]([PersonnelClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecPersonnel_PersonnelSpec_ProdSeg_PersonnelSpec_ProdSegId_ProdSegId]
    ON [dbo].[SpecPersonnel_PersonnelSpec_ProdSeg]([PersonnelSpec_ProdSegId] ASC, [ProdSegId] ASC);

