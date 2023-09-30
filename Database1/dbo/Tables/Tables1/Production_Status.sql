CREATE TABLE [dbo].[Production_Status] (
    [ProdStatus_Id]          INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Color_Id]               INT                  NULL,
    [Count_For_Inventory]    TINYINT              CONSTRAINT [Production_Status_DF_Count_For_Inventory] DEFAULT ((1)) NOT NULL,
    [Count_For_Production]   TINYINT              CONSTRAINT [Production_Status_DF_Count_For_Production] DEFAULT ((1)) NOT NULL,
    [Icon_Id]                INT                  NULL,
    [ProdStatus_Desc_Global] [dbo].[Varchar_Desc] NULL,
    [ProdStatus_Desc_Local]  [dbo].[Varchar_Desc] NOT NULL,
    [Status_Valid_For_Input] TINYINT              CONSTRAINT [Production_Status_DF_Status_Valid_For_Input] DEFAULT ((1)) NULL,
    [LifecycleStage]         AS                   (case when [Count_For_Inventory]<>(1) AND [Count_For_Production]<>(1) then (1) when [Count_For_Inventory]=(1) AND [Count_For_Production]=(1) then (2) when [Count_For_Inventory]<>(1) AND [Count_For_Production]=(1) then (3) else (0) end),
    [ProdStatus_Desc]        AS                   (case when (@@options&(512))=(0) then isnull([ProdStatus_Desc_Global],[ProdStatus_Desc_Local]) else [ProdStatus_Desc_Local] end),
    [NoHistory]              INT                  CONSTRAINT [ProductionStatus_DF_NoHistory] DEFAULT ((0)) NOT NULL,
    [LockData]               TINYINT              NULL,
    CONSTRAINT [ProdStatus_PK_ProdStatusId] PRIMARY KEY CLUSTERED ([ProdStatus_Id] ASC),
    CONSTRAINT [ProdStatus_UC_ProdStatusDescLocal] UNIQUE NONCLUSTERED ([ProdStatus_Desc_Local] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ProdStatus_IDX_ValidLifeCycle]
    ON [dbo].[Production_Status]([Status_Valid_For_Input] ASC, [LifecycleStage] ASC);


GO
CREATE TRIGGER dbo.Production_Status_Ins ON dbo.Production_Status
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
  --
  -- Insert a initial undefined product crossreference for this unit on the default
  -- master unit.
  --
  INSERT INTO Production_Status_XRef(Production_Status_XRef, ProdStatus_Id, PU_Id)
    SELECT Production_Status_XRef = '(Undefined)',
           ProdStatus_Id,
           PU_Id = NULL
      FROM INSERTED

GO
CREATE TRIGGER [dbo].[Production_Status_TableFieldValue_Del]
 ON  [dbo].[Production_Status]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.ProdStatus_Id
 WHERE tfv.TableId = 37
