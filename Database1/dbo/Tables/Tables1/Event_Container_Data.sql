CREATE TABLE [dbo].[Event_Container_Data] (
    [Container_Id]      INT        NOT NULL,
    [Dimension_X]       REAL       NULL,
    [Dimension_Y]       REAL       NULL,
    [Dimension_Z]       REAL       NULL,
    [Event_Id]          INT        NOT NULL,
    [ECD_Id]            INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dimension_A]       FLOAT (53) NULL,
    [Entry_On]          DATETIME   NULL,
    [Final_Dimension_A] FLOAT (53) NULL,
    [Final_Dimension_X] FLOAT (53) NULL,
    [Final_Dimension_Y] FLOAT (53) NULL,
    [Final_Dimension_Z] FLOAT (53) NULL,
    [Orientation_A]     FLOAT (53) NULL,
    [Orientation_X]     FLOAT (53) NULL,
    [Orientation_Y]     FLOAT (53) NULL,
    [Orientation_Z]     FLOAT (53) NULL,
    [Timestamp]         DATETIME   NOT NULL,
    [User_Id]           INT        NULL,
    CONSTRAINT [EventContData_PK_ECD_Id] PRIMARY KEY NONCLUSTERED ([ECD_Id] ASC),
    CONSTRAINT [EventContData_FK_ContainerId] FOREIGN KEY ([Container_Id]) REFERENCES [dbo].[Containers] ([Container_Id]),
    CONSTRAINT [EvtCont_UC_EventIdContId] UNIQUE CLUSTERED ([Container_Id] ASC, [Event_Id] ASC)
);


