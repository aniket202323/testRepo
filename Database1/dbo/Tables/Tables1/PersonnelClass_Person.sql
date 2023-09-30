CREATE TABLE [dbo].[PersonnelClass_Person] (
    [ClassOrder]         INT              NULL,
    [Version]            BIGINT           NULL,
    [PersonnelClassName] NVARCHAR (200)   NOT NULL,
    [PersonId]           UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([PersonnelClassName] ASC, [PersonId] ASC),
    CONSTRAINT [PersonnelClass_Person_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]),
    CONSTRAINT [PersonnelClass_Person_PersonnelClass_Relation1] FOREIGN KEY ([PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON UPDATE CASCADE
);


GO
ALTER TABLE [dbo].[PersonnelClass_Person] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelClass_Person_PersonId]
    ON [dbo].[PersonnelClass_Person]([PersonId] ASC);

