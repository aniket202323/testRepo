CREATE TABLE [dbo].[LegacyServiceAttributes] (
    [ContractName]                      NVARCHAR (255)   NULL,
    [LdapName]                          NVARCHAR (255)   NULL,
    [RestAddress]                       NVARCHAR (255)   NULL,
    [DefaultProviderName]               NVARCHAR (255)   NULL,
    [LogicalProviderName]               NVARCHAR (255)   NULL,
    [EnableOnInternet]                  BIT              NULL,
    [UseFixedAddress]                   BIT              NULL,
    [Version]                           BIGINT           NULL,
    [ServiceInterfaceServiceProviderId] UNIQUEIDENTIFIER NOT NULL,
    [ServiceInterfaceTypeDefinitionId]  UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ServiceInterfaceServiceProviderId] ASC, [ServiceInterfaceTypeDefinitionId] ASC),
    CONSTRAINT [LegacyServiceAttributes_ServiceInterface_Relation1] FOREIGN KEY ([ServiceInterfaceServiceProviderId], [ServiceInterfaceTypeDefinitionId]) REFERENCES [dbo].[ServiceInterface] ([ServiceProviderId], [TypeDefinitionId])
);

