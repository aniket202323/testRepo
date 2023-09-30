CREATE TABLE [erp].[Route] (
    [id]                 BIGINT         IDENTITY (1, 1) NOT NULL,
    [bomFormulationId]   BIGINT         NULL,
    [createdBy]          VARCHAR (255)  NULL,
    [createdOn]          DATETIME2 (7)  NULL,
    [description]        VARCHAR (1000) NULL,
    [lastModifiedBy]     VARCHAR (255)  NULL,
    [lastModifiedOn]     DATETIME2 (7)  NULL,
    [latest]             BIT            NULL,
    [name]               VARCHAR (100)  NOT NULL,
    [producedMaterialId] BIGINT         NOT NULL,
    [productionLineId]   BIGINT         NOT NULL,
    [released]           BIT            NULL,
    [revision]           INT            NOT NULL,
    [state]              BIT            NULL,
    [status]             VARCHAR (50)   NULL,
    [version]            INT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [U_ROUTE_NAME] UNIQUE NONCLUSTERED ([name] ASC, [revision] ASC)
);

