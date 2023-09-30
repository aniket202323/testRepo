CREATE TABLE [dbo].[Local_PG_eCIL_QRInfo] (
    [QR_Id]           INT           IDENTITY (1, 1) NOT NULL,
    [QR_Name]         VARCHAR (150) NOT NULL,
    [QR_Description]  VARCHAR (255) NULL,
    [LastModified_On] DATETIME      NULL,
    [Line_Ids]        VARCHAR (255) NULL,
    [Var_Ids]         VARCHAR (MAX) NULL,
    [Route_Ids]       VARCHAR (255) NULL,
    [Tour_Stop_Id]    INT           NULL,
    [Entry_By]        INT           NOT NULL,
    [QR_Type]         VARCHAR (50)  NULL,
    [QR_Created_On]   DATETIME      CONSTRAINT [df_Time] DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([QR_Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Local_PG_eCIL_QRInfo_IX_QRName_QRType]
    ON [dbo].[Local_PG_eCIL_QRInfo]([QR_Name] ASC, [QR_Type] ASC);


GO

CREATE TRIGGER [dbo].[Local_PG_eCIL_QRInfo_History_Ins]
 ON  [dbo].[Local_PG_eCIL_QRInfo]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 DECLARE  @Populate_History TinyInt
 DECLARE  @DBTT_Id	INT = 2 /*value 2 is for INSERT Operation*/
 SELECT @Populate_History = Value FROM Site_Parameters WHERE Parm_Id = 421
 IF (@Populate_History = 1 or @Populate_History = 3) 
   BEGIN
 	  	     INSERT INTO Local_PG_eCIL_QRInfo_History
 	  	   (QR_Id,QR_Name,QR_Description,QR_Created_On,LastModified_On,line_Ids,Var_Ids,Route_Ids,Tour_Stop_Id,QR_Type,DBTT_Id,Entry_By)
 	  	   SELECT  a.QR_Id,a.QR_Name,a.QR_Description,a.QR_Created_On,dbo.fnServer_CmnGetDate(getUTCdate()),a.line_Ids,a.Var_Ids,a.Route_Ids,a.Tour_Stop_Id,a.QR_Type,@DBTT_Id,a.Entry_By
 	  	   FROM Inserted a
   END

GO

CREATE TRIGGER [dbo].[Local_PG_eCIL_QRInfo_History_Del]
 ON  [dbo].[Local_PG_eCIL_QRInfo]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Declare  @DBTT_Id  INT = 4  /* value 4 is for delete operation*/
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 421
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	    Insert Into Local_PG_eCIL_QRInfo_History
 	  	   (QR_Id,QR_Name,QR_Description,QR_Created_On,LastModified_On,line_Ids,Var_Ids,Route_Ids,Tour_Stop_Id,QR_Type,DBTT_Id,Entry_By)
 	  	   Select  a.QR_Id,a.QR_Name,a.QR_Description,a.QR_Created_On,dbo.fnServer_CmnGetDate(getUTCdate()),a.line_Ids,a.Var_Ids,a.Route_Ids,a.Tour_Stop_Id,a.QR_Type,@DBTT_Id,a.Entry_By
 	  	   From Deleted a
   End

GO

CREATE TRIGGER [dbo].[Local_PG_eCIL_QRInfo_History_Upd]
 ON  [dbo].[Local_PG_eCIL_QRInfo]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 DECLARE  @Populate_History TinyInt
 DECLARE  @DBTT_Id INT = 3 /*value 3 is for Update */
 SELECT @Populate_History = Value FROM Site_Parameters WHERE Parm_Id = 421
 IF (@Populate_History = 1 or @Populate_History = 3) 
   BEGIN
 	  	    INSERT INTO Local_PG_eCIL_QRInfo_History
 	  	   (QR_Id,QR_Name,QR_Description,QR_Created_On,LastModified_On,line_Ids,Var_Ids,Route_Ids,Tour_Stop_Id,QR_Type,DBTT_Id,Entry_By)
 	  	   SELECT  a.QR_Id,a.QR_Name,a.QR_Description,a.QR_Created_On,dbo.fnServer_CmnGetDate(getUTCdate()),a.line_Ids,a.Var_Ids,a.Route_Ids,a.Tour_Stop_Id,a.QR_Type,3,a.Entry_By
 	  	   FROM Inserted a
   END
