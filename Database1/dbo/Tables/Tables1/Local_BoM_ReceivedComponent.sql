CREATE TABLE [dbo].[Local_BoM_ReceivedComponent] (
    [ComponentId]       INT           IDENTITY (1, 1) NOT NULL,
    [FPPId]             INT           NOT NULL,
    [ParentComponentId] INT           NULL,
    [GCAS]              VARCHAR (250) NOT NULL,
    [UniqueId]          VARCHAR (250) NOT NULL,
    [SubstitutesFor]    INT           NULL,
    [ObjectType]        VARCHAR (200) NOT NULL,
    [RawMessage]        XML           NOT NULL,
    [Completed]         TINYINT       NULL,
    CONSTRAINT [LocalBoMReceivedComponent_PK_ComponentId] PRIMARY KEY CLUSTERED ([ComponentId] ASC),
    CONSTRAINT [FK_Local_BoM_Received_Component_Local_BoM_Received_Product] FOREIGN KEY ([FPPId]) REFERENCES [dbo].[Local_BoM_ReceivedProduct] ([FPPId])
);

