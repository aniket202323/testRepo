Create Procedure dbo.spCHT_StartTrendSheet 
@Sheet_Desc nvarchar(50),
@User_Id int,
@WithPlots int = NULL
AS
  -- Declare local variables.
  DECLARE @Sheet_id int,
          @Initial_Count int,
          @Sheet_type int,
          @GroupID int,
          @HasPermission nvarchar(10),
          @StartTime datetime,
          @VarId int, 
          @VarMasterId int, 
          @IsEventBased int,
          @IsImmediateActivation int,
          @StartTimeInterval datetime,
          @EndTimeInterval datetime,
          @LastTimeStamp datetime,
          @LastResult nvarchar(25),
          @SPCAlarmColor int,
 	  	   @Now 	  	  	  	 DateTime
 	 SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate()) 
 	 SELECT @StartTimeInterval  = dateadd(day,-2,@Now)
 	 SELECT @EndTimeInterval = dateadd(day,1,@Now)
  -- Get general sheet information.
  SELECT @Sheet_Id = Sheet_Id,
         @Initial_Count = Initial_Count,
         @Sheet_type = Sheet_Type,
         @GroupID = Coalesce(s.Group_Id, sg.Group_Id)
    FROM Sheets s
    Left Outer Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id
    WHERE (Sheet_Desc = @Sheet_Desc)
  Select @SPCAlarmColor = c.Color
    From Colors c
    Join Sheet_Display_Options s on s.Value = c.Color_Id
    Where s.Sheet_Id = @Sheet_Id and s.Display_Option_Id = 158
  -- See If User Has Permission To View Sheet 
  Select @HasPermission = 'No'
  If @Sheet_Id Is Not Null and ((@GroupId Is Null) or (@GroupId = 0)) 
    Select @HasPermission = 'Yes'
  Else If (
            Select Count(Access_Level) 
              From User_Security
              Where (User_Id = @User_Id and 
                    Group_Id = @GroupId and 
                    Access_Level >= 1) or
                    (User_Id = @User_Id and
                    Group_Id = 1 and
                    Access_Level = 4)   
           ) > 0 
    Select @HasPermission = 'Yes'
  -- Calculate Start Time For Data Retrieval
--   Select @StartTime = convert(datetime,convert(nvarchar(15),dateadd(hour,-1 * @Initial_Count,getdate()),113)+'00')  
-- select @initial_count=2
     Select @StartTime = dateadd(hour,-1 * @Initial_Count,@Now)  
  --******************************************************   
  --** Resultset #1 - Return Sheet Information
  --******************************************************   
  If @HasPermission = 'Yes'
    Select Sheet_Id = @Sheet_Id, Group_Id = @GroupId, Sheet_Description = @Sheet_Desc, Sheet_Type = @Sheet_Type, Start_Time = @StartTime, Time_Span = @Initial_Count, SPCAlarmColor = @SPCAlarmColor
  Else
    Begin
      Select Sheet_Id = 0, Group_Id = 0, Sheet_Description = '', Sheet_Type = 0, Start_Time = 0, Time_Span = 0, SPCAlarmColor = 0
      return
    End
/* Gather info about variable assigned to this sheet */
  Create Table #Vars (
    Var_Id1 int,  
    Var_Id1_Master_Unit_Id int NULL,
    Var_Id2 int,  
    Var_Id2_Master_Unit_Id int NULL,
    Var_Id3 int,  
    Var_Id3_Master_Unit_Id int NULL,
    Var_Id4 int,  
    Var_Id4_Master_Unit_Id int NULL,
    Var_Id5 int,  
    Var_Id5_Master_Unit_Id int NULL,
    SPC_Trend_Type_Id int NULL,
    Plot_Order int NULL
  )
   Insert Into #Vars
    Select sp.Var_Id1, Coalesce(pu1.Master_Unit, pu1.Pu_Id),
           sp.Var_Id2, Coalesce(pu2.Master_Unit, pu2.Pu_Id),
           sp.Var_Id3, Coalesce(pu3.Master_Unit, pu3.Pu_Id),
           sp.Var_Id4, Coalesce(pu4.Master_Unit, pu4.Pu_Id),
           sp.Var_Id5, Coalesce(pu5.Master_Unit, pu5.Pu_Id),
           sp.SPC_Trend_Type_Id, sp.Plot_Order
     From Sheet_Plots sp
      Left Outer Join Variables v1 on v1.var_id = sp.var_id1
      Left Outer Join Variables v2 on v2.var_id = sp.var_id2
      Left Outer Join Variables v3 on v3.var_id = sp.var_id3
      Left Outer Join Variables v4 on v4.var_id = sp.var_id4
      Left Outer Join Variables v5 on v5.var_id = sp.var_id5
      Left Outer Join Prod_Units pu1 On pu1.PU_Id = v1.PU_Id
      Left Outer Join Prod_Units pu2 On pu2.PU_Id = v2.PU_Id
      Left Outer Join Prod_Units pu3 On pu3.PU_Id = v3.PU_Id
      Left Outer Join Prod_Units pu4 On pu4.PU_Id = v4.PU_Id
      Left Outer Join Prod_Units pu5 On pu5.PU_Id = v5.PU_Id
      Where (sp.Sheet_Id = @Sheet_Id)
  --******************************************************   
  --** Resultset #2 - Return Variable Information
  --******************************************************   
  --@WithPlots for backward compatibility with older clients
  If @WithPlots is not NULL
    Select * From #Vars Order By Plot_Order
  Else
    Select Var_Id1 as Var_Id, Plot_Order as Var_Order, Var_Id1_Master_Unit_Id as Var_Master_Unit_Id from #Vars Order By Var_Order
  Drop Table #Vars
