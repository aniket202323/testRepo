CREATE TABLE [dbo].[Event_Configuration_Values] (
    [ECV_Id] INT  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Value]  TEXT NULL,
    CONSTRAINT [Event_Configuration_Values_PK] PRIMARY KEY NONCLUSTERED ([ECV_Id] ASC)
);


GO
CREATE TRIGGER [dbo].[Event_Configuration_Values_Ins]
 ON  [dbo].[Event_Configuration_Values]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 432
 Declare @xtype int
 Select @xtype = xtype from sys.syscolumns where object_Id('Event_Configuration_Values') = id And name = 'value'
 If (@Populate_History = 1 or @Populate_History = 3)  and ( Update(ECV_id) or Update(Value) ) 
   Begin
  	    	    Insert Into Event_Configuration_Value_History(DBTT_Id,ECV_Id,History_EntryOn,Value,Value_Updated)
 	  	    Select 2,a.ECV_Id,dbo.fnServer_CmnGetDate(getUTCdate()),Case when @xtype = 35 then cast(Ecv.Value as varchar(max)) else cast(Ecv.Value as nvarchar(max)) End,1
  	    	    From Inserted a join Event_Configuration_Values Ecv on Ecv.ECV_Id = a.ECV_Id
   End

GO
CREATE TRIGGER [dbo].[Event_Configuration_Values_Del]
 ON  [dbo].[Event_Configuration_Values]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 432
 If (@Populate_History = 1 or @Populate_History = 3)  
   Begin
  	    	    Insert Into Event_Configuration_Value_History(DBTT_Id,ECV_Id,History_EntryOn)--,Value,Value_Updated)
 	  	    Select 4,a.ECV_Id,dbo.fnServer_CmnGetDate(getUTCdate())--,NULL,null
  	    	    From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Event_Configuration_Values_Upd]
 ON  [dbo].[Event_Configuration_Values]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 432
 Declare @xtype int
 Select @xtype = xtype from sys.syscolumns where object_Id('Event_Configuration_Values') = id And name = 'value'
 If (@Populate_History = 1 or @Populate_History = 3)  and ( Update(ECV_id) or Update(Value) ) 
   Begin
  	    	    Insert Into Event_Configuration_Value_History(DBTT_Id,ECV_Id,History_EntryOn,Value,Value_Updated)
 	  	    Select 3,a.ECV_Id,dbo.fnServer_CmnGetDate(getUTCdate()),Case when @xtype = 35 then cast(Ecv.Value as varchar(max)) else cast(Ecv.Value as nvarchar(max)) End,1
  	    	    From Inserted a join Event_Configuration_Values Ecv on Ecv.ECV_Id = a.ECV_Id
   End
