  ---    spGE_GetSheetData 'P1 Sheeter'
Create Procedure dbo.spGE_GetSheetData
@DisplayName nvarchar(50),
@MasterUnit  Int = 0,
@Version 	  	  Int = 0
 AS
Select @Version = isnull(@Version,0)
Declare @Isactive  	 Int,
 	 @SheetType  	 Int,
 	 @SheetId      	 Int,
 	 @PUId         	 Int,
 	 @TimeStamp  	 Datetime,
 	 @IC 	  	 Int,
 	 @MaxCount 	 Int,
 	 @GroupId 	 Int,
 	 @Patterns 	 Int,
 	 @DbTZ 	  	 nvarchar(100),
 	 @Now 	  	 DateTime
select @DbTZ=value from site_parameters where parm_id=192
SELECT @Now = dbo.fnServer_CmnGetDate(GetUTCDate())
Declare @TempUnit Int
Select @TempUnit = Null
Select @TempUnit = Case When value = '' Then Null
 	  	 else value
 	  	 End
 	 From Parameters sp
 	 Join Site_parameters p on p.parm_Id = sp.Parm_Id
        Where  Parm_Name = 'Temporary Unit'
Select @TempUnit = isnull(@TempUnit,0)
  SELECT @PUId = Master_Unit,@IsActive = Is_Active,@SheetType = Sheet_Type,
 	  @SheetId = Sheet_Id,
 	  @IC = Initial_Count,
 	  @Maxcount = Maximum_Count,
 	  @GroupId = Coalesce(s.Group_Id, sg.Group_Id)
    FROM Sheets s
    Left Outer Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id 
    where Sheet_Desc = @DisplayName
  If @MasterUnit Is null or  @MasterUnit = 0
 	 Select @MasterUnit = @PUId
Select @Patterns = Null
-- Patterns not supported at this time
Select @Patterns = Convert(int,value) From Sheet_Display_Options
 	 Where Sheet_id = @SheetId and Display_Option_Id = 6
Declare @PatternPU int
If @Patterns is not null and @Patterns > 0
Select @PatternPU = (Select Min(pei.PU_Id)
 	 From PrdExec_Input_Sources pis
 	 Join PrdExec_Inputs pei  on pis.PEI_Id = pei.PEI_Id
 	 Where pis.PU_Id = @MasterUnit)
-- Patterns not supported at this time
--If @PatternPU Is Null
Select @Patterns = Null
Select @TimeStamp =   Max(Timestamp)
    FROM Events e
     where e.pu_id   = @MasterUnit     and (timestamp Between '01/01/1970' and @Now)
  If @IsActive <> 1 
    Select @PUId = -2
  If @SheetType <> 10 
    Select @PUId = -3
  Declare @PU Table(PU_Id int)
  INsert into @PU (PU_Id) Values (@MasterUnit)
 Select p.PU_Id,EventMask = Coalesce(Event_Mask,''),
 	  	 Prompt = Coalesce(Event_Subtype_Desc,'N/A'),
 	  	 Maximum_Count = @Maxcount,Initial_Count = @IC,Group_Id = @GroupId,
 	  	 UnitTimeZone = isnull(dbo.fnServer_GetTimeZone(p.PU_Id),@DbTZ)
    From @PU p
    Left Join event_configuration ec on ec.PU_Id = p.PU_Id and ec.et_id = 1     -- take out is active
    Left Join Event_Subtypes es   on es.Event_Subtype_Id = ec.Event_Subtype_Id
    where  p.pu_id is not null
 Select Distinct pei.PEI_Id,Input_Name,EventMask = Coalesce(Event_Mask,''),
 	  	 Prompt = Coalesce(Event_Subtype_Desc,'N/A')
 	 From PrdExec_Inputs pei
 	 Join PrdExec_Input_Sources pd on pd.PEI_Id =pei.PEI_Id
 	 Left Join Event_Subtypes es on es.Event_Subtype_Id = pei.Event_Subtype_Id
 	 Where pei.PU_Id = @MasterUnit
--
--Select all possible events for input to subscribe
--
If @Patterns is not null and @Patterns > 0
 Select Distinct pis.PU_Id,PU_Desc
 	 From PrdExec_Inputs pei
 	 Join PrdExec_Input_Sources pis on pis.PEI_Id = pei.PEI_Id
 	 Join Prod_Units pu On pu.PU_Id = pis.pu_Id
 	 Where pei.PU_Id = @MasterUnit and pis.PU_Id <> @TempUnit
union
   Select Distinct pei.PU_Id,PU_Desc
 	 From PrdExec_Input_Sources pis
 	 Join PrdExec_Inputs pei  on pis.PEI_Id = pei.PEI_Id
 	 Join Prod_Units pu On pu.PU_Id = pei.pu_Id
 	 Where pis.PU_Id = @MasterUnit and pei.PU_Id <> @TempUnit
else
 Select Distinct pis.PU_Id,PU_Desc
 	 From PrdExec_Inputs pei
 	 Join PrdExec_Input_Sources pis on pis.PEI_Id = pei.PEI_Id
 	 Join Prod_Units pu On pu.PU_Id = pis.pu_Id
 	 Where pei.PU_Id = @MasterUnit and pis.PU_Id <> @TempUnit
Declare @CurrentEvent Int,
 	  	 @IsCurrent 	   Int
Select @CurrentEvent = Null
Select @CurrentEvent = Event_Id,@IsCurrent = Case When Start_Time = @TimeStamp then 1 Else 0 End
 From Events e
 Where  e.pu_id   = @MasterUnit and  Timestamp = @TimeStamp
