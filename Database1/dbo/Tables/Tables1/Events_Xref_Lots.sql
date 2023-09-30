CREATE TABLE [dbo].[Events_Xref_Lots] (
    [XRefId]  BIGINT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [EventId] INT              NOT NULL,
    [LotId]   UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [EventsXrefLots_PK_XRefId] PRIMARY KEY NONCLUSTERED ([XRefId] ASC),
    CONSTRAINT [EventsXrefLots_FK_Events] FOREIGN KEY ([EventId]) REFERENCES [dbo].[Events] ([Event_Id]) ON DELETE CASCADE
);


GO
ALTER TABLE [dbo].[Events_Xref_Lots] NOCHECK CONSTRAINT [EventsXrefLots_FK_Events];


GO
CREATE NONCLUSTERED INDEX [EventsXrefLots_IDX_LotId]
    ON [dbo].[Events_Xref_Lots]([LotId] ASC);


GO
CREATE NONCLUSTERED INDEX [EventsXrefLots_IDX_EventId]
    ON [dbo].[Events_Xref_Lots]([EventId] ASC);


GO
CREATE TRIGGER [dbo].[Events_Xref_Lots_History_Upd]
 ON  [dbo].[Events_Xref_Lots]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 456
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Events_Xref_Lot_History
 	  	   (EventId,XRefId,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.EventId,a.XRefId,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Events_Xref_Lots_History_Ins]
 ON  [dbo].[Events_Xref_Lots]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 456
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Events_Xref_Lot_History
 	  	   (EventId,XRefId,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.EventId,a.XRefId,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Events_Xref_Lots_History_Del]
 ON  [dbo].[Events_Xref_Lots]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 456
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Events_Xref_Lot_History
 	  	   (EventId,XRefId,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.EventId,a.XRefId,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
