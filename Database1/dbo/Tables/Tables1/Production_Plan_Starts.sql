CREATE TABLE [dbo].[Production_Plan_Starts] (
    [PP_Start_Id]   INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]    INT      NULL,
    [End_Time]      DATETIME NULL,
    [Is_Production] BIT      CONSTRAINT [ProductionPlanStarts_DF_IsProduction] DEFAULT ((1)) NOT NULL,
    [PP_Id]         INT      NOT NULL,
    [pp_setup_id]   INT      NULL,
    [PU_Id]         INT      NOT NULL,
    [Start_Time]    DATETIME NOT NULL,
    [User_Id]       INT      NULL,
    CONSTRAINT [PP_Starts_PK_PPSId] PRIMARY KEY NONCLUSTERED ([PP_Start_Id] ASC),
    CONSTRAINT [PP_Starts_FK_Production_Plan] FOREIGN KEY ([PP_Id]) REFERENCES [dbo].[Production_Plan] ([PP_Id]),
    CONSTRAINT [PP_Starts_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [ProductionPlanStartsUser_FK_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE CLUSTERED INDEX [ProductionPlanStarts_IX_PUIdStartTime]
    ON [dbo].[Production_Plan_Starts]([PU_Id] ASC, [Start_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [ProductionPlanStarts_IDX_PPId]
    ON [dbo].[Production_Plan_Starts]([PP_Id] ASC);


GO
CREATE TRIGGER dbo.Production_Plan_Starts_Del
  ON dbo.Production_Plan_Starts
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@PPStartId int,
 	 @Comment_Id int
Declare Production_Plan_Starts_Del_Cursor INSENSITIVE CURSOR
  For (Select PP_Start_Id, Comment_Id From DELETED)
  For Read Only
  Open Production_Plan_Starts_Del_Cursor  
Fetch_Loop:
  Fetch Next From Production_Plan_Starts_Del_Cursor Into @@PPStartId, @Comment_Id 
  If (@@Fetch_Status = 0)
    Begin
      If @Comment_Id is NOT NULL 
        BEGIN
          Delete From Comments Where TopOfChain_Id = @Comment_Id 
          Delete From Comments Where Comment_Id = @Comment_Id   
        END
 	     Execute spServer_CmnRemoveScheduledTask @@PPStartId,12
      Goto Fetch_Loop
    End
Close Production_Plan_Starts_Del_Cursor
Deallocate Production_Plan_Starts_Del_Cursor

GO
CREATE TRIGGER [dbo].[Production_Plan_Starts_History_Upd]
 ON  [dbo].[Production_Plan_Starts]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 409
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Production_Plan_Starts_History
 	  	   (Comment_Id,End_Time,Is_Production,PP_Id,pp_setup_id,PP_Start_Id,PU_Id,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.End_Time,a.Is_Production,a.PP_Id,a.pp_setup_id,a.PP_Start_Id,a.PU_Id,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Production_Plan_Starts_History_Ins]
 ON  [dbo].[Production_Plan_Starts]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 409
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Production_Plan_Starts_History
 	  	   (Comment_Id,End_Time,Is_Production,PP_Id,pp_setup_id,PP_Start_Id,PU_Id,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.End_Time,a.Is_Production,a.PP_Id,a.pp_setup_id,a.PP_Start_Id,a.PU_Id,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Production_Plan_Starts_Upd
  ON dbo.Production_Plan_Starts
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @PPStartId int,
  @PUId int,
  @StartTime DateTime,
  @EndTime   DateTime,
  @PP_Id 	 Int,
  @Path_Id Int,
  @OldPPId Int,
  @OldPathId Int,
  @OldPUId Int,
  @ModifiedEnd 	 DateTime,
  @ModifiedStart DateTime,
  @Path_Code VarChar(100)
Declare Production_Plan_Starts_Upd_Cursor INSENSITIVE CURSOR
  For (Select PP_Start_Id,PU_Id,Start_Time,PP_Id,End_Time From INSERTED)
  For Read Only
  Open Production_Plan_Starts_Upd_Cursor  
Fetch_Loop:
  Fetch Next From Production_Plan_Starts_Upd_Cursor Into @PPStartId,@PUId,@StartTime,@PP_Id,@EndTime
  If (@@Fetch_Status = 0)
    Begin /* Sync execution Path Starts*/
 	   Select @Path_Id = Path_Id from Production_Plan Where PP_Id = @PP_Id
 	   Select @ModifiedStart = Start_Time,@ModifiedEnd = End_Time,@OldPPId = PP_Id,@OldPUId = PU_Id From Deleted Where PP_Start_Id = @PPStartId
 	   Select @OldPathId = Path_Id from Production_Plan Where PP_Id = @OldPPId
 	   If @OldPathId <> @Path_Id or @ModifiedEnd <> @EndTime or @ModifiedStart <> @StartTime
   	  	 Execute spServer_DBMgrUpdPrdExecPathStarts Null,@PUId,@Path_Id,@StartTime Output,0,8,@Path_Code Output, @EndTime OUTPUT,  @ModifiedStart  OUTPUT,  @ModifiedEnd  OUTPUT
      Execute spServer_CmnAddScheduledTask @PPStartId,12,@PUId,@StartTime
      Goto Fetch_Loop
    End
Close Production_Plan_Starts_Upd_Cursor
Deallocate Production_Plan_Starts_Upd_Cursor

GO
CREATE TRIGGER dbo.Production_Plan_Starts_Ins
  ON dbo.Production_Plan_Starts
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @PPStartId int,
  @PUId int,
  @StartTime DateTime,
  @PP_Id 	 Int,
  @Path_Id Int,
  @CurrentPath 	 Int,
  @Current_EndTime 	 DateTime,
  @Current_Id 	 Int,
  @Path_Code VarChar(100),
  @ModifiedEnd DateTime,
  @ModifiedStart DateTime
Declare Production_Plan_Starts_Ins_Cursor INSENSITIVE CURSOR
  For (Select PP_Start_Id,PU_Id,Start_Time,PP_Id,End_Time From INSERTED)
  For Read Only
  Open Production_Plan_Starts_Ins_Cursor  
Fetch_Loop:
  Fetch Next From Production_Plan_Starts_Ins_Cursor Into @PPStartId,@PUId,@StartTime,@PP_Id,@Current_EndTime
  If (@@Fetch_Status = 0)
    Begin
 	   Select @Path_Id = Path_Id from Production_Plan Where PP_Id = @PP_Id
 	   If @Path_Id is not null
 	  	   Execute spServer_DBMgrUpdPrdExecPathStarts Null,@PUId,@Path_Id,@StartTime Output,0,8,@Path_Code Output, @Current_EndTime OUTPUT,  @ModifiedStart  OUTPUT,  @ModifiedEnd  OUTPUT
  	   Execute spServer_CmnAddScheduledTask @PPStartId,12,@PUId,@StartTime
      Goto Fetch_Loop
    End
Close Production_Plan_Starts_Ins_Cursor
Deallocate Production_Plan_Starts_Ins_Cursor

GO
CREATE TRIGGER [dbo].[Production_Plan_Starts_History_Del]
 ON  [dbo].[Production_Plan_Starts]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 409
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Production_Plan_Starts_History
 	  	   (Comment_Id,End_Time,Is_Production,PP_Id,pp_setup_id,PP_Start_Id,PU_Id,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.End_Time,a.Is_Production,a.PP_Id,a.pp_setup_id,a.PP_Start_Id,a.PU_Id,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
