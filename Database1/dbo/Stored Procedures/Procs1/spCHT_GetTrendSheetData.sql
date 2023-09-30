Create Procedure dbo.spCHT_GetTrendSheetData 
@StartTime datetime,
@EndTime datetime,
@AlarmTypeId int,
@ReturnVariableInfo nvarchar(255),
@VariableList1 nvarchar(255),
@VariableList2 nvarchar(255) =NULL,
@VariableList3 nvarchar(255) =NULL,
@VariableList4 nvarchar(255) =NULL,
@VariableList5 nvarchar(255) =NULL,
@DecimalSep char(1) = '.'
AS
/**** This part (downward) of the sp was added to correct a backward-compatibility issue */
/**** The AlarmTypeId parameters was added in the middle of the input parameters, must shift each parameter */
/**** before running the stored procedure to get the correct inputs */
Declare @ReturnVariableInfoNew int
If Right(@ReturnVariableInfo, 1) = '$'
  Begin
    Select @VariableList5 = @VariableList4
    Select @VariableList4 = @VariableList3
    Select @VariableList3 = @VariableList2
    Select @VariableList2 = @VariableList1
    Select @VariableList1 = @ReturnVariableInfo
    Select @ReturnVariableInfoNew = @AlarmTypeId
    Select @AlarmTypeId = 0
  End
Else
  Begin
    Select @ReturnVariableInfoNew = Convert(int, @ReturnVariableInfo)
  End
/**** This part (upward) of the sp was added to correct a backward-compatibility issue */
Select @DecimalSep = Coalesce(@DecimalSep, '.')
create table #IdList (
  ItemId int,
  ItemOrder int,
  CONSTRAINT I_ItemId PRIMARY KEY (ItemId, ItemOrder)
)
declare @LastDataStartTime datetime
declare @LastDataMaxTimeStamp datetime
declare @CurIds nvarchar(255)
declare @i integer
declare @IdCount integer
declare @tchar char
declare @tvchar nvarchar(10)
declare @ParCount integer
declare @tID integer
Select @Parcount=1
select @tvchar='' -- make SP work on 7.0
Select @IdCount = 0
Select @i = 1 	  	     
Select @CurIds = @VariableList1
Select @tchar = SUBSTRING (@CurIds, @i, 1)
While (@tchar <> '$') And (@i < 254) and (@tchar is not null)
  Begin
     If @tchar <> ',' And @tchar <> '_'
       Select @tvchar = @tvchar + @tchar
     Else
       Begin
         Select @tvchar = LTRIM(RTRIM(@tvchar))
         If @tvchar <> '' 
           Begin
             Select @tID = CONVERT(integer, @tvchar)
--             If (Select Count(*) From #IdList Where ItemId=@Tid)=0 
              if 1 = 1 
              Begin
               Select @IdCount = @IdCount + 1
               Insert into #IdList (ItemId, ItemOrder) values (@tID, @IdCount)
              End
           End
           If @tchar = ','
             Begin
 	        Select @tvchar = ''
 	      End
           Else -- Go To Next Set Of Ids (@tchar = '_')
             Begin
               Select @ParCount = @ParCount+1
               Select @tvchar = ''
               Select @i = 0
               If @ParCount = 2
                 Select @CurIds = @VariableList2
               If @ParCount = 3
                 Select @CurIds = @VariableList3
               If @ParCount = 4
                 Select @CurIds = @VariableList4
               If @ParCount = 5
                 Select @CurIds = @VariableList5
 	     End
       End
     Select @i = @i + 1
     Select @tchar = SUBSTRING(@CurIds, @i, 1)
  End
 	  	 
Select @tvchar = LTRIM(RTRIM(@tvchar))
If @tvchar <> '' and (@tvchar is not null)
  Begin
    Select @tID = CONVERT(integer, @tvchar)
--    If (Select Count(*) From #IdList Where ItemId=@Tid)=0 
    If 1 = 1 
    Begin
      Select @IdCount = @IdCount + 1
      Insert into #IdList (ItemId, ItemOrder) values (@tID, @IdCount)
    End
  End
Create Table #Vars (
    Var_Id int not NULL, 
    Var_Desc nvarchar(100),
    Var_Units nvarchar(50) NULL,
    Var_Precision int NULL,
    Var_Order int,
    Var_Data_Source nvarchar(25) NULL,
    Var_Spec_Id int NULL,
    Var_Spec_Desc nvarchar(100) NULL,
    Var_Event_Type int NULL, 
    Var_Unit_Id int NULL,
    Var_Unit_Name nvarchar(100) NULL,
    Var_Master_Unit_Id int NULL,
    Var_Spec_Activation int NULL, 
    Var_Comment_Id int NULL,
    Var_Qtt int NULL,
    Var_Data_Type_Id int,
    UseSigmaTable int
    CONSTRAINT V_VarId PRIMARY KEY (Var_Id, Var_Order)
  )
  -- Get Variable Information Together
  Insert Into #Vars(Var_Id,Var_Desc,Var_Units,Var_Precision,Var_Order,
    Var_Data_Source,Var_Spec_Id,Var_Spec_Desc,Var_Event_Type,Var_Unit_Id,
    Var_Unit_Name,Var_Master_Unit_Id,Var_Spec_Activation,Var_Comment_Id,Var_Qtt,
    Var_Data_Type_Id,UseSigmaTable)
    Select v.Var_Id, v.Var_Desc, v.Eng_Units, Case When v.Var_Precision is not NULL Then v.Var_Precision Else 0 End, i.ItemOrder, 
 	  	  	 ds.DS_Desc, v.Spec_Id, s.Spec_Desc, v.Event_Type, v.PU_Id, 
 	  	  	 pu.PU_Desc, Case When pu.Master_Unit Is NUll Then pu.PU_Id Else pu.Master_Unit End, v.sa_id, v.Comment_Id,0,
 	  	  	 v.Data_Type_Id,0
      From #Idlist i
      Inner Join Variables v on v.var_id = i.ItemId
      Inner Join Prod_Units pu on pu.PU_Id = v.PU_Id
      Left Outer Join Specifications s on s.Spec_Id = v.Spec_Id
      Inner Join Data_Source ds on ds.ds_id = v.ds_id
      Where v.data_type_id in (1,2,4,6,7)   --and v.var_id<>101
