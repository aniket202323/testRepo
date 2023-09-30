CREATE PROCEDURE dbo.spEM_GetSheetInformation 
@SheetId  int  
AS
/* ##### spEM_GetSheetInformation #####
Description 	 : Fetches all information related to Sheet while showing display options in PA Admin
Creation Date 	 : NA
Created By 	 : NA
#### Update History ####
DATE 	  	  	  	 Modified By 	  	 UserStory/Defect No 	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018/02/08 	 Prasad 	  	  	  	  	  	  	  	  	  	  	  	  	 Added Alias column for Title Activity
*/
Declare @Sheet_Type Integer,
 	     @Event_Type Integer,
 	     @Autolabel 	 Integer,
     	 @PLId 	  	 int,
 	  	 @IsDefault 	 Int,
 	  	 @Master_Unit Int,
 	  	 @PEI_Id 	  	  Int,
 	  	 @DefaultSheetId 	 Int,
        @Filter nvarchar(50),
        @SQL nvarchar(1000),
        @IncludeActivities Int,
 	  	 @DisplayActivityType Int,
 	  	 @ActivitiesperTitle int
DECLARE @UnitOnSheetAlready Table(PUId Int)
DECLARE @LineOnSheetAlready Table(PLId Int)
DECLARE @SkippedParameters TABLE (SkippedId Int)
--DECLARE @PreRelease Int
SELECT @Sheet_Type = Sheet_Type,@Event_Type = Event_Type,@Autolabel = Auto_Label_Status,@PLId = PL_Id,@PEI_Id = PEI_Id,@Master_Unit = Master_Unit
 FROM Sheets  
 Where sheet_Id = @SheetId
If @Sheet_Type is null
 	 Begin
-- 	   sheetype = autolog 1 - for time - 2 for event eventtype 0 = 1 sheet type 
 	   Select @Sheet_Type =  @Event_Type + 1
 	 End
