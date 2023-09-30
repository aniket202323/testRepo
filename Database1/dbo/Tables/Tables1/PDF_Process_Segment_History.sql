CREATE TABLE [dbo].[PDF_Process_Segment_History] (
    [PDF_Process_Segment_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Entry_On]                       DATETIME     NULL,
    [Process_Segment_Component_Id]   INT          NULL,
    [Product_Family_Id]              INT          NULL,
    [User_Id]                        INT          NULL,
    [PDFPS_Id]                       INT          NULL,
    [Modified_On]                    DATETIME     NULL,
    [DBTT_Id]                        TINYINT      NULL,
    [Column_Updated_BitMask]         VARCHAR (15) NULL,
    CONSTRAINT [PDF_Process_Segment_History_PK_Id] PRIMARY KEY NONCLUSTERED ([PDF_Process_Segment_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [PDFProcessSegmentHistory_IX_PDFPSIdModifiedOn]
    ON [dbo].[PDF_Process_Segment_History]([PDFPS_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[PDF_Process_Segment_History_UpdDel]
 ON  [dbo].[PDF_Process_Segment_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
