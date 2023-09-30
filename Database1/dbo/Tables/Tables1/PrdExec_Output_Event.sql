CREATE TABLE [dbo].[PrdExec_Output_Event] (
    [Output_Event_Id] INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]      INT      NULL,
    [Entry_On]        DATETIME NOT NULL,
    [Event_Id]        INT      NULL,
    [Timestamp]       DATETIME NOT NULL,
    [Unloaded]        TINYINT  CONSTRAINT [PrdExecOutputEvent_DF_Unloaded] DEFAULT ((0)) NOT NULL,
    [User_Id]         INT      NOT NULL,
    CONSTRAINT [PrdExec_Output_Event_PK_OutputEventId] PRIMARY KEY CLUSTERED ([Output_Event_Id] ASC),
    CONSTRAINT [PrdExec_Output_Event_FK_EventId] FOREIGN KEY ([Event_Id]) REFERENCES [dbo].[Events] ([Event_Id])
);


GO
ALTER TABLE [dbo].[PrdExec_Output_Event] NOCHECK CONSTRAINT [PrdExec_Output_Event_FK_EventId];


GO
CREATE NONCLUSTERED INDEX [PrdExecOutputEvent_IDX_EventId]
    ON [dbo].[PrdExec_Output_Event]([Event_Id] ASC);


GO
CREATE TRIGGER dbo.PrdExec_Output_Event_Upd
  ON dbo.PrdExec_Output_Event
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int,
  @@Populate_History bit
Select @@Populate_History = Value From Site_Parameters Where Parm_Id = 418
If @@Populate_History = 1
  Begin
    Declare @Timestamp_Updated bit,@Event_Id_Updated bit, @Unloaded_Updated bit
    Declare @Compare_Timestamp datetime,  @Compare_Event_Id int, @Compare_Unloaded tinyint
    Declare @Timestamp datetime, @Event_Id int, @Unloaded tinyint
  End
DECLARE Event_Cursor CURSOR
  FOR SELECT Output_Event_Id FROM INSERTED
  FOR READ ONLY
OPEN Event_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Cursor INTO @@Id
  IF @@FETCH_STATUS = 0
    BEGIN
      If @@Populate_History = 1
        Begin
          Select @Compare_Timestamp = Timestamp,
            @Compare_Event_Id = Event_Id, 
            @Compare_Unloaded = Unloaded
           From DELETED
           Where Output_Event_Id = @@Id
          Select @Timestamp = Timestamp, 
            @Event_Id = Event_Id, 
            @Unloaded = Unloaded
           From INSERTED
           Where Output_Event_Id = @@Id
          Select @Timestamp_Updated = 0, @Event_Id_Updated = 0, @Unloaded_Updated = 0
          If (@Compare_Timestamp<>@Timestamp)
            Select @Timestamp_Updated = 1
          If (@Compare_Event_Id<>@Event_Id or (@Compare_Event_Id is NULL and @Event_Id is NOT NULL) or (@Compare_Event_Id is NOT NULL and @Event_Id is NULL))
            Select @Event_Id_Updated = 1
          If (@Compare_Unloaded<>@Unloaded)
            Select @Unloaded_Updated = 1
          If (Select Convert(int, @Timestamp_Updated) + Convert(int, @Event_Id_Updated) + Convert(int, @Unloaded_Updated)) > 0
            Begin
              -- Update History
              Insert Into PrdExec_Output_Event_History 
                (Output_Event_Id, Timestamp, Entry_On, User_Id,Comment_Id,Event_Id,Unloaded, DBTT_Id, Timestamp_Updated,Event_Id_Updated,Unloaded_Updated, History_EntryOn)
                Select Output_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, Event_Id, Unloaded, 3, 
                       @Timestamp_Updated, @Event_Id_Updated, @Unloaded_Updated, dbo.fnServer_CmnGetDate(getutcdate())
                 From INSERTED
                 Where Output_Event_Id = @@Id
            End
        End
      GOTO Fetch_Next_Event
    END
  DEALLOCATE Event_Cursor

GO
Create  TRIGGER dbo.PrdExec_Output_Event_InsUpd_Trans
 	 ON dbo.PrdExec_Output_Event
 	 FOR INSERT, UPDATE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE 	  	 @This_EventId 	  	  	  	 Int,
 	  	  	 @This_Time 	  	  	  	  	 DateTime,
 	  	  	 @Delete_Event_Id 	 Int,
 	  	  	 @Deleted_Time 	  	 DateTime
DECLARE 	 Output_Event_Cursor CURSOR
 	 FOR 	 SELECT 	 Event_Id,TimeStamp
 	  	  	  	 FROM 	 INSERTED
 	 FOR READ ONLY