If @CurrentEvent is not null
 	 Select @TimeStamp = Max(TimeStamp) From Events where TimeStamp < @TimeStamp and pu_id = @MasterUnit
Declare @PrevId Int
Select @PrevId = Event_Id 
 	 From Events e
 	 Where  e.pu_id   = @MasterUnit and  Timestamp = @TimeStamp
Select Event_Id = Coalesce(@PrevId,0),CurrentEventId = coalesce(@CurrentEvent,-2),IsCurrent = Coalesce(@IsCurrent,0)
Declare @Options Table(Display_Option_Id Int,value Varchar(7000),Binary_Id Int,DisplayOptionDesc nvarchar(100))
Insert INto @Options (Display_Option_Id ,value,Binary_Id,DisplayOptionDesc)
     Select st.Display_Option_Id,[value] = case when sdo.Display_Option_Id = 160 then
 	  	  	  	  	  	  	  	  	  	 (Select convert(nvarchar(25),Color) From Colors where Color_Id = Value)
 	  	  	  	  	  	  	  	  	    When st.Display_Option_Id = 6 and   @Patterns is null then null
 	  	  	  	  	  	  	  	  	    When Value is null then Display_Option_Default
 	                                    Else 	  	 Value
 	  	  	           End ,Binary_Id,Display_Option_Desc
 	 From Sheet_Type_Display_Options st
    Left Join Sheet_Display_Options sdo on  Sheet_id = @SheetId and st.Display_Option_Id = sdo.Display_Option_Id
 	 Join Display_Options do on do.Display_Option_Id = st.Display_Option_Id
    Where st.Sheet_Type_Id = @SheetType
-- remove any options
Declare @tempVal Varchar(7000),@StartPos Int
  If @version = 0 
 	 Begin
  	    Select @tempVal = value from @Options where Display_Option_Id = 159
 	   If @tempVal is not null
 	  	 Begin
 	  	  	 select @StartPos = 0
 	  	  	 Select @StartPos = charindex(char(2),@tempVal)
 	  	  	 If @StartPos > 0
 	  	  	  	 Begin
  	    	    	    	    Update  @Options set Value = Left(@tempVal, @StartPos -1) where  Display_Option_Id = 159
 	  	  	  	 End
 	  	 end
 	 end
  IF @MasterUnit <> @PUId and @MasterUnit <> 0 and @version <> 0
    Update @Options set Value = Sheet_Unit.Value
 	   From Sheet_Unit
 	   Where Sheet_Unit.Sheet_Id = @SheetId and Sheet_Unit.PU_Id = @MasterUnit and Display_Option_Id = 159
  Select * from @Options Where value is not Null
--
--Select all possible events Statuses for rollmap
--
If @Patterns is not null and @Patterns > 0
 Select Distinct pis.PU_Id,pisd.Valid_Status
 	 From PrdExec_Inputs pei
 	 Join PrdExec_Input_Sources pis on pis.PEI_Id = pei.PEI_Id
 	 join PrdExec_Input_Source_Data pisd on pisd.PEIS_Id= pis.PEIS_Id
 	 Where pei.PU_Id = @MasterUnit and pis.PU_Id <> @TempUnit
 Union
 Select Distinct pis.PU_Id,pisd.Valid_Status
 	 From PrdExec_Inputs pei
 	 Join PrdExec_Input_Sources pis on pis.PEI_Id = pei.PEI_Id
 	 join PrdExec_Input_Source_Data pisd on pisd.PEIS_Id= pis.PEIS_Id
 	 Where pei.PU_Id = @PatternPU and pis.PU_Id <> @TempUnit
 	 order by pis.PU_Id
Else
 Select Distinct pis.PU_Id,pisd.Valid_Status
 	 From PrdExec_Inputs pei
 	 Join PrdExec_Input_Sources pis on pis.PEI_Id = pei.PEI_Id
 	 join PrdExec_Input_Source_Data pisd on pisd.PEIS_Id= pis.PEIS_Id
 	 Join Prod_Units pu On pu.PU_Id = pis.pu_Id
 	 Where pei.PU_Id = @MasterUnit and pis.PU_Id <> @TempUnit
 	 order by pis.PU_Id    
If @Patterns is not null and @Patterns > 0
 	 Select @PatternPU as PU_Id
 Select DimAName = Dimension_A_Name,DimXName = Dimension_X_Name,
 	 DimYName = Dimension_Y_Name,DimZName = Dimension_Z_Name
    From Prod_Units p
    Left Join event_configuration ec on ec.PU_Id = p.PU_Id and ec.et_id = 1
    Left Join Event_Subtypes es   on es.Event_Subtype_Id = ec.Event_Subtype_Id
    where  p.pu_id = @MasterUnit
 Select Sheet_Id = @SheetId, Group_Id = coalesce(@GroupId,0)
 Select Distinct p.PU_Id,atd.Var_Id
 	  	 From  Alarm_Template_Var_Data atd
 	  	 Join  variables v on v.Var_Id = atd.Var_Id
 	  	 Join Prod_Units p ON p.PU_Id = v.Pu_Id
 	  	 Where v.pu_Id  = @MasterUnit
 Select Distinct Unit_Desc = pu.PU_Desc,pu.PU_Id
 	  from Prod_Units pu
 	 Where Pu_Id in (Select PU_Id From Sheet_Unit Where Sheet_Id = @SheetId) or pu.PU_Id = @PUId
