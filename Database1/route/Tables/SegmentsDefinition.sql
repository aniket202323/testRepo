CREATE TABLE [route].[SegmentsDefinition] (
    [id]                 BIGINT         IDENTITY (1, 1) NOT NULL,
    [routeId]            BIGINT         NOT NULL,
    [segmentsDefinition] NVARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_Route_RouteId] FOREIGN KEY ([routeId]) REFERENCES [route].[Route] ([id]),
    CONSTRAINT [U_SGMNNTN_ROUTEID] UNIQUE NONCLUSTERED ([routeId] ASC)
);

