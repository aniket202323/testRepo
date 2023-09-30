CREATE TABLE [dbo].[Local_iWebServices_OutboundLogging] (
    [Transaction_Id]          INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]               DATETIME      NOT NULL,
    [End_Timestamp]           DATETIME      NULL,
    [URL]                     VARCHAR (500) NOT NULL,
    [External_Component_Name] VARCHAR (500) NOT NULL,
    [Command_Name]            VARCHAR (500) NULL,
    [HTTP_Verb]               VARCHAR (10)  NOT NULL,
    [Input_XML]               XML           NULL,
    [Output_XML]              XML           NULL,
    [HTTP_Status_Code]        SMALLINT      NULL,
    [Raw_Output]              VARCHAR (MAX) NULL,
    CONSTRAINT [LocaliWebServicesOutboundLogging_PK_TransactionId] PRIMARY KEY CLUSTERED ([Transaction_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebServices_OutboundLogging_Timestamp]
    ON [dbo].[Local_iWebServices_OutboundLogging]([Timestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebServices_OutboundLogging_External_Component_Name]
    ON [dbo].[Local_iWebServices_OutboundLogging]([External_Component_Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebServices_OutboundLogging_Command_Name]
    ON [dbo].[Local_iWebServices_OutboundLogging]([Command_Name] ASC);


GO
CREATE PRIMARY XML INDEX [IX_XML_Local_iWebServices_OutboundLogging_Output_XML]
    ON [dbo].[Local_iWebServices_OutboundLogging]([Output_XML])
    WITH (PAD_INDEX = OFF);


GO
CREATE PRIMARY XML INDEX [IX_XML_Local_iWebServices_OutboundLogging_Input_XML]
    ON [dbo].[Local_iWebServices_OutboundLogging]([Input_XML])
    WITH (PAD_INDEX = OFF);

