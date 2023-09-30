CREATE TABLE [dbo].[NonProductive_Detail_History] (
    [NonProductive_Detail_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [End_Time]                        DATETIME     NULL,
    [Entry_On]                        DATETIME     NULL,
    [PU_Id]                           INT          NULL,
    [Start_Time]                      DATETIME     NULL,
    [Comment_Id]                      INT          NULL,
    [Event_Reason_Tree_Data_Id]       INT          NULL,
    [Reason_Level1]                   INT          NULL,
    [Reason_Level2]                   INT          NULL,
    [Reason_Level3]                   INT          NULL,
    [Reason_Level4]                   INT          NULL,
    [User_Id]                         INT          NULL,
    [NPDet_Id]                        INT          NULL,
    [Modified_On]                     DATETIME     NULL,
    [DBTT_Id]                         TINYINT      NULL,
    [Column_Updated_BitMask]          VARCHAR (15) NULL,
    [NPT_Group_Id]                    INT          NULL,
    CONSTRAINT [NonProductive_Detail_History_PK_Id] PRIMARY KEY NONCLUSTERED ([NonProductive_Detail_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [NonProductiveDetailHistory_IX_NPDetIdModifiedOn]
    ON [dbo].[NonProductive_Detail_History]([NPDet_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[NonProductive_Detail_History_UpdDel]
 ON  [dbo].[NonProductive_Detail_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
