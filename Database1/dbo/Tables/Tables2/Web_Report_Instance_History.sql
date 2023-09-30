CREATE TABLE [dbo].[Web_Report_Instance_History] (
    [Web_Report_Instance_History_Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Attachment_File]                VARCHAR (1000) NULL,
    [Entry_On]                       DATETIME       NULL,
    [File_Name]                      VARCHAR (1000) NULL,
    [Report_Approved_Date]           DATETIME       NULL,
    [Report_Create_Date]             DATETIME       NULL,
    [Report_Email_Date]              DATETIME       NULL,
    [Report_Id]                      INT            NULL,
    [Report_Print_Date]              DATETIME       NULL,
    [Report_Reject_Date]             DATETIME       NULL,
    [Report_Schedule_Date]           DATETIME       NULL,
    [WAS_Id]                         INT            NULL,
    [WRD_Id]                         INT            NULL,
    [WRI_Id]                         INT            NULL,
    [Modified_On]                    DATETIME       NULL,
    [DBTT_Id]                        TINYINT        NULL,
    [Column_Updated_BitMask]         VARCHAR (15)   NULL,
    CONSTRAINT [Web_Report_Instance_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Web_Report_Instance_History_Id] ASC)
);


GO
CREATE TRIGGER [dbo].[Web_Report_Instance_History_UpdDel]
 ON  [dbo].[Web_Report_Instance_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
