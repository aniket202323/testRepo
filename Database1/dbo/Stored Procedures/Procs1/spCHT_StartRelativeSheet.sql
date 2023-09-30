Create Procedure dbo.spCHT_StartRelativeSheet 
@Sheet_Desc nvarchar(50),
@User_Id int,
@Scope int,
@DecimalSep char(1) = '.'
AS
Select @DecimalSep = Coalesce(@DecimalSep, '.')
  -- Declare local variables.
  DECLARE @Sheet_id int,
          @Initial_Count int,
          @MasterUnit int,
          @CurrentProdId int,
          @CurrentProdCode nvarchar(50),
          @LastProductChange datetime, 
          @GroupID int,
          @HasPermission nvarchar(10),
          @StartTime datetime
  -- Get general sheet information.
  SELECT @Sheet_Id = Sheet_Id,
         @Initial_Count = Initial_Count,
         @GroupID = Coalesce(s.Group_Id,sg.Group_Id),
         @MasterUnit = Master_Unit
    FROM Sheets s
    Left Outer Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id
    WHERE (Sheet_Desc = @Sheet_Desc)
  -- See If User Has Permission To View Sheet 
  Select @HasPermission = 'No'
  If @Sheet_Id Is Not Null and ((@GroupId Is Null) or (@GroupId = 0)) 
    Select @HasPermission = 'Yes'
  Else If (
            Select Count(Access_Level) 
              From User_Security
              Where User_Id = @User_Id and 
                    Group_Id = @GroupId and 
                    Access_Level >= 1   
           ) > 0 
    Select @HasPermission = 'Yes'
  -- Calculate Start Time For Data Retrieval
  SELECT @StartTime = dbo.fnServer_CmnGetDate(getUTCdate())
  SELECT @StartTime = DateAdd(Hour,-1*@Initial_Count,@StartTime)
  SELECT @StartTime = DateAdd(millisecond,-DatePart(Millisecond,@StartTime),@StartTime)
  -- Get Current Product For Master Unit
  Select @CurrentProdId = Prod_Id, @LastProductChange = Start_Time
    From Production_Starts
    Where PU_Id = @MasterUnit and
          End_Time Is Null
  Select @CurrentProdCode = Prod_Code
   From Products 
   Where Prod_Id = @CurrentProdId
  --******************************************************   
  --** Resultset #1 - Return Sheet Information
  --******************************************************   
 If @Scope = 0 
  Begin
   If @HasPermission = 'Yes'
     Select Sheet_Id = @Sheet_Id, Group_Id = @GroupId, Sheet_Description = @Sheet_Desc, Start_Time = @StartTime, Time_Span = @Initial_Count, Current_Product_Id = @CurrentProdId, Current_Prod_Code = @CurrentProdCode, LastProductChange = @LastProductChange
   Else
     Begin
       Select Sheet_Id = 0, Group_Id = 0, Sheet_Description = '', Start_Time = 0, Time_Span = 0, Current_Product_Id = 0, Current_Prod_Code = '', LastProductChange = 0
       return
     End
--*******************************************************
--** Return DisplayIOptions settings
--******************************************************
  Create Table #DisplayOptionsSettings (
    Name nvarchar(50),
    Value nvarchar(50) Null
  )
  Insert Into #DisplayOptionsSettings Values ('DISPLAYALLVARIABLES', 'False')
  Insert Into #DisplayOptionsSettings Values ('WARNINGFACTOR','2')
  Insert Into #DisplayOptionsSettings Values ('REJECTFACTOR','3')
  Insert Into #DisplayOptionsSettings Values ('SHOWTOOLBAR','False')
  Insert Into #DisplayOptionsSettings Values ('MAXIMUMNUMBEROFRESULTS','5')
  Insert Into #DisplayOptionsSettings Values ('MAXIMUMNUMBEROFVARIABLES','40')
  Insert Into #DisplayOptionsSettings
    Select DO.Display_Option_Desc, SDO.Value
      From Display_Options DO
        Join Sheet_Display_Options SDO on SDO.Display_Option_Id = DO.Display_Option_Id
      Where SDO.Sheet_Id = @Sheet_Id 
