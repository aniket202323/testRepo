CREATE TABLE [dbo].[Golden_Batches] (
    [Golden_Batch_Id] INT           IDENTITY (1, 1) NOT NULL,
    [Prod_Id]         INT           NOT NULL,
    [Event_Id]        INT           NOT NULL,
    [Status]          INT           NULL,
    [Description]     VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_Golden_Batches] PRIMARY KEY CLUSTERED ([Golden_Batch_Id] ASC),
    CONSTRAINT [FK_golden_batches_Events] FOREIGN KEY ([Event_Id]) REFERENCES [dbo].[Events] ([Event_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_prod_id] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [GoldenBatches_IDX_Event_Id]
    ON [dbo].[Golden_Batches]([Event_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [GoldenBatches_IDX_Event_Id_And_Prodduct]
    ON [dbo].[Golden_Batches]([Event_Id] ASC, [Prod_Id] ASC);

