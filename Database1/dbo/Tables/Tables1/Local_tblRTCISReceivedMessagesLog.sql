CREATE TABLE [dbo].[Local_tblRTCISReceivedMessagesLog] (
    [Id]             INT                   IDENTITY (1, 1) NOT NULL,
    [EntryOn]        DATETIME              NOT NULL,
    [MessageType]    INT                   NULL,
    [DocumentHeader] VARCHAR (50)          NOT NULL,
    [MessageHeader]  VARCHAR (50)          NULL,
    [SessionKey]     VARCHAR (50)          NULL,
    [MessageId]      VARCHAR (50)          NULL,
    [TimeStamp]      VARCHAR (50)          NULL,
    [DetailHeader]   VARCHAR (50)          NULL,
    [MatReq]         VARCHAR (50)          NULL,
    [ULId]           VARCHAR (50)          NULL,
    [ItmCod]         VARCHAR (50)          NULL,
    [CtlGrp]         VARCHAR (50)          NULL,
    [Qty]            [dbo].[Float_Natural] NULL,
    [UOM]            VARCHAR (50)          NULL,
    [Locatn]         VARCHAR (50)          NULL,
    [PrdOrd]         VARCHAR (50)          NULL,
    [ErrMsg]         VARCHAR (100)         NULL
);

