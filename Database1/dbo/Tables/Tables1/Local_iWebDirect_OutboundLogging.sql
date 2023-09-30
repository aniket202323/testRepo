CREATE TABLE [dbo].[Local_iWebDirect_OutboundLogging] (
    [Transaction_Id]          INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]               DATETIME      NOT NULL,
    [End_Timestamp]           DATETIME      NULL,
    [URL]                     VARCHAR (500) NOT NULL,
    [External_Component_Name] VARCHAR (50)  NOT NULL,
    [Command_Name]            VARCHAR (500) NULL,
    [HTTP_Verb]               VARCHAR (10)  NOT NULL,
    [Input_Payload]           VARCHAR (MAX) NULL,
    [Output_Payload]          VARCHAR (MAX) NULL,
    [HTTP_Status_Code]        SMALLINT      NULL,
    CONSTRAINT [LocaliWebDirectOutboundLogging_PK_TransactionId] PRIMARY KEY CLUSTERED ([Transaction_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebDirect_OutboundLogging_Command_Name]
    ON [dbo].[Local_iWebDirect_OutboundLogging]([Command_Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebDirect_OutboundLogging_External_Component_Name]
    ON [dbo].[Local_iWebDirect_OutboundLogging]([External_Component_Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebDirect_OutboundLogging_Timestamp]
    ON [dbo].[Local_iWebDirect_OutboundLogging]([Timestamp] ASC);

