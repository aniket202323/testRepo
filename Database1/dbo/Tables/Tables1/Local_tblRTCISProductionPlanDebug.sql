CREATE TABLE [dbo].[Local_tblRTCISProductionPlanDebug] (
    [Id]           INT          IDENTITY (1, 1) NOT NULL,
    [PPId]         INT          NULL,
    [PPStatusId]   INT          NULL,
    [PPStatusDesc] VARCHAR (25) NULL,
    [PathId]       INT          NULL,
    [ProcessOrder] VARCHAR (25) NULL,
    [ForecastQty]  FLOAT (53)   NULL,
    [ProdId]       INT          NULL,
    [ProdCode]     VARCHAR (25) NULL,
    [EntryOn]      DATETIME     NULL
);

