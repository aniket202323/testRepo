CREATE TABLE [PR_Projects].[ProjectInfo] (
    [Key]                  BIGINT           IDENTITY (1, 1) NOT NULL,
    [ProjectId]            UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL,
    [Name]                 NVARCHAR (50)    NOT NULL,
    [Description]          NVARCHAR (255)   NULL,
    [VersionMajor]         INT              DEFAULT ((1)) NOT NULL,
    [VersionMinor]         INT              DEFAULT ((0)) NOT NULL,
    [VersionBuild]         INT              DEFAULT ((0)) NOT NULL,
    [VersionRevision]      INT              DEFAULT ((1)) NOT NULL,
    [LastUpdatedAuthor]    NVARCHAR (50)    NOT NULL,
    [LastUpdatedTimestamp] DATETIME2 (7)    DEFAULT (getdate()) NOT NULL,
    [DeployedAuthor]       NVARCHAR (50)    NULL,
    [DeployedTimestamp]    DATETIME2 (7)    NULL,
    CONSTRAINT [PK_ProjectInfo] PRIMARY KEY CLUSTERED ([Key] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_ProjectInfo_Name]
    ON [PR_Projects].[ProjectInfo]([Name] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_ProjectInfo_ProjectId]
    ON [PR_Projects].[ProjectInfo]([ProjectId] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table contains the metadata for a Project', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Integer identifier used for the ProjectInfo primary key.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'Key';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'GUID for ProjectInfo record. Used for import.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'ProjectId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'User-defined name for the project. Required.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'Name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Project description. Optional.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'Description';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'User-defined Project major version. Default is 1. (<major>.<minor>.<build>.<revision>)', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'VersionMajor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'User-defined Project minor version.  Default is 0. (<major>.<minor>.<build>.<revision>)', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'VersionMinor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Project build version.  Default is 0 (<major>.<minor>.<build>.<revision>)', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'VersionBuild';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Project revision number.  Incremented each time the ProjectInfo record is updated.(<major>.<minor>.<build>.<revision>)', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'VersionRevision';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'User name (Person.S95Id) of user who last saved a change to the Project. ', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'LastUpdatedAuthor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The timestamp of the last saved change.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'LastUpdatedTimestamp';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'User name (Person.S95Id) of user who last deployed the Project.  Null if the Project has never been deployed.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'DeployedAuthor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The timestamp of the last deployment of the Project.  Null if the Project has never been deployed.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectInfo', @level2type = N'COLUMN', @level2name = N'DeployedTimestamp';

