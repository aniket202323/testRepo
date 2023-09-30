CREATE TABLE [dbo].[Event_Components] (
    [Component_Id]          INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dimension_A]           FLOAT (53)    NULL,
    [Dimension_X]           FLOAT (53)    NULL,
    [Dimension_Y]           FLOAT (53)    NULL,
    [Dimension_Z]           FLOAT (53)    NULL,
    [Entry_On]              DATETIME      NULL,
    [Event_Id]              INT           NOT NULL,
    [Extended_Info]         VARCHAR (255) NULL,
    [Parent_Component_Id]   INT           NULL,
    [PEI_Id]                INT           NULL,
    [Report_As_Consumption] BIT           CONSTRAINT [EventComponent_DF_ReportAsConsumption] DEFAULT ((1)) NULL,
    [Signature_Id]          INT           NULL,
    [Source_Event_Id]       INT           NOT NULL,
    [Start_Coordinate_A]    FLOAT (53)    NULL,
    [Start_Coordinate_X]    FLOAT (53)    NULL,
    [Start_Coordinate_Y]    FLOAT (53)    NULL,
    [Start_Coordinate_Z]    FLOAT (53)    NULL,
    [Start_Time]            DATETIME      NULL,
    [Timestamp]             DATETIME      NULL,
    [user_id]               INT           NULL,
    CONSTRAINT [Event_Components_PK_CompId] PRIMARY KEY CLUSTERED ([Component_Id] ASC),
    CONSTRAINT [Event_Components_FK_EventId] FOREIGN KEY ([Event_Id]) REFERENCES [dbo].[Events] ([Event_Id]),
    CONSTRAINT [Event_Components_FK_SEventId] FOREIGN KEY ([Source_Event_Id]) REFERENCES [dbo].[Events] ([Event_Id]),
    CONSTRAINT [EventComponent_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [EventComponents_FK_ParentComponentId] FOREIGN KEY ([Parent_Component_Id]) REFERENCES [dbo].[Event_Components] ([Component_Id]),
    CONSTRAINT [EventComponents_UC_EventSourceTSPCompIdPEIId] UNIQUE NONCLUSTERED ([Event_Id] ASC, [Source_Event_Id] ASC, [Timestamp] ASC, [Parent_Component_Id] ASC, [PEI_Id] ASC)
);


GO
ALTER TABLE [dbo].[Event_Components] NOCHECK CONSTRAINT [Event_Components_FK_EventId];


GO
ALTER TABLE [dbo].[Event_Components] NOCHECK CONSTRAINT [Event_Components_FK_SEventId];


