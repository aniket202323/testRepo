CREATE TABLE [dbo].[Container_Location] (
    [Comment_Id]          INT      NULL,
    [Container_Id]        INT      NOT NULL,
    [Container_Status_Id] INT      NOT NULL,
    [Entry_On]            DATETIME NOT NULL,
    [PU_Id]               INT      NOT NULL,
    [Timestamp]           DATETIME NOT NULL,
    [User_Id]             INT      NOT NULL,
    [ContLoc_Id]          INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Location_id]         INT      NULL,
    CONSTRAINT [ContLoc_PK_ContLoc_Id] PRIMARY KEY NONCLUSTERED ([ContLoc_Id] ASC),
    CONSTRAINT [ConstLoc_FK_LocId] FOREIGN KEY ([Location_id]) REFERENCES [dbo].[Unit_Locations] ([Location_Id]),
    CONSTRAINT [ContLoc_FK_ContainerId] FOREIGN KEY ([Container_Id]) REFERENCES [dbo].[Containers] ([Container_Id]),
    CONSTRAINT [ContLoc_FK_ContStatusId] FOREIGN KEY ([Container_Status_Id]) REFERENCES [dbo].[Container_Statuses] ([Container_Status_Id]),
    CONSTRAINT [ContLoc_UC_ContIdPUId] UNIQUE CLUSTERED ([Container_Id] ASC, [PU_Id] ASC)
);


GO
CREATE TRIGGER dbo.ContainerLocation_InsUpd_StatTrans
 	 ON dbo.Container_Location
 	 FOR INSERT, UPDATE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE  	 @This_EntryOn  	    	    	    	    	  DATETIME,
 	  	  	  	  	 @This_Status  	    	    	    	    	  TINYINT,
 	  	  	  	  	 @This_Location  	    	    	    	    	  INT,
 	  	  	  	  	 @This_PUId  	    	    	    	    	  INT,
 	  	  	  	  	 @Deleted_EntryOn  	    	    	    	  DATETIME,
 	  	  	  	  	 @Deleted_Status  	    	    	    	  TINYINT,
 	  	  	  	  	 @CurrentId  	    	    	    	    	    	  INT,
  	    	    	  	  	 @CurrentStartTime 	  	  	 DateTime,
 	  	  	  	  	 @TestId 	  	  	  	  	  	 INT,
 	  	  	  	  	 @ThisStartTime 	  	  	  	 DATETIME
DECLARE  	  CL_InsUpd_StatTrans_Cursor CURSOR
  	  FOR  	  SELECT  	  ContLoc_Id,Container_Status_Id,Entry_On,Timestamp,PU_Id
  	    	    	    	  FROM  	  INSERTED
  	  FOR READ ONLY
