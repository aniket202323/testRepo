CREATE TABLE [dbo].[Process_Segment_Component_History] (
    [Process_Segment_Component_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Entry_On]                             DATETIME      NULL,
    [Segment_Reference_Id]                 INT           NULL,
    [User_Id]                              INT           NULL,
    [Sequence]                             INT           NULL,
    [Code]                                 NVARCHAR (50) NULL,
    [Comment_Id]                           INT           NULL,
    [Parent_Implementation_Id]             INT           NULL,
    [Implementation_Id]                    INT           NULL,
    [Modified_On]                          DATETIME      NULL,
    [DBTT_Id]                              TINYINT       NULL,
    [Column_Updated_BitMask]               VARCHAR (15)  NULL,
    CONSTRAINT [Process_Segment_Component_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Process_Segment_Component_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProcessSegmentComponentHistory_IX_ImplementationIdModifiedOn]
    ON [dbo].[Process_Segment_Component_History]([Implementation_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Process_Segment_Component_History_UpdDel]
 ON  [dbo].[Process_Segment_Component_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