--******************************************************   
--** Resultset #2 - Return DisplayIOptions settings
--******************************************************    
  Select * From  #DisplayOptionsSettings
   Drop Table #DisplayOptionsSettings
 End 
  Create Table #Vars (
    Var_Id int, 
    Var_Desc nvarchar(100),
    Var_Units nvarchar(50) NULL,
    Var_Precision int NULL,
    Var_Order int NULL,
    Var_Data_Source nvarchar(25) NULL,
    Var_Spec_Id int NULL,
    Var_Spec_Desc nvarchar(100) NULL,
    Var_Event_Type int NULL, 
    Var_Unit_Id int NULL,
    Var_Unit_Name nvarchar(100) NULL,
    Var_Master_Unit_Id int NULL,
    Var_Spec_Activation int NULL, 
    Var_Comment_Id int NULL
  )
  -- Get Variable Information Together
  Insert Into #Vars
    Select sv.Var_Id, v.Var_Desc, v.Eng_Units, v.Var_Precision, sv.Var_Order, ds.DS_Desc, v.Spec_Id, s.Spec_Desc, v.Event_Type, v.PU_Id, pu.PU_Desc, Case When pu.Master_Unit Is NUll Then pu.PU_Id Else pu.Master_Unit End, v.sa_id, v.Comment_Id
      From Sheet_Variables sv
      Join Variables v on v.var_id = sv.var_id
      Join Prod_Units pu on pu.PU_Id = v.PU_Id
      Left Outer Join Specifications s on s.Spec_Id = v.Spec_Id
      Join Data_Source ds on ds.ds_id = v.ds_id
      Where (sv.Sheet_Id = @Sheet_Id) And v.data_type_id in (1,2,6,7)
  --******************************************************   
  --** Resultset #3 - Return Variable Information
  --******************************************************   
  Select * From #Vars Order By Var_Order
  -- Get Test Information Together
  Create Table #TestResults (
    Var_Id int,
    Var_Order int,
    Master_Id int,
    IsEventBased tinyint NULL,
    IsImmediateActivation tinyint NULL,
    TimeStamp datetime, 
    Value nvarchar(25), 
    Event_Num nvarchar(50) NULL,
    Prod_Id int NULL,
    Prod_Code nvarchar(50) NULL,
    Activation_Date datetime NULL,
    URL nvarchar(25) NULL,
    UWL nvarchar(25) NULL,
    TGT nvarchar(25) NULL,
    LWL nvarchar(25) NULL,
    LRL nvarchar(25) NULL,
    Comment_Id int NULL
  )  
  -- Get The Data From The Test Table
  Declare
    @VarId int, 
    @MUnit int,
    @VarOrder int,  
    @EventType int, 
    @SpecAct int
  Declare MyCursor INSENSITIVE CURSOR
    For (Select Var_Id, 
 	   v.Var_Order, v.Var_Master_Unit_Id, Case When v.Var_Event_Type = 1 Then 1 Else 0 End, Case When v.Var_Spec_Activation = 1 Then 1 Else 0 End
 	   from #Vars v)
    For Read Only
    Open MyCursor
  MyLoop1:
    Fetch Next From MyCursor Into @VarId, @VarOrder, @MUnit, @EventType, @SpecAct
    If (@@Fetch_Status = 0)
      Begin
        Insert Into #TestResults (Var_Id, Var_Order, Master_Id, TimeStamp, Value, Comment_Id, IsEventBased, IsImmediateActivation)
          Select @VarId, @VarOrder, @MUnit, t.Result_On, t.Result, t.Comment_Id, @EventType, @SpecAct
            From Tests t 
            Where t.Var_Id = @Varid and
         	   t.Result_On >= @StartTime and t.result_on <= dateadd(Month, 1, dbo.fnServer_CmnGetDate(getUTCdate())) and
                  t.Result Is Not Null
        GoTo MyLoop1
      End
  Close MyCursor
  Deallocate MyCursor
  -- Get Events Attached To Data
  Update #TestResults
    Set Event_Num = EV.Event_Num
    From #TestResults
    Join Events EV on EV.PU_Id = #TestResults.Master_Id and EV.TimeStamp = #TestResults.TimeStamp and #TestResults.IsEventBased = 1
  Create TABLE #ProdStarts(
   PU_Id int, 
   Start_Time datetime, 
   End_Time datetime NULL, 
   Prod_Id int
   ) 
  Insert into #ProdStarts
    Select pu_id, Start_Time, End_Time, Prod_Id 
      From Production_Starts 
      Where PU_Id in (Select DISTINCT Master_Id from #TestResults) and 
            (Start_Time <= (Select MAX(TimeStamp) from #TestResults) and
            (End_Time >= (Select MIN(TimeStamp) from #TestResults) or End_Time is null))
  -- Get Products Attached To Data, Map Time Based On Spec Activation
  Update #TestResults
    Set Prod_Id = PS.Prod_Id,
        Activation_Date = Case
                           When #TestResults.IsImmediateActivation = 1 Then #TestResults.TimeStamp
                           Else PS.Start_Time
                        End  
    From #TestResults
    Join #ProdStarts PS on PS.PU_Id = #TestResults.Master_Id and 
                                 PS.Start_Time <= #TestResults.TimeStamp and 
                               ((#TestResults.TimeStamp < PS.End_Time) or (PS.End_Time Is Null))
    Where PS.PU_Id = #TestResults.Master_Id and 
                                 PS.Start_Time <= #TestResults.TimeStamp and 
                               ((#TestResults.TimeStamp < PS.End_Time) or (PS.End_Time Is Null))
/*
  Update #TestResults
    Set Prod_Id = PS.Prod_Id,
        Activation_Date = Case
                           When #TestResults.IsImmediateActivation = 1 Then #TestResults.TimeStamp
                           Else PS.Start_Time
                        End  
    From #TestResults
    Join Production_Starts PS on PS.PU_Id = #TestResults.Master_Id and 
                                 PS.Start_Time <= #TestResults.TimeStamp and 
                               ((#TestResults.TimeStamp < PS.End_Time) or (PS.End_Time Is Null))
    Where PS.PU_Id = #TestResults.Master_Id and 
                                 PS.Start_Time <= #TestResults.TimeStamp and 
                               ((#TestResults.TimeStamp < PS.End_Time) or (PS.End_Time Is Null))
*/
  Update #TestResults
    Set Prod_Code = P.Prod_Code
    From #TestResults
    Join Products P on P.Prod_Id = #TestResults.Prod_Id
  -- Get Specs Attached To Data
/*
 replaced by the cache object
  Update #TestResults
    Set URL = VS.U_Reject,UWL = VS.U_Warning, TGT = VS.Target, LWL = VS.L_Warning, LRL = VS.L_Reject
    From #TestResults
    Join Var_Specs VS on VS.Var_Id = #TestResults.Var_Id and 
                         VS.Prod_Id = #TestResults.Prod_Id and
                         VS.Effective_Date <=  #TestResults.Activation_Date and
                         ((VS.Expiration_Date > #TestResults.Activation_Date) or (VS.Expiration_Date Is NULL))
*/
  --******************************************************   
  --** Resultset #4 - Return Test and Spec Information
  --******************************************************   
  Select t.Var_Id, t.TimeStamp, t.Event_Num, t.Prod_Id, t.Prod_Code, 
         Value = Case When @DecimalSep <> '.' and v.Data_Type_Id = 2 Then Replace(t.Value, '.', @DecimalSep) Else t.Value End -- , URL, UWL, TGT, LWL, LRL
    From #TestResults t
      Join Variables v on v.Var_Id = t.Var_id
    Order By t.Var_Order, t.TimeStamp Desc --ASC
  Drop Table #TestResults
  Drop Table #Vars
  Drop Table #ProdStarts
