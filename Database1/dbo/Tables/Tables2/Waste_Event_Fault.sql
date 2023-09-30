CREATE TABLE [dbo].[Waste_Event_Fault] (
    [WEFault_Id]                INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Event_Reason_Tree_Data_Id] INT           NULL,
    [PU_Id]                     INT           NULL,
    [Reason_Level1]             INT           NULL,
    [Reason_Level2]             INT           NULL,
    [Reason_Level3]             INT           NULL,
    [Reason_Level4]             INT           NULL,
    [Source_PU_Id]              INT           NULL,
    [WEFault_Value]             VARCHAR (25)  NOT NULL,
    [WEFault_Name_Global]       VARCHAR (100) NULL,
    [WEFault_Name_Local]        VARCHAR (100) NOT NULL,
    [WEFault_Name]              AS            (case when (@@options&(512))=(0) then isnull([WEFault_Name_Global],[WEFault_Name_Local]) else [WEFault_Name_Local] end),
    CONSTRAINT [WEvent_Fault_PK_WEFaultId] PRIMARY KEY CLUSTERED ([WEFault_Id] ASC),
    CONSTRAINT [WEvent_Fault_FK_EventReasonTreeData] FOREIGN KEY ([Event_Reason_Tree_Data_Id]) REFERENCES [dbo].[Event_Reason_Tree_Data] ([Event_Reason_Tree_Data_Id]),
    CONSTRAINT [WEvent_Fault_FK_RsnLevel1] FOREIGN KEY ([Reason_Level1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [WEvent_Fault_FK_RsnLevel2] FOREIGN KEY ([Reason_Level2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [WEvent_Fault_FK_RsnLevel3] FOREIGN KEY ([Reason_Level3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [WEvent_Fault_FK_RsnLevel4] FOREIGN KEY ([Reason_Level4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [WEventFault_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [WEventFault_FK_SourcePUId] FOREIGN KEY ([Source_PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


GO
CREATE NONCLUSTERED INDEX [WEvent_Fault_IDX_PUId]
    ON [dbo].[Waste_Event_Fault]([PU_Id] ASC);


GO
CREATE TRIGGER [dbo].[Waste_Event_Fault_History_Ins]
 ON  [dbo].[Waste_Event_Fault]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 445
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Waste_Event_Fault_History
 	  	   (Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Source_PU_Id,WEFault_Id,WEFault_Name,WEFault_Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Source_PU_Id,a.WEFault_Id,a.WEFault_Name,a.WEFault_Value,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Waste_Event_Fault_History_Del]
 ON  [dbo].[Waste_Event_Fault]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 445
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Waste_Event_Fault_History
 	  	   (Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Source_PU_Id,WEFault_Id,WEFault_Name,WEFault_Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Source_PU_Id,a.WEFault_Id,a.WEFault_Name,a.WEFault_Value,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Waste_Event_Fault_History_Upd]
 ON  [dbo].[Waste_Event_Fault]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 445
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Waste_Event_Fault_History
 	  	   (Event_Reason_Tree_Data_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Source_PU_Id,WEFault_Id,WEFault_Name,WEFault_Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Event_Reason_Tree_Data_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Source_PU_Id,a.WEFault_Id,a.WEFault_Name,a.WEFault_Value,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
