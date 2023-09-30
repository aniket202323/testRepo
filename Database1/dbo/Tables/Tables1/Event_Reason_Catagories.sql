CREATE TABLE [dbo].[Event_Reason_Catagories] (
    [ERC_Id]          INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ERC_Desc_Global] [dbo].[Varchar_Desc] NULL,
    [ERC_Desc_Local]  [dbo].[Varchar_Desc] NOT NULL,
    [ERC_Desc]        AS                   (case when (@@options&(512))=(0) then isnull([ERC_Desc_Global],[ERC_Desc_Local]) else [ERC_Desc_Local] end),
    CONSTRAINT [EvtRsnCat_PK_ERCId] PRIMARY KEY NONCLUSTERED ([ERC_Id] ASC),
    CONSTRAINT [EvtRsnCat_UC_ERCDescLocal] UNIQUE NONCLUSTERED ([ERC_Desc_Local] ASC)
);


GO
CREATE TRIGGER [dbo].[Event_Reason_Catagories_TableFieldValue_Del]
 ON  [dbo].[Event_Reason_Catagories]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.ERC_Id
 WHERE tfv.TableId = 25
