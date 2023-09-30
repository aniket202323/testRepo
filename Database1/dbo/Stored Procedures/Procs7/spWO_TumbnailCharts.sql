Create Procedure [dbo].[spWO_TumbnailCharts]
@SheetName nVarChar(100),
@StartTime datetime,
@EndTime datetime,
@InTimeZone nVarChar(200)=NULL
AS
--*******************************************
-- For Testing
--Select @SheetName = 'PM1 Backtender Logsheet'
--Select @StartTime = '2001-10-01'
--Select @EndTime = '2001-10-03'
--*******************************************
 	 Select @StartTime =[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)  
 	 Select @EndTime= [dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)  
 -- Get Sheet Information
Create Table #Variables (
  VariableId int,
  VariableOrder int NULL 
)
Declare @SheetId int
Select @SheetId = NULL
Select @SheetId = Sheet_Id 
  From Sheets 
  Where Sheet_Desc = @SheetName
Declare @SheetErr nVarChar(100)
Set @SheetErr = 'SP: Sheet Name ' + @SheetName + ' Not Found'
If @SheetId Is Null
  Raiserror (@SheetErr, 1, 1)
-- Get Sheet Variables
Insert into #Variables
  Select v.Var_Id, sv.Var_Order
    From Sheet_Variables sv 
    Join Variables v on v.var_id = sv.var_id and v.data_type_id in (1,2,6,7) and v.Pu_Id <> 0 
    Where sv.Sheet_Id = @SheetId and
          sv.Var_Id Is Not Null
Declare @UpperRejectColor int
Declare @UpperWarningColor int
Declare @TargetColor int
Declare @LowerWarningColor int
Declare @LowerRejectColor int
Declare @CSId Int
Select @CSId = Value from sheet_Display_options where display_Option_Id = 31 and Sheet_Id = @SheetId
Select @CSId = Coalesce(@CSId,1)
--Select @UpperRejectColor = 141
Select @UpperRejectColor = coalesce(csd.Color_Scheme_Value,csf.Default_Color_Scheme_Color)
From  Color_Scheme_Fields csf  
Left Join Color_Scheme_Data csd On csd.Color_Scheme_Field_Id = csf.Color_Scheme_Field_Id and CS_Id = @CSId
Where   csf.Color_Scheme_Field_Id = 78
Select @LowerRejectColor = @UpperRejectColor
--Select @TargetColor = 79
Select @TargetColor = coalesce(csd.Color_Scheme_Value,csf.Default_Color_Scheme_Color)
From  Color_Scheme_Fields csf  
Left Join Color_Scheme_Data csd On csd.Color_Scheme_Field_Id = csf.Color_Scheme_Field_Id and CS_Id = @CSId
Where   csf.Color_Scheme_Field_Id = 77
--Select @UpperWarningColor = 37
Select @UpperWarningColor = coalesce(csd.Color_Scheme_Value,csf.Default_Color_Scheme_Color)
From  Color_Scheme_Fields csf  
Left Join Color_Scheme_Data csd On csd.Color_Scheme_Field_Id = csf.Color_Scheme_Field_Id and CS_Id = @CSId
Where   csf.Color_Scheme_Field_Id = 79
Select @LowerWarningColor = @UpperWarningColor
--TODO: Get Specification Setting For Comparisons
Declare @SpecSetting Int
Select @SpecSetting = value from site_Parameters where parm_Id = 13 and hostname =''
Select @SpecSetting = Coalesce(@SpecSetting,1) 
Declare @@VariableId int
Declare @MasterUnit int
-- Cursor Through Each Variable
Declare Variable_Cursor Insensitive Cursor 
  For Select VariableId From #Variables Order By VariableOrder
  For Read Only
Open Variable_Cursor
Fetch Next From Variable_Cursor Into @@VariableId
While @@Fetch_Status = 0
  Begin
    Select @MasterUnit = Case When pu.Master_Unit Is Null Then pu.PU_Id Else pu.Master_Unit End
      From Variables v
      Join Prod_Units pu on pu.PU_Id = v.PU_Id
      Where Var_Id = @@VariableId
    -- Return Variable Information First
    Select Id = v.Var_id, LongName = v.Var_Desc, ShortName = v.Test_Name, 
           EngineeringUnits = v.Eng_Units, Unit = pu.PU_Desc
      From Variables v
      Join Prod_Units pu on pu.pu_id = v.pu_id
      Where v.Var_Id = @@VariableId    
    -- Return Variable Data Second
    Select 'Timestamp' =   [dbo].[fnServer_CmnConvertFromDbTime] (t.Result_On,@InTimeZone)  , Value = t.Result, 
           Color = Case 
                     When (@SpecSetting = 1) and (convert(real,t.Result) > convert(real,vs.U_Reject)) Then @UpperRejectColor
                     When (@SpecSetting = 1) and (convert(real,t.Result) < convert(real,vs.L_Reject)) Then @LowerRejectColor
                     When (@SpecSetting = 1) and (convert(real,t.Result) > convert(real,vs.U_Warning)) Then @UpperWarningColor
                     When (@SpecSetting = 1) and (convert(real,t.Result) < convert(real,vs.L_Warning)) Then @LowerWarningColor
                     When (@SpecSetting = 2) and (convert(real,t.Result) >= convert(real,vs.U_Reject)) Then @UpperRejectColor
                     When (@SpecSetting = 2) and (convert(real,t.Result) <= convert(real,vs.L_Reject)) Then @LowerRejectColor
                     When (@SpecSetting = 2) and (convert(real,t.Result) >= convert(real,vs.U_Warning)) Then @UpperWarningColor
                     When (@SpecSetting = 2) and (convert(real,t.Result) <= convert(real,vs.L_Warning)) Then @LowerWarningColor
                     Else
                       @TargetColor
                   End
      From Tests t  
      Join Production_Starts ps on ps.PU_Id = @MasterUnit and ps.Start_Time <= t.Result_On and (ps.End_Time > t.Result_On or ps.End_Time Is Null)
      Left Outer Join Var_Specs vs on vs.Var_Id = @@VariableId and vs.Prod_Id = ps.Prod_Id and vs.effective_date <= t.result_on and (vs.Expiration_Date > t.Result_On or vs.Expiration_Date Is Null)
      Where t.Var_Id = @@VariableId and
            t.Result_On > @StartTime and 
            t.Result_On <= @EndTime and
            t.Result Is Not Null
      Order by [Timestamp]   
    Fetch Next From Variable_Cursor Into @@VariableId
  End
Close Variable_Cursor
Deallocate Variable_Cursor  
Drop Table #Variables
return
