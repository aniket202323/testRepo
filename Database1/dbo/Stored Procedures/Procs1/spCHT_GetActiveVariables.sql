﻿Create Procedure dbo.spCHT_GetActiveVariables 
@Sheet_Desc nvarchar(50),
@TimeStamp datetime
AS
  -- Declare local variables.
  DECLARE @Sheet_id int
  -- Get general sheet information.
  SELECT @Sheet_Id = Sheet_Id
    FROM Sheets
    WHERE (Sheet_Desc = @Sheet_Desc)
  Create Table #Vars (
    Var_Id int, 
    Var_Order int,
    Var_Master_Unit_Id int NULL,
    IsImmediateActivation int NULL,
    Activation_Date datetime NULL,
    Prod_Id int NULL,
    Prod_Code nvarchar(50) NULL,
    URL nvarchar(25) NULL,
    UWL nvarchar(25) NULL,
    TGT nvarchar(25) NULL,
    LWL nvarchar(25) NULL,
    LRL nvarchar(25) NULL,
    TFREQ int NULL,
    Comment_Id int NULL    
  )
  -- Get Variable Information Together
  Insert Into #Vars (Var_Id, Var_Order, Var_Master_Unit_Id, IsImmediateActivation) 
    Select sv.Var_Id, sv.Var_Order, Case When pu.Master_Unit Is NUll Then pu.PU_Id Else pu.Master_Unit End, case When v.sa_id = 1 then 1 else 0 end 
      From Sheet_Variables sv
      Join Variables v on v.var_id = sv.var_id
      Join Prod_Units pu on pu.PU_Id = v.PU_Id
      Where (sv.Sheet_Id = @Sheet_Id) And v.data_type_id in (1,2,6,7)
  -- Get Current Product For Each Variable
  Update #Vars 
    Set Prod_Id = PS.Prod_Id,
        Activation_Date = Case
                           When #Vars.IsImmediateActivation = 1 Then @TimeStamp
                           Else PS.Start_Time
                        End  
    From #Vars
    Join Production_Starts PS on PS.PU_Id = #Vars.Var_Master_Unit_Id and 
                                 PS.Start_Time <= @TimeStamp and 
                               ((@TimeStamp < PS.End_Time) or (PS.End_Time Is Null))
  Update #Vars
    Set Prod_Code = P.Prod_Code
    From #Vars
    Join Products P on P.Prod_Id = #Vars.Prod_Id
  -- Get Specs Attached To Data
  Update #Vars
    Set URL = VS.U_Reject,UWL = VS.U_Warning, TGT = VS.Target, LWL = VS.L_Warning, LRL = VS.L_Reject, TFREQ = VS.Test_Freq, Comment_Id = VS.Comment_Id
    From #Vars
    Join Var_Specs VS on VS.Var_Id =  #Vars.Var_Id and 
                         VS.Prod_Id =  #Vars.Prod_Id and
                         VS.Effective_Date <=   #Vars.Activation_Date and
                         ((VS.Expiration_Date >  #Vars.Activation_Date) or (VS.Expiration_Date Is NULL))
  Delete From #Vars Where TFREQ = 0 or ((TFREQ Is Null) and (URL Is NULL) and (UWL Is NULL) and (TGT Is NULL) and (LWL Is NULL) and (LRL Is NULL))
  --******************************************************   
  --** Resultset #1 - Return Spec and Product Information
  --******************************************************   
  Select Var_Id, Prod_Id, Prod_Code, URL, UWL, TGT, LWL, LRL, TFREQ
    From #Vars
    Order By Var_Order -- Var_Id
  Drop Table #Vars