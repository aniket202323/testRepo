CREATE TABLE [dbo].[CompletionCodeDefinition] (
    [Description]                      NVARCHAR (255)   NULL,
    [DisplayName]                      NVARCHAR (50)    NULL,
    [Enabled]                          BIT              NULL,
    [CompletionCodeDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [CompletionCodeDefinitionRevision] BIGINT           NOT NULL,
    [LastModified]                     DATETIME         NULL,
    [UserVersion]                      NVARCHAR (128)   NULL,
    [Version]                          BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([CompletionCodeDefinitionId] ASC, [CompletionCodeDefinitionRevision] ASC)
);


GO
ALTER TABLE [dbo].[CompletionCodeDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);

