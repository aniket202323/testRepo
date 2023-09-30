CREATE TABLE [dbo].[AlarmAttributeValues] (
    [Alarm_Id]             INT            NOT NULL,
    [Alarm_Modified_On]    DATETIME       NULL,
    [Alarm_Modified_On_Ms] INT            NULL,
    [Attribute_Id]         INT            NOT NULL,
    [Value]                VARCHAR (1000) NOT NULL,
    CONSTRAINT [AlarmAttributeValues_PK_AlarmIdAttrId] PRIMARY KEY CLUSTERED ([Alarm_Id] ASC, [Attribute_Id] ASC),
    CONSTRAINT [AlarmAttributeValues_FK_AlarmId] FOREIGN KEY ([Alarm_Id]) REFERENCES [dbo].[Alarms] ([Alarm_Id]),
    CONSTRAINT [AlarmAttributeValues_FK_AttributeID] FOREIGN KEY ([Attribute_Id]) REFERENCES [dbo].[VendorAttributes] ([Attribute_Id])
);


GO
CREATE TRIGGER [dbo].[AlarmAttributeValues_History_Del]
 ON  [dbo].[AlarmAttributeValues]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 435
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into AlarmAttributeValue_History
 	  	   (Alarm_Id,Alarm_Modified_On,Alarm_Modified_On_Ms,Attribute_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alarm_Id,a.Alarm_Modified_On,a.Alarm_Modified_On_Ms,a.Attribute_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[AlarmAttributeValues_History_Ins]
 ON  [dbo].[AlarmAttributeValues]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 435
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into AlarmAttributeValue_History
 	  	   (Alarm_Id,Alarm_Modified_On,Alarm_Modified_On_Ms,Attribute_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alarm_Id,a.Alarm_Modified_On,a.Alarm_Modified_On_Ms,a.Attribute_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[AlarmAttributeValues_History_Upd]
 ON  [dbo].[AlarmAttributeValues]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 435
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into AlarmAttributeValue_History
 	  	   (Alarm_Id,Alarm_Modified_On,Alarm_Modified_On_Ms,Attribute_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alarm_Id,a.Alarm_Modified_On,a.Alarm_Modified_On_Ms,a.Attribute_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
