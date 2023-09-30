CREATE TABLE [dbo].[FaultDefinition] (
    [Message]                 NVARCHAR (1024)  NULL,
    [Description]             NVARCHAR (255)   NULL,
    [DisplayName]             NVARCHAR (50)    NULL,
    [Enabled]                 BIT              NULL,
    [FaultDefinitionId]       UNIQUEIDENTIFIER NOT NULL,
    [FaultDefinitionRevision] BIGINT           NOT NULL,
    [LastModified]            DATETIME         NULL,
    [UserVersion]             NVARCHAR (128)   NULL,
    [Version]                 BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([FaultDefinitionId] ASC, [FaultDefinitionRevision] ASC)
);

