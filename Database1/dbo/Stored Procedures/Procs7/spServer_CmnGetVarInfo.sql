CREATE PROCEDURE dbo.spServer_CmnGetVarInfo
@VarId int
AS
Declare
  @DefaultHistorian nVarChar(100),
  @ProdDayMinutes int,
  @ShiftInterval int,
  @ShiftOffset int,
  @ActualProdDayMinutes int,
  @ActualShiftInterval int,
  @ActualShiftOffset int,
  @@TheId int,
  @@MasterUnit int
Select @DefaultHistorian = NULL
Select @DefaultHistorian = COALESCE(Alias,Hist_Servername) From Historians Where Hist_Default = 1
If (@DefaultHistorian Is NULL)
  Select @DefaultHistorian = ''
Declare @Vars Table(
TheId int Identity(1,1),
Var_Desc nVarChar(300) COLLATE DATABASE_DEFAULT NULL, 
DS_Id int NULL,
Var_Id int NULL,
PU_Id int NULL,
Input_Tag nVarChar(1000) COLLATE DATABASE_DEFAULT NULL,
Input_Tag2 nVarChar(1000) COLLATE DATABASE_DEFAULT NULL,
DQ_Tag nVarChar(1000) COLLATE DATABASE_DEFAULT,
Tot_Factor float NULL,
Sampling_Interval int NULL,
Sampling_Offset int NULL,
Sampling_Type int NULL,
Sampling_Window int NULL,
Var_Precision int NULL,
Event_Type int NULL,
ShouldArchive int NULL,
Data_Type_Id int NULL,
MaxRatePerMinute float NULL,
ResetValue float null,
MasterUnit int NULL,
TagOnly nVarChar(1000) COLLATE DATABASE_DEFAULT NULL,
Alias nVarChar(255) COLLATE DATABASE_DEFAULT NULL,
DQTagOnly nVarChar(1000) COLLATE DATABASE_DEFAULT NULL,
DQAlias nVarChar(255) COLLATE DATABASE_DEFAULT NULL,
TagOnly2 nVarChar(1000) COLLATE DATABASE_DEFAULT NULL,
Alias2 nVarChar(255) COLLATE DATABASE_DEFAULT NULL,
Comparison_Operator_Id int NULL,
Comparison_Value nVarChar(100) COLLATE DATABASE_DEFAULT NULL,
ShiftInterval int NULL,
ShiftOffset int NULL,
ProdDayMinutes int NULL, 
ReadLagTime int NULL, 
EventSubType int NULL, 
TagHistId int NULL, 
DQTagHistId int NULL,
 Tag2HistId int NULL, 
BadConfig int NULL, 
SampRefVarId int NULL,
 DebugMode int NULL,
CPK_SubGroup_Size int NULL)
Insert Into @Vars(Var_Desc,DS_Id,Var_Id,PU_Id,Input_Tag,DQ_Tag,Tot_Factor,Sampling_Interval,Sampling_Offset,Sampling_Type,Sampling_Window,Var_Precision,Event_Type,ShouldArchive,Data_Type_Id,MaxRatePerMinute,ResetValue,MasterUnit,TagOnly,Alias,DQTagOnly,DQAlias,Comparison_Operator_Id,Comparison_Value,ShiftInterval,ShiftOffset,ProdDayMinutes,ReadLagTime,EventSubType,Input_Tag2,TagOnly2,Alias2,SampRefVarId,DebugMode,CPK_SubGroup_Size)
(Select Var_Desc,
        DS_Id,
        Var_Id,
        a.PU_Id,
        Input_Tag,
        DQ_Tag,
        Tot_Factor,
        Sampling_Interval,
        Sampling_Offset,
        Sampling_Type,
        Sampling_Window,
        Var_Precision,
        Event_Type,
        ShouldArchive,
        Data_Type_Id = Data_Type_Id,
        MaxRatePerMinute = Max_RPM,
        ResetValue = Reset_Value,
        MasterUnit = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
        TagOnly = 
          CASE 
            When ((Input_Tag is NULL) or (Input_Tag = '')) Then ''
            When (CharIndex('\\',Input_Tag) = 0)           Then Input_Tag
            When (CharIndex('\\',Input_Tag) = 1)           Then SubString(Input_Tag,CharIndex('\',SubString(Input_Tag,3,100)) + 3,100)
            Else
              Input_Tag
          END,
        Alias = 
          CASE 
            When ((Input_Tag is NULL) or (Input_Tag = '')) Then ''
            When (CharIndex('\\',Input_Tag) = 0)           Then @DefaultHistorian
            When (CharIndex('\\',Input_Tag) = 1)           Then SubString(Input_Tag,3,CharIndex('\',SubString(Input_Tag,3,100)) - 1)
            Else
              @DefaultHistorian
          END,
        DQTagOnly = 
          CASE 
            When ((DQ_Tag is NULL) or (DQ_Tag = ''))       Then ''
            When (CharIndex('\\',DQ_Tag) = 0)              Then DQ_Tag
            When (CharIndex('\\',DQ_Tag) = 1)              Then SubString(DQ_Tag,CharIndex('\',SubString(DQ_Tag,3,100)) + 3,100)
            Else
              DQ_Tag
          END,
        DQAlias = 
          CASE 
            When ((DQ_Tag is NULL) or (DQ_Tag = ''))       Then ''
            When (CharIndex('\\',DQ_Tag) = 0)              Then @DefaultHistorian
            When (CharIndex('\\',DQ_Tag) = 1)              Then SubString(DQ_Tag,3,CharIndex('\',SubString(DQ_Tag,3,100)) - 1)
            Else
              @DefaultHistorian
          END,
 	 Comparison_Operator_Id,
 	 Comparison_Value,
 	 ShiftInterval = NULL,
 	 ShiftOffset = NULL,
 	 ProdDayMinutes = NULL,
        LagTime = COALESCE(ReadLagTime,-1),
        SubType = 
          CASE Event_Type
            When 17 Then PEI_Id
            Else Event_Subtype_Id
          END,
        Tag2 = Input_Tag2,
        TagOnly2 = 
          CASE 
            When ((Input_Tag2 is NULL) or (Input_Tag2 = '')) Then ''
            When (CharIndex('\\',Input_Tag2) = 0)            Then Input_Tag2
            When (CharIndex('\\',Input_Tag2) = 1)            Then SubString(Input_Tag2,CharIndex('\',SubString(Input_Tag2,3,100)) + 3,100)
            Else
              Input_Tag2
          END,
        Alias2 = 
          CASE 
            When ((Input_Tag2 is NULL) or (Input_Tag2 = '')) Then ''
            When (CharIndex('\\',Input_Tag2) = 0)            Then @DefaultHistorian
            When (CharIndex('\\',Input_Tag2) = 1)            Then SubString(Input_Tag2,3,CharIndex('\',SubString(Input_Tag2,3,100)) - 1)
            Else
              @DefaultHistorian
          END,
 	 a.Sampling_Reference_Var_Id,
        a.Debug,
 	 a.CPK_SubGroup_Size
  From Variables_Base a
  Join Prod_Units_Base b on b.PU_Id = a.PU_Id
  Where (a.Var_Id = @VarId))
Update @Vars Set Sampling_Interval = 1, Sampling_Offset = 0, Sampling_Window = 0 Where Sampling_Type = 31
Declare Var_Cursor INSENSITIVE CURSOR 
  For (Select TheId,MasterUnit From @Vars)
  For Read Only
  Open Var_Cursor  
Fetch_Loop:
  Fetch Next From Var_Cursor Into @@TheId,@@MasterUnit
  If (@@Fetch_Status = 0)
    Begin
      Select @ActualShiftInterval = NULL
      Select @ActualShiftOffset = NULL
      Select @ActualProdDayMinutes = NULL
      Execute spServer_CmnGetLocalInfoByUnit @@MasterUnit,@ActualShiftInterval OUTPUT,@ActualShiftOffset OUTPUT,@ActualProdDayMinutes OUTPUT
      Update @Vars Set 
          ShiftInterval = @ActualShiftInterval,
          ShiftOffset = @ActualShiftOffset,
          ProdDayMinutes = @ActualProdDayMinutes
 	  	     Where TheId = @@TheId
      Goto Fetch_Loop
    End
Close Var_Cursor
Deallocate Var_Cursor
Update @Vars
  Set TagHistId = b.Hist_Id
  From @Vars a, Historians b
  Where (a.Alias = b.Alias) and (b.Is_Active = 1)
Update @Vars
  Set DQTagHistId = b.Hist_Id
  From @Vars a, Historians b
  Where (a.DQAlias = b.Alias) and (b.Is_Active = 1)
Update @Vars Set DQTagOnly = NULL, DQAlias = NULL Where DQTagHistId Is NULL
Update @Vars
  Set Tag2HistId = b.Hist_Id
  From @Vars a, Historians b
  Where (a.Alias2 = b.Alias) and (b.Is_Active = 1)
Update @Vars Set TagOnly2 = NULL, Alias2 = NULL Where Tag2HistId Is NULL
Select DS_Id,
       Var_Id,
       PU_Id,
       Tot_Factor,
       Sampling_Interval,
       Sampling_Offset,
       Sampling_Type,
       Sampling_Window,
       Var_Precision,
       Event_Type,
       ShouldArchive,
       Data_Type_Id,
       MaxRatePerMinute,
       ResetValue,
       MasterUnit,
       TagOnly,
       Alias,
       DQTagOnly,
       DQAlias,
       Comparison_Operator_Id,
       Comparison_Value,
       ShiftInterval,
       ShiftOffset,
       ProdDayMinutes,
       ReadLagTime,
       EventSubType,
       Var_Desc,
       TagOnly2,
       Alias2,
       SampRefVarId,
       DebugMode,
       CPK_SubGroup_Size,
       dbo.fnServer_GetTimeZone(PU_Id)
  From @Vars
