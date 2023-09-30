CREATE TABLE [dbo].[Local_E2P_Received_Component] (
    [ComponentId]       INT           IDENTITY (1, 1) NOT NULL,
    [FPPId]             INT           NOT NULL,
    [ParentComponentId] INT           NULL,
    [UniqueId]          VARCHAR (250) NOT NULL,
    [SubstitutesFor]    INT           NULL,
    [RawMessage]        XML           NOT NULL,
    [Completed]         TINYINT       NULL,
    CONSTRAINT [LocalE2PReceivedComponent_PK_ComponentId] PRIMARY KEY CLUSTERED ([ComponentId] ASC),
    CONSTRAINT [FK_Local_E2P_Received_Component_Local_E2P_Received_FPP] FOREIGN KEY ([FPPId]) REFERENCES [dbo].[Local_E2P_Received_FPP] ([FPPId])
);

