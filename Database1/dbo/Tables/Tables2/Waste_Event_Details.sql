CREATE TABLE [dbo].[Waste_Event_Details] (
    [WED_Id]                    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Action_Comment_Id]         INT           NULL,
    [Action_Level1]             INT           NULL,
    [Action_Level2]             INT           NULL,
    [Action_Level3]             INT           NULL,
    [Action_Level4]             INT           NULL,
    [Amount]                    FLOAT (53)    NULL,
    [Cause_Comment_Id]          INT           NULL,
    [Dimension_A]               FLOAT (53)    NULL,
    [Dimension_X]               FLOAT (53)    NULL,
    [Dimension_Y]               FLOAT (53)    NULL,
    [Dimension_Z]               FLOAT (53)    NULL,
    [EC_Id]                     INT           NULL,
    [Entry_On]                  DATETIME      NULL,
    [Event_Id]                  INT           NULL,
    [Event_Reason_Tree_Data_Id] INT           NULL,
    [PU_Id]                     INT           NOT NULL,
    [Reason_Level1]             INT           NULL,
    [Reason_Level2]             INT           NULL,
    [Reason_Level3]             INT           NULL,
    [Reason_Level4]             INT           NULL,
    [Research_Close_Date]       DATETIME      NULL,
    [Research_Comment_Id]       INT           NULL,
    [Research_Open_Date]        DATETIME      NULL,
    [Research_Status_Id]        INT           NULL,
    [Research_User_Id]          INT           NULL,
    [Signature_Id]              INT           NULL,
    [Source_PU_Id]              INT           NULL,
    [Start_Coordinate_A]        FLOAT (53)    NULL,
    [Start_Coordinate_X]        FLOAT (53)    NULL,
    [Start_Coordinate_Y]        FLOAT (53)    NULL,
    [Start_Coordinate_Z]        FLOAT (53)    NULL,
    [TimeStamp]                 DATETIME      NOT NULL,
    [User_General_1]            VARCHAR (255) NULL,
    [User_General_2]            VARCHAR (255) NULL,
    [User_General_3]            VARCHAR (255) NULL,
    [User_General_4]            VARCHAR (255) NULL,
    [User_General_5]            VARCHAR (255) NULL,
    [User_Id]                   INT           NULL,
    [WEFault_Id]                INT           NULL,
    [WEMT_Id]                   INT           NULL,
    [WET_Id]                    INT           NULL,
    [Work_Order_Number]         VARCHAR (50)  NULL,
    CONSTRAINT [WEvent_Details_PK_WEDId] PRIMARY KEY NONCLUSTERED ([WED_Id] ASC),
    CONSTRAINT [WEvent_Details_FK_EventId] FOREIGN KEY ([Event_Id]) REFERENCES [dbo].[Events] ([Event_Id]),
    CONSTRAINT [WEvent_Details_FK_Fault] FOREIGN KEY ([WEFault_Id]) REFERENCES [dbo].[Waste_Event_Fault] ([WEFault_Id]),
    CONSTRAINT [WEvent_Details_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [WEvent_Details_FK_RsnLevel1] FOREIGN KEY ([Reason_Level1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [WEvent_Details_FK_RsnLevel2] FOREIGN KEY ([Reason_Level2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [WEvent_Details_FK_RsnLevel3] FOREIGN KEY ([Reason_Level3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [WEvent_Details_FK_RsnLevel4] FOREIGN KEY ([Reason_Level4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [WEvent_Details_FK_RUserId] FOREIGN KEY ([Research_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [WEvent_Details_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [WEvent_Details_FK_SrcPUId] FOREIGN KEY ([Source_PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [WEvent_Details_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [WEvent_Details_FK_WEMTId] FOREIGN KEY ([WEMT_Id]) REFERENCES [dbo].[Waste_Event_Meas] ([WEMT_Id]),
    CONSTRAINT [WEvent_Details_FK_WETId] FOREIGN KEY ([WET_Id]) REFERENCES [dbo].[Waste_Event_Type] ([WET_Id])
);


GO
ALTER TABLE [dbo].[Waste_Event_Details] NOCHECK CONSTRAINT [WEvent_Details_FK_EventId];


GO
CREATE CLUSTERED INDEX [WEvent_Details_IDX_PUIdTime]
    ON [dbo].[Waste_Event_Details]([PU_Id] ASC, [TimeStamp] ASC);


GO
CREATE NONCLUSTERED INDEX [WEventDetails_IDX_ECId]
    ON [dbo].[Waste_Event_Details]([EC_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [WEvent_Details_IDX_EventId]
    ON [dbo].[Waste_Event_Details]([Event_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [WEvent_Details_IDX_EventIdTime]
    ON [dbo].[Waste_Event_Details]([Event_Id] ASC, [TimeStamp] ASC);


GO
CREATE NONCLUSTERED INDEX [WEvent_Details_IDX_WEFault_Id]
    ON [dbo].[Waste_Event_Details]([WEFault_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_Waste_Event_Details_Amount_includes]
    ON [dbo].[Waste_Event_Details]([Amount] ASC)
    INCLUDE([PU_Id], [Event_Id]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_WASTEEVENTDETAILS_WEDID_TIMESTAMP_PUID_WEMTID_EVENTID]
    ON [dbo].[Waste_Event_Details]([WED_Id] ASC)
    INCLUDE([Action_Comment_Id], [Action_Level1], [Action_Level2], [Action_Level3], [Action_Level4], [Amount], [Cause_Comment_Id], [Entry_On], [Event_Id], [Reason_Level1], [Reason_Level2], [Reason_Level3], [Reason_Level4], [Source_PU_Id], [User_Id], [WEFault_Id], [WEMT_Id], [WET_Id]);


GO
CREATE NONCLUSTERED INDEX [IX_WASTE_EVENT_DETAILS_GETEVENTSPROC]
    ON [dbo].[Waste_Event_Details]([TimeStamp] ASC)
    INCLUDE([Action_Comment_Id], [Action_Level1], [Action_Level2], [Action_Level3], [Action_Level4], [Amount], [Cause_Comment_Id], [Entry_On], [Event_Id], [Reason_Level1], [Reason_Level2], [Reason_Level3], [Reason_Level4], [Source_PU_Id], [User_Id], [WED_Id], [WEFault_Id], [WEMT_Id], [WET_Id]);


GO
CREATE NONCLUSTERED INDEX [IDX_WASTEEVENT_DETAILS_WORKORDERNUMBER]
    ON [dbo].[Waste_Event_Details]([Work_Order_Number] ASC)
    INCLUDE([Event_Id], [Amount]);


GO
CREATE TRIGGER dbo.Waste_Event_Details_Upd
  ON dbo.Waste_Event_Details
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int,
  @@PUId int,
  @@timestamp datetime,
  @UserId 	  	 Int
 	  	 
SELECT @UserId = MIN(User_Id) FROM Inserted
IF @UserId = 49
 	 RETURN
Declare Waste_Event_Details_Upd_Cursor INSENSITIVE CURSOR
  For (Select WED_Id,PU_Id,Timestamp From INSERTED)
  For Read Only
  Open Waste_Event_Details_Upd_Cursor  
Fetch_Loop:
  Fetch Next From Waste_Event_Details_Upd_Cursor Into @@Id,@@PUId,@@timestamp
  If (@@Fetch_Status = 0)
    Begin
      Execute spServer_CmnAddScheduledTask @@Id,4,@@PUId,@@timestamp
      Goto Fetch_Loop
    End
Close Waste_Event_Details_Upd_Cursor
Deallocate Waste_Event_Details_Upd_Cursor

GO
CREATE TRIGGER [dbo].[Waste_Event_Details_History_Ins]
 ON  [dbo].[Waste_Event_Details]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 401
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Waste_Event_Detail_History
 	  	   (Action_Comment_Id,Action_Level1,Action_Level2,Action_Level3,Action_Level4,Amount,Cause_Comment_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,EC_Id,Entry_On,Event_Id,Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_PU_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,TimeStamp,User_General_1,User_General_2,User_General_3,User_General_4,User_General_5,User_Id,WED_Id,WEFault_Id,WEMT_Id,WET_Id,Work_Order_Number,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action_Level1,a.Action_Level2,a.Action_Level3,a.Action_Level4,a.Amount,a.Cause_Comment_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.EC_Id,a.Entry_On,a.Event_Id,a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_PU_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.TimeStamp,a.User_General_1,a.User_General_2,a.User_General_3,a.User_General_4,a.User_General_5,a.User_Id,a.WED_Id,a.WEFault_Id,a.WEMT_Id,a.WET_Id,a.Work_Order_Number,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Waste_Event_Details_History_Upd]
 ON  [dbo].[Waste_Event_Details]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 401
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Waste_Event_Detail_History
 	  	   (Action_Comment_Id,Action_Level1,Action_Level2,Action_Level3,Action_Level4,Amount,Cause_Comment_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,EC_Id,Entry_On,Event_Id,Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_PU_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,TimeStamp,User_General_1,User_General_2,User_General_3,User_General_4,User_General_5,User_Id,WED_Id,WEFault_Id,WEMT_Id,WET_Id,Work_Order_Number,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action_Level1,a.Action_Level2,a.Action_Level3,a.Action_Level4,a.Amount,a.Cause_Comment_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.EC_Id,a.Entry_On,a.Event_Id,a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_PU_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.TimeStamp,a.User_General_1,a.User_General_2,a.User_General_3,a.User_General_4,a.User_General_5,a.User_Id,a.WED_Id,a.WEFault_Id,a.WEMT_Id,a.WET_Id,a.Work_Order_Number,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
 If (@Populate_History = 3)
   Begin 
 	  	   Insert Into Waste_Event_Detail_History
 	  	   (Action_Comment_Id,Action_Level1,Action_Level2,Action_Level3,Action_Level4,Amount,Cause_Comment_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,EC_Id,Entry_On,Event_Id,Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_PU_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,TimeStamp,User_General_1,User_General_2,User_General_3,User_General_4,User_General_5,User_Id,WED_Id,WEFault_Id,WEMT_Id,WET_Id,Work_Order_Number,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action_Level1,a.Action_Level2,a.Action_Level3,a.Action_Level4,a.Amount,a.Cause_Comment_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.EC_Id,a.Entry_On,a.Event_Id,a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_PU_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.TimeStamp,a.User_General_1,a.User_General_2,a.User_General_3,a.User_General_4,a.User_General_5,a.User_Id,a.WED_Id,a.WEFault_Id,a.WEMT_Id,a.WET_Id,a.Work_Order_Number,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a 
  	  	 Join Events b on b.Event_Id = a.Event_Id
 	  	 Join Production_Status c on c.ProdStatus_Id = b.Event_Status 
 	  	 WHERE  c.NoHistory = 0 or a.User_id = 1 or a.User_id > 50
End 

GO
CREATE TRIGGER dbo.Waste_Event_Details_Ins
  ON dbo.Waste_Event_Details
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int,
  @@PUId int,
  @@timestamp datetime,
  @UserId 	  	 Int
 	  	 
SELECT @UserId = MIN(User_Id) FROM Inserted
IF @UserId = 49
 	 RETURN
Declare Waste_Event_Details_Ins_Cursor INSENSITIVE CURSOR
  For (Select WED_Id,PU_Id,Timestamp From INSERTED)
  For Read Only
  Open Waste_Event_Details_Ins_Cursor  
Fetch_Loop:
  Fetch Next From Waste_Event_Details_Ins_Cursor Into @@Id,@@PUId,@@timestamp
  If (@@Fetch_Status = 0)
    Begin
      Execute spServer_CmnAddScheduledTask @@Id,4,@@PUId,@@timestamp
      Goto Fetch_Loop
    End
Close Waste_Event_Details_Ins_Cursor
Deallocate Waste_Event_Details_Ins_Cursor

GO
CREATE TRIGGER [dbo].[Waste_Event_Details_History_Del]
 ON  [dbo].[Waste_Event_Details]
  FOR DELETE
  AS
 DECLARE @NEwUserID Int
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 SELECT @NEWUserId =  CONVERT(int, CONVERT(varbinary(4), CONTEXT_INFO()))
 IF NOT EXISTS(Select 1 FROM Users_base WHERE USER_Id = @NEWUserId)
      SET @NEWUserId = Null
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 401
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Waste_Event_Detail_History
 	  	   (Action_Comment_Id,Action_Level1,Action_Level2,Action_Level3,Action_Level4,Amount,Cause_Comment_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,EC_Id,Entry_On,Event_Id,Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_PU_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,TimeStamp,User_General_1,User_General_2,User_General_3,User_General_4,User_General_5,User_Id,WED_Id,WEFault_Id,WEMT_Id,WET_Id,Work_Order_Number,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action_Level1,a.Action_Level2,a.Action_Level3,a.Action_Level4,a.Amount,a.Cause_Comment_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.EC_Id,a.Entry_On,a.Event_Id,a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_PU_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.TimeStamp,a.User_General_1,a.User_General_2,a.User_General_3,a.User_General_4,a.User_General_5,coalesce(@NEWUserId,a.User_Id),a.WED_Id,a.WEFault_Id,a.WEMT_Id,a.WET_Id,a.Work_Order_Number,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER dbo.Waste_Event_Details_Del
  ON dbo.Waste_Event_Details
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int,
  @@PUId int,
  @@timestamp datetime,
 	 @Comment_Id1 int,
 	 @Comment_Id2 int,
 	 @Comment_Id3 int
Declare Waste_Event_Details_Del_Cursor INSENSITIVE CURSOR
  For (Select WED_Id,PU_Id,Timestamp,Cause_Comment_Id,Action_Comment_Id,Research_Comment_Id From DELETED)
  For Read Only
  Open Waste_Event_Details_Del_Cursor  
Fetch_Loop:
  Fetch Next From Waste_Event_Details_Del_Cursor Into @@Id,@@PUId,@@timestamp, @Comment_Id1, @Comment_Id2, @Comment_Id3
  If (@@Fetch_Status = 0)
    Begin
 	     IF @Comment_Id1 IS NOT NULL 
 	       BEGIN
 	         Delete From Comments Where TopOfChain_Id = @Comment_Id1 
 	         Delete From Comments Where Comment_Id = @Comment_Id1 
 	       END
 	     IF @Comment_Id2 IS NOT NULL 
 	       BEGIN
 	         Delete From Comments Where TopOfChain_Id = @Comment_Id2
 	         Delete From Comments Where Comment_Id = @Comment_Id2
 	       END
 	     IF @Comment_Id3 IS NOT NULL 
 	       BEGIN
 	         Delete From Comments Where TopOfChain_Id = @Comment_Id3 
 	         Delete From Comments Where Comment_Id = @Comment_Id3 
 	       END
      Execute spServer_CmnRemoveScheduledTask @@Id,4
      Goto Fetch_Loop
    End
Close Waste_Event_Details_Del_Cursor
Deallocate Waste_Event_Details_Del_Cursor
