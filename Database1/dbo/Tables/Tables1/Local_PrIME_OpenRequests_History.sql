CREATE TABLE [dbo].[Local_PrIME_OpenRequests_History] (
    [OpenRequestHistoryId] INT             IDENTITY (1, 1) NOT NULL,
    [OpenTableId]          INT             NOT NULL,
    [RequestId]            VARCHAR (50)    NULL,
    [PrIMEReturnCode]      INT             NULL,
    [RequestTime]          DATETIME        NOT NULL,
    [LocationId]           VARCHAR (50)    NOT NULL,
    [CurrentLocation]      VARCHAR (50)    NULL,
    [ULID]                 VARCHAR (50)    NULL,
    [Batch]                VARCHAR (50)    NULL,
    [ProcessOrder]         VARCHAR (50)    NULL,
    [PrimaryGCas]          VARCHAR (50)    NOT NULL,
    [AlternateGCas]        VARCHAR (50)    NULL,
    [GCas]                 VARCHAR (50)    NULL,
    [QuantityValue]        DECIMAL (19, 5) NOT NULL,
    [QuantityUoM]          VARCHAR (50)    NULL,
    [Status]               VARCHAR (50)    NULL,
    [EstimatedDelivery]    DATETIME        NULL,
    [LastUpdatedTime]      DATETIME        NULL,
    [UserId]               INT             NULL,
    [EventId]              INT             NULL,
    [Comment]              VARCHAR (8000)  NULL,
    [ModifiedOn]           DATETIME        NOT NULL,
    [DBTT_ID]              INT             NOT NULL,
    [PlantID]              VARCHAR (50)    NULL,
    [WarehouseID]          VARCHAR (50)    NULL,
    [ResponseTime]         DATETIME        NULL,
    CONSTRAINT [LocalPrIMEOpenRequestsHistory_PK_OpenRequestHistoryId] PRIMARY KEY CLUSTERED ([OpenRequestHistoryId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequestsHistory_IDX_LocationId]
    ON [dbo].[Local_PrIME_OpenRequests_History]([LocationId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequestsHistory_IDX_ProcessOrder]
    ON [dbo].[Local_PrIME_OpenRequests_History]([ProcessOrder] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequestsHistory_IDX_ModifiedOn]
    ON [dbo].[Local_PrIME_OpenRequests_History]([ModifiedOn] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequestsHistory_IDX_EstimatedDelivery]
    ON [dbo].[Local_PrIME_OpenRequests_History]([EstimatedDelivery] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequestsHistory_IDX_RequestTime]
    ON [dbo].[Local_PrIME_OpenRequests_History]([RequestTime] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPrIMEOpenRequestsHistory_IDX_LastUpdatedTime]
    ON [dbo].[Local_PrIME_OpenRequests_History]([LastUpdatedTime] ASC);


GO

CREATE TRIGGER [dbo].[LocalPrIME_OpenRequests_History_UpdDel]
 ON  [dbo].[Local_PrIME_OpenRequests_History]
  INSTEAD OF UPDATE,DELETE
  AS
 	 DECLARE @Last_Identity INT