--SELECT @PreRelease = CONVERT(Int, COALESCE(Value, '0')) 
-- 	 FROM Site_Parameters 
-- 	 WHERE Parm_Id = 608
--SELECT @PreRelease = Coalesce(@PreRelease,0)
/* Roll Map */
INSERT INTO @SkippedParameters(SkippedId) VALUES(83)
INSERT INTO @SkippedParameters(SkippedId) VALUES(84)
INSERT INTO @SkippedParameters(SkippedId) VALUES(85)
INSERT INTO @SkippedParameters(SkippedId) VALUES(86)
INSERT INTO @SkippedParameters(SkippedId) VALUES(87)
INSERT INTO @SkippedParameters(SkippedId) VALUES(88)
INSERT INTO @SkippedParameters(SkippedId) VALUES(89)
INSERT INTO @SkippedParameters(SkippedId) VALUES(160)
/* End Of Roll Map  */
--IF @PreRelease = 0
--BEGIN
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(444)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(445)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(446)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(447)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(448)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(449)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(450)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(451)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(452)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(453)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(454)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(455)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(456)
-- 	 INSERT INTO @SkippedParameters(SkippedId) VALUES(457)
--END
--ELSE
--BEGIN
 	 SELECT  @IncludeActivities = so.Value 
 	 FROM Sheet_Display_Options so 
 	 JOIN Sheet_Type_Display_Options std on std.Sheet_Type_Id = @Sheet_Type And std.Display_Option_Id = so.Display_Option_Id
 	 where so.sheet_Id = @SheetId AND so.Display_Option_Id = 444
 	 SET @IncludeActivities = Coalesce(@IncludeActivities,0)
 	 IF @IncludeActivities = 0
 	 BEGIN
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(445)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(446)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(447)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(448)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(449)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(450)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(451)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(452)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(453)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(454)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(455)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(456)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(457)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(459)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(460)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(461)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(462)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(463)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(464)
 	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(465)
 	 END
 	 ELSE
 	 BEGIN
 	  	 SET @IncludeActivities = 0
 	  	 SELECT  @IncludeActivities = so.Value 
 	  	 FROM Sheet_Display_Options so 
 	  	 JOIN Sheet_Type_Display_Options std on std.Sheet_Type_Id = @Sheet_Type And std.Display_Option_Id = so.Display_Option_Id
 	  	 where so.sheet_Id = @SheetId AND so.Display_Option_Id = 445
 	  	 SET @IncludeActivities = Coalesce(@IncludeActivities,0)
 	  	 IF @IncludeActivities = 1
 	  	 BEGIN
 	  	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(447)
 	  	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(448)
 	  	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(450)
 	  	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(460)
 	  	 END
 	  	 --check for custom form setting
 	  	 SET @ActivitiesperTitle =0
 	  	 SET @DisplayActivityType = 0
 	  	 SELECT  @ActivitiesperTitle = so.Value 
 	  	 FROM Sheet_Display_Options so 
 	  	 JOIN Sheet_Type_Display_Options std on std.Sheet_Type_Id = @Sheet_Type And std.Display_Option_Id = so.Display_Option_Id
 	  	 where so.sheet_Id = @SheetId AND so.Display_Option_Id = 445
 	  	 SET @ActivitiesperTitle = Coalesce(@ActivitiesperTitle,0)
 	  	 SELECT  @DisplayActivityType = so.Value 
 	  	 FROM Sheet_Display_Options so 
 	  	 JOIN Sheet_Type_Display_Options std on std.Sheet_Type_Id = @Sheet_Type And std.Display_Option_Id = so.Display_Option_Id
 	  	 where so.sheet_Id = @SheetId AND so.Display_Option_Id = 461
 	  	 SET @DisplayActivityType = Coalesce(@DisplayActivityType,0)
 	  	 IF @DisplayActivityType = 0 OR (@DisplayActivityType = 1 AND @ActivitiesperTitle = 1)
 	  	 BEGIN
 	  	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(462)
 	  	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(463)
 	  	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(464)
 	  	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(465)
 	  	 END
 	  	 
 	  	 IF @DisplayActivityType = 1
 	  	 BEGIN
 	  	  	 INSERT INTO @SkippedParameters(SkippedId) VALUES(449)
 	  	 END
 	 END
--END
  Select @IsDefault = 0
  If @Sheet_Type = 2 and  @Master_Unit is not null
   Begin
 	  Select @DefaultSheetId = Def_Event_Sheet_Id from Prod_Units where PU_Id = @Master_Unit
 	  If @DefaultSheetId = @SheetId 
 	  	 Select @IsDefault = 1
   End
  IF @Sheet_Type = 19 and @PEI_Id is not null
   Begin
 	 Select @DefaultSheetId = Def_Event_Comp_Sheet_Id from PrdExec_inputs where PEI_ID = @PEI_Id
 	 If @DefaultSheetId = @SheetId 
 	  	 Select @IsDefault = 1
   End
  select s.*,Binary_Id = so.Binary_Id,IsDefault = @IsDefault,IncludeActivities = @IncludeActivities,
  DisplayActivityType = @DisplayActivityType,ActivitiesperTitle = @ActivitiesperTitle
    from sheets s
    Left Join Sheet_Display_Options so on so.Sheet_Id = s.sheet_Id and so.Display_Option_Id = 5 
    where s.sheet_Id = @SheetId
