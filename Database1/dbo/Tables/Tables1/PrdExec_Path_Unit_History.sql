CREATE TABLE [dbo].[PrdExec_Path_Unit_History] (
    [PrdExec_Path_Unit_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Is_Production_Point]          BIT          NULL,
    [Is_Schedule_Point]            BIT          NULL,
    [Path_Id]                      INT          NULL,
    [PU_Id]                        INT          NULL,
    [Unit_Order]                   INT          NULL,
    [PEPU_Id]                      INT          NULL,
    [Modified_On]                  DATETIME     NULL,
    [DBTT_Id]                      TINYINT      NULL,
    [Column_Updated_BitMask]       VARCHAR (15) NULL,
    CONSTRAINT [PrdExec_Path_Unit_History_PK_Id] PRIMARY KEY NONCLUSTERED ([PrdExec_Path_Unit_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [PrdExecPathUnitHistory_IX_PEPUIdModifiedOn]
    ON [dbo].[PrdExec_Path_Unit_History]([PEPU_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[PrdExec_Path_Unit_History_UpdDel]
 ON  [dbo].[PrdExec_Path_Unit_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
