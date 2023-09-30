CREATE TABLE [dbo].[S95_Event] (
    [Event_Id]   INT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Char_Id]    INT              NULL,
    [Event_Type] INT              NOT NULL,
    [S95_Guid]   UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [SegmentResponseQuality_PK_EventId] PRIMARY KEY NONCLUSTERED ([Event_Id] ASC),
    CONSTRAINT [S95Event_FK_CharId] FOREIGN KEY ([Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [SegmentResponseQuality_UC_S95Guid] UNIQUE NONCLUSTERED ([S95_Guid] ASC)
);


GO
CREATE NONCLUSTERED INDEX [s95Events_IDX_CharId]
    ON [dbo].[S95_Event]([Char_Id] ASC);


GO
CREATE TRIGGER [dbo].[S95_Event_History_Del]
 ON  [dbo].[S95_Event]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 455
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into S95_Event_History
 	  	   (Char_Id,Event_Id,Event_Type,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Char_Id,a.Event_Id,a.Event_Type,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[S95_Event_History_Upd]
 ON  [dbo].[S95_Event]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 455
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into S95_Event_History
 	  	   (Char_Id,Event_Id,Event_Type,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Char_Id,a.Event_Id,a.Event_Type,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.S95_Event_Del 
  ON dbo.S95_Event 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @EventId Int,
 	  	 @EventType 	 Int
DECLARE S95_Event_Cursor_Del CURSOR
 	 FOR SELECT Event_Id,Event_Type FROM DELETED
 	 FOR READ ONLY
 	 OPEN S95_Event_Cursor_Del
Fetch_Next_S95_Event:
 	 FETCH NEXT FROM S95_Event_Cursor_Del INTO @EventId,@EventType
 	 IF @@FETCH_STATUS = 0
    BEGIN
 	  	 Execute spServer_CmnAddScheduledTask @EventId,55,Null,Null,Null,Null,Null,@EventType
 	  	 GOTO Fetch_Next_S95_Event
    END
 	 DEALLOCATE S95_Event_Cursor_Del

GO
CREATE TRIGGER [dbo].[S95_Event_History_Ins]
 ON  [dbo].[S95_Event]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 455
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into S95_Event_History
 	  	   (Char_Id,Event_Id,Event_Type,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Char_Id,a.Event_Id,a.Event_Type,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.S95_Event_Ins
  ON dbo.S95_Event
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @EventId int,
  @EventType 	 Int
DECLARE S95_Event_Ins_Cursor CURSOR
 	 FOR SELECT Event_Id,Event_Type FROM INSERTED
 	 FOR READ ONLY
OPEN S95_Event_Ins_Cursor
Fetch_Next_S95_Event:
FETCH NEXT FROM S95_Event_Ins_Cursor INTO @EventId,@EventType
IF @@FETCH_STATUS = 0
BEGIN
 	 Execute spServer_CmnAddScheduledTask @EventId,55,Null,Null,Null,Null,Null,@EventType
 	 GOTO Fetch_Next_S95_Event
END
DEALLOCATE S95_Event_Ins_Cursor
