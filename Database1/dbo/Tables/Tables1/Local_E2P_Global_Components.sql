CREATE TABLE [dbo].[Local_E2P_Global_Components] (
    [ComponentId]       INT           IDENTITY (1, 1) NOT NULL,
    [ReportId]          INT           NOT NULL,
    [ParentComponentId] INT           NULL,
    [Location]          VARCHAR (255) NOT NULL,
    [ObjectType]        VARCHAR (255) NOT NULL,
    [CanonicalType]     VARCHAR (255) NOT NULL,
    [Type]              VARCHAR (255) NOT NULL,
    [Identifier]        VARCHAR (25)  NOT NULL,
    [Revision]          VARCHAR (25)  NOT NULL,
    [Description]       VARCHAR (100) NULL,
    [Segment]           VARCHAR (25)  NULL,
    [UniqueId]          VARCHAR (255) NOT NULL,
    [SequenceNumber]    VARCHAR (25)  NULL,
    [Quantity]          VARCHAR (25)  NULL,
    [SubstitutesFor]    INT           NULL,
    CONSTRAINT [LocalE2PGlobalComponents_PK_ComponentId] PRIMARY KEY CLUSTERED ([ComponentId] ASC),
    CONSTRAINT [FK_Local_E2P_Global_Components_Local_E2P_Global_Components_Parent] FOREIGN KEY ([ParentComponentId]) REFERENCES [dbo].[Local_E2P_Global_Components] ([ComponentId]),
    CONSTRAINT [FK_Local_E2P_Global_Components_Local_E2P_Global_Reports] FOREIGN KEY ([ReportId]) REFERENCES [dbo].[Local_E2P_Global_Reports] ([ReportId])
);

