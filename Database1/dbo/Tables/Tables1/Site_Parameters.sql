CREATE TABLE [dbo].[Site_Parameters] (
    [HostName]      VARCHAR (50)   NOT NULL,
    [Parm_Id]       INT            NOT NULL,
    [Parm_Required] BIT            CONSTRAINT [Site_Parameters_DF_Required] DEFAULT ((0)) NOT NULL,
    [Value]         VARCHAR (5000) NOT NULL,
    CONSTRAINT [SiteParams_PK_ParmIdHostName] PRIMARY KEY NONCLUSTERED ([Parm_Id] ASC, [HostName] ASC),
    CONSTRAINT [SiteParams_FK_ParmId] FOREIGN KEY ([Parm_Id]) REFERENCES [dbo].[Parameters] ([Parm_Id])
);


GO
CREATE UNIQUE CLUSTERED INDEX [CL_Site_Parameters_KS1]
    ON [dbo].[Site_Parameters]([Parm_Id] ASC, [HostName] ASC) WITH (FILLFACTOR = 100);


GO
CREATE TRIGGER [dbo].[Site_Parameters_History_Upd]
 ON  [dbo].[Site_Parameters]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 433
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Site_Parameter_History
 	  	   (HostName,Parm_Id,Parm_Required,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.HostName,a.Parm_Id,a.Parm_Required,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Site_Parameters_History_Ins]
 ON  [dbo].[Site_Parameters]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 433
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Site_Parameter_History
 	  	   (HostName,Parm_Id,Parm_Required,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.HostName,a.Parm_Id,a.Parm_Required,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Site_Parameter_Upd]
 ON  [dbo].[Site_Parameters]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 insert into Sheet_Display_Options_Changed
 Select i.Parm_Id,NULL,--i.value 
 case 
 	 when i.Parm_Id = 8 Then 'productionmetrics-app-service'
 	 when i.Parm_Id = 12 Then 'processanalyzer-service-impl'
 	 when i.Parm_Id = 14 Then 'activities-app-service, activities-service, productionmetrics-app-service'
 	 when i.Parm_Id = 15 Then 'activities-app-service, activities-service, productionmetrics-app-service'
 	 when i.Parm_Id = 16 Then 'activities-app-service, activities-service, productionmetrics-app-service'
 	 when i.Parm_Id = 17 Then 'activities-app-service, activities-service, productionmetrics-app-service'
 	 when i.Parm_Id = 192 Then 'activities-app-service, activities-service, productionmetrics-app-service, processanalyzer-service-impl'
 	 when i.Parm_Id = 301 Then 'activities-app-service, activities-service, productionmetrics-app-service'
 	 when i.Parm_Id = 317 Then 'productionmetrics-app-service'
 	 when i.Parm_Id = 607 Then 'productionmetrics-app-service'
 	 when i.Parm_Id = 609 Then 'processanalyzer-service-impl'
 	 when i.Parm_Id = 612 Then 'alarm-app-service'
 	 when i.Parm_Id = 70 Then 'esignature-app-service'
 	 when i.Parm_Id = 74 Then 'esignature-app-service'
 	 when i.Parm_Id = 438 Then 'esignature-app-service'
 	 when i.Parm_Id = 439 Then 'esignature-app-service'
 	 when i.Parm_Id = 440 Then 'esignature-app-service'
 	 when i.Parm_Id = 441 Then 'esignature-app-service' 	 
End
 from inserted i join deleted d on d.Parm_Id = i.Parm_Id 
 Where d.Value <> i.value and i.Parm_Id in(8,12,14,15,16,17,192,301,317,607,609,612,70,74,438,439,440,441)

GO
CREATE TRIGGER [dbo].[Site_Parameters_History_Del]
 ON  [dbo].[Site_Parameters]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 433
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Site_Parameter_History
 	  	   (HostName,Parm_Id,Parm_Required,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.HostName,a.Parm_Id,a.Parm_Required,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
