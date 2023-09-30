Create Procedure dbo.spCHT_GetRelativeVarData
@VarId int,
@StartTime DateTime,
@DecimalSep char(1) = '.'
AS
Select @DecimalSep = Coalesce(@DecimalSep, '.')
  -- Declare local variables.
  DECLARE @MasterUnitId int,
          @SpecActivation int,
          @EventType int
  -- Get Variable Information Together
  Select @MasterUnitId = Coalesce(PU.Master_Unit, PU.PU_Id), @SpecActivation=V.Sa_Id, @EventType =v.Event_Type 
   From Variables V Inner Join Prod_Units PU On V.PU_Id = PU.PU_id
    Where V.Var_id = @VarId and V.Data_Type_id in (1,2,6,7)
  -- Get Test Information Together
  Create Table #TestResults (
    Var_Id int,
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
  Insert Into #TestResults (Var_Id, Master_Id, TimeStamp, Value, Comment_Id, IsEventBased, IsImmediateActivation)
    Select T.Var_Id,@MasterUnitId, T.Result_On, T.Result, T.Comment_Id, Case When @EventType = 1 Then 1 Else 0 End, 
     Case When @SpecActivation = 1 Then 1 Else 0 End
      From Tests T 
        Where T.Var_Id = @VarId 
         And T.Result_On >= @StartTime 
         And T.Result Is Not Null
  -- Get Events Attached To Data
  Update #TestResults
    Set Event_Num = EV.Event_Num
    From #TestResults
    Join Events EV on EV.PU_Id = #TestResults.Master_Id and EV.TimeStamp = #TestResults.TimeStamp and #TestResults.IsEventBased = 1
  -- Get Products Attached To Data, Map Time Based On Spec Activation
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
  Update #TestResults
    Set Prod_Code = P.Prod_Code
    From #TestResults
    Join Products P on P.Prod_Id = #TestResults.Prod_Id
/*
 specs are obtained from the cache
  -- Get Specs Attached To Data
  Update #TestResults
    Set URL = VS.U_Reject,UWL = VS.U_Warning, TGT = VS.Target, LWL = VS.L_Warning, LRL = VS.L_Reject
    From #TestResults
    Join Var_Specs VS on VS.Var_Id = #TestResults.Var_Id and 
                         VS.Prod_Id = #TestResults.Prod_Id and
                         VS.Effective_Date <=  #TestResults.Activation_Date and
                         ((VS.Expiration_Date > #TestResults.Activation_Date) or (VS.Expiration_Date Is NULL))
*/
  --******************************************************   
  --** Resultset #3 - Return Test and Spec Information
  --******************************************************   
  Select t.Var_Id, t.TimeStamp, t.Event_Num, t.Prod_Id, t.Prod_Code, t.Comment_Id,
         Value = Case When @DecimalSep <> '.' and v.Data_Type_Id = 2 Then Replace(t.Value, '.', @DecimalSep) Else t.Value End -- , URL, UWL, TGT, LWL, LRL
   From #TestResults t
     Join Variables v on v.Var_Id = t.Var_Id
    Order By  TimeStamp Desc 
  Drop Table #TestResults
