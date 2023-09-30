CREATE TABLE [dbo].[PrdExec_Path_Unit_Starts_History] (
    [PrdExec_Path_Unit_Starts_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Path_Id]                             INT          NULL,
    [PU_Id]                               INT          NULL,
    [Start_Time]                          DATETIME     NULL,
    [Comment_Id]                          INT          NULL,
    [End_Time]                            DATETIME     NULL,
    [User_Id]                             INT          NULL,
    [PEPUS_Id]                            INT          NULL,
    [Modified_On]                         DATETIME     NULL,
    [DBTT_Id]                             TINYINT      NULL,
    [Column_Updated_BitMask]              VARCHAR (15) NULL,
    CONSTRAINT [PrdExec_Path_Unit_Starts_History_PK_Id] PRIMARY KEY NONCLUSTERED ([PrdExec_Path_Unit_Starts_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [PrdExecPathUnitStartsHistory_IX_PEPUSIdModifiedOn]
    ON [dbo].[PrdExec_Path_Unit_Starts_History]([PEPUS_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[PrdExec_Path_Unit_Starts_History_UpdDel]
 ON  [dbo].[PrdExec_Path_Unit_Starts_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
