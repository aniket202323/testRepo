CREATE TABLE [dbo].[Process_Segment_Family_History] (
    [Process_Segment_Family_History_Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Entry_On]                          DATETIME       NULL,
    [Process_Segment_Family_Desc]       NVARCHAR (300) NULL,
    [User_Id]                           INT            NULL,
    [Parent_PSF_Id]                     INT            NULL,
    [Process_Segment_Family_Id]         INT            NULL,
    [Modified_On]                       DATETIME       NULL,
    [DBTT_Id]                           TINYINT        NULL,
    [Column_Updated_BitMask]            VARCHAR (15)   NULL,
    CONSTRAINT [Process_Segment_Family_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Process_Segment_Family_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProcessSegmentFamilyHistory_IX_ProcessSegmentFamilyIdModifiedOn]
    ON [dbo].[Process_Segment_Family_History]([Process_Segment_Family_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Process_Segment_Family_History_UpdDel]
 ON  [dbo].[Process_Segment_Family_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
