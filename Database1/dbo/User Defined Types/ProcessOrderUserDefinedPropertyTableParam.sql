CREATE TYPE [dbo].[ProcessOrderUserDefinedPropertyTableParam] AS TABLE (
    [ProcessOrderId]       BIGINT         NULL,
    [PropertyDefinitionId] BIGINT         NULL,
    [PropertyValue]        NVARCHAR (MAX) NULL,
    [TableId]              INT            NULL);