IF @Sheet_Type = 10
     	 Select p.PL_Id,PL_Desc,p.PU_Id,PU_Desc
 	  	  From Prod_Units p 
 	  	  Join Prod_Lines pl ON pl.PL_Id =p.PL_Id
 	  	  Where master_unit is null and p.PU_Id <> (Select Master_Unit from Sheets Where Sheet_Id = @SheetId)
 	  	  Order by PL_Desc,PU_Order,PU_Desc  
  Else IF @Sheet_Type in (8,14,11)
 	    	 Select p.PL_Id,PL_Desc,p.PU_Id,PU_Desc
 	  	  From Prod_Units p 
 	  	  Join Prod_Lines pl ON pl.PL_Id =p.PL_Id
 	  	  Where master_unit is null
 	  	  Order by PL_Desc,PU_Order,PU_Desc
  Else IF @Sheet_Type = 30
 	 BEGIN
 	  	 INSERT INTO @UnitOnSheetAlready(PUId) 
 	  	  	 SELECT su.PU_Id 
 	  	  	 From Sheet_Unit su
 	  	  	 JOIN Sheets s ON s.Sheet_Id = su.Sheet_Id 
 	  	  	 Where s.Sheet_Type = @Sheet_Type and su.Sheet_Id <> @SheetId
 	  	 INSERT INTO @LineOnSheetAlready(PLId) 
 	  	  	 SELECT s.PL_Id 
 	  	  	 FROM Sheets s 
 	  	  	 Where s.Sheet_Type = @Sheet_Type  and s.Sheet_Id <> @SheetId
 	  	 INSERT INTO @UnitOnSheetAlready(PUId) 
 	  	  	 SELECT pu.PU_Id 
 	  	  	 From Prod_Units pu
 	  	  	 JOIN @LineOnSheetAlready s ON pu.PL_Id = s.PLId 
 	  	 Select p.PL_Id,PL_Desc,p.PU_Id,PU_Desc
 	  	  From Prod_Units p 
 	  	  Join Prod_Lines pl ON pl.PL_Id =p.PL_Id
 	  	  Left Join @UnitOnSheetAlready s on s.PUId  = p.Pu_Id 
 	  	  Where p.master_unit is null  and s.PUId Is null
 	  	  Order by PL_Desc,PU_Order,PU_Desc
 	  END
Else IF  @Sheet_Type = 15
 	    	 Select p.PL_Id,PL_Desc,p.PU_Id,PU_Desc
 	  	  From Prod_Units p 
 	  	  Join Prod_Lines pl ON pl.PL_Id =p.PL_Id
 	  	  Where master_unit is null and pl.PL_Id = @PLId and Timed_Event_Association > 0
 	  	  Order by PL_Desc,PU_Order,PU_Desc
  Else IF @Sheet_Type =  27
 	    	 Select p.PL_Id,PL_Desc,p.PU_Id,PU_Desc
 	  	  From Prod_Units p 
 	  	  Join Prod_Lines pl ON pl.PL_Id =p.PL_Id
 	  	  Where master_unit is null and p.Non_Productive_Category is not Null
 	  	  Order by PL_Desc,PU_Order,PU_Desc
 	 Else IF  @Sheet_Type = 17
 	    	 Select pl.PL_Id,pl.PL_Desc,pp.Path_Id,Path_Code
 	  	  From PrdExec_Paths pp
 	  	  Join Prod_Lines pl ON pl.PL_Id =pp.PL_Id
 	  	  Order by pl.PL_Desc,Path_Code
 	 else if @Sheet_Type = 28
 	  	 Select p.PL_Id,PL_Desc,p.PU_Id,PU_Desc
 	  	  From Prod_Units p 
 	  	  Join Prod_Lines pl ON pl.PL_Id =p.PL_Id
 	  	  join event_configuration ec on ec.pu_id = p.pu_id and ec.et_id = 2 
 	  	  Where master_unit is null
 	  	  Order by PL_Desc,PU_Order,PU_Desc
 	 else if @Sheet_Type = 29
 	  	 Select p.PL_Id,PL_Desc,p.PU_Id,PU_Desc
 	  	  From Prod_Units p 
 	  	  Join Prod_Lines pl ON pl.PL_Id =p.PL_Id
 	  	  join event_configuration ec on ec.pu_id = p.pu_id and ec.et_id = 3
 	  	  Where master_unit is null
 	  	  Order by PL_Desc,PU_Order,PU_Desc
ELSE -- empty result set
    Select *  From variables  Where PU_Id is null
 	 
If @Sheet_Type in( 8 ,14,15,10 ,27 ,28,29,30)
   Select * from Sheet_Unit  Where sheet_id  = @SheetId 
Else If @Sheet_Type = 17
   Select * from Sheet_Paths  Where sheet_id  = @SheetId 