GO
CREATE NONCLUSTERED INDEX [Event_Components_IDX_Source]
    ON [dbo].[Event_Components]([Source_Event_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [EventComponents_IDX_ParentCompId]
    ON [dbo].[Event_Components]([Parent_Component_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [EventComponent_IDX_SignatureId]
    ON [dbo].[Event_Components]([Signature_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [EventComponents_IDX_PEIIdTimeStamp]
    ON [dbo].[Event_Components]([PEI_Id] ASC, [Timestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_Components_IDX_Event]
    ON [dbo].[Event_Components]([Event_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_Components_IX_EventId_SrcId_ExtInfo]
    ON [dbo].[Event_Components]([Event_Id] ASC, [Source_Event_Id] ASC, [Extended_Info] ASC);


GO
CREATE NONCLUSTERED INDEX [EventComponents_IDX_TimeStampEventId]
    ON [dbo].[Event_Components]([Timestamp] ASC, [Event_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EVENTCOMPONENTS_ENTRYON_REPORTASCONSUMPTION]
    ON [dbo].[Event_Components]([Component_Id] ASC, [Report_As_Consumption] ASC, [Dimension_X] ASC)
    INCLUDE([Event_Id], [Source_Event_Id], [Entry_On], [Timestamp], [user_id]);


GO
CREATE TRIGGER [dbo].[Event_Components_History_Upd]
 ON  [dbo].[Event_Components]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 404
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Event_Component_History
 	  	   (Component_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,Entry_On,Event_Id,Extended_Info,Parent_Component_Id,PEI_Id,Report_As_Consumption,Signature_Id,Source_Event_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,Start_Time,Timestamp,user_id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Component_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.Entry_On,a.Event_Id,a.Extended_Info,a.Parent_Component_Id,a.PEI_Id,a.Report_As_Consumption,a.Signature_Id,a.Source_Event_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.Start_Time,a.Timestamp,a.user_id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Event_Components_History_Ins]
 ON  [dbo].[Event_Components]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 404
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Event_Component_History
 	  	   (Component_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,Entry_On,Event_Id,Extended_Info,Parent_Component_Id,PEI_Id,Report_As_Consumption,Signature_Id,Source_Event_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,Start_Time,Timestamp,user_id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Component_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.Entry_On,a.Event_Id,a.Extended_Info,a.Parent_Component_Id,a.PEI_Id,a.Report_As_Consumption,a.Signature_Id,a.Source_Event_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.Start_Time,a.Timestamp,a.user_id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Event_Components_History_Del]
 ON  [dbo].[Event_Components]
  FOR DELETE
  AS
 DECLARE @NEwUserID Int
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 SELECT @NEWUserId =  CONVERT(int, CONVERT(varbinary(4), CONTEXT_INFO()))
 IF NOT EXISTS(Select 1 FROM Users_base WHERE USER_Id = @NEWUserId)
      SET @NEWUserId = Null
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 404
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Event_Component_History
 	  	   (Component_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,Entry_On,Event_Id,Extended_Info,Parent_Component_Id,PEI_Id,Report_As_Consumption,Signature_Id,Source_Event_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,Start_Time,Timestamp,user_id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Component_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.Entry_On,a.Event_Id,a.Extended_Info,a.Parent_Component_Id,a.PEI_Id,a.Report_As_Consumption,a.Signature_Id,a.Source_Event_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.Start_Time,a.Timestamp,coalesce(@NEWUserId,a.User_Id),dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER dbo.Event_Components_Del 
  ON dbo.Event_Components 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id Int
DECLARE Event_Components_Cursor CURSOR
  FOR SELECT Component_Id FROM DELETED
  FOR READ ONLY
OPEN Event_Components_Cursor
  Fetch_Next_Event_Component:
  FETCH NEXT FROM Event_Components_Cursor INTO @@Id
  IF @@FETCH_STATUS = 0
    BEGIN
      Execute spServer_CmnRemoveScheduledTask @@Id,10
      GOTO Fetch_Next_Event_Component
    END
  DEALLOCATE Event_Components_Cursor

GO
CREATE TRIGGER dbo.Event_Components_Upd
  ON dbo.Event_Components
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int
Declare 
  @This_Time datetime,
  @This_StartTime datetime,
  @Deleted_Time datetime,
  @Deleted_StartTime datetime,
  @Time_Flag tinyint
DECLARE Event_Components_Upd_Cursor CURSOR
  FOR SELECT Component_Id,Start_Time, Timestamp FROM INSERTED
  FOR READ ONLY
OPEN Event_Components_Upd_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Components_Upd_Cursor INTO @@Id,@This_StartTime,@This_Time
  IF @@FETCH_STATUS = 0
    BEGIN
     Select @Deleted_StartTime = Start_Time,
             @Deleted_Time = TimeStamp
        From DELETED
        Where (Component_Id = @@Id)
      Select @Time_Flag = 0
      If (@Deleted_Time Is NULL) Or (@This_Time Is NULL)
        Begin
          If NOT((@Deleted_Time Is NULL) And (@This_Time Is NULL))
            Select @Time_Flag = 1
        End
      Else
       	 If (@Deleted_Time <> @This_Time)
          Select @Time_Flag = 1
 	   If @Time_Flag = 0 
        Begin
          If (@Deleted_StartTime Is NULL) Or (@This_StartTime Is NULL)
            Begin
              If NOT((@Deleted_StartTime Is NULL) And (@This_StartTime Is NULL))
                Select @Time_Flag = 1
            End
          Else
       	     If (@Deleted_StartTime <> @This_StartTime)
              Select @Time_Flag = 1
        End
      Execute spServer_CmnAddScheduledTask @@Id,10,Null,Null,Null,@Time_Flag
      GOTO Fetch_Next_Event
    END
  DEALLOCATE Event_Components_Upd_Cursor

GO
CREATE TRIGGER dbo.Event_Components_Ins
  ON dbo.Event_Components
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int
DECLARE Event_Components_Ins_Cursor CURSOR
  FOR SELECT Component_Id FROM INSERTED
  FOR READ ONLY
OPEN Event_Components_Ins_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Event_Components_Ins_Cursor INTO @@Id
  IF @@FETCH_STATUS = 0
    BEGIN
      Execute spServer_CmnAddScheduledTask @@Id,10
      GOTO Fetch_Next_Event
    END
DEALLOCATE Event_Components_Ins_Cursor
