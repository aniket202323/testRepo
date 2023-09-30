CREATE TABLE [dbo].[Local_tblRTCISSentMessagesLog] (
    [MessageId]             INT              IDENTITY (1, 1) NOT NULL,
    [MessageType]           INT              NOT NULL,
    [GUIDIDENTIFIER]        UNIQUEIDENTIFIER NULL,
    [DocumentHeaderRequest] VARCHAR (50)     NOT NULL,
    [DocumentHeaderCancel]  VARCHAR (50)     NULL,
    [MessageHeader]         VARCHAR (50)     NOT NULL,
    [DetailHeader]          VARCHAR (50)     NOT NULL,
    [SessionKey]            VARCHAR (50)     NOT NULL,
    [TimeStamp]             VARCHAR (50)     NOT NULL,
    [SiteName]              VARCHAR (50)     NULL,
    [SubSite]               VARCHAR (50)     NULL,
    [ItmCod]                VARCHAR (50)     NULL,
    [Qty]                   INT              NULL,
    [To_Locatn]             VARCHAR (50)     NULL,
    [PrdOrd]                VARCHAR (50)     NOT NULL,
    [PrdLin]                VARCHAR (50)     NULL,
    [Status]                VARCHAR (50)     NULL,
    [EntryOn]               DATETIME         NULL,
    [ErrMsg]                VARCHAR (1000)   NULL,
    [MATREQ]                INT              NULL
);


GO
CREATE CLUSTERED INDEX [ClusteredIndex-MessageID]
    ON [dbo].[Local_tblRTCISSentMessagesLog]([MessageId] ASC);


GO
CREATE NONCLUSTERED INDEX [tblRTCISSentMessagesLog_entry_on]
    ON [dbo].[Local_tblRTCISSentMessagesLog]([EntryOn] ASC);

