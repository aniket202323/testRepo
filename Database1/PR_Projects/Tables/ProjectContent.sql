CREATE TABLE [PR_Projects].[ProjectContent] (
    [Key]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [ProjectKey]  BIGINT         NOT NULL,
    [LDAP]        NVARCHAR (255) NOT NULL,
    [ContentType] NVARCHAR (50)  NOT NULL,
    [Name]        NVARCHAR (50)  NOT NULL,
    [Description] NVARCHAR (255) NULL,
    CONSTRAINT [PK_ProjectContent] PRIMARY KEY CLUSTERED ([Key] ASC),
    CONSTRAINT [FK_ProjectContent_ProjectInfo] FOREIGN KEY ([ProjectKey]) REFERENCES [PR_Projects].[ProjectInfo] ([Key]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_ProjectContent_ProjectKey]
    ON [PR_Projects].[ProjectContent]([ProjectKey] ASC, [LDAP] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table contains the list of content for a Project.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectContent';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Integer identifier used for the ProjectContent primary key.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectContent', @level2type = N'COLUMN', @level2name = N'Key';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ProjectInfo.Key value for the project to which this project content record belongs.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectContent', @level2type = N'COLUMN', @level2name = N'ProjectKey';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The LDAP address of the content.', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectContent', @level2type = N'COLUMN', @level2name = N'LDAP';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The content type.  (i.e: Equipment, Material, Personnel etc.)', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectContent', @level2type = N'COLUMN', @level2name = N'ContentType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The name (S95Id) of the Project content. (i.e: Equipment.S95Id)', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectContent', @level2type = N'COLUMN', @level2name = N'Name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The description of the Project content. (i.e: Equipment.Description)', @level0type = N'SCHEMA', @level0name = N'PR_Projects', @level1type = N'TABLE', @level1name = N'ProjectContent', @level2type = N'COLUMN', @level2name = N'Description';

