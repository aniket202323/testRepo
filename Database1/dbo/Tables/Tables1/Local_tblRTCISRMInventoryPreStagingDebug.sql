CREATE TABLE [dbo].[Local_tblRTCISRMInventoryPreStagingDebug] (
    [Id]                 INT          IDENTITY (1, 1) NOT NULL,
    [MATREQ]             VARCHAR (25) NULL,
    [ULID]               VARCHAR (25) NULL,
    [LOCATN]             VARCHAR (25) NULL,
    [PRDORD]             VARCHAR (25) NULL,
    [ITMCOD]             VARCHAR (25) NULL,
    [CTLGRP]             VARCHAR (25) NULL,
    [CASQTY]             VARCHAR (25) NULL,
    [CASQTY_UOM]         VARCHAR (25) NULL,
    [BOMRMProdGroupId]   INT          NULL,
    [BOMRMProdGroupDesc] VARCHAR (25) NULL,
    [EntryOn]            DATETIME     NULL
);

