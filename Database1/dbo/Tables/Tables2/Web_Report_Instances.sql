CREATE TABLE [dbo].[Web_Report_Instances] (
    [WRI_Id]               INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Attachment_File]      VARCHAR (1000) NULL,
    [Entry_On]             DATETIME       NULL,
    [File_Name]            VARCHAR (1000) NULL,
    [Report_Approved_Date] DATETIME       NULL,
    [Report_Create_Date]   DATETIME       NULL,
    [Report_Email_Date]    DATETIME       NULL,
    [Report_Id]            INT            NULL,
    [Report_Print_Date]    DATETIME       NULL,
    [Report_Reject_Date]   DATETIME       NULL,
    [Report_Schedule_Date] DATETIME       NULL,
    [WAS_Id]               INT            NULL,
    [WRD_Id]               INT            NULL,
    CONSTRAINT [PK_Web_Report_Instances] PRIMARY KEY NONCLUSTERED ([WRI_Id] ASC),
    CONSTRAINT [WRI_WAS] FOREIGN KEY ([WAS_Id]) REFERENCES [dbo].[Web_App_Status] ([WAS_Id]),
    CONSTRAINT [WRI_WRD] FOREIGN KEY ([WRD_Id]) REFERENCES [dbo].[Web_Report_Definitions] ([WRD_Id])
);


GO
CREATE TRIGGER [dbo].[Web_Report_Instances_History_Upd]
 ON  [dbo].[Web_Report_Instances]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 417
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Web_Report_Instance_History
 	  	   (Attachment_File,Entry_On,File_Name,Report_Approved_Date,Report_Create_Date,Report_Email_Date,Report_Id,Report_Print_Date,Report_Reject_Date,Report_Schedule_Date,WAS_Id,WRD_Id,WRI_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Attachment_File,a.Entry_On,a.File_Name,a.Report_Approved_Date,a.Report_Create_Date,a.Report_Email_Date,a.Report_Id,a.Report_Print_Date,a.Report_Reject_Date,a.Report_Schedule_Date,a.WAS_Id,a.WRD_Id,a.WRI_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Web_Report_Instances_History_Del]
 ON  [dbo].[Web_Report_Instances]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 417
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Web_Report_Instance_History
 	  	   (Attachment_File,Entry_On,File_Name,Report_Approved_Date,Report_Create_Date,Report_Email_Date,Report_Id,Report_Print_Date,Report_Reject_Date,Report_Schedule_Date,WAS_Id,WRD_Id,WRI_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Attachment_File,a.Entry_On,a.File_Name,a.Report_Approved_Date,a.Report_Create_Date,a.Report_Email_Date,a.Report_Id,a.Report_Print_Date,a.Report_Reject_Date,a.Report_Schedule_Date,a.WAS_Id,a.WRD_Id,a.WRI_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Web_Report_Instances_History_Ins]
 ON  [dbo].[Web_Report_Instances]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 417
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Web_Report_Instance_History
 	  	   (Attachment_File,Entry_On,File_Name,Report_Approved_Date,Report_Create_Date,Report_Email_Date,Report_Id,Report_Print_Date,Report_Reject_Date,Report_Schedule_Date,WAS_Id,WRD_Id,WRI_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Attachment_File,a.Entry_On,a.File_Name,a.Report_Approved_Date,a.Report_Create_Date,a.Report_Email_Date,a.Report_Id,a.Report_Print_Date,a.Report_Reject_Date,a.Report_Schedule_Date,a.WAS_Id,a.WRD_Id,a.WRI_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
