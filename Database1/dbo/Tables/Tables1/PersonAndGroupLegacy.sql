CREATE TABLE [dbo].[PersonAndGroupLegacy] (
    [Version]  BIGINT           NULL,
    [PersonId] UNIQUEIDENTIFIER NOT NULL,
    [IdGroup]  UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([PersonId] ASC, [IdGroup] ASC),
    CONSTRAINT [PersonAndGroup_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [dbo].[PersonLegacy] ([PersonId]),
    CONSTRAINT [PersonAndGroup_PersonnelGroup_Relation1] FOREIGN KEY ([IdGroup]) REFERENCES [dbo].[PersonnelGroupLegacy] ([IdGroup])
);


GO
CREATE NONCLUSTERED INDEX [NC_PersonAndGroup_PersonId]
    ON [dbo].[PersonAndGroupLegacy]([PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonAndGroup_IdGroup]
    ON [dbo].[PersonAndGroupLegacy]([IdGroup] ASC);

