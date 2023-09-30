CREATE TABLE [dbo].[Local_iWebDirect_InboundLogging] (
    [Transaction_Id]          INT              IDENTITY (1, 1) NOT NULL,
    [Timestamp]               DATETIME         NOT NULL,
    [End_Timestamp]           DATETIME         NULL,
    [External_Component_Name] VARCHAR (50)     NOT NULL,
    [Command_Name]            VARCHAR (500)    NOT NULL,
    [HTTP_Verb]               VARCHAR (10)     NOT NULL,
    [Input_Payload]           VARCHAR (MAX)    NULL,
    [Output_Payload]          VARCHAR (MAX)    NULL,
    [HTTP_Status_Code]        SMALLINT         NULL,
    [Remote_IP]               VARCHAR (16)     NULL,
    [Remote_Host]             VARCHAR (256)    NULL,
    [Error_Id]                UNIQUEIDENTIFIER NULL,
    [Username]                VARCHAR (50)     NOT NULL,
    CONSTRAINT [LocaliWebDirectInboundLogging_PK_TransactionId] PRIMARY KEY CLUSTERED ([Transaction_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebDirect_InboundLogging_Command_Name]
    ON [dbo].[Local_iWebDirect_InboundLogging]([Command_Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebDirect_InboundLogging_Error_Id]
    ON [dbo].[Local_iWebDirect_InboundLogging]([Error_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebDirect_InboundLogging_External_Component_Name]
    ON [dbo].[Local_iWebDirect_InboundLogging]([External_Component_Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebDirect_InboundLogging_Timestamp]
    ON [dbo].[Local_iWebDirect_InboundLogging]([Timestamp] ASC);

