CREATE TABLE [dbo].[Local_E2P_Global_RelatedSpecifications] (
    [RelatedSpecId]    INT            IDENTITY (1, 1) NOT NULL,
    [ComponentId]      INT            NOT NULL,
    [SpeciicationType] VARCHAR (255)  NULL,
    [Type]             VARCHAR (255)  NOT NULL,
    [Name]             VARCHAR (255)  NOT NULL,
    [Revision]         VARCHAR (25)   NOT NULL,
    [Title]            VARCHAR (255)  NULL,
    [Description]      VARCHAR (5000) NULL,
    CONSTRAINT [LocalE2PGlobalRelatedSpecifications_PK_RelatedSpecId] PRIMARY KEY CLUSTERED ([RelatedSpecId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_RelatedSpecifications_Local_E2P_Global_Components] FOREIGN KEY ([ComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId])
);

