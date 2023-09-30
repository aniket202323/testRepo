CREATE TABLE [dbo].[Users_Aspect_Person] (
    [Users_Aspect_PersonPkId]   UNIQUEIDENTIFIER NOT NULL,
    [Version]                   BIGINT           NULL,
    [User_Id]                   INT              NULL,
    [Origin2PersonnelClassName] NVARCHAR (200)   NULL,
    [Origin1PersonId]           UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Users_Aspect_PersonPkId] ASC),
    CONSTRAINT [Users_Aspect_Person_Person_Relation1] FOREIGN KEY ([Origin1PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]),
    CONSTRAINT [Users_Aspect_Person_PersonnelClass_Relation1] FOREIGN KEY ([Origin2PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON UPDATE CASCADE,
    CONSTRAINT [Users_Aspect_Person_Users_Base_Relation1] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]) ON DELETE SET NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Users_Aspect_Person_User_Id]
    ON [dbo].[Users_Aspect_Person]([User_Id] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Users_Aspect_Person_Origin2PersonnelClassName_Origin1PersonId]
    ON [dbo].[Users_Aspect_Person]([Origin2PersonnelClassName] ASC, [Origin1PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Users_Aspect_Person_User_Id]
    ON [dbo].[Users_Aspect_Person]([User_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Users_Aspect_Person_Origin2PersonnelClassName]
    ON [dbo].[Users_Aspect_Person]([Origin2PersonnelClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Users_Aspect_Person_Origin1PersonId]
    ON [dbo].[Users_Aspect_Person]([Origin1PersonId] ASC);

