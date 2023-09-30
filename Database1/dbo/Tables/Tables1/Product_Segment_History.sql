CREATE TABLE [dbo].[Product_Segment_History] (
    [Product_Segment_History_Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Entry_On]                   DATETIME       NULL,
    [Process_Segment_Id]         INT            NULL,
    [Product_Definition_Id]      INT            NULL,
    [Product_Segment_Name]       NVARCHAR (50)  NULL,
    [User_Id]                    INT            NULL,
    [Sequence]                   INT            NULL,
    [Code]                       NVARCHAR (50)  NULL,
    [Parent_PS_Id]               INT            NULL,
    [Product_Segment_Desc]       NVARCHAR (300) NULL,
    [Product_Segment_Id]         INT            NULL,
    [Modified_On]                DATETIME       NULL,
    [DBTT_Id]                    TINYINT        NULL,
    [Column_Updated_BitMask]     VARCHAR (15)   NULL,
    CONSTRAINT [Product_Segment_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Segment_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductSegmentHistory_IX_ProductSegmentIdModifiedOn]
    ON [dbo].[Product_Segment_History]([Product_Segment_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Segment_History_UpdDel]
 ON  [dbo].[Product_Segment_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