OPEN Output_Event_Cursor
Fetch_Next_Output_Event:
 	 SELECT 	 @This_EventId = Null, @This_Time = Null
 	 FETCH NEXT FROM Output_Event_Cursor INTO @This_EventId,@This_Time
 	 IF @@FETCH_STATUS = 0
 	 BEGIN
 	   SELECT 	 @Delete_Event_Id = Null,@Deleted_Time = Null
 	   SELECT 	 @Delete_Event_Id = Event_Id,@Deleted_Time = Timestamp
 	  	 FROM 	 DELETED
 	  	 WHERE 	 Event_Id = @This_EventId
 	   IF (@Delete_Event_Id IS Null) and (@This_EventId is not Null)-- New Record
 	     Begin
 	  	   Insert Into PrdExec_Output_Event_Transitions (Event_Id,Start_Time,End_Time)
 	  	  	 Values (@This_EventId,@This_Time,Null)
 	     End
 	   Else If (@Delete_Event_Id is not Null) and (@This_EventId is  Null)
 	     BEGIN
 	  	   Update PrdExec_Output_Event_Transitions Set End_Time = @This_Time 
 	  	  	 Where  (Event_Id = @Delete_Event_Id) and (End_Time is Null)
 	     END
 	   Else If (@Delete_Event_Id  = @This_EventId)
 	    Begin
 	  	   Update PrdExec_Output_Event_Transitions Set Start_Time = @This_Time 
 	  	  	 Where  (Event_Id = @This_EventId) and (Start_Time = @Deleted_Time)
 	    End
 	   If @This_EventId is not null
 	     Execute spServer_CmnAddScheduledTask @This_EventId,16
 	   GOTO Fetch_Next_Output_Event
 	 END
 	 Close Output_Event_Cursor
 	 DEALLOCATE Output_Event_Cursor

GO
CREATE TRIGGER dbo.PrdExec_Output_Event_Del 
  ON dbo.PrdExec_Output_Event 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int,
  @@Populate_History bit,
 	 @Comment_Id int
Select @@Populate_History = Value From Site_Parameters Where Parm_Id = 418
--
--
  DECLARE Event_Cursor CURSOR
    FOR SELECT Output_Event_Id, Comment_Id FROM DELETED
    FOR READ ONLY
  OPEN Event_Cursor
--
--
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Cursor INTO @@Id, @Comment_Id 
  IF @@FETCH_STATUS = 0
    BEGIN
      If @Comment_Id is NOT NULL 
        BEGIN
          Delete From Comments Where TopOfChain_Id = @Comment_Id 
          Delete From Comments Where Comment_Id = @Comment_Id   
        END
      If @@Populate_History = 1
        Begin
          -- Delete History
          Insert Into PrdExec_Output_Event_History 
            (Output_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, Event_Id, Unloaded, DBTT_Id,
       	  	  	  Timestamp_Updated, Event_Id_Updated, Unloaded_Updated, History_EntryOn)
            Select Output_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, Event_Id, Unloaded, 4, 
                   0, 0, 0, dbo.fnServer_CmnGetDate(getutcdate())
             From DELETED
             Where Output_Event_Id = @@Id
        End
      Execute spServer_CmnRemoveScheduledTask @@Id,5
      GOTO Fetch_Next_Event
    END
  DEALLOCATE Event_Cursor

GO
CREATE TRIGGER dbo.PrdExec_Output_Event_Ins
  ON dbo.PrdExec_Output_Event
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int,
  @@Populate_History bit
Select @@Populate_History = Value From Site_Parameters Where Parm_Id = 418
DECLARE Event_Cursor CURSOR
  FOR SELECT Output_Event_Id FROM INSERTED
  FOR READ ONLY
OPEN Event_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Cursor INTO @@Id
  IF @@FETCH_STATUS = 0
    BEGIN
      If @@Populate_History = 1
        Begin
          -- Insert History
          Insert Into PrdExec_Output_Event_History 
            (Output_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, Event_Id,Unloaded, DBTT_Id, 
            Timestamp_Updated, Event_Id_Updated, Unloaded_Updated, History_EntryOn)
            Select Output_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, Event_Id, Unloaded, 2, 
                   1, 1, 1, dbo.fnServer_CmnGetDate(getutcdate())
             From INSERTED
             Where Output_Event_Id = @@Id
        End
      Execute spServer_CmnAddScheduledTask @@Id,5
      GOTO Fetch_Next_Event
    END
DEALLOCATE Event_Cursor
