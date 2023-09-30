CREATE PROCEDURE [dbo].[spServer_CmnGetVars]
@EventType int,
@MasterUnit int = NULL
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
  @@MYMasterUnit int,
  @@VarId int,
  @@TagHistId int,
  @@TagOnly nVarChar(255),
  @@DQTagHistId int,
  @@DQTagOnly nVarChar(255),
  @@Tag2HistId int,
  @@TagOnly2 nVarChar(255),
  @TmpTag nVarChar(1000),
  @NewTag nVarChar(255),
  @Pos int,
  @BadConfig int,
  @LineDesc nVarChar(255),
  @UnitDesc nVarChar(255),
  @VarDesc nVarChar(255),
  @BaseVarId int,
  @RejectCount Int
Select @DefaultHistorian = NULL
Select @DefaultHistorian = COALESCE(Alias,Hist_Servername) From Historians Where Hist_Default = 1 and Is_Active = 1
If (@DefaultHistorian Is NULL)
  Select @DefaultHistorian = ''
declare @Vars Table (TheId int Identity(1,1),Var_Desc nVarChar(300) COLLATE DATABASE_DEFAULT, DS_Id int,Var_Id int,PU_Id int,Input_Tag nVarChar(1000) COLLATE DATABASE_DEFAULT,Input_Tag2 nVarChar(1000) COLLATE DATABASE_DEFAULT NULL,DQ_Tag nVarChar(1000) COLLATE DATABASE_DEFAULT,Tot_Factor float,Sampling_Interval int NULL,Sampling_Offset int NULL,Sampling_Type int NULL,Sampling_Window int NULL,Var_Precision int NULL,Event_Type int NULL,ShouldArchive int NULL,Data_Type_Id int NULL,MaxRatePerMinute float,ResetValue float,MasterUnit int,TagOnly nVarChar(1000) COLLATE DATABASE_DEFAULT,Alias nVarChar(255) COLLATE DATABASE_DEFAULT,DQTagOnly nVarChar(1000) COLLATE DATABASE_DEFAULT,DQAlias nVarChar(255) COLLATE DATABASE_DEFAULT,TagOnly2 nVarChar(1000) COLLATE DATABASE_DEFAULT NULL,Alias2 nVarChar(255) COLLATE DATABASE_DEFAULT NULL,Comparison_Operator_Id int NULL,Comparison_Value nVarChar(100) COLLATE DATABASE_DEFAULT NULL,ShiftInterval int NULL,ShiftOffset int NULL,ProdDayMinutes int NULL, ReadLagTime int NULL, EventSubType int NULL, TagHistId int NULL, DQTagHistId int NULL, Tag2HistId int NULL, BadConfig int NULL, SampRefVarId int NULL, DebugMode int NULL, Unit_Reject int, CPK_SubGroup_Size int NULL, Ignore_Event_Status int NULL,NRejects Int Null)
If  (@MasterUnit Is Not NULL) And (@MasterUnit <> 0)
Begin
  	  Insert Into @Vars(Var_Desc,DS_Id,Var_Id,PU_Id,Input_Tag,DQ_Tag,Tot_Factor,Sampling_Interval,Sampling_Offset,Sampling_Type,Sampling_Window,Var_Precision,Event_Type,ShouldArchive,Data_Type_Id,MaxRatePerMinute,ResetValue,MasterUnit,TagOnly,Alias,DQTagOnly,DQAlias,Comparison_Operator_Id,Comparison_Value,ShiftInterval,ShiftOffset,ProdDayMinutes,ReadLagTime,EventSubType,Input_Tag2,TagOnly2,Alias2,SampRefVarId,DebugMode,Unit_Reject,CPK_SubGroup_Size,Ignore_Event_Status)
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
  	              When ((Input_Tag is NULL) or (Input_Tag = ''))                Then ''
  	              When (CharIndex('\\',Input_Tag) = 0)                          Then Input_Tag
  	              When (CharIndex('\\',Input_Tag) = 1) and (Len(Input_Tag) > 2) Then SubString(Input_Tag,CharIndex('\',SubString(Input_Tag,3,1000)) + 3,1000)
  	              Else
  	                Input_Tag
  	            END,
  	          Alias = 
  	            CASE 
  	              When ((Input_Tag is NULL) or (Input_Tag = ''))                Then ''
  	              When (CharIndex('\\',Input_Tag) = 0)                          Then @DefaultHistorian
  	              When (CharIndex('\\',Input_Tag) = 1) and (Len(Input_Tag) > 2) Then SubString(Input_Tag,3,CharIndex('\',SubString(Input_Tag,3,1000)) - 1)
  	              Else
  	                @DefaultHistorian
  	            END,
  	          DQTagOnly = 
  	            CASE 
  	              When ((DQ_Tag is NULL) or (DQ_Tag = ''))                Then ''
  	              When (CharIndex('\\',DQ_Tag) = 0)                       Then DQ_Tag
  	              When (CharIndex('\\',DQ_Tag) = 1) and (Len(DQ_Tag) > 2) Then SubString(DQ_Tag,CharIndex('\',SubString(DQ_Tag,3,1000)) + 3,1000)
  	              Else
  	                DQ_Tag
  	            END,
  	          DQAlias = 
  	            CASE 
  	              When ((DQ_Tag is NULL) or (DQ_Tag = ''))                Then ''
  	              When (CharIndex('\\',DQ_Tag) = 0)                       Then @DefaultHistorian
  	              When (CharIndex('\\',DQ_Tag) = 1) and (Len(DQ_Tag) > 2) Then SubString(DQ_Tag,3,CharIndex('\',SubString(DQ_Tag,3,1000)) - 1)
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
  	              When ((Input_Tag2 is NULL) or (Input_Tag2 = ''))                Then ''
  	              When (CharIndex('\\',Input_Tag2) = 0)                           Then Input_Tag2
  	              When (CharIndex('\\',Input_Tag2) = 1) and (Len(Input_Tag2) > 2) Then SubString(Input_Tag2,CharIndex('\',SubString(Input_Tag2,3,1000)) + 3,1000)
  	              Else
  	                Input_Tag2
  	            END,
  	          Alias2 = 
  	            CASE 
  	              When ((Input_Tag2 is NULL) or (Input_Tag2 = ''))                Then ''
  	              When (CharIndex('\\',Input_Tag2) = 0)                           Then @DefaultHistorian
  	              When (CharIndex('\\',Input_Tag2) = 1) and (Len(Input_Tag2) > 2) Then SubString(Input_Tag2,3,CharIndex('\',SubString(Input_Tag2,3,1000)) - 1)
  	              Else
  	                @DefaultHistorian
  	            END,
  	    	  a.Sampling_Reference_Var_Id,
  	    	  a.Debug,
  	    	  a.Unit_Reject,
 	  	 a.CPK_SubGroup_Size,
 	  	 COALESCE(a.Ignore_Event_Status,0)
  	    From Variables_Base a
  	    Join Prod_Units_Base b on b.PU_Id = a.PU_Id
  	    Where ((b.Master_Unit = @MasterUnit) or (b.PU_Id = @MasterUnit)) and ((DS_Id = 3) And (Input_Tag Is Not Null) And (Input_Tag <> '')) And 
  	          (Event_Type = @EventType) And
  	          (Sampling_Type Is Not Null) And 
  	    	    	      (Sampling_Type Not In (19,28)) And
  	          ((Data_Type_Id In (1,2,3,6,7) Or (Data_Type_Id > 50))) And
  	          (Is_Active = 1))
  End
Else
  Begin
 	 Insert Into @Vars(Var_Desc,DS_Id,Var_Id,PU_Id,Input_Tag,DQ_Tag,Tot_Factor,Sampling_Interval,Sampling_Offset,Sampling_Type,Sampling_Window,Var_Precision,Event_Type,ShouldArchive,Data_Type_Id,MaxRatePerMinute,ResetValue,MasterUnit,TagOnly,Alias,DQTagOnly,DQAlias,Comparison_Operator_Id,Comparison_Value,ShiftInterval,ShiftOffset,ProdDayMinutes,ReadLagTime,EventSubType,Input_Tag2,TagOnly2,Alias2,SampRefVarId,DebugMode,Unit_Reject,CPK_SubGroup_Size,Ignore_Event_Status)
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
  	              When ((Input_Tag is NULL) or (Input_Tag = ''))                Then ''
  	              When (CharIndex('\\',Input_Tag) = 0)                          Then Input_Tag
  	              When (CharIndex('\\',Input_Tag) = 1) and (Len(Input_Tag) > 2) Then SubString(Input_Tag,CharIndex('\',SubString(Input_Tag,3,1000)) + 3,1000)
  	              Else
  	                Input_Tag
  	            END,
  	          Alias = 
  	            CASE 
  	              When ((Input_Tag is NULL) or (Input_Tag = ''))                Then ''
  	              When (CharIndex('\\',Input_Tag) = 0)                          Then @DefaultHistorian
  	              When (CharIndex('\\',Input_Tag) = 1) and (Len(Input_Tag) > 2) Then SubString(Input_Tag,3,CharIndex('\',SubString(Input_Tag,3,1000)) - 1)
  	              Else
  	                @DefaultHistorian
  	            END,
  	          DQTagOnly = 
  	            CASE 
  	              When ((DQ_Tag is NULL) or (DQ_Tag = ''))                Then ''
  	              When (CharIndex('\\',DQ_Tag) = 0)                       Then DQ_Tag
  	              When (CharIndex('\\',DQ_Tag) = 1) and (Len(DQ_Tag) > 2) Then SubString(DQ_Tag,CharIndex('\',SubString(DQ_Tag,3,1000)) + 3,1000)
  	              Else
  	                DQ_Tag
  	            END,
  	          DQAlias = 
  	            CASE 
  	              When ((DQ_Tag is NULL) or (DQ_Tag = ''))                Then ''
  	              When (CharIndex('\\',DQ_Tag) = 0)                       Then @DefaultHistorian
  	              When (CharIndex('\\',DQ_Tag) = 1) and (Len(DQ_Tag) > 2) Then SubString(DQ_Tag,3,CharIndex('\',SubString(DQ_Tag,3,1000)) - 1)
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
  	              When ((Input_Tag2 is NULL) or (Input_Tag2 = ''))                Then ''
  	              When (CharIndex('\\',Input_Tag2) = 0)                           Then Input_Tag2
  	              When (CharIndex('\\',Input_Tag2) = 1) and (Len(Input_Tag2) > 2) Then SubString(Input_Tag2,CharIndex('\',SubString(Input_Tag2,3,1000)) + 3,1000)
  	              Else
  	                Input_Tag2
  	            END,
  	          Alias2 = 
  	            CASE 
  	              When ((Input_Tag2 is NULL) or (Input_Tag2 = ''))                Then ''
  	              When (CharIndex('\\',Input_Tag2) = 0)                           Then @DefaultHistorian
  	              When (CharIndex('\\',Input_Tag2) = 1) and (Len(Input_Tag2) > 2) Then SubString(Input_Tag2,3,CharIndex('\',SubString(Input_Tag2,3,1000)) - 1)
  	              Else
  	                @DefaultHistorian
  	            END,
  	    	  a.Sampling_Reference_Var_Id,
  	    	  a.Debug,
  	    	  a.Unit_Reject,
 	  	 a.CPK_SubGroup_Size,
 	  	 COALESCE(a.Ignore_Event_Status,0)
  	    From Variables_Base a
  	    Join Prod_Units_Base b on b.PU_Id = a.PU_Id
  	    Where ((DS_Id = 3) And (Input_Tag Is Not Null) And (Input_Tag <> '')) And 
  	    	    	    	    	  (b.PU_Id > 0) And
  	    	    	      (Event_Type = @EventType) And
  	          (Sampling_Type Is Not Null) And 
  	    	  (Sampling_Type Not In (19,28)) And
  	          ((Data_Type_Id In (1,2,3,6,7) Or (Data_Type_Id > 50))) And
  	          (Is_Active = 1))
  End
Delete From @Vars Where (Sampling_Type = 31) And (Event_Type <> 0)
Delete From @Vars Where (Sampling_Type = 31) And (DS_Id <> 3)
Update @Vars Set Sampling_Interval = 1, Sampling_Offset = 0, Sampling_Window = 0 Where Sampling_Type = 31
Update @Vars
  Set TagHistId = b.Hist_Id
  From @Vars a, Historians b
  Where (a.Alias = b.Alias) and (b.Is_Active = 1)
Delete From @Vars Where TagHistId Is NULL
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
Declare Var_Cursor INSENSITIVE CURSOR
  For Select Var_Id,TagHistId,TagOnly,DQTagHistId,DQTagOnly,Tag2HistId,TagOnly2 From @Vars
  For Read Only
  Open Var_Cursor  
Var_Loop:
  Fetch Next From Var_Cursor Into @@VarId,@@TagHistId,@@TagOnly,@@DQTagHistId,@@DQTagOnly,@@Tag2HistId,@@TagOnly2
  If (@@Fetch_Status = 0)
    Begin
      Select @BadConfig = 0
      If (@BadConfig = 0) And (@@TagHistId = -1) And (IsNumeric(@@TagOnly) = 0)
        Begin
          Execute @BadConfig = spServer_CmnDecodeVarId @@TagOnly,@BaseVarId output
          If (@BadConfig = 0)
            Update @Vars Set TagOnly = Convert(nVarChar(50),@BaseVarId) Where Var_Id = @@VarId
        End
      If (@BadConfig = 0) And (@@DQTagHistId = -1) And (IsNumeric(@@DQTagOnly) = 0)
        Begin
          Execute @BadConfig = spServer_CmnDecodeVarId @@DQTagOnly,@BaseVarId output
          If (@BadConfig = 0)
            Update @Vars Set DQTagOnly = Convert(nVarChar(50),@BaseVarId) Where Var_Id = @@VarId
        End
      If (@BadConfig = 0) And (@@Tag2HistId = -1) And (IsNumeric(@@TagOnly2) = 0)
        Begin
          Execute @BadConfig = spServer_CmnDecodeVarId @@TagOnly2,@BaseVarId output
          If (@BadConfig = 0)
            Update @Vars Set TagOnly2 = Convert(nVarChar(50),@BaseVarId) Where Var_Id = @@VarId
        End
      If (@BadConfig = 1)
        Update @Vars Set BadConfig = 1 Where Var_Id = @@VarId
      Goto Var_Loop
    End
Close Var_Cursor 
Deallocate Var_Cursor
DELETE FROM @Vars WHERE BadConfig IS NOT NULL
Declare Var_Cursor INSENSITIVE CURSOR 
  For (Select DISTINCT MasterUnit From @Vars)
  For Read Only
  Open Var_Cursor  
Fetch_Loop:
  Fetch Next From Var_Cursor Into @@MYMasterUnit
  If (@@Fetch_Status = 0)
    Begin
      Select @ActualShiftInterval = NULL
      Select @ActualShiftOffset = NULL
      Select @ActualProdDayMinutes = NULL
      Execute spServer_CmnGetLocalInfoByUnit @@MYMasterUnit,@ActualShiftInterval OUTPUT,@ActualShiftOffset OUTPUT,@ActualProdDayMinutes OUTPUT
      Update @Vars Set 
          ShiftInterval = @ActualShiftInterval,
          ShiftOffset = @ActualShiftOffset,
          ProdDayMinutes = @ActualProdDayMinutes
  	    	      Where MasterUnit = @@MYMasterUnit
      Goto Fetch_Loop
    End
Close Var_Cursor
Deallocate Var_Cursor
Declare UR_Cursor INSENSITIVE CURSOR 
  For (Select DISTINCT PU_Id From @Vars)
  For Read Only
  Open UR_Cursor  
Fetch_Loop2:
  Fetch Next From UR_Cursor Into @@MYMasterUnit
  If (@@Fetch_Status = 0)
    Begin
 	  	 SET @RejectCount = 0
 	 SELECT @RejectCount = SUM(Unit_Reject)   FROM @Vars where PU_id = @@MYMasterUnit
     Update @Vars Set 
          NRejects = @RejectCount
  	    	      Where PU_id = @@MYMasterUnit
      Goto Fetch_Loop2
    End
Close UR_Cursor
Deallocate UR_Cursor
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
       NumUnitRejects = NRejects, --(select count(b.PU_Id) from Variables b where b.PU_Id=a.PU_Id and b.Unit_Reject = 1),
       CPK_SubGroup_Size,
       dbo.fnServer_GetTimeZone(PU_Id),
       Ignore_Event_Status
  From @Vars a
  Order By Alias,TagOnly
