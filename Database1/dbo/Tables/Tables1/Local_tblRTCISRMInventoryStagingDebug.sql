CREATE TABLE [dbo].[Local_tblRTCISRMInventoryStagingDebug] (
    [Id]                 INT          IDENTITY (1, 1) NOT NULL,
    [RMEventId]          INT          NULL,
    [RMEventNum]         VARCHAR (50) NULL,
    [RMPUId]             INT          NULL,
    [RMPUDesc]           VARCHAR (50) NULL,
    [RMInitDimX]         REAL         NULL,
    [RMFinalDimX]        REAL         NULL,
    [RMProdId]           INT          NULL,
    [RMProdCode]         VARCHAR (25) NULL,
    [BOMRMProdGroupId]   INT          NULL,
    [BOMRMProdGroupDesc] VARCHAR (25) NULL,
    [RMPPId]             INT          NULL,
    [RMProcessOrder]     VARCHAR (50) NULL,
    [EntryOn]            DATETIME     NULL
);

