CREATE TABLE [dbo].[Local_E2P_Global_Legacy_PackingComponents] (
    [PackingComponentId] INT            IDENTITY (1, 1) NOT NULL,
    [ComponentId]        INT            NOT NULL,
    [TrackingCode]       VARCHAR (255)  NOT NULL,
    [Description]        VARCHAR (5000) NOT NULL,
    [PackingLevel]       VARCHAR (255)  NOT NULL,
    [SubType]            VARCHAR (255)  NOT NULL,
    [Comments]           VARCHAR (5000) NULL,
    CONSTRAINT [LocalE2PGlobalLegacyPackingComponents_PK_PackingComponentId] PRIMARY KEY CLUSTERED ([PackingComponentId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Legacy_PackingComponents_Local_E2P_Global_Components] FOREIGN KEY ([ComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId])
);

