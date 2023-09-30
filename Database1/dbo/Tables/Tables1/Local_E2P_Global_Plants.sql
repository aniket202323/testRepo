CREATE TABLE [dbo].[Local_E2P_Global_Plants] (
    [PlantId]             INT           IDENTITY (1, 1) NOT NULL,
    [ComponentId]         INT           NOT NULL,
    [Name]                VARCHAR (255) NOT NULL,
    [Code]                VARCHAR (255) NOT NULL,
    [AuthorizedToProduce] TINYINT       NOT NULL,
    [AuthorizedToUse]     TINYINT       NOT NULL,
    [Authorized]          TINYINT       NOT NULL,
    [Activated]           TINYINT       NOT NULL,
    CONSTRAINT [LocalE2PGlobalPlants_PK_PlantId] PRIMARY KEY CLUSTERED ([PlantId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Plants_Local_E2P_Global_Components] FOREIGN KEY ([ComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId])
);

