CREATE TABLE [dbo].[EventPropertyDefinition] (
    [EventPropertyDefinitionPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [Name]                              NVARCHAR (255)   NULL,
    [Description]                       NVARCHAR (255)   NULL,
    [ValidationPattern]                 NVARCHAR (255)   NULL,
    [DataType]                          INT              NULL,
    [Version]                           BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([EventPropertyDefinitionPropertyId] ASC)
);

