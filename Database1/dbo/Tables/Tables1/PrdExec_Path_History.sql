CREATE TABLE [dbo].[PrdExec_Path_History] (
    [PrdExec_Path_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Is_Line_Production]      BIT          NULL,
    [Is_Schedule_Controlled]  BIT          NULL,
    [Path_Code]               VARCHAR (50) NULL,
    [Path_Desc]               VARCHAR (50) NULL,
    [PL_Id]                   INT          NULL,
    [Create_Children]         BIT          NULL,
    [Comment_Id]              INT          NULL,
    [Schedule_Control_Type]   TINYINT      NULL,
    [Path_Id]                 INT          NULL,
    [Modified_On]             DATETIME     NULL,
    [DBTT_Id]                 TINYINT      NULL,
    [Column_Updated_BitMask]  VARCHAR (15) NULL,
    CONSTRAINT [PrdExec_Path_History_PK_Id] PRIMARY KEY NONCLUSTERED ([PrdExec_Path_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [PrdExecPathHistory_IX_PathIdModifiedOn]
    ON [dbo].[PrdExec_Path_History]([Path_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[PrdExec_Path_History_UpdDel]
 ON  [dbo].[PrdExec_Path_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
