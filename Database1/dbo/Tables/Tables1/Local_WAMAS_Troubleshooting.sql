CREATE TABLE [dbo].[Local_WAMAS_Troubleshooting] (
    [Id]                    INT          IDENTITY (1, 1) NOT NULL,
    [ErrorCode]             INT          NULL,
    [TransactionType]       INT          NULL,
    [RequestId]             VARCHAR (50) NULL,
    [RequestTime]           DATETIME     NULL,
    [LocationId]            VARCHAR (50) NULL,
    [LineId]                VARCHAR (50) NULL,
    [ULID]                  VARCHAR (50) NULL,
    [VendorLotId]           VARCHAR (50) NULL,
    [ProcessOrder]          VARCHAR (50) NULL,
    [PrimaryGCas]           VARCHAR (50) NULL,
    [AlternateGCas]         VARCHAR (50) NULL,
    [GCas]                  VARCHAR (50) NULL,
    [Quantity]              INT          NULL,
    [UoM]                   VARCHAR (50) NULL,
    [Status]                VARCHAR (50) NULL,
    [EstimatedDeliveryTime] DATETIME     NULL,
    [LastUpdatedTime]       DATETIME     NULL,
    CONSTRAINT [LocalWAMASTroubleshooting_PK_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);

