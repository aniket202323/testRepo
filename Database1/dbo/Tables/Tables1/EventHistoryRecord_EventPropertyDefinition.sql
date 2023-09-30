CREATE TABLE [dbo].[EventHistoryRecord_EventPropertyDefinition] (
    [r_Order]                           INT              NULL,
    [Value]                             SQL_VARIANT      NULL,
    [Quality]                           SMALLINT         NULL,
    [TimeStamp]                         DATETIME         NULL,
    [Version]                           BIGINT           NULL,
    [EventId]                           UNIQUEIDENTIFIER NOT NULL,
    [EventPropertyDefinitionPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                            UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([EventId] ASC, [EventPropertyDefinitionPropertyId] ASC),
    CONSTRAINT [EventHistoryRecord_EventPropertyDefinition_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [EventHistoryRecord_EventPropertyDefinition_EventHistory_Relation1] FOREIGN KEY ([EventId]) REFERENCES [dbo].[EventHistory] ([EventId]),
    CONSTRAINT [EventHistoryRecord_EventPropertyDefinition_EventPropertyDefinition_Relation1] FOREIGN KEY ([EventPropertyDefinitionPropertyId]) REFERENCES [dbo].[EventPropertyDefinition] ([EventPropertyDefinitionPropertyId])
);


GO
CREATE NONCLUSTERED INDEX [NC_EventHistoryRecord_EventPropertyDefinition_EventPropertyDefinitionPropertyId]
    ON [dbo].[EventHistoryRecord_EventPropertyDefinition]([EventPropertyDefinitionPropertyId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_EventHistoryRecord_EventPropertyDefinition_ItemId]
    ON [dbo].[EventHistoryRecord_EventPropertyDefinition]([ItemId] ASC);

