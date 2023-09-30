CREATE TABLE [dbo].[Local_tblINTIntegrationTriggeredEvents] (
    [Id]                   INT            IDENTITY (1, 1) NOT NULL,
    [MessageType]          VARCHAR (255)  NULL,
    [Field01]              VARCHAR (255)  NOT NULL,
    [Field02]              VARCHAR (255)  NOT NULL,
    [Field03]              VARCHAR (255)  NULL,
    [Field04]              VARCHAR (255)  NULL,
    [Field05]              VARCHAR (255)  NULL,
    [Field06]              VARCHAR (255)  NULL,
    [Field07]              VARCHAR (255)  NULL,
    [Field08]              VARCHAR (255)  NULL,
    [Field09]              VARCHAR (255)  NULL,
    [Field10]              VARCHAR (255)  NULL,
    [Field11]              VARCHAR (255)  NULL,
    [Field12]              VARCHAR (255)  NULL,
    [Field13]              VARCHAR (255)  NULL,
    [Field14]              VARCHAR (255)  NULL,
    [Field15]              VARCHAR (255)  NULL,
    [Field16]              VARCHAR (255)  NULL,
    [Field17]              VARCHAR (255)  NULL,
    [Field18]              VARCHAR (255)  NULL,
    [Field19]              VARCHAR (255)  NULL,
    [Field20]              VARCHAR (255)  NULL,
    [InsertedDate]         DATETIME       CONSTRAINT [DF_Local_tblINTIntegrationTriggeredEvents_InsertedDate] DEFAULT (getdate()) NULL,
    [NextRetryDate]        DATETIME       NULL,
    [ProcessedDate]        DATETIME       NULL,
    [ErrorCode]            INT            NULL,
    [Site]                 VARCHAR (255)  NULL,
    [FlagBypassDispatcher] VARCHAR (255)  NULL,
    [errormessage]         VARCHAR (1024) NULL,
    CONSTRAINT [PK_Local_tblINTIntegrationTriggeredEvents] PRIMARY KEY CLUSTERED ([Field01] ASC, [Field02] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Local_tblINTIntegrationTriggeredEvents_IDX1]
    ON [dbo].[Local_tblINTIntegrationTriggeredEvents]([ProcessedDate] ASC);


GO
CREATE NONCLUSTERED INDEX [Local_tblINTIntegrationTriggeredEvents_IDX2]
    ON [dbo].[Local_tblINTIntegrationTriggeredEvents]([InsertedDate] ASC);


GO
CREATE NONCLUSTERED INDEX [Local_tblINTIntegrationTriggeredEvents_IDX3]
    ON [dbo].[Local_tblINTIntegrationTriggeredEvents]([Id] ASC);

