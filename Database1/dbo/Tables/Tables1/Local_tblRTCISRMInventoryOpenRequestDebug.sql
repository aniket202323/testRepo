CREATE TABLE [dbo].[Local_tblRTCISRMInventoryOpenRequestDebug] (
    [Id]                 INT            IDENTITY (1, 1) NOT NULL,
    [MATREQ]             VARCHAR (25)   NULL,
    [STATUS]             VARCHAR (25)   NULL,
    [PLNUMB]             VARCHAR (25)   NULL,
    [PRDORD]             VARCHAR (25)   NULL,
    [REQITM]             VARCHAR (25)   NULL,
    [ULQTY]              INT            NULL,
    [REQDAT]             DATETIME       NULL,
    [UOMQty]             REAL           NULL,
    [UOM]                VARCHAR (25)   NULL,
    [BOMRMProdGroupId]   INT            NULL,
    [BOMRMProdGroupDesc] NCHAR (10)     NULL,
    [ORErrMsg]           VARCHAR (1000) NULL,
    [EntryOn]            DATETIME       NULL,
    [DEPLOC]             VARCHAR (25)   NOT NULL
);

