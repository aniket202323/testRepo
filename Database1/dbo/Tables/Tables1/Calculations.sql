CREATE TABLE [dbo].[Calculations] (
    [Calculation_Id]        INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Calculation_Desc]      VARCHAR (255)        NOT NULL,
    [Calculation_Name]      VARCHAR (255)        NOT NULL,
    [Calculation_Type_Id]   INT                  NOT NULL,
    [Comment_Id]            INT                  NULL,
    [Equation]              VARCHAR (255)        NULL,
    [Lag_Time]              INT                  NULL,
    [Locked]                BIT                  CONSTRAINT [DF_Calculations_Locked] DEFAULT ((0)) NOT NULL,
    [Max_Run_Time]          INT                  CONSTRAINT [Calculations_DF_MaxRunTime] DEFAULT ((15)) NULL,
    [Optimize_Calc_Runs]    BIT                  CONSTRAINT [Calculation_DF_OptimizeCalcRuns] DEFAULT ((1)) NOT NULL,
    [Script]                TEXT                 NULL,
    [Stored_Procedure_Name] [dbo].[Varchar_Desc] NULL,
    [System_Calculation]    INT                  NULL,
    [Trigger_Type_Id]       INT                  CONSTRAINT [Calculations_DF_TriggerTypeId] DEFAULT ((1)) NOT NULL,
    [Version]               VARCHAR (10)         NOT NULL,
    CONSTRAINT [PK_Calculations] PRIMARY KEY NONCLUSTERED ([Calculation_Id] ASC),
    CONSTRAINT [Calculations_FK_CalcType] FOREIGN KEY ([Calculation_Type_Id]) REFERENCES [dbo].[Calculation_Types] ([Calculation_Type_Id]),
    CONSTRAINT [FK_Calculations_TriggerTypeId] FOREIGN KEY ([Trigger_Type_Id]) REFERENCES [dbo].[Calculation_Trigger_Types] ([Trigger_Type_Id]),
    CONSTRAINT [Calculations_IX_Name] UNIQUE NONCLUSTERED ([Calculation_Name] ASC)
);


GO
CREATE TRIGGER [dbo].[Calculations_History_Ins]
 ON  [dbo].[Calculations]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 429
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Calculation_History
 	  	   (Calculation_Desc,Calculation_Id,Calculation_Name,Calculation_Type_Id,Comment_Id,Equation,Lag_Time,Locked,Max_Run_Time,Optimize_Calc_Runs,Stored_Procedure_Name,System_Calculation,Trigger_Type_Id,Version,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Calculation_Desc,a.Calculation_Id,a.Calculation_Name,a.Calculation_Type_Id,a.Comment_Id,a.Equation,a.Lag_Time,a.Locked,a.Max_Run_Time,a.Optimize_Calc_Runs,a.Stored_Procedure_Name,a.System_Calculation,a.Trigger_Type_Id,a.Version,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
Create  TRIGGER dbo.Calculation_Reload_InsUpdDel
 	 ON dbo.calculations
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
CREATE TRIGGER [dbo].[Calculations_History_Upd]
 ON  [dbo].[Calculations]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 429
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Calculation_History
 	  	   (Calculation_Desc,Calculation_Id,Calculation_Name,Calculation_Type_Id,Comment_Id,Equation,Lag_Time,Locked,Max_Run_Time,Optimize_Calc_Runs,Stored_Procedure_Name,System_Calculation,Trigger_Type_Id,Version,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Calculation_Desc,a.Calculation_Id,a.Calculation_Name,a.Calculation_Type_Id,a.Comment_Id,a.Equation,a.Lag_Time,a.Locked,a.Max_Run_Time,a.Optimize_Calc_Runs,a.Stored_Procedure_Name,a.System_Calculation,a.Trigger_Type_Id,a.Version,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Calculations_Del 
  ON dbo.Calculations
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Calculations_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Calculations_Del_Cursor 
--
--
Fetch_Next_Calculation:
FETCH NEXT FROM Calculations_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
 	   Delete From Comments Where TopOfChain_Id = @Comment_Id 
   	 Delete From Comments Where Comment_Id = @Comment_Id 
 	   GOTO Fetch_Next_Calculation
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Calculations_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Calculations_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Calculations_History_Del]
 ON  [dbo].[Calculations]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 429
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Calculation_History
 	  	   (Calculation_Desc,Calculation_Id,Calculation_Name,Calculation_Type_Id,Comment_Id,Equation,Lag_Time,Locked,Max_Run_Time,Optimize_Calc_Runs,Stored_Procedure_Name,System_Calculation,Trigger_Type_Id,Version,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Calculation_Desc,a.Calculation_Id,a.Calculation_Name,a.Calculation_Type_Id,a.Comment_Id,a.Equation,a.Lag_Time,a.Locked,a.Max_Run_Time,a.Optimize_Calc_Runs,a.Stored_Procedure_Name,a.System_Calculation,a.Trigger_Type_Id,a.Version,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
