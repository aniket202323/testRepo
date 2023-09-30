CREATE TABLE [dbo].[PDF_Process_Segments] (
    [PDFPS_Id]                     INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Entry_On]                     DATETIME NOT NULL,
    [Process_Segment_Component_Id] INT      NOT NULL,
    [Product_Family_Id]            INT      NOT NULL,
    [User_Id]                      INT      NOT NULL,
    CONSTRAINT [PK_PDF_Process_Segments] PRIMARY KEY CLUSTERED ([PDFPS_Id] ASC),
    CONSTRAINT [FK_PDF_Process_Segments_Process_Segment_Components] FOREIGN KEY ([Process_Segment_Component_Id]) REFERENCES [dbo].[Process_Segment_Components] ([Implementation_Id]),
    CONSTRAINT [FK_PDF_Process_Segments_Product_Family] FOREIGN KEY ([Product_Family_Id]) REFERENCES [dbo].[Product_Family] ([Product_Family_Id]),
    CONSTRAINT [FK_PDF_Process_Segments_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[PDF_Process_Segments_History_Upd]
 ON  [dbo].[PDF_Process_Segments]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into PDF_Process_Segment_History
 	  	   (Entry_On,PDFPS_Id,Process_Segment_Component_Id,Product_Family_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.PDFPS_Id,a.Process_Segment_Component_Id,a.Product_Family_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[PDF_Process_Segments_History_Ins]
 ON  [dbo].[PDF_Process_Segments]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into PDF_Process_Segment_History
 	  	   (Entry_On,PDFPS_Id,Process_Segment_Component_Id,Product_Family_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.PDFPS_Id,a.Process_Segment_Component_Id,a.Product_Family_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[PDF_Process_Segments_History_Del]
 ON  [dbo].[PDF_Process_Segments]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into PDF_Process_Segment_History
 	  	   (Entry_On,PDFPS_Id,Process_Segment_Component_Id,Product_Family_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.PDFPS_Id,a.Process_Segment_Component_Id,a.Product_Family_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
