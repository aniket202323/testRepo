CREATE TABLE [dbo].[Local_TblMaterialRequest] (
    [MRID]                 INT          IDENTITY (1, 1) NOT NULL,
    [TransactionType]      VARCHAR (30) NULL,
    [PathID]               INT          NULL,
    [PPID]                 INT          NULL,
    [ProdID]               INT          NULL,
    [OG]                   VARCHAR (4)  NULL,
    [UOM]                  VARCHAR (25) NULL,
    [PUID]                 INT          NULL,
    [LineName]             VARCHAR (50) NULL,
    [RequestDate]          DATETIME     NULL,
    [Quantity]             FLOAT (53)   NULL,
    [UserID]               INT          NULL,
    [Step]                 VARCHAR (20) NULL,
    [RequestType]          VARCHAR (10) NULL,
    [CommentId]            INT          NULL,
    [Status]               VARCHAR (10) NULL,
    [OCOAutoOrderMaterial] VARCHAR (20) NULL,
    [AutoOrderingInterval] INT          NULL,
    [POProgression]        FLOAT (53)   NULL,
    [PreStagingUL]         INT          NULL,
    [StagingUL]            INT          NULL,
    [PreStagingUOM]        INT          NULL,
    [StagingUOM]           INT          NULL,
    [ThresholdUOM]         FLOAT (53)   NULL,
    [CapacityUL]           INT          NULL,
    [StillNeededUOM]       INT          NULL,
    [OnOrderUL]            INT          NULL,
    [PRDAutoOrdering]      VARCHAR (50) NULL,
    [ToLocation]           VARCHAR (50) NULL
);


GO
CREATE NONCLUSTERED INDEX [TblMaterialRequest_RequestDate]
    ON [dbo].[Local_TblMaterialRequest]([RequestDate] ASC);

