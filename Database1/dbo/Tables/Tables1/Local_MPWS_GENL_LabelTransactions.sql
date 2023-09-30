CREATE TABLE [dbo].[Local_MPWS_GENL_LabelTransactions] (
    [Id]            INT            IDENTITY (1, 1) NOT NULL,
    [LabelType]     VARCHAR (50)   NULL,
    [LabelFolder]   VARCHAR (1024) NULL,
    [LabelText]     VARCHAR (MAX)  NULL,
    [Username]      VARCHAR (255)  NULL,
    [InsertedDate]  DATETIME       CONSTRAINT [DF_Local_MPWS_GENL_LabelTransactions_InsertedDate] DEFAULT (getdate()) NULL,
    [ProcessedDate] DATETIME       NULL,
    [ErrorCode]     INT            CONSTRAINT [DF_Local_MPWS_GENL_LabelTransactions_ErrorCode] DEFAULT ((0)) NULL,
    [Errormessage]  VARCHAR (1024) NULL,
    CONSTRAINT [PK_Local_MPWS_GENL_LabelTransactions] PRIMARY KEY CLUSTERED ([Id] ASC)
);

