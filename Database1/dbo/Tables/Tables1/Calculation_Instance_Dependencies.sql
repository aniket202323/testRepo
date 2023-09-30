CREATE TABLE [dbo].[Calculation_Instance_Dependencies] (
    [Calc_Dependency_NotActive] TINYINT CONSTRAINT [Calculation_Instance_Dependencies_DF_NotActive] DEFAULT ((0)) NOT NULL,
    [Calc_Dependency_Scope_Id]  INT     NOT NULL,
    [Result_Var_Id]             INT     NOT NULL,
    [Var_Id]                    INT     NOT NULL,
    CONSTRAINT [PK_Calculation_Instance_Dependencies] PRIMARY KEY NONCLUSTERED ([Result_Var_Id] ASC, [Var_Id] ASC),
    CONSTRAINT [FK_Calculation_Instance_Dependencies_Calculation_Dependency_Scopes] FOREIGN KEY ([Calc_Dependency_Scope_Id]) REFERENCES [dbo].[Calculation_Dependency_Scopes] ([Calc_Dependency_Scope_Id]),
    CONSTRAINT [FK_Calculation_Instance_Dependencies_Variables] FOREIGN KEY ([Result_Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [FK_Calculation_Instance_Dependencies_Variables1] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);


GO
CREATE TRIGGER [dbo].[Calculation_Instance_Dependencies_History_Ins]
 ON  [dbo].[Calculation_Instance_Dependencies]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 428
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Calculation_Instance_Dependencies_History
 	  	   (Calc_Dependency_NotActive,Calc_Dependency_Scope_Id,Result_Var_Id,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Calc_Dependency_NotActive,a.Calc_Dependency_Scope_Id,a.Result_Var_Id,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
Create  TRIGGER dbo.CalculationInstanceDep_Reload_InsUpdDel
 	 ON dbo.Calculation_Instance_Dependencies
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

GO
CREATE TRIGGER [dbo].[Calculation_Instance_Dependencies_History_Del]
 ON  [dbo].[Calculation_Instance_Dependencies]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 428
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Calculation_Instance_Dependencies_History
 	  	   (Calc_Dependency_NotActive,Calc_Dependency_Scope_Id,Result_Var_Id,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Calc_Dependency_NotActive,a.Calc_Dependency_Scope_Id,a.Result_Var_Id,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Calculation_Instance_Dependencies_History_Upd]
 ON  [dbo].[Calculation_Instance_Dependencies]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 428
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Calculation_Instance_Dependencies_History
 	  	   (Calc_Dependency_NotActive,Calc_Dependency_Scope_Id,Result_Var_Id,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Calc_Dependency_NotActive,a.Calc_Dependency_Scope_Id,a.Result_Var_Id,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
