CREATE TABLE [dbo].[Event_Details] (
    [Alternate_Event_Num]   VARCHAR (50) NULL,
    [Blocked_In_Location]   TINYINT      NULL,
    [Comment_Id]            INT          NULL,
    [Entered_By]            INT          NULL,
    [Entered_On]            DATETIME     NULL,
    [Event_Id]              INT          NOT NULL,
    [Final_Dimension_A]     FLOAT (53)   NULL,
    [Final_Dimension_X]     FLOAT (53)   NULL,
    [Final_Dimension_Y]     FLOAT (53)   NULL,
    [Final_Dimension_Z]     FLOAT (53)   NULL,
    [Initial_Dimension_A]   FLOAT (53)   NULL,
    [Initial_Dimension_X]   FLOAT (53)   NULL,
    [Initial_Dimension_Y]   FLOAT (53)   NULL,
    [Initial_Dimension_Z]   FLOAT (53)   NULL,
    [Location_Id]           INT          NULL,
    [Order_Id]              INT          NULL,
    [Order_Line_Id]         INT          NULL,
    [Orientation_A]         FLOAT (53)   NULL,
    [Orientation_X]         FLOAT (53)   NULL,
    [Orientation_Y]         FLOAT (53)   NULL,
    [Orientation_Z]         FLOAT (53)   NULL,
    [PP_Id]                 INT          NULL,
    [PP_Setup_Detail_Id]    INT          NULL,
    [PP_Setup_Id]           INT          NULL,
    [Product_Definition_Id] INT          NULL,
    [PU_Id]                 INT          NULL,
    [Shipment_Id]           INT          NULL,
    [Shipment_Item_Id]      INT          NULL,
    [Signature_Id]          INT          NULL,
    CONSTRAINT [Event_Details_PK_EventId] PRIMARY KEY CLUSTERED ([Event_Id] ASC),
    CONSTRAINT [Event_Details_FK_EnteredBy] FOREIGN KEY ([Entered_By]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Event_Details_FK_EventId] FOREIGN KEY ([Event_Id]) REFERENCES [dbo].[Events] ([Event_Id]),
    CONSTRAINT [Event_Details_FK_OrderId] FOREIGN KEY ([Order_Id]) REFERENCES [dbo].[Customer_Orders] ([Order_Id]),
    CONSTRAINT [Event_Details_FK_OrderLId] FOREIGN KEY ([Order_Line_Id]) REFERENCES [dbo].[Customer_Order_Line_Items] ([Order_Line_Id]),
    CONSTRAINT [Event_Details_FK_PPId] FOREIGN KEY ([PP_Id]) REFERENCES [dbo].[Production_Plan] ([PP_Id]),
    CONSTRAINT [Event_Details_FK_PPSetupDetailId] FOREIGN KEY ([PP_Setup_Detail_Id]) REFERENCES [dbo].[Production_Setup_Detail] ([PP_Setup_Detail_Id]),
    CONSTRAINT [Event_Details_FK_PPSetupId] FOREIGN KEY ([PP_Setup_Id]) REFERENCES [dbo].[Production_Setup] ([PP_Setup_Id]),
    CONSTRAINT [Event_Details_FK_ShipItemId] FOREIGN KEY ([Shipment_Item_Id]) REFERENCES [dbo].[Shipment_Line_Items] ([Shipment_Item_Id]),
    CONSTRAINT [Event_Details_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [EventDetails_FK_ProductDefId] FOREIGN KEY ([Product_Definition_Id]) REFERENCES [dbo].[Product_Definitions] ([Product_Definition_Id]) ON DELETE CASCADE,
    CONSTRAINT [EventDetails_FK_ShipmentId] FOREIGN KEY ([Shipment_Id]) REFERENCES [dbo].[Shipment] ([Shipment_Id]),
    CONSTRAINT [EventDetails_FK_UnitLocations] FOREIGN KEY ([Location_Id]) REFERENCES [dbo].[Unit_Locations] ([Location_Id])
);


GO
ALTER TABLE [dbo].[Event_Details] NOCHECK CONSTRAINT [Event_Details_FK_EventId];


GO
CREATE NONCLUSTERED INDEX [Event_Details_IDX_Alt_Num]
    ON [dbo].[Event_Details]([Alternate_Event_Num] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_Details_IDX_Shipment]
    ON [dbo].[Event_Details]([Shipment_Item_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_Details_IDX_ProductDefId]
    ON [dbo].[Event_Details]([Product_Definition_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_Details_IDX_PPSetupDetail]
    ON [dbo].[Event_Details]([PP_Id] ASC, [PP_Setup_Id] ASC, [PP_Setup_Detail_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_Details_IDX_OrderLine]
    ON [dbo].[Event_Details]([Order_Line_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_Details_IDX_Order]
    ON [dbo].[Event_Details]([Order_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_Detail_IDX_PPSetupId]
    ON [dbo].[Event_Details]([PP_Setup_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IxEventDT_FinalX]
    ON [dbo].[Event_Details]([Event_Id] ASC, [Final_Dimension_X] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EVENTDETAILS_PPSETUP_PPSETUPDETAILID]
    ON [dbo].[Event_Details]([PP_Setup_Detail_Id] ASC, [PP_Setup_Id] ASC);


GO
CREATE TRIGGER dbo.Event_Details_Ins
  ON dbo.Event_Details
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @Id int,
 	  	 @EventId 	 Int,
 	  	 @PUId 	  	 Int,
 	  	 @Time 	  	 DateTime,
 	  	 @SrcEventId 	 Int,
 	  	 @UserId 	  	 Int
 	  	 
SELECT @UserId = MIN(Entered_By) FROM Inserted
IF @UserId = 49
 	 RETURN
--See if there are any pu_ids used as inputs for genealogy events. Capture the result var id & its pu id too
Declare @AllPUs TABLE (PUId INT, ResultVarId INT, ResultVarIdPUId INT)
Insert into @AllPUs (PUId, ResultVarId, ResultVarIdPUId)
 	 select d.pu_id, d.Result_Var_Id, ISNULL(p.Master_Unit,p.PU_Id)
 	   from Calculation_Inputs i 
 	   Join calculation_input_data d on i.calc_input_id = d.calc_input_id and d.pu_id IS NOT NULL
    Join Variables v on v.Var_Id = d.Result_Var_Id
 	  	 Join Prod_Units p on p.PU_Id = v.PU_Id 
 	   Where i.Calc_Input_Entity_Id = 8 -- Genealogy Events
Insert into @AllPUs (PUId, ResultVarId, ResultVarIdPUId)
 	 select p1.pu_id, d.Result_Var_Id, ISNULL(p2.Master_Unit,p2.PU_Id)
 	   from Calculation_Inputs i 
 	   Join calculation_input_data d on i.calc_input_id = d.calc_input_id and d.pu_id IS NOT NULL
 	  	 Join Prod_Units p1 on p1.Equipment_Type = d.Alias_Name
    Join Variables v on v.Var_Id = d.Result_Var_Id
 	  	 Join Prod_Units p2 on p2.PU_Id = v.PU_Id 
 	   Where i.Calc_Input_Entity_Id = 9 -- Genealogy Event Aliases
--We're done if there aren't any Genealogy Event or Genealogy Event Alias inputs being used.
-- Just add a task for the current Event ID
If (Select Count(*) from @AllPUs) = 0 
  begin
 	  	 DECLARE Event_Details_Ins_Cursor3 CURSOR
 	  	   FOR SELECT ed.Event_Id, e.PU_Id, e.Timestamp FROM INSERTED ed JOIN Events e on ed.Event_Id = e.Event_Id
 	  	   FOR READ ONLY
 	  	  	  	 OPEN Event_Details_Ins_Cursor3
 	  	   Fetch_Next_Event3:
   	  	 Fetch Next From Event_Details_Ins_Cursor3 Into @EventId,@PUId,@Time
 	  	   IF @@FETCH_STATUS = 0
 	  	     BEGIN
 	  	  	  	  	 Execute spServer_CmnAddScheduledTask @EventId,14,@PUId,@Time
 	  	       GOTO Fetch_Next_Event3
 	  	     END
 	  	 Close Event_Details_Ins_Cursor3
 	  	 DEALLOCATE Event_Details_Ins_Cursor3
 	  	 GOTO EXITPROC
  end
--Whittle it down to just the distinct PUs that changed. 
Declare @PUs TABLE (PUId INT)
Insert Into @PUs (PUId)
 	 Select DISTINCT PUId from @AllPUs
 	 UNION 
 	 Select DISTINCT ResultVarIdPUId from @AllPUs
 	 UNION
 	 SELECT  DISTINCT e.PU_Id FROM INSERTED ed JOIN Events e on ed.Event_Id = e.Event_Id
create table #ResultEvents (EventId int, EventUnit int, EndTime datetime)
DECLARE Event_Details_Ins_Cursor CURSOR
  FOR SELECT Event_Id FROM INSERTED
  FOR READ ONLY
OPEN Event_Details_Ins_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Details_Ins_Cursor INTO @Id
  IF @@FETCH_STATUS = 0
    BEGIN
 	   Insert INto #ResultEvents
 	     	   Execute spServer_CalcMgrGetAffectedGenEventIds @Id,@Id
      GOTO Fetch_Next_Event
    END
Close Event_Details_Ins_Cursor
DEALLOCATE Event_Details_Ins_Cursor
Declare Event_Details_Ins_Cursor2 CURSOR
  FOR SELECT Distinct EventId,EventUnit,EndTime 
 	  	  	  	 FROM #ResultEvents
 	  	  	  	 JOIN @PUs on PUId = EventUnit
  FOR READ ONLY
 	  	 Open Event_Details_Ins_Cursor2
Loop1:
  Fetch Next From Event_Details_Ins_Cursor2 Into @EventId,@PUId,@Time
  IF @@FETCH_STATUS = 0
 	 BEGIN
 	  	  	 -- This is actually sticking extra pending tasks in for task id 30 but there 
 	  	  	 -- shouldn't be that many so we just left it alone. If this becomes a performance
 	  	  	 -- issue, just insert a row into pendingtasks for taskid 30 for only the current event.
 	  	  	 -- No other events in the tree should care about it. 
    	   Execute spServer_CmnAddScheduledTask @EventId,14,@PUId,@Time
 	   Goto Loop1
 	 End
Close Event_Details_Ins_Cursor2
Deallocate Event_Details_Ins_Cursor2
Drop Table #ResultEvents
EXITPROC: 

GO
CREATE TRIGGER [dbo].[Event_Details_History_Del]
 ON  [dbo].[Event_Details]
  FOR DELETE
  AS
 DECLARE @NEwUserID Int
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 SELECT @NEWUserId =  CONVERT(int, CONVERT(varbinary(4), CONTEXT_INFO()))
 IF NOT EXISTS(Select 1 FROM Users_base WHERE USER_Id = @NEWUserId)
      SET @NEWUserId = Null
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 405
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Event_Detail_History
 	  	   (Alternate_Event_Num,Blocked_In_Location,Comment_Id,Entered_By,Entered_On,Event_Id,Final_Dimension_A,Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,Initial_Dimension_A,Initial_Dimension_X,Initial_Dimension_Y,Initial_Dimension_Z,Location_Id,Order_Id,Order_Line_Id,Orientation_A,Orientation_X,Orientation_Y,Orientation_Z,PP_Id,PP_Setup_Detail_Id,PP_Setup_Id,Product_Definition_Id,PU_Id,Shipment_Id,Shipment_Item_Id,Signature_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alternate_Event_Num,a.Blocked_In_Location,a.Comment_Id,coalesce(@NEWUserId,a.Entered_By),a.Entered_On,a.Event_Id,a.Final_Dimension_A,a.Final_Dimension_X,a.Final_Dimension_Y,a.Final_Dimension_Z,a.Initial_Dimension_A,a.Initial_Dimension_X,a.Initial_Dimension_Y,a.Initial_Dimension_Z,a.Location_Id,a.Order_Id,a.Order_Line_Id,a.Orientation_A,a.Orientation_X,a.Orientation_Y,a.Orientation_Z,a.PP_Id,a.PP_Setup_Detail_Id,a.PP_Setup_Id,a.Product_Definition_Id,a.PU_Id,a.Shipment_Id,a.Shipment_Item_Id,a.Signature_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Event_Details_History_Upd]
 ON  [dbo].[Event_Details]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 405
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Event_Detail_History
 	  	   (Alternate_Event_Num,Blocked_In_Location,Comment_Id,Entered_By,Entered_On,Event_Id,Final_Dimension_A,Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,Initial_Dimension_A,Initial_Dimension_X,Initial_Dimension_Y,Initial_Dimension_Z,Location_Id,Order_Id,Order_Line_Id,Orientation_A,Orientation_X,Orientation_Y,Orientation_Z,PP_Id,PP_Setup_Detail_Id,PP_Setup_Id,Product_Definition_Id,PU_Id,Shipment_Id,Shipment_Item_Id,Signature_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alternate_Event_Num,a.Blocked_In_Location,a.Comment_Id,a.Entered_By,a.Entered_On,a.Event_Id,a.Final_Dimension_A,a.Final_Dimension_X,a.Final_Dimension_Y,a.Final_Dimension_Z,a.Initial_Dimension_A,a.Initial_Dimension_X,a.Initial_Dimension_Y,a.Initial_Dimension_Z,a.Location_Id,a.Order_Id,a.Order_Line_Id,a.Orientation_A,a.Orientation_X,a.Orientation_Y,a.Orientation_Z,a.PP_Id,a.PP_Setup_Detail_Id,a.PP_Setup_Id,a.Product_Definition_Id,a.PU_Id,a.Shipment_Id,a.Shipment_Item_Id,a.Signature_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
 If (@Populate_History = 3)
   Begin 
 	  	   Insert Into Event_Detail_History
 	  	   (Alternate_Event_Num,Blocked_In_Location,Comment_Id,Entered_By,Entered_On,Event_Id,Final_Dimension_A,Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,Initial_Dimension_A,Initial_Dimension_X,Initial_Dimension_Y,Initial_Dimension_Z,Location_Id,Order_Id,Order_Line_Id,Orientation_A,Orientation_X,Orientation_Y,Orientation_Z,PP_Id,PP_Setup_Detail_Id,PP_Setup_Id,Product_Definition_Id,PU_Id,Shipment_Id,Shipment_Item_Id,Signature_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alternate_Event_Num,a.Blocked_In_Location,a.Comment_Id,a.Entered_By,a.Entered_On,a.Event_Id,a.Final_Dimension_A,a.Final_Dimension_X,a.Final_Dimension_Y,a.Final_Dimension_Z,a.Initial_Dimension_A,a.Initial_Dimension_X,a.Initial_Dimension_Y,a.Initial_Dimension_Z,a.Location_Id,a.Order_Id,a.Order_Line_Id,a.Orientation_A,a.Orientation_X,a.Orientation_Y,a.Orientation_Z,a.PP_Id,a.PP_Setup_Detail_Id,a.PP_Setup_Id,a.Product_Definition_Id,a.PU_Id,a.Shipment_Id,a.Shipment_Item_Id,a.Signature_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a 
  	  	 Join Events b on b.Event_Id = a.Event_Id
 	  	 Join Production_Status c on c.ProdStatus_Id = b.Event_Status
 	  	 WHERE  c.NoHistory = 0 or a.Entered_By = 1 or a.Entered_By > 50
End 

GO
CREATE TRIGGER dbo.Event_Details_Upd
  ON dbo.Event_Details
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id  	  	 int,
 	  	 @EventId 	 Int,
 	  	 @PUId 	  	 Int,
 	  	 @Time 	  	 DateTime,
 	  	 @SrcEventId 	 Int,
 	  	 @UserId 	  	 Int
 	  	 
SELECT @UserId = MIN(Entered_By) FROM Inserted
IF @UserId = 49
 	 RETURN
--See if there are any pu_ids used as inputs for genealogy events. Capture the result var id & its pu id too
Declare @AllPUs TABLE (PUId INT, ResultVarId INT, ResultVarIdPUId INT)
Insert into @AllPUs (PUId, ResultVarId, ResultVarIdPUId)
 	 select d.pu_id, d.Result_Var_Id, ISNULL(p.Master_Unit,p.PU_Id)
 	   from Calculation_Inputs i 
 	   Join calculation_input_data d on i.calc_input_id = d.calc_input_id and d.pu_id IS NOT NULL
    Join Variables v on v.Var_Id = d.Result_Var_Id
 	  	 Join Prod_Units p on p.PU_Id = v.PU_Id 
 	   Where i.Calc_Input_Entity_Id = 8 -- Genealogy Events
Insert into @AllPUs (PUId, ResultVarId, ResultVarIdPUId)
 	 select p1.pu_id, d.Result_Var_Id, ISNULL(p2.Master_Unit,p2.PU_Id)
 	   from Calculation_Inputs i 
 	   Join calculation_input_data d on i.calc_input_id = d.calc_input_id and d.pu_id IS NOT NULL
 	  	 Join Prod_Units p1 on p1.Equipment_Type = d.Alias_Name
    Join Variables v on v.Var_Id = d.Result_Var_Id
 	  	 Join Prod_Units p2 on p2.PU_Id = v.PU_Id 
 	   Where i.Calc_Input_Entity_Id = 9 -- Genealogy Event Aliases
--We're done if there aren't any Genealogy Event or Genealogy Event Alias inputs being used.
-- Just add a task for the current Event ID
If (Select Count(*) from @AllPUs) = 0 
  begin
 	  	 DECLARE Event_Details_Upd_Cursor3 CURSOR
 	  	   FOR SELECT ed.Event_Id, e.PU_Id, e.Timestamp FROM INSERTED ed JOIN Events e on ed.Event_Id = e.Event_Id
 	  	   FOR READ ONLY
 	  	  	  	 OPEN Event_Details_Upd_Cursor3
 	  	   Fetch_Next_Event3:
   	  	 Fetch Next From Event_Details_Upd_Cursor3 Into @EventId,@PUId,@Time
 	  	   IF @@FETCH_STATUS = 0
 	  	     BEGIN
 	  	  	  	  	 Execute spServer_CmnAddScheduledTask @EventId,14,@PUId,@Time
 	  	       GOTO Fetch_Next_Event3
 	  	     END
 	  	 Close Event_Details_Upd_Cursor3
 	  	 DEALLOCATE Event_Details_Upd_Cursor3
 	  	 GOTO EXITPROC
  end
--Whittle it down to just the distinct PUs that changed. 
Declare @PUs TABLE (PUId INT)
Insert Into @PUs (PUId)
 	 Select DISTINCT PUId from @AllPUs
 	 UNION 
 	 Select DISTINCT ResultVarIdPUId from @AllPUs
 	 UNION
 	 SELECT  DISTINCT e.PU_Id FROM INSERTED ed JOIN Events e on ed.Event_Id = e.Event_Id
create table #ResultEvents (EventId int, EventUnit int,  EndTime datetime)
DECLARE Event_Details_Upd_Cursor CURSOR
  FOR SELECT Event_Id FROM INSERTED
  FOR READ ONLY
OPEN Event_Details_Upd_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Details_Upd_Cursor INTO @@Id
  IF @@FETCH_STATUS = 0
    BEGIN
 	   Insert INto #ResultEvents
 	     	   Execute spServer_CalcMgrGetAffectedGenEventIds @@Id,@@Id
      GOTO Fetch_Next_Event
    END
Close Event_Details_Upd_Cursor
DEALLOCATE Event_Details_Upd_Cursor
Declare Event_Details_Upd_Cursor2 CURSOR
  FOR SELECT Distinct EventId,EventUnit,EndTime 
 	  	  	  	 FROM #ResultEvents
 	  	  	  	 JOIN @PUs on PUId = EventUnit
  FOR READ ONLY
 	  	 Open Event_Details_Upd_Cursor2
Loop1:
  Fetch Next From Event_Details_Upd_Cursor2 Into @EventId,@PUId,@Time
  IF @@FETCH_STATUS = 0
 	 BEGIN
 	  	  	 -- This is actually sticking extra pending tasks in for task id 30 but there 
 	  	  	 -- shouldn't be that many so we just left it alone. If this becomes a performance
 	  	  	 -- issue, just insert a row into pendingtasks for taskid 30 for only the current event.
 	  	  	 -- No other events in the tree should care about it. 
    	   Execute spServer_CmnAddScheduledTask @EventId,14,@PUId,@Time
 	   Goto Loop1
 	 End
Close Event_Details_Upd_Cursor2
Deallocate Event_Details_Upd_Cursor2
Drop Table #ResultEvents
EXITPROC: 

GO
CREATE TRIGGER dbo.Event_Details_Del 
  ON dbo.Event_Details 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id  	  	 int,
 	  	 @EventId 	 Int,
 	  	 @PUId 	  	 Int,
 	  	 @Time 	  	 DateTime,
 	  	 @SrcEventId 	 Int, 
    @CommentId int
--See if there are any pu_ids used as inputs for genealogy events. Capture the result var id & its pu id too
Declare @AllPUs TABLE (PUId INT, ResultVarId INT, ResultVarIdPUId INT)
Insert into @AllPUs (PUId, ResultVarId, ResultVarIdPUId)
 	 select d.pu_id, d.Result_Var_Id, ISNULL(p.Master_Unit,p.PU_Id)
 	   from Calculation_Inputs i 
 	   Join calculation_input_data d on i.calc_input_id = d.calc_input_id and d.pu_id IS NOT NULL
    Join Variables v on v.Var_Id = d.Result_Var_Id
 	  	 Join Prod_Units p on p.PU_Id = v.PU_Id 
 	   Where i.Calc_Input_Entity_Id = 8 -- Genealogy Events
Insert into @AllPUs (PUId, ResultVarId, ResultVarIdPUId)
 	 select p1.pu_id, d.Result_Var_Id, ISNULL(p2.Master_Unit,p2.PU_Id)
 	   from Calculation_Inputs i 
 	   Join calculation_input_data d on i.calc_input_id = d.calc_input_id and d.pu_id IS NOT NULL
 	  	 Join Prod_Units p1 on p1.Equipment_Type = d.Alias_Name
    Join Variables v on v.Var_Id = d.Result_Var_Id
 	  	 Join Prod_Units p2 on p2.PU_Id = v.PU_Id 
 	   Where i.Calc_Input_Entity_Id = 9 -- Genealogy Event Aliases
--We're done if there aren't any Genealogy Event or Genealogy Event Alias inputs being used.
-- Just add a task for the current Event ID
If (Select Count(*) from @AllPUs) = 0 
  begin
 	  	 DECLARE Event_Details_Del_Cursor3 CURSOR
 	  	   FOR SELECT ed.Event_Id, e.PU_Id, e.Timestamp FROM INSERTED ed JOIN Events e on ed.Event_Id = e.Event_Id
 	  	   FOR READ ONLY
 	  	  	  	 OPEN Event_Details_Del_Cursor3
 	  	   Fetch_Next_Event3:
   	  	 Fetch Next From Event_Details_Del_Cursor3 Into @EventId,@PUId,@Time
 	  	   IF @@FETCH_STATUS = 0
 	  	     BEGIN
 	  	  	  	  	 Execute spServer_CmnAddScheduledTask @EventId,14,@PUId,@Time
 	  	       GOTO Fetch_Next_Event3
 	  	     END
 	  	 Close Event_Details_Del_Cursor3
 	  	 DEALLOCATE Event_Details_Del_Cursor3
 	  	 GOTO EXITPROC
  end
--Whittle it down to just the distinct PUs that changed. 
Declare @PUs TABLE (PUId INT)
Insert Into @PUs (PUId)
 	 Select DISTINCT PUId from @AllPUs
 	 UNION 
 	 Select DISTINCT ResultVarIdPUId from @AllPUs
 	 UNION
 	 SELECT  DISTINCT e.PU_Id FROM INSERTED ed JOIN Events e on ed.Event_Id = e.Event_Id
create table #ResultEvents (EventId int, EventUnit int,  EndTime datetime)
DECLARE Event_Details_Del_Cursor CURSOR
  FOR SELECT Event_Id, Comment_Id FROM DELETED
  FOR READ ONLY
OPEN Event_Details_Del_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Details_Del_Cursor INTO @@Id, @CommentId
  IF @@FETCH_STATUS = 0
    BEGIN
 	  	 If @CommentId is NOT NULL 
 	  	   BEGIN
 	  	     Delete From Comments Where TopOfChain_Id = @CommentId 
 	  	     Delete From Comments Where Comment_Id = @CommentId   
 	  	   END
 	   Insert INto #ResultEvents
 	     	   Execute spServer_CalcMgrGetAffectedGenEventIds @@Id,@@Id
      GOTO Fetch_Next_Event
    END
Close Event_Details_Del_Cursor
DEALLOCATE Event_Details_Del_Cursor
Declare Event_Details_Del_Cursor2 CURSOR
  FOR SELECT Distinct EventId,EventUnit,EndTime 
 	  	  	  	 FROM #ResultEvents
 	  	  	  	 JOIN @PUs on PUId = EventUnit
  FOR READ ONLY
 	  	 Open Event_Details_Del_Cursor2
Loop1:
  Fetch Next From Event_Details_Del_Cursor2 Into @EventId,@PUId,@Time
  IF @@FETCH_STATUS = 0
 	 BEGIN
 	  	  	 -- This is actually sticking extra pending tasks in for task id 30 but there 
 	  	  	 -- shouldn't be that many so we just left it alone. If this becomes a performance
 	  	  	 -- issue, just insert a row into pendingtasks for taskid 30 for only the current event.
 	  	  	 -- No other events in the tree should care about it. 
    	   Execute spServer_CmnAddScheduledTask @EventId,14,@PUId,@Time
 	   Goto Loop1
 	 End
Close Event_Details_Del_Cursor2
Deallocate Event_Details_Del_Cursor2
Drop Table #ResultEvents
EXITPROC: 

GO
CREATE TRIGGER [dbo].[Event_Details_History_Ins]
 ON  [dbo].[Event_Details]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 405
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Event_Detail_History
 	  	   (Alternate_Event_Num,Blocked_In_Location,Comment_Id,Entered_By,Entered_On,Event_Id,Final_Dimension_A,Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,Initial_Dimension_A,Initial_Dimension_X,Initial_Dimension_Y,Initial_Dimension_Z,Location_Id,Order_Id,Order_Line_Id,Orientation_A,Orientation_X,Orientation_Y,Orientation_Z,PP_Id,PP_Setup_Detail_Id,PP_Setup_Id,Product_Definition_Id,PU_Id,Shipment_Id,Shipment_Item_Id,Signature_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alternate_Event_Num,a.Blocked_In_Location,a.Comment_Id,a.Entered_By,a.Entered_On,a.Event_Id,a.Final_Dimension_A,a.Final_Dimension_X,a.Final_Dimension_Y,a.Final_Dimension_Z,a.Initial_Dimension_A,a.Initial_Dimension_X,a.Initial_Dimension_Y,a.Initial_Dimension_Z,a.Location_Id,a.Order_Id,a.Order_Line_Id,a.Orientation_A,a.Orientation_X,a.Orientation_Y,a.Orientation_Z,a.PP_Id,a.PP_Setup_Detail_Id,a.PP_Setup_Id,a.Product_Definition_Id,a.PU_Id,a.Shipment_Id,a.Shipment_Item_Id,a.Signature_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