Else If @Sheet_Type = 11 --Alarm display has both Units and Variables so return 2 results sets
 Begin
   Select * from Sheet_Unit  Where sheet_id  = @SheetId 
   Select v.Var_Id,V.Ds_Id,v.pVar_Id,v.var_Desc,pu.PU_Desc,pug.PUG_Desc,pl.PL_Desc,sv.Var_Order,sv.Title
 	   From Sheet_Variables sv
   	 Left Join Variables v on v.var_Id = sv.Var_Id
 	   Left Join Prod_Units pu on PU.PU_Id = v.PU_Id
   	 Left Join PU_Groups pug on v.PUG_Id = pug.PUG_Id
 	   Left Join Prod_Lines pl on pl.PL_Id = pu.PL_Id
   	 Where sv.sheet_id  = @SheetId
 	   order by Var_Order
 End
Else
 Select v.Var_Id,V.Ds_Id,v.pVar_Id,v.var_Desc,pu.PU_Desc,pug.PUG_Desc,pl.PL_Desc,sv.Var_Order,sv.Title,
 	 Activity_Order = Coalesce(Activity_Order,0),Target_Duration = Coalesce(Target_Duration,0),Execution_Start_Duration = Coalesce(Execution_Start_Duration,0)
 	 ,ISNULL(sv.Activity_Alias,'') Activity_Alias --<Changed by Prasad: Added Activity_Alias column>
 	 ,AutoComplete_Duration = coalesce(AutoComplete_Duration,0) --<KP : Added Autocomplete duration>
 	 ,External_URL_Link=ISNULL(External_URL_Link,''),Open_URL_Configuration=coalesce(Open_URL_Configuration,0),User_Login=ISNULL(User_Login,''),Password=ISNULL(Password,'') --<KP : Added new columns>
 	 From Sheet_Variables sv
 	 Left Join Variables v on v.var_Id = sv.Var_Id
 	 Left Join Prod_Units pu on PU.PU_Id = v.PU_Id
 	 Left Join PU_Groups pug on v.PUG_Id = pug.PUG_Id
 	 Left Join Prod_Lines pl on pl.PL_Id = pu.PL_Id
 	 Where sv.sheet_id  = @SheetId
 	 order by Var_Order
If @Autolabel Is not Null and @Sheet_Type in(Select Sheet_Type_Id From Sheet_Type_Display_Options Where Display_Option_Id = 12)
 	 If (Select Count(*) From Sheet_Display_Options Where Sheet_Id = @SheetId and Display_Option_Id = 12) = 0
 	  	 Insert Into Sheet_Display_Options ( Sheet_Id,Display_Option_Id,Value) Values (@SheetId,12,@Autolabel)
  Create Table #Temp ([Id] Int,[Desc] nVarChar(100))
