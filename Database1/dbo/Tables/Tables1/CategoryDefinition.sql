CREATE TABLE [dbo].[CategoryDefinition] (
    [Description]                NVARCHAR (255)   NULL,
    [DisplayName]                NVARCHAR (50)    NULL,
    [Enabled]                    BIT              NULL,
    [CategoryDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [CategoryDefinitionRevision] BIGINT           NOT NULL,
    [LastModified]               DATETIME         NULL,
    [UserVersion]                NVARCHAR (128)   NULL,
    [Version]                    BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([CategoryDefinitionId] ASC, [CategoryDefinitionRevision] ASC)
);


GO
ALTER TABLE [dbo].[CategoryDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

