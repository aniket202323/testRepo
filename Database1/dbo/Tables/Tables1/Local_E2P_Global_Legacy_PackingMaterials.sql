CREATE TABLE [dbo].[Local_E2P_Global_Legacy_PackingMaterials] (
    [PackingMaterialId]   INT            IDENTITY (1, 1) NOT NULL,
    [PackingComponentId]  INT            NOT NULL,
    [Type]                VARCHAR (255)  NOT NULL,
    [TrackingCode]        VARCHAR (255)  NULL,
    [Change]              VARCHAR (255)  NULL,
    [FinishedProductCode] VARCHAR (255)  NULL,
    [SapDescription]      VARCHAR (5000) NOT NULL,
    [Quantity]            VARCHAR (25)   NOT NULL,
    [UnitOfMeasure]       VARCHAR (255)  NOT NULL,
    [Comments]            VARCHAR (5000) NULL,
    [Specification]       VARCHAR (255)  NULL,
    [Gcas]                VARCHAR (25)   NOT NULL,
    [SpecificationId]     VARCHAR (255)  NOT NULL,
    CONSTRAINT [LocalE2PGlobalLegacyPackingMaterials_PK_PackingMaterialId] PRIMARY KEY CLUSTERED ([PackingMaterialId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Legacy_PackingMaterials_Local_E2P_Global_Legacy_PackingComponents] FOREIGN KEY ([PackingComponentId]) REFERENCES [dbo].[Local_E2P_Global_Legacy_PackingComponents] ([PackingComponentId])
);

