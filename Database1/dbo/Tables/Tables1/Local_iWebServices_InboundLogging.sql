CREATE TABLE [dbo].[Local_iWebServices_InboundLogging] (
    [Transaction_Id]          INT              IDENTITY (1, 1) NOT NULL,
    [Timestamp]               DATETIME         NOT NULL,
    [End_Timestamp]           DATETIME         NULL,
    [External_Component_Name] VARCHAR (50)     NOT NULL,
    [Command_Name]            VARCHAR (500)    NOT NULL,
    [HTTP_Verb]               VARCHAR (10)     NOT NULL,
    [Input_Raw]               VARCHAR (MAX)    NULL,
    [Input_XML]               XML              NULL,
    [Output_XML]              XML              NULL,
    [HTTP_Status_Code]        SMALLINT         NULL,
    [Remote_IP]               VARCHAR (16)     NULL,
    [Remote_Host]             VARCHAR (256)    NULL,
    [Error_Id]                UNIQUEIDENTIFIER NULL,
    [User_Id]                 INT              NOT NULL,
    CONSTRAINT [LocaliWebServicesInboundLogging_PK_TransactionId] PRIMARY KEY CLUSTERED ([Transaction_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebServices_InboundLogging_External_Component_Name]
    ON [dbo].[Local_iWebServices_InboundLogging]([External_Component_Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebServices_InboundLogging_Command_Name]
    ON [dbo].[Local_iWebServices_InboundLogging]([Command_Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebServices_InboundLogging_Timestamp]
    ON [dbo].[Local_iWebServices_InboundLogging]([Timestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Local_iWebServices_InboundLogging_Error_Id]
    ON [dbo].[Local_iWebServices_InboundLogging]([Error_Id] ASC);


GO
CREATE PRIMARY XML INDEX [IX_XML_Local_iWebServices_InboundLogging_Output_XML]
    ON [dbo].[Local_iWebServices_InboundLogging]([Output_XML])
    WITH (PAD_INDEX = OFF);


GO
CREATE PRIMARY XML INDEX [IX_XML_Local_iWebServices_InboundLogging_Input_XML]
    ON [dbo].[Local_iWebServices_InboundLogging]([Input_XML])
    WITH (PAD_INDEX = OFF);

