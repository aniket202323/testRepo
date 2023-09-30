CREATE TABLE [dbo].[GroupAndPersonLegacy] (
    [Version]  BIGINT           NULL,
    [PersonId] UNIQUEIDENTIFIER NOT NULL,
    [IdGroup]  UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([PersonId] ASC, [IdGroup] ASC),
    CONSTRAINT [GroupAndPerson_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [dbo].[PersonLegacy] ([PersonId]),
    CONSTRAINT [GroupAndPerson_PersonnelGroup_Relation1] FOREIGN KEY ([IdGroup]) REFERENCES [dbo].[PersonnelGroupLegacy] ([IdGroup])
);


GO
CREATE NONCLUSTERED INDEX [NC_GroupAndPerson_PersonId]
    ON [dbo].[GroupAndPersonLegacy]([PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_GroupAndPerson_IdGroup]
    ON [dbo].[GroupAndPersonLegacy]([IdGroup] ASC);

