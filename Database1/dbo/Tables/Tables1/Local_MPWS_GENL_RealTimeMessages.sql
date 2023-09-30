CREATE TABLE [dbo].[Local_MPWS_GENL_RealTimeMessages] (
    [Id]              INT           IDENTITY (1, 1) NOT NULL,
    [EventId]         INT           NULL,
    [ResultsetId]     INT           NULL,
    [TransactionType] INT           NULL,
    [Transnum]        INT           NULL,
    [InsertedDate]    DATETIME      CONSTRAINT [DF_Local_MPWS_GENL_RealTimeMessages_InsertedDate] DEFAULT (getdate()) NULL,
    [ProcessedDate]   DATETIME      NULL,
    [ErrorCode]       INT           CONSTRAINT [DF_Local_MPWS_GENL_RealTimeMessages_ErrorCode] DEFAULT ((0)) NULL,
    [Errormessage]    VARCHAR (255) NULL
);


GO
CREATE NONCLUSTERED INDEX [RealTimeMessages_IDX1]
    ON [dbo].[Local_MPWS_GENL_RealTimeMessages]([ProcessedDate] ASC);


GO
CREATE NONCLUSTERED INDEX [RealTimeMessages_IDX2]
    ON [dbo].[Local_MPWS_GENL_RealTimeMessages]([ErrorCode] ASC);


GO
CREATE NONCLUSTERED INDEX [RealTimeMessages_IDX3]
    ON [dbo].[Local_MPWS_GENL_RealTimeMessages]([Id] ASC);

