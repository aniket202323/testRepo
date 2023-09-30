CREATE TABLE [dbo].[Process_Segment_Equipment_History] (
    [Process_Segment_Equipment_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Entry_On]                             DATETIME     NULL,
    [Key_Id]                               INT          NULL,
    [Process_Segment_Id]                   INT          NULL,
    [Table_Id]                             INT          NULL,
    [User_id]                              INT          NULL,
    [PS_Equipment_Id]                      INT          NULL,
    [Modified_On]                          DATETIME     NULL,
    [DBTT_Id]                              TINYINT      NULL,
    [Column_Updated_BitMask]               VARCHAR (15) NULL,
    CONSTRAINT [Process_Segment_Equipment_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Process_Segment_Equipment_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProcessSegmentEquipmentHistory_IX_PSEquipmentIdModifiedOn]
    ON [dbo].[Process_Segment_Equipment_History]([PS_Equipment_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Process_Segment_Equipment_History_UpdDel]
 ON  [dbo].[Process_Segment_Equipment_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
