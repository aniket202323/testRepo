CREATE TYPE [dbo].[ProcessOrderCustomPropertyTableParam] AS TABLE (
    [ProcessOrderId]       BIGINT         NULL,
    [PropertyDefinitionId] NVARCHAR (MAX) NULL,
    [PropertyValue]        NVARCHAR (MAX) NULL);

