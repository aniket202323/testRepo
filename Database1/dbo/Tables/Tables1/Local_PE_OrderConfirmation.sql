CREATE TABLE [dbo].[Local_PE_OrderConfirmation] (
    [id]              INT          IDENTITY (1, 1) NOT NULL,
    [PathId]          INT          NULL,
    [ProcessOrder]    VARCHAR (12) NULL,
    [Batch]           VARCHAR (12) NULL,
    [ActualStartTime] DATETIME     NULL,
    [ActualEndTime]   DATETIME     NULL,
    [Quantity]        FLOAT (53)   NULL,
    [Material]        VARCHAR (25) NULL,
    [ConfirmPO]       INT          NULL,
    [processTime]     DATETIME     NULL
);


GO
CREATE NONCLUSTERED INDEX [NonClusteredIndex]
    ON [dbo].[Local_PE_OrderConfirmation]([ProcessOrder] ASC);


GO
CREATE NONCLUSTERED INDEX [OrderConfirmation_Pro]
    ON [dbo].[Local_PE_OrderConfirmation]([ProcessOrder] ASC);

