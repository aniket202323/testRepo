CREATE TABLE [erp].[SegmentsDefinition] (
    [id]                BIGINT         IDENTITY (1, 1) NOT NULL,
    [routeId]           BIGINT         NOT NULL,
    [segmentDefinition] VARCHAR (8000) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [U_SGMNNTN_ROUTEID] UNIQUE NONCLUSTERED ([routeId] ASC)
);

