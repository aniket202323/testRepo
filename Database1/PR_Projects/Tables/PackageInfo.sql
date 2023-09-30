CREATE TABLE [PR_Projects].[PackageInfo] (
    [Key]            BIGINT        IDENTITY (1, 1) NOT NULL,
    [ProjectKey]     BIGINT        NOT NULL,
    [InfoType]       CHAR (1)      NOT NULL,
    [ProjectVersion] NVARCHAR (50) NOT NULL,
    [Timestamp]      DATETIME2 (7) NOT NULL,
    [Author]         NVARCHAR (50) NOT NULL,
    [ServerName]     NVARCHAR (50) NOT NULL,
    [ServerVersion]  NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_PackageInfo] PRIMARY KEY CLUSTERED ([Key] ASC),
    CONSTRAINT [CK_PackageInfo_Type] CHECK ([InfoType]='P' OR [InfoType]='D'),
    CONSTRAINT [FK_PackageInfo_ProjectInfo] FOREIGN KEY ([ProjectKey]) REFERENCES [PR_Projects].[ProjectInfo] ([Key]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_PackageInfo_ProjectKey]
    ON [PR_Projects].[PackageInfo]([ProjectKey] ASC, [InfoType] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table contains the last packaging and deployment information for a Project.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'PackageInfo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Integer identifier used for the PackageInfo primary key. Automatically populated by the database.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'PackageInfo', @level2type = N'COLUMN', @level2name = N'Key';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ProjectInfo.Key value for the project to which this package info record belongs.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'PackageInfo', @level2type = N'COLUMN', @level2name = N'ProjectKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The PackageInfo type. D - deployment, P - packaging', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'PackageInfo', @level2type = N'COLUMN', @level2name = N'InfoType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The version of the project when it was packaged or deployed.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'PackageInfo', @level2type = N'COLUMN', @level2name = N'ProjectVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The timestamp of when the project was last packaged or deployed.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'PackageInfo', @level2type = N'COLUMN', @level2name = N'Timestamp';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The user name (User.S95Id) of the user who last packaged or deployed the project.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'PackageInfo', @level2type = N'COLUMN', @level2name = N'Author';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Server name on which the project was packaged or deployed.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'PackageInfo', @level2type = N'COLUMN', @level2name = N'ServerName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Server version on which the project was packaged or deployed. (<major>.<minor>.<sp>.<sim>).', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'PackageInfo', @level2type = N'COLUMN', @level2name = N'ServerVersion';

