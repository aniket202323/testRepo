CREATE TABLE [dbo].[Local_WAMAS_OpenRequests_History] (
    [OpenRequestHistoryId] INT          IDENTITY (1, 1) NOT NULL,
    [OpenTableId]          INT          NOT NULL,
    [RequestId]            VARCHAR (50) NULL,
    [RequestTime]          DATETIME     NOT NULL,
    [LocationId]           VARCHAR (50) NOT NULL,
    [LineId]               VARCHAR (50) NOT NULL,
    [ULID]                 VARCHAR (50) NULL,
    [VendorLotId]          VARCHAR (50) NULL,
    [ProcessOrder]         VARCHAR (50) NOT NULL,
    [PrimaryGCas]          VARCHAR (50) NOT NULL,
    [AlternateGCas]        VARCHAR (50) NULL,
    [GCas]                 VARCHAR (50) NULL,
    [QuantityValue]        INT          NOT NULL,
    [QuantityUoM]          VARCHAR (50) NOT NULL,
    [Status]               VARCHAR (50) NULL,
    [EstimatedDelivery]    DATETIME     NULL,
    [LastUpdatedTime]      DATETIME     NULL,
    [UserId]               INT          NOT NULL,
    [ModifiedOn]           DATETIME     NOT NULL,
    [DBTT_ID]              INT          NOT NULL,
    CONSTRAINT [LocalWAMASOpenRequestsHistory_PK_OpenRequestHistoryId] PRIMARY KEY CLUSTERED ([OpenRequestHistoryId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequestsHistory_IDX_LocationId]
    ON [dbo].[Local_WAMAS_OpenRequests_History]([LocationId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequestsHistory_IDX_LineId]
    ON [dbo].[Local_WAMAS_OpenRequests_History]([LineId] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequestsHistory_IDX_ProcessOrder]
    ON [dbo].[Local_WAMAS_OpenRequests_History]([ProcessOrder] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequestsHistory_IDX_ModifiedOn]
    ON [dbo].[Local_WAMAS_OpenRequests_History]([ModifiedOn] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequestsHistory_IDX_EstimatedDelivery]
    ON [dbo].[Local_WAMAS_OpenRequests_History]([EstimatedDelivery] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequestsHistory_IDX_RequestTime]
    ON [dbo].[Local_WAMAS_OpenRequests_History]([RequestTime] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalWAMASOpenRequestsHistory_IDX_LastUpdatedTime]
    ON [dbo].[Local_WAMAS_OpenRequests_History]([LastUpdatedTime] ASC);


GO

CREATE TRIGGER [dbo].[LocalWAMAS_OpenRequests_History_UpdDel]
 ON  [dbo].[Local_WAMAS_OpenRequests_History]
  INSTEAD OF UPDATE,DELETE
  AS
 	 DECLARE @Last_Identity INT