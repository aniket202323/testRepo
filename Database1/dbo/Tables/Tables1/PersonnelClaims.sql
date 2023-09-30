CREATE TABLE [dbo].[PersonnelClaims] (
    [PersonnelClaimId] UNIQUEIDENTIFIER NOT NULL,
    [ResourceId]       NVARCHAR (2048)  NULL,
    [Location]         NVARCHAR (255)   NULL,
    [Scope]            SMALLINT         NULL,
    [Version]          BIGINT           NULL,
    [IdGroup]          UNIQUEIDENTIFIER NULL,
    [PersonId]         UNIQUEIDENTIFIER NULL,
    [IdRoles]          UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([PersonnelClaimId] ASC),
    CONSTRAINT [PersonnelClaims_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId]),
    CONSTRAINT [PersonnelClaims_PersonnelGroup_Relation1] FOREIGN KEY ([IdGroup]) REFERENCES [PR_Authorization].[UserGroup] ([UserGroupId]),
    CONSTRAINT [PersonnelClaims_PersonnelRole_Relation1] FOREIGN KEY ([IdRoles]) REFERENCES [dbo].[PersonnelRole] ([IdRoles])
);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelClaims_IdGroup]
    ON [dbo].[PersonnelClaims]([IdGroup] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelClaims_PersonId]
    ON [dbo].[PersonnelClaims]([PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_PersonnelClaims_IdRoles]
    ON [dbo].[PersonnelClaims]([IdRoles] ASC);

