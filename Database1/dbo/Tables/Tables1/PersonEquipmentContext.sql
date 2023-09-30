CREATE TABLE [dbo].[PersonEquipmentContext] (
    [EquipmentContextAddress]    NVARCHAR (1024)  NULL,
    [PersonEquipmentContextPkId] UNIQUEIDENTIFIER NOT NULL,
    [Version]                    BIGINT           NULL,
    [PersonPersonId]             UNIQUEIDENTIFIER NULL,
    [Origin2PersonnelClassName]  NVARCHAR (200)   NULL,
    [Origin1PersonId]            UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([PersonEquipmentContextPkId] ASC),
    CONSTRAINT [PersonEquipmentContext_Person_Relation1] FOREIGN KEY ([PersonPersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]),
    CONSTRAINT [PersonEquipmentContext_Person_Relation2] FOREIGN KEY ([Origin1PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]) ON UPDATE CASCADE,
    CONSTRAINT [PersonEquipmentContext_PersonnelClass_Relation1] FOREIGN KEY ([Origin2PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PersonEquipmentContext_Origin2PersonnelClassName_Origin1PersonId]
    ON [dbo].[PersonEquipmentContext]([Origin2PersonnelClassName] ASC, [Origin1PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonEquipmentContext_PersonPersonId]
    ON [dbo].[PersonEquipmentContext]([PersonPersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonEquipmentContext_Origin1PersonId]
    ON [dbo].[PersonEquipmentContext]([Origin1PersonId] ASC);

