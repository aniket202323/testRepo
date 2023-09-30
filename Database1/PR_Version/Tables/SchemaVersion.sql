CREATE TABLE [PR_Version].[SchemaVersion] (
    [Key]                  BIGINT         IDENTITY (1, 1) NOT NULL,
    [SchemaName]           NVARCHAR (50)  NOT NULL,
    [SchemaDescription]    NVARCHAR (100) NOT NULL,
    [SchemaVersion]        INT            NOT NULL,
    [PublisherVersion]     NVARCHAR (20)  NULL,
    [PublisherDescription] NVARCHAR (255) NULL,
    [LastModifiedDate]     DATETIME2 (7)  DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_SchemaVersion] PRIMARY KEY CLUSTERED ([Key] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_SchemaVersion_Name]
    ON [PR_Version].[SchemaVersion]([SchemaName] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table to contain version information for Proficy schemas.', @level0type = N'SCHEMA', @level0name = N'PR_Version', @level1type = N'TABLE', @level1name = N'SchemaVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The unique identifier for the Version table records.', @level0type = N'SCHEMA', @level0name = N'PR_Version', @level1type = N'TABLE', @level1name = N'SchemaVersion', @level2type = N'COLUMN', @level2name = N'Key';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The schema name. Must be unique.', @level0type = N'SCHEMA', @level0name = N'PR_Version', @level1type = N'TABLE', @level1name = N'SchemaVersion', @level2type = N'COLUMN', @level2name = N'SchemaName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Brief description for the schema.', @level0type = N'SCHEMA', @level0name = N'PR_Version', @level1type = N'TABLE', @level1name = N'SchemaVersion', @level2type = N'COLUMN', @level2name = N'SchemaDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Schema version.  Increments by 10.', @level0type = N'SCHEMA', @level0name = N'PR_Version', @level1type = N'TABLE', @level1name = N'SchemaVersion', @level2type = N'COLUMN', @level2name = N'SchemaVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Proficy product version as supplied by ConfigureDatabase.', @level0type = N'SCHEMA', @level0name = N'PR_Version', @level1type = N'TABLE', @level1name = N'SchemaVersion', @level2type = N'COLUMN', @level2name = N'PublisherVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This column can optionally be used to further describe the schema or its version. ', @level0type = N'SCHEMA', @level0name = N'PR_Version', @level1type = N'TABLE', @level1name = N'SchemaVersion', @level2type = N'COLUMN', @level2name = N'PublisherDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The timestamp for when the record was created or last updated.', @level0type = N'SCHEMA', @level0name = N'PR_Version', @level1type = N'TABLE', @level1name = N'SchemaVersion', @level2type = N'COLUMN', @level2name = N'LastModifiedDate';

