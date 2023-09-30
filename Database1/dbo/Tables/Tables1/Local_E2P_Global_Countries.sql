CREATE TABLE [dbo].[Local_E2P_Global_Countries] (
    [CountryId]      INT           IDENTITY (1, 1) NOT NULL,
    [ComponentId]    INT           NOT NULL,
    [Name]           VARCHAR (255) NOT NULL,
    [IsoCode]        VARCHAR (25)  NOT NULL,
    [ShortCode]      VARCHAR (25)  NOT NULL,
    [ApprovalStatus] VARCHAR (255) NULL,
    CONSTRAINT [LocalE2PGlobalCountries_PK_CountryId] PRIMARY KEY CLUSTERED ([CountryId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Countries_Local_E2P_Global_Components] FOREIGN KEY ([ComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId])
);

