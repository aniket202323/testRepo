CREATE TABLE [dbo].[Event_Configuration_Data] (
    [Alias]           VARCHAR (50) NULL,
    [EC_Id]           INT          NOT NULL,
    [ECV_Id]          INT          NOT NULL,
    [ED_Attribute_Id] INT          NULL,
    [ED_Field_Id]     INT          NOT NULL,
    [Input_Precision] TINYINT      CONSTRAINT [DF_Event_Configuration_Data_Input_Precision] DEFAULT ((0)) NOT NULL,
    [IsTrigger]       TINYINT      NULL,
    [PEI_Id]          INT          NULL,
    [PU_Id]           INT          NULL,
    [Sampling_Offset] INT          NULL,
    [ST_Id]           TINYINT      NULL,
    CONSTRAINT [EventCfgData_FK_AttId] FOREIGN KEY ([ED_Attribute_Id]) REFERENCES [dbo].[ED_Attributes] ([ED_Attribute_Id]),
    CONSTRAINT [EventCfgData_FK_ECId] FOREIGN KEY ([EC_Id]) REFERENCES [dbo].[Event_Configuration] ([EC_Id]),
    CONSTRAINT [EventCfgData_FK_ECVId] FOREIGN KEY ([ECV_Id]) REFERENCES [dbo].[Event_Configuration_Values] ([ECV_Id]),
    CONSTRAINT [EventCfgData_FK_FieldId] FOREIGN KEY ([ED_Field_Id]) REFERENCES [dbo].[ED_Fields] ([ED_Field_Id]),
    CONSTRAINT [EventCfgData_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [EventCfgData_FK_STId] FOREIGN KEY ([ST_Id]) REFERENCES [dbo].[Sampling_Type] ([ST_Id])
);


GO
CREATE NONCLUSTERED INDEX [EventCfgData_IDX_ECIdEDFieldId]
    ON [dbo].[Event_Configuration_Data]([EC_Id] ASC, [ED_Field_Id] ASC);


GO
CREATE TRIGGER [dbo].[Event_Configuration_Data_History_Ins]
 ON  [dbo].[Event_Configuration_Data]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 431
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Event_Configuration_Data_History
 	  	   (Alias,EC_Id,ECV_Id,ED_Attribute_Id,ED_Field_Id,Input_Precision,IsTrigger,PEI_Id,PU_Id,Sampling_Offset,ST_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias,a.EC_Id,a.ECV_Id,a.ED_Attribute_Id,a.ED_Field_Id,a.Input_Precision,a.IsTrigger,a.PEI_Id,a.PU_Id,a.Sampling_Offset,a.ST_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
Create  TRIGGER dbo.EventConfigurationData_Reload_InsUpdDel
 	 ON dbo.Event_Configuration_Data
 	 FOR INSERT, UPDATE, DELETE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	 Declare @ShouldReload Int
 	 Select @ShouldReload = sp.Value 
 	  	 From Parameters p
 	  	 Join Site_Parameters sp on p.Parm_Id = sp.Parm_Id
 	  	 Where Parm_Name = 'Perform automatic service reloads'
 	 If @ShouldReload is null or @ShouldReload = 0 
 	  	 Return
/*
2  -Database Mgr
4  -Event Mgr
5  -Reader
6  -Writer
7  -Summary Mgr
8  -Stubber
9  -Message Bus
14 -Gateway
16 -Email Engine
17 -Alarm Manager
18 -FTP Engine
19 -Calculation Manager
20 -Print Server
22 -Schedule Mgr
*/
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (4)

GO
CREATE TRIGGER [dbo].[Event_Configuration_Data_History_Upd]
 ON  [dbo].[Event_Configuration_Data]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 431
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Event_Configuration_Data_History
 	  	   (Alias,EC_Id,ECV_Id,ED_Attribute_Id,ED_Field_Id,Input_Precision,IsTrigger,PEI_Id,PU_Id,Sampling_Offset,ST_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias,a.EC_Id,a.ECV_Id,a.ED_Attribute_Id,a.ED_Field_Id,a.Input_Precision,a.IsTrigger,a.PEI_Id,a.PU_Id,a.Sampling_Offset,a.ST_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Event_Configuration_Data_History_Del]
 ON  [dbo].[Event_Configuration_Data]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 431
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Event_Configuration_Data_History
 	  	   (Alias,EC_Id,ECV_Id,ED_Attribute_Id,ED_Field_Id,Input_Precision,IsTrigger,PEI_Id,PU_Id,Sampling_Offset,ST_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias,a.EC_Id,a.ECV_Id,a.ED_Attribute_Id,a.ED_Field_Id,a.Input_Precision,a.IsTrigger,a.PEI_Id,a.PU_Id,a.Sampling_Offset,a.ST_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
