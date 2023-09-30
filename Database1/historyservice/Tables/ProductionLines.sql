CREATE TABLE [historyservice].[ProductionLines] (
    [Id]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description] NVARCHAR (255) NULL,
    [LineId]      BIGINT         NULL,
    [Name]        NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [U_PRDCLNS_LINEID] UNIQUE NONCLUSTERED ([LineId] ASC)
);

