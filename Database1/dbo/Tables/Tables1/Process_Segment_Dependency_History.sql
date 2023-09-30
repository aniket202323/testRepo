CREATE TABLE [dbo].[Process_Segment_Dependency_History] (
    [Process_Segment_Dependency_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Designated_PS_Id]                      INT          NULL,
    [Entry_On]                              DATETIME     NULL,
    [Process_Segment_Id]                    INT          NULL,
    [User_Id]                               INT          NULL,
    [Dependency_Id]                         INT          NULL,
    [PS_Dependency_Id]                      INT          NULL,
    [Modified_On]                           DATETIME     NULL,
    [DBTT_Id]                               TINYINT      NULL,
    [Column_Updated_BitMask]                VARCHAR (15) NULL,
    CONSTRAINT [Process_Segment_Dependency_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Process_Segment_Dependency_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProcessSegmentDependencyHistory_IX_PSDependencyIdModifiedOn]
    ON [dbo].[Process_Segment_Dependency_History]([PS_Dependency_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Process_Segment_Dependency_History_UpdDel]
 ON  [dbo].[Process_Segment_Dependency_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
