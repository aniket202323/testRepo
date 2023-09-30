CREATE TABLE [dbo].[MaterialDefinition] (
    [S95Id]                NVARCHAR (255)   NULL,
    [MaterialDefinitionId] UNIQUEIDENTIFIER NOT NULL,
    [Description]          NVARCHAR (255)   NULL,
    [Version]              BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([MaterialDefinitionId] ASC)
);


GO
ALTER TABLE [dbo].[MaterialDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MaterialDefinition_S95Id]
    ON [dbo].[MaterialDefinition]([S95Id] ASC);

