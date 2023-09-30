CREATE TABLE [dbo].[Calculation_Input_Data] (
    [Alias_Name]    VARCHAR (50)         NULL,
    [Calc_Input_Id] INT                  NOT NULL,
    [Default_Value] VARCHAR (1000)       NULL,
    [Input_Name]    [dbo].[Varchar_Desc] NULL,
    [Member_Var_Id] INT                  NULL,
    [PU_Id]         INT                  NULL,
    [Result_Var_Id] INT                  NOT NULL,
    CONSTRAINT [PK_Calculation_Input_Data] PRIMARY KEY NONCLUSTERED ([Calc_Input_Id] ASC, [Result_Var_Id] ASC),
    CONSTRAINT [FK_Calculation_Input_Data_Calculation_Inputs] FOREIGN KEY ([Calc_Input_Id]) REFERENCES [dbo].[Calculation_Inputs] ([Calc_Input_Id]),
    CONSTRAINT [FK_Calculation_Input_Data_PUID] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [FK_Calculation_Input_Data_Variables] FOREIGN KEY ([Member_Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [FK_Calculation_Input_Data_Variables2] FOREIGN KEY ([Result_Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);


GO
CREATE TRIGGER [dbo].[Calculation_Input_Data_History_Ins]
 ON  [dbo].[Calculation_Input_Data]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 426
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Calculation_Input_Data_History
 	  	   (Alias_Name,Calc_Input_Id,Default_Value,Input_Name,Member_Var_Id,PU_Id,Result_Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias_Name,a.Calc_Input_Id,a.Default_Value,a.Input_Name,a.Member_Var_Id,a.PU_Id,a.Result_Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Calculation_Input_Data_History_Del]
 ON  [dbo].[Calculation_Input_Data]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 426
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Calculation_Input_Data_History
 	  	   (Alias_Name,Calc_Input_Id,Default_Value,Input_Name,Member_Var_Id,PU_Id,Result_Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias_Name,a.Calc_Input_Id,a.Default_Value,a.Input_Name,a.Member_Var_Id,a.PU_Id,a.Result_Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Calculation_Input_Data_History_Upd]
 ON  [dbo].[Calculation_Input_Data]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 426
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Calculation_Input_Data_History
 	  	   (Alias_Name,Calc_Input_Id,Default_Value,Input_Name,Member_Var_Id,PU_Id,Result_Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias_Name,a.Calc_Input_Id,a.Default_Value,a.Input_Name,a.Member_Var_Id,a.PU_Id,a.Result_Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
Create  TRIGGER dbo.CalculationInputData_Reload_InsUpdDel
 	 ON dbo.calculation_Input_Data
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