GO
CREATE TRIGGER [dbo].[Event_Container_Data_History_Ins]
 ON  [dbo].[Event_Container_Data]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 457
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Event_Container_Data_History
 	  	   (Container_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,ECD_Id,Entry_On,Event_Id,Final_Dimension_A,Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,Orientation_A,Orientation_X,Orientation_Y,Orientation_Z,Timestamp,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Container_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.ECD_Id,a.Entry_On,a.Event_Id,a.Final_Dimension_A,a.Final_Dimension_X,a.Final_Dimension_Y,a.Final_Dimension_Z,a.Orientation_A,a.Orientation_X,a.Orientation_Y,a.Orientation_Z,a.Timestamp,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Event_Container_Data_History_Del]
 ON  [dbo].[Event_Container_Data]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 457
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Event_Container_Data_History
 	  	   (Container_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,ECD_Id,Entry_On,Event_Id,Final_Dimension_A,Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,Orientation_A,Orientation_X,Orientation_Y,Orientation_Z,Timestamp,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Container_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.ECD_Id,a.Entry_On,a.Event_Id,a.Final_Dimension_A,a.Final_Dimension_X,a.Final_Dimension_Y,a.Final_Dimension_Z,a.Orientation_A,a.Orientation_X,a.Orientation_Y,a.Orientation_Z,a.Timestamp,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Event_Container_Data_History_Upd]
 ON  [dbo].[Event_Container_Data]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 457
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Event_Container_Data_History
 	  	   (Container_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,ECD_Id,Entry_On,Event_Id,Final_Dimension_A,Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,Orientation_A,Orientation_X,Orientation_Y,Orientation_Z,Timestamp,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Container_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.ECD_Id,a.Entry_On,a.Event_Id,a.Final_Dimension_A,a.Final_Dimension_X,a.Final_Dimension_Y,a.Final_Dimension_Z,a.Orientation_A,a.Orientation_X,a.Orientation_Y,a.Orientation_Z,a.Timestamp,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.EventContainer_Del_EventTrans 
  ON dbo.Event_Container_Data 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE 	 @This_Time 	  	  	 DATETIME
 	  	  	 
Update Event_Container_Transitions 	 SET 	 End_Time = coalesce(End_Time,dbo.fnServer_CmnGetDate(getUTCdate()))
FROM Event_Container_Transitions a
Join  	 DELETED d  	   ON (a.Event_id = d.Event_Id and a.Container_Id = d.Container_Id)

GO
CREATE TRIGGER dbo.EventContainer_InsUpd_EventTrans
 	 ON dbo.Event_Container_Data
 	 FOR INSERT, UPDATE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE  	 @This_EntryOn 	  	  	 DATETIME,
 	  	  	  	  	 @This_Event 	  	  	  	 Int,
 	  	  	  	  	 @This_Container 	  	 Int,
 	  	  	  	  	 @Deleted_EntryOn 	 DATETIME,
 	  	  	  	  	 @Deleted_Event 	  	 Int,
 	  	  	  	  	 @Deleted_Container 	 Int,
 	  	  	  	  	 @CurrentId 	  	  	  	 Int,
 	  	  	  	  	 @TestId 	  	  	  	  	  	 Int,
 	  	  	  	  	 @ThisStartTime 	  	 DATETIME
DECLARE  	  EC_InsUpd_EventTrans_Cursor CURSOR
  	  FOR  	  SELECT  	  Container_Id,Event_Id,Entry_On,Timestamp
  	    	    	    	  FROM  	  INSERTED
  	  FOR READ ONLY
OPEN EC_InsUpd_EventTrans_Cursor
Fetch_Next_Event:
  	  SELECT  	  @This_Event = NULL, @This_Container = NULL, @This_EntryOn = NULL,@ThisStartTime =Null
  	  FETCH NEXT FROM EC_InsUpd_EventTrans_Cursor INTO @This_Container,@This_Event,@This_EntryOn,@ThisStartTime
  	  IF @@FETCH_STATUS = 0
  	  BEGIN
  	    	  SELECT  	  @Deleted_EntryOn = NULL,@Deleted_Event =  NULL
  	    	  SELECT  	  @Deleted_EntryOn = Entry_On,
  	    	    	    	    	  @Deleted_Event = Event_Id
  	    	    	  FROM  	  DELETED
  	    	    	  WHERE  	  (Container_Id = @This_Container)
  	    	  IF (@This_Event <> @Deleted_Event) OR (@Deleted_Event IS NULL)
  	    	  BEGIN
  	    	    	  SELECT  	  @CurrentId = NULL
  	    	    	  SELECT  	  @CurrentId = ECT_Id
  	    	    	    	  FROM  	  Event_Container_Transitions
  	    	    	    	  WHERE  	  Container_Id = @This_Container AND End_Time IS NULL
  	    	    	  SELECT  	  @TestId = NULL
  	    	    	  SELECT  	  @TestId = ECT_Id 
  	    	    	    	  FROM  	  Event_Container_Transitions 
  	    	    	    	  WHERE  	  Container_Id = @This_Container AND Start_Time = @This_EntryOn
  	    	    	  IF (@TestId IS NOT NULL) AND (@Deleted_Event IS NOT NULL)
  	    	    	  BEGIN
   	    	  	  	  SET @This_EntryOn = isnull(@This_EntryOn,dbo.fnServer_CmnGetDate(getUTCdate()))
  	    	    	  END
  	    	    	  IF @CurrentId IS NOT NULL
  	    	    	  BEGIN
  	    	    	    	  UPDATE  	  Event_Container_Transitions
  	    	    	    	    	  SET  	  End_Time = @This_EntryOn
  	    	    	    	    	  WHERE  	  ECT_Id = @CurrentId
  	    	    	  END
   	    	  	  SET @ThisStartTime = Coalesce(@ThisStartTime,@This_EntryOn,dbo.fnServer_CmnGetDate(getUTCdate()))
  	    	    	  INSERT INTO Event_Container_Transitions (Container_Id,Event_Id, Start_Time)
  	    	    	  	  	  	  	 VALUES (@This_Container, @This_Event, @ThisStartTime)
  	    	  END
  	    	  GOTO Fetch_Next_Event
  	  END
  	  ELSE IF @@FETCH_STATUS <> -1
  	  BEGIN
      RAISERROR('Fetch error in EventContainer_InsUpd_EventTrans (@@FETCH_STATUS = %d).', 11,-1, @@FETCH_STATUS)
  	  END
  	  DEALLOCATE EC_InsUpd_EventTrans_Cursor
