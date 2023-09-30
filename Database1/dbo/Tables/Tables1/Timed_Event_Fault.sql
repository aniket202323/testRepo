CREATE TABLE [dbo].[Timed_Event_Fault] (
    [TEFault_Id]                INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Event_Reason_Tree_Data_Id] INT           NULL,
    [PU_Id]                     INT           NULL,
    [Reason_Level1]             INT           NULL,
    [Reason_Level2]             INT           NULL,
    [Reason_Level3]             INT           NULL,
    [Reason_Level4]             INT           NULL,
    [Source_PU_Id]              INT           NULL,
    [TEFault_Value]             VARCHAR (25)  NOT NULL,
    [TEFault_Name_Global]       VARCHAR (100) NULL,
    [TEFault_Name_Local]        VARCHAR (100) NOT NULL,
    [TEFault_Name]              AS            (case when (@@options&(512))=(0) then isnull([TEFault_Name_Global],[TEFault_Name_Local]) else [TEFault_Name_Local] end),
    CONSTRAINT [TEvent_Fault_PK_TEFaultId] PRIMARY KEY CLUSTERED ([TEFault_Id] ASC),
    CONSTRAINT [TEvent_Fault_FK_EventReasonTreeData] FOREIGN KEY ([Event_Reason_Tree_Data_Id]) REFERENCES [dbo].[Event_Reason_Tree_Data] ([Event_Reason_Tree_Data_Id]),
    CONSTRAINT [TEvent_Fault_FK_RsnLevel1] FOREIGN KEY ([Reason_Level1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [TEvent_Fault_FK_RsnLevel2] FOREIGN KEY ([Reason_Level2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [TEvent_Fault_FK_RsnLevel3] FOREIGN KEY ([Reason_Level3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [TEvent_Fault_FK_RsnLevel4] FOREIGN KEY ([Reason_Level4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id])
);


GO
CREATE NONCLUSTERED INDEX [TEvent_Fault_IDX_PUId]
    ON [dbo].[Timed_Event_Fault]([PU_Id] ASC);


GO
CREATE TRIGGER [dbo].[Timed_Event_Fault_History_Del]
 ON  [dbo].[Timed_Event_Fault]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 444
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Timed_Event_Fault_History
 	  	   (Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Source_PU_Id,TEFault_Id,TEFault_Name,TEFault_Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Source_PU_Id,a.TEFault_Id,a.TEFault_Name,a.TEFault_Value,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Timed_Event_Fault_History_Upd]
 ON  [dbo].[Timed_Event_Fault]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 444
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Timed_Event_Fault_History
 	  	   (Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Source_PU_Id,TEFault_Id,TEFault_Name,TEFault_Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Source_PU_Id,a.TEFault_Id,a.TEFault_Name,a.TEFault_Value,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Timed_Event_Fault_History_Ins]
 ON  [dbo].[Timed_Event_Fault]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 444
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Timed_Event_Fault_History
 	  	   (Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Source_PU_Id,TEFault_Id,TEFault_Name,TEFault_Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Source_PU_Id,a.TEFault_Id,a.TEFault_Name,a.TEFault_Value,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
