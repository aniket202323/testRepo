CREATE TABLE [dbo].[Sheet_Columns] (
    [Approver_Reason_Id] INT      NULL,
    [Approver_User_Id]   INT      NULL,
    [Comment_Id]         INT      NULL,
    [Result_On]          DATETIME NOT NULL,
    [Sheet_Id]           INT      NOT NULL,
    [Signature_Id]       INT      NULL,
    [User_Reason_Id]     INT      NULL,
    [User_Signoff_Id]    INT      NULL,
    CONSTRAINT [Sheet_Cols_PK_ShtIdResultOn] PRIMARY KEY CLUSTERED ([Sheet_Id] ASC, [Result_On] ASC),
    CONSTRAINT [Sheet_Cols_FK_ShtId] FOREIGN KEY ([Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id]),
    CONSTRAINT [Sheet_Columns_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [SheetColumnsApproverReason_FK_Event_Reasons] FOREIGN KEY ([Approver_Reason_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [SheetColumnsApproverUserId_FK_Users] FOREIGN KEY ([Approver_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [SheetColumnsUserReason_FK_Event_Reasons] FOREIGN KEY ([User_Reason_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [SheetColumnsUserSignoffId_FK_Users] FOREIGN KEY ([User_Signoff_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE NONCLUSTERED INDEX [sheetcolumns_IDX_SheetIdCommentId]
    ON [dbo].[Sheet_Columns]([Sheet_Id] ASC, [Comment_Id] ASC);


GO
CREATE TRIGGER [dbo].[Sheet_Columns_History_Ins]
 ON  [dbo].[Sheet_Columns]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 415
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Sheet_Column_History
 	  	   (Approver_Reason_Id,Approver_User_Id,Comment_Id,Result_On,Sheet_Id,Signature_Id,User_Reason_Id,User_Signoff_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Approver_Reason_Id,a.Approver_User_Id,a.Comment_Id,a.Result_On,a.Sheet_Id,a.Signature_Id,a.User_Reason_Id,a.User_Signoff_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Sheet_Columns_Del 
  ON dbo.Sheet_Columns 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
Delete from Comments Where TopOfChain_Id in (Select Distinct Comment_Id from DELETED Where Comment_Id IS NOT NULL);
Delete from Comments Where Comment_Id in (Select Distinct Comment_Id from DELETED Where Comment_Id IS NOT NULL);
IF @@ERROR <> 0
BEGIN
 	 RAISERROR('Error in deleting Comments', 11,
      -1, @@ERROR)
END
--DECLARE Sheet_Columns_Del_Cursor CURSOR
--  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
--  FOR READ ONLY
--OPEN Sheet_Columns_Del_Cursor 
----
----
--Fetch_Next_Sheet_Columns_Del:
--FETCH NEXT FROM Sheet_Columns_Del_Cursor INTO @Comment_Id
--IF @@FETCH_STATUS = 0
--  BEGIN
--    Delete From Comments Where TopOfChain_Id = @Comment_Id 
--    Delete From Comments Where Comment_Id = @Comment_Id 
--    GOTO Fetch_Next_Sheet_Columns_Del
--  END
--ELSE IF @@FETCH_STATUS <> -1
--  BEGIN
--    RAISERROR('Fetch error in Sheet_Columns_Del (@@FETCH_STATUS = %d).', 11,
--      -1, @@FETCH_STATUS)
--  END
--DEALLOCATE Sheet_Columns_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Sheet_Columns_History_Del]
 ON  [dbo].[Sheet_Columns]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 415
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Sheet_Column_History
 	  	   (Approver_Reason_Id,Approver_User_Id,Comment_Id,Result_On,Sheet_Id,Signature_Id,User_Reason_Id,User_Signoff_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Approver_Reason_Id,a.Approver_User_Id,a.Comment_Id,a.Result_On,a.Sheet_Id,a.Signature_Id,a.User_Reason_Id,a.User_Signoff_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Sheet_Columns_History_Upd]
 ON  [dbo].[Sheet_Columns]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 415
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Sheet_Column_History
 	  	   (Approver_Reason_Id,Approver_User_Id,Comment_Id,Result_On,Sheet_Id,Signature_Id,User_Reason_Id,User_Signoff_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Approver_Reason_Id,a.Approver_User_Id,a.Comment_Id,a.Result_On,a.Sheet_Id,a.Signature_Id,a.User_Reason_Id,a.User_Signoff_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
