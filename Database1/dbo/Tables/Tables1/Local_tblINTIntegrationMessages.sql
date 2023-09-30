CREATE TABLE [dbo].[Local_tblINTIntegrationMessages] (
    [Id]               INT            IDENTITY (1, 1) NOT NULL,
    [Site]             VARCHAR (255)  NULL,
    [SystemSource]     VARCHAR (255)  NULL,
    [SystemTarget]     VARCHAR (255)  NULL,
    [MessageType]      VARCHAR (255)  NULL,
    [Message]          VARCHAR (MAX)  NULL,
    [MainData]         VARCHAR (255)  NULL,
    [InsertedDate]     DATETIME       CONSTRAINT [DF_Local_Local_tblINTIntegrationMessages_InsertedDate] DEFAULT (getdate()) NULL,
    [NextRetryDate]    DATETIME       NULL,
    [StartProcessDate] DATETIME       NULL,
    [ProcessedDate]    DATETIME       NULL,
    [ErrorCode]        INT            NULL,
    [TriggerId]        INT            NULL,
    [errormessage]     VARCHAR (1024) NULL
);


GO
CREATE NONCLUSTERED INDEX [Local_tblINTIntegrationMessages_IDX1]
    ON [dbo].[Local_tblINTIntegrationMessages]([SystemTarget] ASC, [MessageType] ASC, [ProcessedDate] ASC);


GO
CREATE NONCLUSTERED INDEX [Local_tblINTIntegrationMessages_IDX2]
    ON [dbo].[Local_tblINTIntegrationMessages]([InsertedDate] ASC);


GO
CREATE NONCLUSTERED INDEX [Local_tblINTIntegrationMessages_IDX3]
    ON [dbo].[Local_tblINTIntegrationMessages]([Id] ASC);

