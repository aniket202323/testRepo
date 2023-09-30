CREATE TABLE [dbo].[PrdExec_Input_Event] (
    [Input_Event_Id]     INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]         INT      NULL,
    [Dimension_A]        REAL     NULL,
    [Dimension_X]        REAL     NULL,
    [Dimension_Y]        REAL     NULL,
    [Dimension_Z]        REAL     NULL,
    [Entry_On]           DATETIME NOT NULL,
    [Event_Id]           INT      NULL,
    [PEI_Id]             INT      NOT NULL,
    [PEIP_Id]            INT      NOT NULL,
    [Signature_Id]       INT      NULL,
    [Start_Coordinate_A] REAL     NULL,
    [Start_Coordinate_X] REAL     NULL,
    [Start_Coordinate_Y] REAL     NULL,
    [Start_Coordinate_Z] REAL     NULL,
    [Timestamp]          DATETIME NOT NULL,
    [Unloaded]           TINYINT  CONSTRAINT [PrdExecInputEvents_DF_Unloaded] DEFAULT ((0)) NOT NULL,
    [User_Id]            INT      NOT NULL,
    CONSTRAINT [PrdExec_Input_Event_PK_InputEventId] PRIMARY KEY CLUSTERED ([Input_Event_Id] ASC),
    CONSTRAINT [PrdExec_Input_Event_FK_EventId] FOREIGN KEY ([Event_Id]) REFERENCES [dbo].[Events] ([Event_Id]),
    CONSTRAINT [PrdExec_Input_Event_FK_PEIPId] FOREIGN KEY ([PEIP_Id]) REFERENCES [dbo].[PrdExec_Input_Positions] ([PEIP_Id]),
    CONSTRAINT [PrdExec_Input_Event_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [PrdExecInputs_FK_PEIId] FOREIGN KEY ([PEI_Id]) REFERENCES [dbo].[PrdExec_Inputs] ([PEI_Id])
);


GO
ALTER TABLE [dbo].[PrdExec_Input_Event] NOCHECK CONSTRAINT [PrdExec_Input_Event_FK_EventId];


