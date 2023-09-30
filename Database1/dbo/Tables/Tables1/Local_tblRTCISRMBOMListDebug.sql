﻿CREATE TABLE [dbo].[Local_tblRTCISRMBOMListDebug] (
    [Id]                       INT            IDENTITY (1, 1) NOT NULL,
    [PPId]                     INT            NULL,
    [ProcessOrder]             VARCHAR (50)   NULL,
    [PPStatusStr]              VARCHAR (25)   NULL,
    [BOMRMProdId]              INT            NULL,
    [BOMRMProdCode]            VARCHAR (25)   NULL,
    [BOMRMQty]                 REAL           NULL,
    [BOMRMEngUnitId]           INT            NULL,
    [BOMRMEngUnitdesc]         VARCHAR (25)   NULL,
    [BOMRMScrapFactor]         INT            NULL,
    [BOMRMProdGroupId]         INT            NULL,
    [BOMRMProdGroupDesc]       VARCHAR (25)   NULL,
    [ProductGroupCapacity]     INT            NULL,
    [ProductGroupThreshold]    INT            NULL,
    [ProductUOMToPallet]       REAL           NULL,
    [BOMRMSubProdId]           INT            NULL,
    [BOMRMSubProdCode]         VARCHAR (25)   NULL,
    [BOMRMSubEngUnitId]        INT            NULL,
    [BOMRMSubEngUnitDesc]      VARCHAR (25)   NULL,
    [BOMRMSubConversionFactor] REAL           NULL,
    [BOMErrMsg]                VARCHAR (1000) NULL,
    [EntryOn]                  DATETIME       NULL
);
