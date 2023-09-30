CREATE TABLE [dbo].[Local_E2P_Global_Organizations] (
    [OrganizationId] INT           IDENTITY (1, 1) NOT NULL,
    [ComponentId]    INT           NOT NULL,
    [Type]           VARCHAR (25)  NOT NULL,
    [Name]           VARCHAR (255) NOT NULL,
    CONSTRAINT [LocalE2PGlobalOrganizations_PK_OrganizationId] PRIMARY KEY CLUSTERED ([OrganizationId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Organizations_Local_E2P_Global_Components] FOREIGN KEY ([ComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId])
);

