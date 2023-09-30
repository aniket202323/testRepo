CREATE TABLE [dbo].[Calculation_Inputs] (
    [Calc_Input_Id]           INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alias]                   [dbo].[Varchar_Desc] NOT NULL,
    [Calc_Input_Attribute_Id] INT                  NOT NULL,
    [Calc_Input_Entity_Id]    INT                  NOT NULL,
    [Calc_Input_Order]        INT                  NOT NULL,
    [Calculation_Id]          INT                  NOT NULL,
    [Default_Value]           VARCHAR (1000)       NULL,
    [Input_Name]              [dbo].[Varchar_Desc] NOT NULL,
    [Non_Triggering]          BIT                  CONSTRAINT [DF_Calculation_Inputs_NonTriggering] DEFAULT ((0)) NOT NULL,
    [Optional]                BIT                  CONSTRAINT [DF_Calculation_Inputs_Optional] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Calculation_Inputs] PRIMARY KEY NONCLUSTERED ([Calc_Input_Id] ASC),
    CONSTRAINT [FK_Calculation_Inputs_Calculation_Input_Entities] FOREIGN KEY ([Calc_Input_Entity_Id]) REFERENCES [dbo].[Calculation_Input_Entities] ([Calc_Input_Entity_Id]),
    CONSTRAINT [FK_Calculation_Inputs_Calculation_Input_Entity_Attributes] FOREIGN KEY ([Calc_Input_Attribute_Id]) REFERENCES [dbo].[Calculation_Input_Attributes] ([Calc_Input_Attribute_Id]),
    CONSTRAINT [FK_Calculation_Inputs_Calculations] FOREIGN KEY ([Calculation_Id]) REFERENCES [dbo].[Calculations] ([Calculation_Id])
);


GO
CREATE NONCLUSTERED INDEX [CalculationInputs_IDX_IdCalcId]
    ON [dbo].[Calculation_Inputs]([Calc_Input_Id] ASC, [Calculation_Id] ASC);


GO
CREATE TRIGGER [dbo].[Calculation_Inputs_History_Ins]
 ON  [dbo].[Calculation_Inputs]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 427
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Calculation_Input_History
 	  	   (Alias,Calc_Input_Attribute_Id,Calc_Input_Entity_Id,Calc_Input_Id,Calc_Input_Order,Calculation_Id,Default_Value,Input_Name,Non_Triggering,Optional,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias,a.Calc_Input_Attribute_Id,a.Calc_Input_Entity_Id,a.Calc_Input_Id,a.Calc_Input_Order,a.Calculation_Id,a.Default_Value,a.Input_Name,a.Non_Triggering,a.Optional,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Calculation_Inputs_History_Del]
 ON  [dbo].[Calculation_Inputs]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 427
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Calculation_Input_History
 	  	   (Alias,Calc_Input_Attribute_Id,Calc_Input_Entity_Id,Calc_Input_Id,Calc_Input_Order,Calculation_Id,Default_Value,Input_Name,Non_Triggering,Optional,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias,a.Calc_Input_Attribute_Id,a.Calc_Input_Entity_Id,a.Calc_Input_Id,a.Calc_Input_Order,a.Calculation_Id,a.Default_Value,a.Input_Name,a.Non_Triggering,a.Optional,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Calculation_Inputs_History_Upd]
 ON  [dbo].[Calculation_Inputs]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 427
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Calculation_Input_History
 	  	   (Alias,Calc_Input_Attribute_Id,Calc_Input_Entity_Id,Calc_Input_Id,Calc_Input_Order,Calculation_Id,Default_Value,Input_Name,Non_Triggering,Optional,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias,a.Calc_Input_Attribute_Id,a.Calc_Input_Entity_Id,a.Calc_Input_Id,a.Calc_Input_Order,a.Calculation_Id,a.Default_Value,a.Input_Name,a.Non_Triggering,a.Optional,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
Create  TRIGGER dbo.CalculationInputs_Reload_InsUpdDel
 	 ON dbo.calculation_Inputs
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
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (19)
