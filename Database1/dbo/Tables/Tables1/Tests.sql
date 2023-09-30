CREATE TABLE [dbo].[Tests] (
    [Test_Id]        BIGINT                IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Array_Id]       INT                   NULL,
    [Canceled]       BIT                   CONSTRAINT [Tests_DF_Canceled] DEFAULT ((0)) NOT NULL,
    [Comment_Id]     INT                   NULL,
    [Entry_By]       INT                   NULL,
    [Entry_On]       DATETIME              NOT NULL,
    [Event_Id]       INT                   NULL,
    [Locked]         TINYINT               NULL,
    [Result]         [dbo].[Varchar_Value] NULL,
    [Result_On]      DATETIME              NOT NULL,
    [Second_User_Id] INT                   NULL,
    [Signature_Id]   INT                   NULL,
    [Var_Id]         INT                   NOT NULL,
    [IsVarMandatory] BIT                   CONSTRAINT [DF__Tests__IsVarMand__0EC4C328] DEFAULT ((0)) NULL,
    CONSTRAINT [Tests_PK_TestId] PRIMARY KEY NONCLUSTERED ([Test_Id] ASC),
    CONSTRAINT [Tests_FK_EntryBy] FOREIGN KEY ([Entry_By]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Tests_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [Tests_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [TestsSecondUser_FK_Users] FOREIGN KEY ([Second_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Test_UC_VaridResultonEventid] UNIQUE CLUSTERED ([Var_Id] ASC, [Result_On] ASC, [Event_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Tests_IDX_EventIdVarId]
    ON [dbo].[Tests]([Event_Id] ASC, [Var_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Test_By_CommentId]
    ON [dbo].[Tests]([Comment_Id] ASC);


GO
CREATE  TRIGGER dbo.Tests_Del 
  ON dbo.Tests 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@CommentId int
Declare Comment_Cursor INSENSITIVE CURSOR
  For (SELECT Comment_Id FROM DELETED Where Comment_Id Is Not Null)
  For Read Only
  Open Comment_Cursor  
Comment_Loop:
  Fetch Next From Comment_Cursor Into @@CommentId
  If (@@Fetch_Status = 0)
    Begin
 	     Delete From Comments Where TopOfChain_Id = @@CommentId
 	     Delete From Comments Where Comment_Id = @@CommentId 
      Goto Comment_Loop
    End
Close Comment_Cursor
Deallocate Comment_Cursor
Declare  @@ArrayId int
Declare Array_Cursor INSENSITIVE CURSOR
  For (SELECT Array_Id FROM DELETED Where Array_Id Is Not Null)
  For Read Only
  Open Array_Cursor  
Array_Loop:
  Fetch Next From Array_Cursor Into @@ArrayId
  If (@@Fetch_Status = 0)
    Begin
      Delete From Array_Data Where Array_Id = @@ArrayId
      Goto Array_Loop
    End
Close Array_Cursor
Deallocate Array_Cursor

GO
CREATE TRIGGER [dbo].[Tests_History_Del]
 ON  [dbo].[Tests]
  FOR DELETE
  AS
 DECLARE @NEwUserID Int
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 SELECT @NEWUserId =  CONVERT(int, CONVERT(varbinary(4), CONTEXT_INFO()))
 IF NOT EXISTS(Select 1 FROM Users_base WHERE USER_Id = @NEWUserId)
      SET @NEWUserId = Null
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 414
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Test_History
 	  	   (Array_Id,Canceled,Comment_Id,Entry_By,Entry_On,Event_Id,IsVarMandatory,Locked,Result,Result_On,Second_User_Id,Signature_Id,Test_Id,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Array_Id,a.Canceled,a.Comment_Id,coalesce(@NEWUserId,a.Entry_By),a.Entry_On,a.Event_Id,a.IsVarMandatory,a.Locked,a.Result,a.Result_On,a.Second_User_Id,a.Signature_Id,a.Test_Id,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Tests_History_Ins]
 ON  [dbo].[Tests]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 414
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Test_History
 	  	   (Array_Id,Canceled,Comment_Id,Entry_By,Entry_On,Event_Id,IsVarMandatory,Locked,Result,Result_On,Second_User_Id,Signature_Id,Test_Id,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Array_Id,a.Canceled,a.Comment_Id,a.Entry_By,a.Entry_On,a.Event_Id,a.IsVarMandatory,a.Locked,a.Result,a.Result_On,a.Second_User_Id,a.Signature_Id,a.Test_Id,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Tests_History_Upd]
 ON  [dbo].[Tests]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 declare @Total int,@cnt int,@testId int
 Create table #tmp(TestId int,id int identity(1,1))
 Insert into #tmp(TestId)
 SELECT Test_id from inserted where Canceled = 1
 select @Total=@@ROWCOUNT
 set @cnt =1
 IF(@@ROWCOUNT >0)
 BEGIN
	WHILE @cnt <=@Total
	BEGIN
		
		Select @testId = TestId from #tmp where id = @cnt;
		UPDATE Tests set IsVarMandatory = 0 where Test_id = @testId
		EXEC spServer_DBMgrUpdActivitiesForTest @testId;
		Insert into Message_Log_Detail (Message,Message_Log_Id)
		Select cast(@testId as varchar),12345
		set @cnt=@cnt+1
	END
 END
 

 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 414
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Test_History
 	  	   (Array_Id,Canceled,Comment_Id,Entry_By,Entry_On,Event_Id,IsVarMandatory,Locked,Result,Result_On,Second_User_Id,Signature_Id,Test_Id,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Array_Id,a.Canceled,a.Comment_Id,a.Entry_By,a.Entry_On,a.Event_Id,a.IsVarMandatory,a.Locked,a.Result,a.Result_On,a.Second_User_Id,a.Signature_Id,a.Test_Id,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
 If (@Populate_History = 2) and ( Update(Result)) 
   Begin
 	  	   Insert Into Test_History
 	  	   (Array_Id,Canceled,Comment_Id,Entry_By,Entry_On,Event_Id,IsVarMandatory,Locked,Result,Result_On,Second_User_Id,Signature_Id,Test_Id,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Array_Id,a.Canceled,a.Comment_Id,a.Entry_By,a.Entry_On,a.Event_Id,a.IsVarMandatory,a.Locked,a.Result,a.Result_On,a.Second_User_Id,a.Signature_Id,a.Test_Id,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Deleted a
   End
 If (@Populate_History = 3) and (Update(Result))
   Begin
 	  	 DECLARE @HistoryTests Table(id int identity(1,1),TestId Bigint,VarId Int,ResultOn DateTime,Userid Int)
 	  	 INSERT INTO @HistoryTests(VarId,ResultOn,TestId,Userid)
 	  	  	 SELECT  Var_Id, Result_On,Test_Id,Entry_By FROM inserted
 	  	 DELETE FROM @HistoryTests 
 	  	  	 FROM @HistoryTests a
 	  	  	 JOIN Variables_base b on b.Var_Id = a.VarId and b.Event_Type in( 1,26) 
 	  	  	 Join Events c on c.TimeStamp = a.ResultOn and b.PU_Id = c.PU_Id
 	  	  	 Join Production_Status d on d.ProdStatus_Id = c.Event_Status and  d.NoHistory = 1 
 	  	  	 WHERE Userid in(3,6,14,26)
 	  	   Insert Into Test_History
 	  	   (Array_Id,Canceled,Comment_Id,Entry_By,Entry_On,Event_Id,IsVarMandatory,Locked,Result,Result_On,Second_User_Id,Signature_Id,Test_Id,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Array_Id,a.Canceled,a.Comment_Id,a.Entry_By,a.Entry_On,a.Event_Id,a.IsVarMandatory,a.Locked,a.Result,a.Result_On,a.Second_User_Id,a.Signature_Id,a.Test_Id,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a 
  	  	 Join  @HistoryTests b on b.TestId = a.Test_Id
End 
