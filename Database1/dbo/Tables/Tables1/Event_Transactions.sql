CREATE TABLE [dbo].[Event_Transactions] (
    [EventTransactionId]         INT            IDENTITY (1, 1) NOT NULL,
    [AreaName]                   VARCHAR (100)  NOT NULL,
    [BatchInstance]              INT            NULL,
    [BatchName]                  VARCHAR (50)   NULL,
    [BatchProductCode]           VARCHAR (25)   NULL,
    [CellName]                   VARCHAR (100)  NOT NULL,
    [EventName]                  VARCHAR (100)  NULL,
    [EventReportType]            VARCHAR (50)   NULL,
    [EventTimeStamp]             DATETIME       NOT NULL,
    [EventType]                  VARCHAR (20)   NOT NULL,
    [OperationInstance]          INT            NULL,
    [OperationName]              VARCHAR (50)   NULL,
    [OrphanedFlag]               BIT            NOT NULL,
    [OrphanedReason]             VARCHAR (255)  NULL,
    [ParameterAttributeComments] VARCHAR (255)  NULL,
    [ParameterAttributeName]     VARCHAR (100)  NULL,
    [ParameterAttributeUOM]      VARCHAR (15)   NULL,
    [ParameterAttributeValue]    VARCHAR (25)   NULL,
    [ParameterName]              VARCHAR (100)  NULL,
    [PhaseInstance]              INT            NULL,
    [PhaseName]                  VARCHAR (50)   NULL,
    [ProcedureEndTime]           DATETIME       NULL,
    [ProcedureStartTime]         DATETIME       NULL,
    [ProcessedFlag]              BIT            NOT NULL,
    [ProcessedTimeStamp]         DATETIME       NULL,
    [Proficy_Id]                 INT            NULL,
    [RawMaterialAreaName]        VARCHAR (100)  NULL,
    [RawMaterialBatchName]       VARCHAR (50)   NULL,
    [RawMaterialCellName]        VARCHAR (100)  NULL,
    [RawMaterialContainerId]     VARCHAR (50)   NULL,
    [RawMaterialDimensionA]      FLOAT (53)     NULL,
    [RawMaterialDimensionX]      FLOAT (53)     NULL,
    [RawMaterialDimensionY]      FLOAT (53)     NULL,
    [RawMaterialDimensionZ]      FLOAT (53)     NULL,
    [RawMaterialProductCode]     VARCHAR (25)   NULL,
    [RawMaterialUnitName]        VARCHAR (100)  NULL,
    [RecipeString]               VARCHAR (1000) NULL,
    [StateValue]                 VARCHAR (25)   NULL,
    [UnitName]                   VARCHAR (100)  NOT NULL,
    [UnitProcedureInstance]      INT            NULL,
    [UnitProcedureName]          VARCHAR (50)   NULL,
    [UserName]                   VARCHAR (100)  NULL,
    [UserSignature]              VARCHAR (255)  NULL,
    [EventSubtype]               VARCHAR (50)   NULL,
    [FinalDimensionA]            FLOAT (53)     NULL,
    [FinalDimensionX]            FLOAT (53)     NULL,
    [FinalDimensionY]            FLOAT (53)     NULL,
    [FinalDimensionZ]            FLOAT (53)     NULL,
    [FriendlyOperationName]      NVARCHAR (100) NULL,
    [InitialDimensionA]          FLOAT (53)     NULL,
    [InitialDimensionX]          FLOAT (53)     NULL,
    [InitialDimensionY]          FLOAT (53)     NULL,
    [InitialDimensionZ]          FLOAT (53)     NULL,
    [LotIdentifier]              NVARCHAR (100) NULL,
    [ProcessOrderId]             INT            NULL,
    [Retries]                    INT            NULL
);


GO
CREATE CLUSTERED INDEX [EventTransactions_IDX_ProcessedOrphanedEventTimeStamp]
    ON [dbo].[Event_Transactions]([ProcessedFlag] ASC, [OrphanedFlag] ASC, [EventTimeStamp] ASC);


GO
CREATE NONCLUSTERED INDEX [EventTransactions_IDX_OrphanedEventTimeStamp]
    ON [dbo].[Event_Transactions]([OrphanedFlag] ASC, [ProcessedTimeStamp] ASC);


GO
CREATE NONCLUSTERED INDEX [EventTransactions_IDX_EventTransactionId]
    ON [dbo].[Event_Transactions]([EventTransactionId] ASC);


GO
CREATE NONCLUSTERED INDEX [EventTransactions_IDX_ProcessedOrphanedProcessedTimeStamp]
    ON [dbo].[Event_Transactions]([ProcessedFlag] ASC, [OrphanedFlag] ASC, [ProcessedTimeStamp] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_Event_Transactions_ProcFlg_Orpflg]
    ON [dbo].[Event_Transactions]([ProcessedFlag] ASC, [OrphanedFlag] ASC);


GO
CREATE NONCLUSTERED INDEX [EventTransactions_IDX_OrphanedEventTimeStamp_Inclds]
    ON [dbo].[Event_Transactions]([OrphanedFlag] ASC, [ProcessedFlag] ASC, [EventTimeStamp] ASC, [EventTransactionId] ASC)
    INCLUDE([EventType], [AreaName], [CellName], [UnitName], [UnitProcedureName], [OperationName], [PhaseName], [RawMaterialAreaName], [RawMaterialCellName], [RawMaterialUnitName], [UserName], [UserSignature]);

