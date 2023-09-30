CREATE TABLE [dbo].[PrdExec_Input_History] (
    [PrdExec_Input_History_Id] BIGINT               IDENTITY (1, 1) NOT NULL,
    [Event_Subtype_Id]         INT                  NULL,
    [Input_Name]               [dbo].[Varchar_Desc] NULL,
    [Input_Order]              INT                  NULL,
    [PU_Id]                    INT                  NULL,
    [Lock_Inprogress_Input]    BIT                  NULL,
    [Alternate_Spec_Id]        INT                  NULL,
    [Def_Event_Comp_Sheet_Id]  INT                  NULL,
    [Primary_Spec_Id]          INT                  NULL,
    [PEI_Id]                   INT                  NULL,
    [Modified_On]              DATETIME             NULL,
    [DBTT_Id]                  TINYINT              NULL,
    [Column_Updated_BitMask]   VARCHAR (15)         NULL,
    CONSTRAINT [PrdExec_Input_History_PK_Id] PRIMARY KEY NONCLUSTERED ([PrdExec_Input_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [PrdExecInputHistory_IX_PEIIdModifiedOn]
    ON [dbo].[PrdExec_Input_History]([PEI_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[PrdExec_Input_History_UpdDel]
 ON  [dbo].[PrdExec_Input_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
