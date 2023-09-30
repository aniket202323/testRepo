CREATE TABLE [dbo].[MaterialClass_MaterialDefinition] (
    [ClassOrder]           INT              NULL,
    [Version]              BIGINT           NULL,
    [MaterialClassName]    NVARCHAR (200)   NOT NULL,
    [MaterialDefinitionId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([MaterialClassName] ASC, [MaterialDefinitionId] ASC),
    CONSTRAINT [MaterialClass_MaterialDefinition_MaterialClass_Relation1] FOREIGN KEY ([MaterialClassName]) REFERENCES [dbo].[MaterialClass] ([MaterialClassName]) ON UPDATE CASCADE,
    CONSTRAINT [MaterialClass_MaterialDefinition_MaterialDefinition_Relation1] FOREIGN KEY ([MaterialDefinitionId]) REFERENCES [dbo].[MaterialDefinition] ([MaterialDefinitionId])
);


GO
ALTER TABLE [dbo].[MaterialClass_MaterialDefinition] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialClass_MaterialDefinition_MaterialDefinitionId]
    ON [dbo].[MaterialClass_MaterialDefinition]([MaterialDefinitionId] ASC);