OPEN CL_InsUpd_StatTrans_Cursor
Fetch_Next_Event:
  	  SELECT  	  @This_Location = NULL, @This_Status = NULL, @This_EntryOn = NULL,@ThisStartTime =Null,@This_PUId = NULL
  	  FETCH NEXT FROM CL_InsUpd_StatTrans_Cursor INTO @This_Location,@This_Status,@This_EntryOn,@ThisStartTime,@This_PUId
  	  IF @@FETCH_STATUS = 0
  	  BEGIN
  	    	  SELECT  	  @Deleted_EntryOn = NULL, 
  	    	    	    	    	  @Deleted_Status =  NULL
  	    	  SELECT  	  @Deleted_EntryOn = Entry_On,
  	    	    	    	    	  @Deleted_Status = Container_Status_Id
  	    	    	  FROM  	  DELETED
  	    	    	  WHERE  	  (ContLoc_Id = @This_Location)
  	    	  IF (@This_Status <> @Deleted_Status) OR (@Deleted_Status IS NULL)
  	    	  BEGIN
  	    	    	  SELECT  	  @CurrentId = NULL
  	    	    	  SELECT  	  @CurrentId = CLST_Id,@CurrentStartTime = Start_Time 
  	    	    	    	  FROM  	  Container_Location_Status_Transitions
  	    	    	    	  WHERE  	  ContLoc_Id = @This_Location AND
  	    	    	    	    	    	  End_Time IS NULL
  	    	    	  SELECT  	  @TestId = NULL
  	    	    	  SELECT  	  @TestId = CLST_Id 
  	    	    	    	  FROM  	  Container_Location_Status_Transitions 
  	    	    	    	  WHERE  	  ContLoc_Id = @This_Location AND 
  	    	    	    	    	    	  Start_Time = @This_EntryOn
  	    	    	  IF (@TestId IS NOT NULL) AND (@Deleted_Status IS NOT NULL)
  	    	    	  BEGIN
   	    	  	  	  SET @This_EntryOn = dbo.fnServer_CmnGetDate(getUTCdate())
  	    	    	  END
  	    	    	  IF @CurrentId IS NOT NULL
  	    	    	  BEGIN
 	  	  	  	 IF @CurrentStartTime > @This_EntryOn  SET @This_EntryOn = @CurrentStartTime
  	    	    	    	  UPDATE  	  Event_Status_Transitions
  	    	    	    	    	  SET  	  End_Time = @This_EntryOn
  	    	    	    	    	  WHERE  	  EST_Id = @CurrentId
   	    	  	  	 SET @ThisStartTime = @This_EntryOn
  	    	    	  END
  	    	    	  ELSE
  	    	    	  BEGIN
  	    	    	  	 -- use starttime if first record
   	    	  	  	 SET @ThisStartTime = Coalesce(@ThisStartTime,@This_EntryOn,dbo.fnServer_CmnGetDate(getUTCdate()))
  	    	    	  END
  	    	    	  INSERT INTO Container_Location_Status_Transitions (ContLoc_Id,Container_Status_Id, Start_Time, PU_Id)
  	    	    	    	  VALUES (@This_Location, @This_Status, @ThisStartTime, @This_PUId)
  	    	  END
  	    	  GOTO Fetch_Next_Event
  	  END
  	  ELSE IF @@FETCH_STATUS <> -1
  	  BEGIN
      RAISERROR('Fetch error in ContainerLocation_InsUpd_StatTrans (@@FETCH_STATUS = %d).', 11,-1, @@FETCH_STATUS)
  	  END
  	  DEALLOCATE CL_InsUpd_StatTrans_Cursor

GO
CREATE TRIGGER [dbo].[Container_Location_History_Upd]
 ON  [dbo].[Container_Location]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 411
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Container_Location_History
 	  	   (Comment_Id,Container_Id,Container_Status_Id,ContLoc_Id,Entry_On,Location_id,PU_Id,Timestamp,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Container_Id,a.Container_Status_Id,a.ContLoc_Id,a.Entry_On,a.Location_id,a.PU_Id,a.Timestamp,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Container_Location_Del
  ON dbo.Container_Location
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Container_Location_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Container_Location_Del_Cursor 
--
--
Fetch_Next_Container_Location:
FETCH NEXT FROM Container_Location_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Next_Container_Location
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Container_Location_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Container_Location_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Container_Location_History_Ins]
 ON  [dbo].[Container_Location]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 411
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Container_Location_History
 	  	   (Comment_Id,Container_Id,Container_Status_Id,ContLoc_Id,Entry_On,Location_id,PU_Id,Timestamp,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Container_Id,a.Container_Status_Id,a.ContLoc_Id,a.Entry_On,a.Location_id,a.PU_Id,a.Timestamp,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Container_Location_History_Del]
 ON  [dbo].[Container_Location]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 411
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Container_Location_History
 	  	   (Comment_Id,Container_Id,Container_Status_Id,ContLoc_Id,Entry_On,Location_id,PU_Id,Timestamp,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Container_Id,a.Container_Status_Id,a.ContLoc_Id,a.Entry_On,a.Location_id,a.PU_Id,a.Timestamp,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
