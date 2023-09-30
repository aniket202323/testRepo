CREATE TABLE [dbo].[PU_Group_History] (
    [PU_Group_History_Id]    BIGINT                   IDENTITY (1, 1) NOT NULL,
    [PU_Id]                  INT                      NULL,
    [PUG_Desc]               [dbo].[Varchar_Desc]     NULL,
    [PUG_Order]              INT                      NULL,
    [Comment_Id]             INT                      NULL,
    [External_Link]          [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]               INT                      NULL,
    [PUG_Id]                 INT                      NULL,
    [Modified_On]            DATETIME                 NULL,
    [DBTT_Id]                TINYINT                  NULL,
    [Column_Updated_BitMask] VARCHAR (15)             NULL,
    CONSTRAINT [PU_Group_History_PK_Id] PRIMARY KEY NONCLUSTERED ([PU_Group_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [PUGroupHistory_IX_PUGIdModifiedOn]
    ON [dbo].[PU_Group_History]([PUG_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[PU_Group_History_UpdDel]
 ON  [dbo].[PU_Group_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