UPDATE a SET UseSigmaTable = 1
 FROM #Vars a
 JOIN Alarm_Template_Var_Data  b on b.Var_Id = a.Var_Id 
 WHERE b.Sampling_Size > 0
-- Get Test Information Together
  Create Table #TestResults (
    Var_Id int not NULL,
    Var_Order int,
    NumberTests int,
    Master_Id int not NUll,
    IsEventBased tinyint NULL,
    IsImmediateActivation tinyint NULL,
    TimeStamp datetime not NULL, 
    Value nvarchar(25) NULL, 
    Event_Num nvarchar(50) NULL,
    Prod_Id int NULL,
    Prod_Code nvarchar(50) NULL,
    Activation_Date datetime NULL,
    URL nvarchar(25) NULL,
    UWL nvarchar(25) NULL,
    TGT nvarchar(25) NULL,
    LWL nvarchar(25) NULL,
    LRL nvarchar(25) NULL,
    Comment_Id int NULL,
    Alarm_Id int,
    Alarm_Start_Time datetime NULL,
    Alarm_End_Time datetime NULL,
    Alarm_Desc nvarchar(1000) NULL, 
    OTCL nvarchar(25) NULL,
    OLCL nvarchar(25) NULL,
    OUCL nvarchar(25) NULL,
    UseOverRide Int,
    CONSTRAINT T_VarId_PU_TimeStamp PRIMARY KEY (Var_Id, Master_Id, TimeStamp, Var_Order, Alarm_Id)
  )  
  -- Get The Data From The Test Table
 Select @LastDataStartTime= dateadd(day,-2,@StartTime) 
 Declare
    @VarId int, 
    @MUnit int,
    @VarOrder int,  
    @EventType int, 
    @SpecAct int,
    @Prec    Int,
    @DataTypeId INT
  Declare MyCursor INSENSITIVE CURSOR
    For (Select Var_Id, v.Var_Order, v.Var_Master_Unit_Id, 
         Case When v.Var_Event_Type = 1 Then 1 Else 0 End, 
         Case When v.Var_Spec_Activation = 1 Then 1 Else 0 End,v.Var_Precision,v.Var_Data_Type_Id 
 	   from #Vars v)
    For Read Only
    Open MyCursor
  MyLoop1:
    Fetch Next From MyCursor Into @VarId, @VarOrder, @MUnit, @EventType, @SpecAct,@prec,@DataTypeId
    If (@@Fetch_Status = 0)
      Begin
 	  	 select @Prec = coalesce(@prec,0)
        Select @LastDataMaxTimeStamp=NULL
        Insert Into #TestResults (Var_Id, Var_Order, NumberTests,Master_Id, TimeStamp, Value, Comment_Id, Alarm_Id, Alarm_Start_Time, Alarm_End_Time, Alarm_Desc, IsEventBased, IsImmediateActivation,OLCL,OTCL,OUCL,UseOverRide)
          Select @VarId, @VarOrder,0, @MUnit, t.Result_On, t.Result, t.Comment_Id, 0, null, null, null, @EventType, @SpecAct,
 	  	  	  	 ltrim(str(tsd.Mean - 3 * tsd.sigma,25,@prec)),
 	  	  	  	 ltrim(str(tsd.Mean,25,@prec)),
 	  	  	  	 ltrim(str(tsd.Mean + 3 * tsd.sigma,25,@prec)),
 	  	  	  	 CASE when tsd.Test_Id is null then 0
 	  	  	  	  	 ELSE 1
 	  	  	  	  	 END
            FROM Tests t
            LEFT JOIN Test_Sigma_Data tsd on tsd.Test_Id = t.Test_Id  
            Where t.Var_Id = @Varid and
               t.Result_On >= @LastDataStartTime and t.result_on <= @endtime and
               t.Result Is Not Null
-- I'm loading data starting on StartTime - 2 days. Now, I get the lastvalue before the starttime and delete everything
-- before this date
         Select @LastDataMaxTimeStamp = Max(TimeStamp) From #TestResults Where Var_Id = @VarId and TimeStamp < @StartTime
         If (@LastDataMaxTimeStamp Is NOT NULL)
          Begin
           Delete From #TestResults
            Where Var_Id = @VarId
             And TimeStamp < @LastDataMaxTimeStamp
          End
        GoTo MyLoop1
      End
  Close MyCursor
  Deallocate MyCursor
  Update #Vars
   Set Var_QTT=(Select Count(*) from #TestResults t 
                               where #Vars.Var_id =t.Var_Id And t.TimeStamp >= @StartTime)                        
  --******************************************************   
  --** Resultset #1 - Return Variable Information
  --******************************************************   
 If (@ReturnVariableInfoNew=1)  Select * From #Vars Order By Var_Order
  -- Get Alarms Attached To Data
   Update #TestResults
    Set Alarm_Id = a.Alarm_Id , Alarm_Start_Time = a.Start_Time, Alarm_End_Time = a.End_Time, Alarm_Desc = a.Alarm_Desc
    From #TestResults t
 	 Join Alarms a on a.Key_Id = t.Var_Id and
 	  	  	 t.TimeStamp >= a.Start_Time and (t.TimeStamp < a.End_Time or a.End_Time is NULL)
  -- Get Events Attached To Data
  Update #TestResults
    Set Event_Num = EV.Event_Num
    From #TestResults
    Join Events EV on EV.PU_Id = #TestResults.Master_Id and EV.TimeStamp = #TestResults.TimeStamp and #TestResults.IsEventBased = 1
  -- Get Products Attached To Data, Map Time Based On Spec Activation
Create TABLE #ProdStarts(
   PU_Id int not NULL, 
   Start_Time datetime not NULL, 
   End_Time datetime NULL, 
   Prod_Id int,
   CONSTRAINT P_PU_StartTime PRIMARY KEY (PU_Id, Start_Time)
   ) 
Declare @stime datetime
Declare @etime datetime
Declare @masters table (puid int)
Select @etime = MAX(TimeStamp) from #TestResults
Select @stime = Min(TimeStamp) from #TestResults
Insert into @masters (puid)
Select DISTINCT Master_Id from #TestResults
Insert into #ProdStarts(PU_Id,Start_Time,End_Time,Prod_Id)
  Select pu_id, Start_Time, End_Time, Prod_Id 
  From Production_Starts pss
    join @masters ms on ms.puid = pss.pu_id
      Where (Start_Time <= @etime and (End_Time >= @stime or End_Time is null))
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
  Update #TestResults
    Set Prod_Code = P.Prod_Code
    From #TestResults
    Join Products P on P.Prod_Id = #TestResults.Prod_Id
--****************--
/*
if there is no value retrieved from test_sigma_Data for OLCL,OTCL,OUCL then retrieve from var_specs table and populate
*/
--****************--
;With VarSpecs as 
(
 	 Select distinct Cast(T_control as float) T_control,cast(U_Control as float)U_Control,cast(L_Control as float)L_Control ,vs.Var_id,vs.Prod_Id from Var_Specs vs 
 	 join #TestResults T on T.Var_Id = vs.Var_Id and T.Prod_Id = vs.Prod_Id
 	 where vs.Expiration_Date IS NULL
)
,Alarm_Rules as (
 	 Select ATV.Var_Id,
 	   rd.alarm_spc_rule_id,coalesce (ATV.Sampling_Size, 0) SamplingSize
 	   FROM Alarm_Templates t 
 	   JOIN Alarm_Template_Var_Data ATV on t.AT_Id = ATV.AT_Id
 	   JOIN Variables_Base V on V.Var_Id = ATV.Var_Id
 	   JOIN Prod_Units_Base P on p.PU_Id = v.PU_Id
 	   JOIN alarm_template_spc_rule_data rd on rd.at_Id = t.at_Id
 	   JOIN alarm_template_SPC_rule_property_data rpd on rd.atsrd_id = rpd.atsrd_id
 	   Join Prod_Lines_Base pl on pl.PL_Id = p.PL_Id 
 	   JOIN Departments_Base dp on dp.Dept_Id = pl.Dept_Id 
 	 WHERE V.Var_Id in (Select Var_Id from VarSpecs)
  ) 
,TblwthControlLimits as (Select V.Var_Id, V.Prod_Id,Case when ISNULL(Ar.SamplingSize,0) = 0 AND ISNULL(Ar.Alarm_spc_Rule_Id,0) in (13,14)  AND V.T_Control IS NOT NULL THEN V.T_Control ELSE L_Control + ((U_Control - L_Control) / 2) END Mean_Value,((V.U_control - V.L_Control) / 6)  Sigma_Value from VarSpecs V left outer join Alarm_Rules Ar On Ar.Var_Id = V.Var_id )
UPDATE T
SET 
 	 T.OLCL = CASE WHEN T.OLCL IS NULL THEN ltrim(str(Tl.Mean_Value - 3 * Tl.Sigma_Value,25,V.Var_Precision)) ELSE T.OLCL END,
 	 T.OTCL = CASE WHEN T.OTCL IS NULL THEN ltrim(str(Tl.Mean_Value,25,V.Var_Precision)) ELSE T.OTCL END,
 	 T.OUCL = CASE WHEN T.OUCL IS NULL THEN ltrim(str(Tl.Mean_Value + 3 * Tl.Sigma_Value,25,V.Var_Precision)) ELSE T.OUCL END
from #TestResults T Join TblwthControlLimits Tl on Tl.Var_Id = T.Var_Id and Tl.Prod_Id = T.Prod_Id Join #Vars V on V.Var_Id = T.Var_Id
  --******************************************************   
  --** Resultset #2 - Maximum number of tests
  --******************************************************   
   Select Max(Var_Qtt) from #Vars
  --******************************************************
  --** ResultSet #3 - Last Good values for each variable
  --******************************************************
   Select Distinct v.Var_Id, V.Var_Order, T.TimeStamp, /*T.Value,*/ T.Event_Num, T.Prod_Id, 
        T.Prod_Code,  T.Comment_ID, T.Alarm_Id, T.Alarm_Start_Time, T.Alarm_End_Time, T.Alarm_Desc,
        OLCL = Case When @DecimalSep <> '.' and V.Var_Data_Type_Id = 2 Then Replace (t.OLCL,'.', @DecimalSep) ELSE  t.OLCL END,
        OTCL = Case When @DecimalSep <> '.' and V.Var_Data_Type_Id = 2 Then Replace (t.OTCL,'.', @DecimalSep) ELSE  t.OTCL END,
        OUCL = Case When @DecimalSep <> '.' and V.Var_Data_Type_Id = 2 Then Replace (t.OUCL,'.', @DecimalSep) ELSE  t.OUCL END,
        UseOverRide,
        Value = Case When @DecimalSep <> '.' and V.Var_Data_Type_Id = 2 Then Replace (t.Value, '.', @DecimalSep) Else t.Value End,UseSigmaTable
  From #Vars V inner Join #TestResults T on v.Var_id = T.Var_id
   Where T.TimeStamp < @StartTime
  order by V.var_order, TimeStamp, t.Alarm_Start_Time ASC
  Delete From #TestResults Where TimeStamp < @StartTime
  --******************************************************   
  --** Resultset #4 - Return Test and Spec Information
  --******************************************************   
 Select Distinct v.Var_Id, V.Var_Order, T.TimeStamp, /*T.Value,*/ T.Event_Num, T.Prod_Id, 
        T.Prod_Code,  T.Comment_ID, T.Alarm_Id, T.Alarm_Start_Time, T.Alarm_End_Time, T.Alarm_Desc,
        OLCL = Case When @DecimalSep <> '.' and V.Var_Data_Type_Id = 2 Then Replace (t.OLCL,'.', @DecimalSep) ELSE  t.OLCL END,
        OTCL = Case When @DecimalSep <> '.' and V.Var_Data_Type_Id = 2 Then Replace (t.OTCL,'.', @DecimalSep) ELSE  t.OTCL END,
        OUCL = Case When @DecimalSep <> '.' and V.Var_Data_Type_Id = 2 Then Replace (t.OUCL,'.', @DecimalSep) ELSE  t.OUCL END,
        UseOverRide,
        Value = Case When @DecimalSep <> '.' and V.Var_Data_Type_Id = 2 Then Replace (t.Value, '.', @DecimalSep) Else t.Value End,UseSigmaTable
  From #Vars V Left Outer Join #TestResults T on v.Var_id = T.Var_id
    Where T.Value is not NULL
  order by V.var_order, TimeStamp, t.Alarm_Start_Time ASC
  Drop Table #TestResults
  Drop Table #IDList
  Drop Table #Vars
  Drop Table #ProdStarts