GO
CREATE NONCLUSTERED INDEX [PrdExec_Input_Event_IX_PEIIdPEIPId]
    ON [dbo].[PrdExec_Input_Event]([PEI_Id] ASC, [PEIP_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [PrdExecInputEvent_IDX_EventId]
    ON [dbo].[PrdExec_Input_Event]([Event_Id] ASC);


GO
CREATE TRIGGER dbo.PrdExec_Input_Event_Upd
  ON dbo.PrdExec_Input_Event
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int,
  @@Populate_History bit
Select @@Populate_History = Value From Site_Parameters Where Parm_Id = 407
If @@Populate_History = 1
  Begin
    Declare
    @Timestamp_Updated bit, @PEI_Id_Updated bit, @PEIP_Id_Updated bit, @Event_Id_Updated bit, @Dimension_X_Updated bit,
    @Dimension_Y_Updated bit, @Dimension_Z_Updated bit, @Dimension_A_Updated bit, @Unloaded_Updated bit,
    @Start_Coordinate_X_Updated Bit,@Start_Coordinate_Y_Updated Bit,@Start_Coordinate_Z_Updated Bit ,@Start_Coordinate_A_Updated Bit
    Declare
    @Compare_Timestamp datetime, @Compare_PEI_Id int, @Compare_PEIP_Id int, @Compare_Event_Id int, @Compare_Dimension_X real, 
    @Compare_Dimension_Y real, @Compare_Dimension_Z real, @Compare_Dimension_A real, @Compare_Unloaded tinyint,
 	 @Compare_Start_Coordinate_X real,@Compare_Start_Coordinate_Y Real, @Compare_Start_Coordinate_Z real,
 	 @Compare_Start_Coordinate_A real    
    Declare
    @Timestamp datetime, @PEI_Id int, @PEIP_Id int, @Event_Id int, @Dimension_X real, @Dimension_Y real, @Dimension_Z real, 
    @Dimension_A real, @Unloaded tinyint,@Start_Coordinate_X real,@Start_Coordinate_Y Real, @Start_Coordinate_Z real,
 	 @Start_Coordinate_A real    
  End
DECLARE Event_Cursor CURSOR
  FOR SELECT Input_Event_Id FROM INSERTED
  FOR READ ONLY
OPEN Event_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Cursor INTO @@Id
  IF @@FETCH_STATUS = 0
    BEGIN
      If @@Populate_History = 1
        Begin
          Select @Compare_Timestamp = Timestamp, 
            @Compare_PEI_Id = PEI_Id, 
            @Compare_PEIP_Id = PEIP_Id, 
            @Compare_Event_Id = Event_Id, 
            @Compare_Dimension_X = Dimension_X, 
            @Compare_Dimension_Y = Dimension_Y, 
            @Compare_Dimension_Z = Dimension_Z, 
            @Compare_Dimension_A = Dimension_A, 
            @Compare_Start_Coordinate_X = Start_Coordinate_X, 
            @Compare_Start_Coordinate_Y = Start_Coordinate_Y, 
            @Compare_Start_Coordinate_Z = Start_Coordinate_Z, 
            @Compare_Start_Coordinate_A = Start_Coordinate_A, 
            @Compare_Unloaded = Unloaded
           From DELETED
           Where Input_Event_Id = @@Id
          Select @Timestamp = Timestamp, 
            @PEI_Id = PEI_Id, 
            @PEIP_Id = PEIP_Id, 
            @Event_Id = Event_Id, 
            @Dimension_X = Dimension_X, 
            @Dimension_Y = Dimension_Y, 
            @Dimension_Z = Dimension_Z, 
            @Dimension_A = Dimension_A, 
            @Start_Coordinate_X = Start_Coordinate_X, 
            @Start_Coordinate_Y = Start_Coordinate_Y, 
            @Start_Coordinate_Z = Start_Coordinate_Z, 
            @Start_Coordinate_A = Start_Coordinate_A, 
            @Unloaded = Unloaded
           From INSERTED
           Where Input_Event_Id = @@Id
          Select @Timestamp_Updated = 0, @PEI_Id_Updated = 0, @PEIP_Id_Updated = 0, @Event_Id_Updated = 0, @Dimension_X_Updated = 0,
            @Dimension_Y_Updated = 0, @Dimension_Z_Updated = 0, @Dimension_A_Updated = 0, @Unloaded_Updated = 0,@Start_Coordinate_X_Updated = 0,
 	  	  	 @Start_Coordinate_Y_Updated = 0,@Start_Coordinate_Z_Updated = 0,@Start_Coordinate_A_Updated = 0
          If (@Compare_Timestamp<>@Timestamp)
            Select @Timestamp_Updated = 1
          If (@Compare_PEI_Id<>@PEI_Id)
            Select @PEI_Id_Updated = 1
          If (@Compare_PEIP_Id<>@PEIP_Id)
            Select @PEIP_Id_Updated = 1
          If (@Compare_Event_Id<>@Event_Id or (@Compare_Event_Id is NULL and @Event_Id is NOT NULL) or (@Compare_Event_Id is NOT NULL and @Event_Id is NULL))
            Select @Event_Id_Updated = 1
          If (@Compare_Dimension_X<>@Dimension_X or (@Compare_Dimension_X is NULL and @Dimension_X is NOT NULL) or (@Compare_Dimension_X is NOT NULL and @Dimension_X is NULL))
            Select @Dimension_X_Updated = 1
          If (@Compare_Dimension_Y<>@Dimension_Y or (@Compare_Dimension_Y is NULL and @Dimension_Y is NOT NULL) or (@Compare_Dimension_Y is NOT NULL and @Dimension_Y is NULL))
            Select @Dimension_Y_Updated = 1
          If (@Compare_Dimension_Z<>@Dimension_Z or (@Compare_Dimension_Z is NULL and @Dimension_Z is NOT NULL) or (@Compare_Dimension_Z is NOT NULL and @Dimension_Z is NULL))
            Select @Dimension_Z_Updated = 1
          If (@Compare_Dimension_A<>@Dimension_A or (@Compare_Dimension_A is NULL and @Dimension_A is NOT NULL) or (@Compare_Dimension_A is NOT NULL and @Dimension_A is NULL))
            Select @Dimension_A_Updated = 1
          If (@Compare_Start_Coordinate_X<>@Start_Coordinate_X or (@Compare_Start_Coordinate_X is NULL and @Start_Coordinate_X is NOT NULL) or (@Compare_Start_Coordinate_X is NOT NULL and @Start_Coordinate_X is NULL))
            Select @Start_Coordinate_X_Updated = 1
          If (@Compare_Start_Coordinate_Y<>@Start_Coordinate_Y or (@Compare_Start_Coordinate_Y is NULL and @Start_Coordinate_Y is NOT NULL) or (@Compare_Start_Coordinate_Y is NOT NULL and @Start_Coordinate_Y is NULL))
            Select @Start_Coordinate_Y_Updated = 1
          If (@Compare_Start_Coordinate_Z<>@Start_Coordinate_Y or (@Compare_Start_Coordinate_Z is NULL and @Start_Coordinate_Z is NOT NULL) or (@Compare_Start_Coordinate_Z is NOT NULL and @Start_Coordinate_Z is NULL))
            Select @Start_Coordinate_Z_Updated = 1
          If (@Compare_Start_Coordinate_A<>@Start_Coordinate_Y or (@Compare_Start_Coordinate_A is NULL and @Start_Coordinate_A is NOT NULL) or (@Compare_Start_Coordinate_A is NOT NULL and @Start_Coordinate_A is NULL))
            Select @Start_Coordinate_A_Updated = 1
         If (@Compare_Unloaded<>@Unloaded)
            Select @Unloaded_Updated = 1
          If (Select Convert(int, @Timestamp_Updated) + Convert(int, @PEI_Id_Updated) + Convert(int, @PEIP_Id_Updated) + 
                     Convert(int, @Event_Id_Updated) + Convert(int, @Dimension_X_Updated) + Convert(int, @Dimension_Y_Updated) + 
                     Convert(int, @Dimension_Z_Updated) + Convert(int, @Dimension_A_Updated) + Convert(int, @Unloaded_Updated) + 
 	  	  	  	  	  Convert(int, @Start_Coordinate_X_Updated) + Convert(int, @Start_Coordinate_Y_Updated) + Convert(int, @Start_Coordinate_Z_Updated) + 
 	  	  	  	  	  Convert(int, @Start_Coordinate_A_Updated)) > 0
            Begin
              -- Update History
              Insert Into PrdExec_Input_Event_History 
                (Input_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, PEI_Id, PEIP_Id, Event_Id, Dimension_X, Dimension_Y,
                Dimension_Z, Dimension_A, Unloaded, Start_Coordinate_X, 	 Start_Coordinate_Y, Start_Coordinate_Z ,Start_Coordinate_A,
       	  	  	     DBTT_Id, Timestamp_Updated, PEI_Id_Updated, PEIP_Id_Updated, Event_Id_Updated,
                Dimension_X_Updated, Dimension_Y_Updated, Dimension_Z_Updated, Dimension_A_Updated, Unloaded_Updated,Start_Coordinate_X_Updated,
 	  	  	          	 Start_Coordinate_Y_Updated, Start_Coordinate_Z_Updated ,Start_Coordinate_A_Updated, History_EntryOn)
                Select Input_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, PEI_Id, PEIP_Id, Event_Id, Dimension_X, Dimension_Y,
                  Dimension_Z, Dimension_A, Unloaded, Start_Coordinate_X,Start_Coordinate_Y, Start_Coordinate_Z ,Start_Coordinate_A,
         	  	  	  	   3, @Timestamp_Updated, @PEI_Id_Updated, @PEIP_Id_Updated, @Event_Id_Updated,
                  @Dimension_X_Updated, @Dimension_Y_Updated, @Dimension_Z_Updated, @Dimension_A_Updated, @Unloaded_Updated,@Start_Coordinate_X_Updated,
 	  	  	  	           @Start_Coordinate_Y_Updated, @Start_Coordinate_Z_Updated ,@Start_Coordinate_A_Updated, dbo.fnServer_CmnGetDate(getutcdate())
                 From INSERTED
                 Where Input_Event_Id = @@Id
            End
        End
      Execute spServer_CmnAddScheduledTask @@Id,5
      GOTO Fetch_Next_Event
    END
  DEALLOCATE Event_Cursor

GO
CREATE TRIGGER dbo.PrdExec_Input_Event_Ins
  ON dbo.PrdExec_Input_Event
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int,
  @@Populate_History bit
Select @@Populate_History = Value From Site_Parameters Where Parm_Id = 407
DECLARE Event_Cursor CURSOR
  FOR SELECT Input_Event_Id FROM INSERTED
  FOR READ ONLY
OPEN Event_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Cursor INTO @@Id
  IF @@FETCH_STATUS = 0
    BEGIN
      If @@Populate_History = 1
        Begin
          -- Insert History
          Insert Into PrdExec_Input_Event_History 
            (Input_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, PEI_Id, PEIP_Id, Event_Id, Dimension_X, Dimension_Y,
            Dimension_Z, Dimension_A, Unloaded,Start_Coordinate_X, Start_Coordinate_Y, Start_Coordinate_Z,
       	  	  	 Start_Coordinate_A, DBTT_Id, Timestamp_Updated, PEI_Id_Updated, PEIP_Id_Updated, Event_Id_Updated,
            Dimension_X_Updated, Dimension_Y_Updated, Dimension_Z_Updated, Dimension_A_Updated, Unloaded_Updated,Start_Coordinate_X_Updated,
 	  	  	       Start_Coordinate_Y_Updated, Start_Coordinate_Z_Updated ,Start_Coordinate_A_Updated, History_EntryOn)
            Select Input_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, PEI_Id, PEIP_Id, Event_Id, Dimension_X, Dimension_Y,
              Dimension_Z, Dimension_A, Unloaded,Start_Coordinate_X, Start_Coordinate_Y, Start_Coordinate_Z,Start_Coordinate_A,
       	  	  	   2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, dbo.fnServer_CmnGetDate(getutcdate())
             From INSERTED
             Where Input_Event_Id = @@Id
        End
      Execute spServer_CmnAddScheduledTask @@Id,5
      GOTO Fetch_Next_Event
    END
DEALLOCATE Event_Cursor

GO
CREATE TRIGGER dbo.PrdExec_Input_Event_Del 
  ON dbo.PrdExec_Input_Event 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int,
  @@Populate_History bit,
 	 @Comment_Id int
Select @@Populate_History = Value From Site_Parameters Where Parm_Id = 407
--
--
  DECLARE Event_Cursor CURSOR
    FOR SELECT Input_Event_Id, Comment_Id FROM DELETED
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
          Insert Into PrdExec_Input_Event_History 
            (Input_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, PEI_Id, PEIP_Id, Event_Id, Dimension_X, Dimension_Y,
            Dimension_Z, Dimension_A, Unloaded,Start_Coordinate_X, Start_Coordinate_Y, Start_Coordinate_Z ,Start_Coordinate_A ,DBTT_Id,
       	  	  	 Timestamp_Updated, PEI_Id_Updated, PEIP_Id_Updated, Event_Id_Updated,Dimension_X_Updated, Dimension_Y_Updated, Dimension_Z_Updated,
 	  	  	       Dimension_A_Updated, Unloaded_Updated,Start_Coordinate_X_Updated, Start_Coordinate_Y_Updated, Start_Coordinate_Z_Updated ,Start_Coordinate_A_Updated, History_EntryOn)
            Select Input_Event_Id, Timestamp, Entry_On, User_Id, Comment_Id, PEI_Id, PEIP_Id, Event_Id, Dimension_X, Dimension_Y,
              Dimension_Z, Dimension_A, Unloaded,Start_Coordinate_X, Start_Coordinate_Y, Start_Coordinate_Z ,Start_Coordinate_A,
       	  	  	   4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, dbo.fnServer_CmnGetDate(getutcdate())
             From DELETED
             Where Input_Event_Id = @@Id
        End
      Execute spServer_CmnRemoveScheduledTask @@Id,5
      GOTO Fetch_Next_Event
    END
  DEALLOCATE Event_Cursor

GO
CREATE TRIGGER dbo.PrdExec_Input_Events_InsUpd_Trans
 	 ON dbo.PrdExec_Input_Event
 	 FOR INSERT, UPDATE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE 	  	 @This_Input 	  	  	  	  	 INT,
 	  	  	 @This_EventId 	  	  	  	 INT,
 	  	  	 @This_Position 	  	  	  	 Int,
 	  	  	 @This_Time 	  	  	  	  	 DateTime,
 	  	  	 @This_Id 	  	  	  	  	 Int,
 	  	  	 @Deleted_PEI_Id 	  	 Int,
 	  	  	 @Deleted_PEIP_Id 	 Int,
 	  	  	 @Delete_Event_Id 	 Int,
 	  	  	 @Deleted_Time 	  	 DateTime
DECLARE 	 Input_Event_Cursor CURSOR
 	 FOR 	 SELECT 	 Event_Id,PEI_Id,PEIP_ID,TimeStamp
 	  	  	  	 FROM 	 INSERTED
 	 FOR READ ONLY
OPEN Input_Event_Cursor
Fetch_Next_Input_Event:
 	 SELECT 	 @This_EventId = Null, @This_Position = Null, @This_Time = Null,@This_Input = Null,@This_Id = Null
 	 FETCH NEXT FROM Input_Event_Cursor INTO @This_EventId,@This_Input,@This_Position,@This_Time
 	 IF @@FETCH_STATUS = 0
 	 BEGIN
 	   SELECT 	 @Delete_Event_Id = Null,@Deleted_Time = Null
 	   SELECT 	 @Delete_Event_Id = Event_Id,@Deleted_Time = Timestamp
 	  	 FROM 	 DELETED
 	  	 WHERE 	 (PEI_Id = @This_Input and PEIP_ID = @This_Position)
 	   IF (@Delete_Event_Id IS Null) and (@This_EventId is not Null)-- New Record
 	     Begin
 	  	   Insert Into PrdExec_Input_Event_Transitions (PEI_Id,PEIP_Id,Event_Id,Start_Time,End_Time)
 	  	  	 Values (@This_Input,@This_Position,@This_EventId,@This_Time,Null)
 	     End
 	   Else If (@Delete_Event_Id is not Null) and (@This_EventId is  Null)
 	     BEGIN
 	  	   Update PrdExec_Input_Event_Transitions Set End_Time = @This_Time 
 	  	  	 Where  (PEI_Id = @This_Input) and (PEIP_ID = @This_Position) and (Start_Time = @Deleted_Time)
 	     END
 	   Else If (@Delete_Event_Id  = @This_EventId)
 	    Begin
 	  	   Update PrdExec_Input_Event_Transitions Set Start_Time = @This_Time 
 	  	  	 Where  (PEI_Id = @This_Input) and (PEIP_ID = @This_Position) and (Start_Time = @Deleted_Time)
 	    End
 	   If @This_EventId is not null
 	    	 Execute spServer_CmnAddScheduledTask @This_EventId,15
 	   GOTO Fetch_Next_Input_Event
 	 END
 	 Close Input_Event_Cursor
 	 DEALLOCATE Input_Event_Cursor
