CREATE TABLE [dbo].[PerActualPropTemplate] (
    [PerActualPropTemplateId]               UNIQUEIDENTIFIER NOT NULL,
    [Version]                               BIGINT           NULL,
    [SpecPersonnel_PersonnelSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [PropertyPersonId]                      UNIQUEIDENTIFIER NULL,
    [PropertyName]                          NVARCHAR (255)   NULL,
    [ClassPropertyPersonnelClassName]       NVARCHAR (200)   NULL,
    [ClassPropertyPropertyName]             NVARCHAR (200)   NULL,
    PRIMARY KEY CLUSTERED ([SpecPersonnel_PersonnelSpec_ProcSegId] ASC, [PerActualPropTemplateId] ASC),
    CONSTRAINT [PerActualPropTemplate_Property_Person_PersonnelClass_Relation1] FOREIGN KEY ([PropertyPersonId], [PropertyName]) REFERENCES [dbo].[Property_Person_PersonnelClass] ([PersonId], [Name]),
    CONSTRAINT [PerActualPropTemplate_Property_PersonnelClass_Relation1] FOREIGN KEY ([ClassPropertyPersonnelClassName], [ClassPropertyPropertyName]) REFERENCES [dbo].[Property_PersonnelClass] ([PersonnelClassName], [PropertyName]),
    CONSTRAINT [PerActualPropTemplate_SpecPersonnel_PersonnelSpec_ProcSeg_Relation1] FOREIGN KEY ([SpecPersonnel_PersonnelSpec_ProcSegId]) REFERENCES [dbo].[SpecPersonnel_PersonnelSpec_ProcSeg] ([SpecPersonnel_PersonnelSpec_ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_PerActualPropTemplate_PropertyPersonId_PropertyName]
    ON [dbo].[PerActualPropTemplate]([PropertyPersonId] ASC, [PropertyName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PerActualPropTemplate_ClassPropertyPersonnelClassName_ClassPropertyPropertyName]
    ON [dbo].[PerActualPropTemplate]([ClassPropertyPersonnelClassName] ASC, [ClassPropertyPropertyName] ASC);