IF @Sheet_Type = 14 or @Sheet_Type = 28 or @Sheet_Type = 29 --SOE
 Begin
  Declare @PUId int,@StrPU varchar(7000)
  Select @StrPU = ''
  Declare c cursor For select Pu_Id from prod_units where pu_Id <> 0
  Open c
  FetchC:
  Fetch next from c into @PUId
  If @@Fetch_Status  = 0
    Begin
     Select @StrPU = @StrPU + Convert(nVarChar(10),@PUId) + ','
 	  If Len(@StrPU) > 6950
 	    Begin
 	  	  Insert INto  #Temp   Execute spCmn_GetEventSubEventByUnit null, @StrPU,1
 	  	  Select @StrPU = ''
 	    End
     GoTo FetchC
    End
  Close c
  Deallocate c
  If @StrPU <> ''
    Insert INto  #Temp   Execute spCmn_GetEventSubEventByUnit null, @StrPU,1
 End
  Declare @DisplayUnboundOrders bit
  Select @DisplayUnboundOrders = Value
    From Sheet_Display_Options
    Where Sheet_Id = @SheetId
    And Display_Option_Id = 47
  Create Table #ScheduleFilters (SF_Id int, SF_Desc nVarChar(100), SF_Key_Id int, SF_Type nvarchar(50))
  Insert Into #ScheduleFilters (SF_Id, SF_Desc, SF_Key_Id, SF_Type)
    exec spSV_GetSchedFilters @SheetId, NULL, NULL, NULL, @DisplayUnboundOrders
  Select doc.Display_Option_Category_Desc,st.Display_Option_Id,d.Display_Option_Desc,d.Display_Option_Long_Desc,
         d.Field_Type_Id,[Value] = Coalesce(s.Value, st.Display_Option_Default),ft.Field_Type_Desc,ft.Store_Id,Value_Text = 
 	 CASE 	 When  Field_Type_Id = 22 and Coalesce(s.Value, st.Display_Option_Default) = 1 Then "TRUE"
 	  	  	 When  Field_Type_Id = 22 and Coalesce(s.Value, st.Display_Option_Default) = 0 Then "FALSE"
 	  	  	 When  Field_Type_Id = 8 Then (Select ST_Desc From Sampling_Type Where ST_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 9 Then (Select Pu_Desc From Prod_Units Where pu_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 80 Then (Select Pu_Desc From Prod_Units Where pu_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 10 Then (Select Var_Desc From Variables Where Var_Id = Coalesce(s.Value, st.Display_Option_Default) and Var_id > 0)
 	  	  	 When  Field_Type_Id = 13 Then (Select WET_Name From Waste_Event_Type Where WET_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 14 Then (Select WEMT_Name From Waste_Event_Meas Where WEMT_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 15 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 16 Then (Select ProdStatus_Desc From Production_Status Where ProdStatus_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 23 Then (Select Char_Desc From Characteristics Where Char_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 24 Then (Select CS_Desc From Color_Scheme Where CS_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 25 Then (Select Binary_Desc From binaries Where Binary_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 27 Then (Select [Desc] From #Temp Where Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 29 Then (Select Tree_Statistic_Desc From Tree_Statistics Where Tree_Statistic_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 30 Then (Select AL_Desc From Access_Level Where Al_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 33 Then (Select Sheet_Desc From Sheets where Sheet_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 34 Then (Select Color_Desc From Colors Where Color_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 39 Then (Select Tree_Name From Event_Reason_Tree Where Tree_Name_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 40 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When  Field_Type_Id = 52 Then (Select SF_Desc From #ScheduleFilters Where SF_Desc = Coalesce(s.Value, st.Display_Option_Default))
 	  	  	 When Field_Type_Id IN(28,31,38,41,42,43,45,46,47,48,49,50,55,64,77,78,81,82,83,84) Then
               (Select [Desc] = Field_Desc From ED_FieldType_ValidValues Where ED_Field_Type_Id = Field_Type_Id and Field_Id = Coalesce(s.Value, case when Field_Type_Id = 84 then 0 else st.Display_Option_Default end))
  	       Else  Coalesce(s.Value, st.Display_Option_Default)
        End,ft.sp_Lookup,Display_Option_Access_Id, st.Display_Option_Min, st.Display_Option_Max, st.Display_Option_Required, Is_Esignature = Coalesce(d.Is_Esignature, 0)
 From Sheet_Type_Display_Options st
 Join display_options d on d.Display_Option_Id = st.Display_Option_Id
 Left Join Sheet_Display_Options s on s.Display_Option_Id = st.Display_Option_Id and s.Sheet_Id = @SheetId
 Left Join Ed_FieldTypes ft on ft.Ed_Field_Type_Id = d.Field_Type_Id
 Left Join Display_Option_Categories doc On doc.Display_Option_Category_Id = d.Display_Option_Category_Id
 where st.Sheet_Type_Id = @Sheet_Type and st.Display_Option_Id not in (SELECT SkippedId  FROM @SkippedParameters)
   and  Display_Option_Access_Id <> 3
 order by doc.Display_Option_Category_Desc,d.Display_Option_Desc
 Drop Table #Temp
 Drop Table #ScheduleFilters
If @Sheet_Type = 6 OR @Sheet_Type = 18
 Begin
   Select SPC_Trend_Type_Id,SPC_Trend_Type_Desc,Var1_Label,Var2_Label = Coalesce(Var2_Label,'') from spc_trend_types
   Select Var_Id1,Var_Id2,Var_Id3,Var_Id4,Var_Id5,SPC_Trend_Type_Id,Plot_Order,
 	 VarDesc1 = v.Var_Desc,VarDesc2 = Coalesce(v1.Var_Desc,''),VarDesc3 = Coalesce(v2.Var_Desc,''),
 	 VarDesc4 = Coalesce(v3.Var_Desc,''),VarDesc5 = Coalesce(v4.Var_Desc,'')
 	 From Sheet_Plots s
 	 Left Join Variables v on v.Var_Id = Var_Id1
 	 Left Join Variables v1 on v1.Var_Id = Var_Id2
 	 Left Join Variables v2 on v2.Var_Id = Var_Id3
 	 Left Join Variables v3 on v3.Var_Id = Var_Id4
 	 Left Join Variables v4 on v4.Var_Id = Var_Id5
    Where s.sheet_Id = @SheetId
 End
If @Sheet_Type = 10
 Begin
   Select pu.PU_Id,PL_Desc,PU_Desc,sgd.Display_Sheet_Id,[Sheet] = coalesce(s.Sheet_Desc,"<none>")
 	 From Prod_Units pu
 	 Join Prod_Lines pl on pl.PL_ID = pu.PL_ID
 	 Left Join Sheet_Genealogy_Data sgd on sgd.pu_Id = pu.pu_Id and sgd.Sheet_Id = @SheetId
 	 Left Join Sheets s on s.Sheet_Id = sgd.Display_Sheet_Id
 	 Where pu.Master_Unit is null and pu.pu_Id <> 0
 	 Order By PL_Desc,PU_Desc
 End
If @Sheet_Type = 14 --SOE
 Begin
      Create Table #ET
      (
      ET_Id int NULL,
      ET_Desc nvarchar(50) NULL,
      Selected int NULL,
      )
/*
 Alarms are special case. Although there is only one record on event_type, you have to handle each different 
 alarm priory level (low, medium, high) as a different event_type
*/
      Declare @AlarmEventDescription nVarChar(100),
              @AlarmSubTypesApply int,
              @AlarmEventModels int
      Select @AlarmEventDescription = Et_Desc From Event_Types Where ET_ID = 11
      If (Select IncludeOnSoe From Event_Types where ET_Id = 11) = 1
        Begin
          Insert Into #ET Values (11, @AlarmEventDescription + ' Low',1)
          Insert Into #ET Values (12, @AlarmEventDescription + ' Medium',1)
          Insert Into #ET Values (13, @AlarmEventDescription + ' High',1)
          Select @AlarmSubTypesApply = SubTypes_Apply,
            @AlarmEventModels = Event_Models
          From Event_Types 
          Where Event_Types.ET_Id = 11
        End
      Insert Into #ET
        Select ET_Id, ET_Desc, 1
        From Event_Types
        Where Et_id<>11
        And IncludeOnSOE=1
--  Filter out selected event types from the Display Option
      Select @Filter = NULL
      Select @Filter = Value from Sheet_Display_Options
        Where Sheet_Id = @SheetId and Display_Option_id = 382
      If @Filter is not NULL
        Begin
          Select @SQL = 'Update #ET Set Selected = 0 where ET_Id in (' + @Filter + ')'
--          Select @SQL as Scott
          Execute (@SQL)
        End
      Select ET_Id, ET_Desc, Selected from #ET oRDER BY et_ID  
      Drop table #ET
 End
IF @Sheet_Type = 30 -- Need Units
BEGIN
 	 SELECT PL_Id,PL_Desc
 	  	 FROM Prod_Lines pl
 	  	 Left Join @LineOnSheetAlready las on las.PLId = pl.PL_Id 
 	  	 WHERE las.PLId is null
END
