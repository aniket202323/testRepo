CREATE PROCEDURE dbo.spServer_CmnAlarmDesc
@ATDId int,
@Desc nVarChar(1000) OUTPUT,
@ATSRD_Id int = NULL,
@ATVRD_Id int = NULL
AS
set NoCount On
/*
declare @Desc nvarchar(50)
exec spServer_CmnAlarmDesc 509, @Desc OUTPUT
select @Desc as 'Config Desc'
select @Desc = ''
exec spServer_CmnAlarmDesc 509, @Desc OUTPUT, 28
select @Desc as 'Control Desc'
*/
Declare 
  @Line  nVarChar(1000), 
  @Unit  nVarChar(1000), 
  @Var   nVarChar(1000), 
  @Limit nVarChar(1000), 
  @Temp  nVarChar(1000), 
  @Custm nVarChar(1000),
  @UseLine bit, 
  @UseUnit bit, 
  @UseVar bit, 
  @UseLimit bit, 
  @UseTemp bit, 
  @Alarm_Type_Id int
set @Desc  = ''
set @Line  = '' 
set @Unit  = ''
set @Var   = ''
set @Limit = ''
set @Temp  = ''
Select
  @UseLine       = Use_Line_Desc, 
  @UseUnit       = Use_Unit_Desc, 
  @UseVar        = Use_Var_Desc, 
  @UseLimit      = Use_Trigger_Desc,
  @UseTemp       = Use_AT_Desc, 
  @Custm         = COALESCE(Custom_Text,''),
  @Alarm_Type_Id = Alarm_Type_Id
 From Alarm_Template_Var_Data d
 Join Alarm_Templates a on a.AT_Id = d.AT_Id
 Where ATD_Id = @ATDId
If (@UseLine = 0 and @UseUnit = 0 and @UseVar = 0 and @UseLimit = 0 and @UseTemp = 0 and @Custm = '')
 	 set @UseTemp = 1
If (@UseLine = 1 or @UseUnit = 1 or @UseVar = 1)
  Select
    @Line = COALESCE(l.PL_Desc, ''),
    @Unit = COALESCE(u.PU_Desc, ''),
    @Var  = COALESCE(v.Var_Desc, '') 
    From Alarm_Template_Var_Data vd 
    Join Variables_Base   v on v.Var_Id  = vd.Var_Id
    Join Prod_Units  u on u.PU_Id   = v.PU_Id
    Join Prod_Lines  l on l.PL_Id   = u.PL_Id
    Where ATD_Id = @ATDId
if (@UseLine = 0)
  set @Line = ''
if (@UseUnit = 0)
  set @Unit = ''
if (@UseVar = 0)
  set @Var = ''
If @UseLimit = 1
  BEGIN 
    If @Alarm_Type_Id = 1
      BEGIN
        --Determine "Actual" Trigger Description For Variable Alarm
        Select @Limit = r.Alarm_Variable_Rule_Desc
        From Alarm_Variable_Rules r
        Join Alarm_Template_Variable_Rule_Data rd on rd.Alarm_Variable_Rule_Id = r.Alarm_Variable_Rule_Id
        Where rd.ATVRD_Id = @ATVRD_Id
        Select @Limit = isnull(@Limit,'')
      END
    Else
      BEGIN
        --Determine "Actual" Trigger For SPC Alarm
--        Select @Limit = REPLACE(r.Alarm_SPC_Rule_Desc, 'n ', pd.value + ' ')
--        From Alarm_SPC_Rules r
--        Join Alarm_Template_SPC_Rule_Data rd on rd.Alarm_SPC_Rule_Id = r.Alarm_SPC_Rule_Id
--        Join Alarm_Template_SPC_Rule_Property_Data pd on pd.ATSRD_Id = rd.ATSRD_Id
--        Join Alarm_SPC_Rule_Properties rp on rp.Alarm_SPC_Rule_Property_Id = pd.Alarm_SPC_Rule_Property_Id
--        Where rd.ATSRD_Id = @ATSRD_Id
        Select @Limit = REPLACE(REPLACE(r.Alarm_SPC_Rule_Desc, 'n ', pd.value + ' '), 'm ', Convert(nVarChar(25), pd.mValue) + ' ')
        From Alarm_SPC_Rules r
        Join Alarm_Template_SPC_Rule_Data rd on rd.Alarm_SPC_Rule_Id = r.Alarm_SPC_Rule_Id
        Join Alarm_Template_SPC_Rule_Property_Data pd on pd.ATSRD_Id = rd.ATSRD_Id
        Join Alarm_SPC_Rule_Properties rp on rp.Alarm_SPC_Rule_Property_Id = pd.Alarm_SPC_Rule_Property_Id
        Where rd.ATSRD_Id = @ATSRD_Id
        If ltrim(rtrim(@Limit)) = ''
          BEGIN
             --Determine "Top Priority" Trigger For SPC Alarm Template
--            Select @Limit = REPLACE(r.Alarm_SPC_Rule_Desc, 'n ', pd.value + ' ')
--            From Alarm_Template_Var_Data v
--            Join Alarm_Templates t on t.AT_Id = v.AT_Id
--            Join Alarm_Template_SPC_Rule_Data rd on rd.AT_Id = t.AT_Id
--            Join Alarm_SPC_Rules r on r.Alarm_SPC_Rule_Id = rd.Alarm_SPC_Rule_Id
--            Join Alarm_Template_SPC_Rule_Property_Data pd on pd.ATSRD_Id = rd.ATSRD_Id
--            Join Alarm_SPC_Rule_Properties rp on rp.Alarm_SPC_Rule_Property_Id = pd.Alarm_SPC_Rule_Property_Id
--            Where v.ATD_Id = @ATDId and rd.Firing_Priority = 1
            Select @Limit = REPLACE(REPLACE(r.Alarm_SPC_Rule_Desc, 'n ', pd.value + ' '), 'm ', Convert(nVarChar(25), pd.mValue) + ' ')
            From Alarm_Template_Var_Data v
            Join Alarm_Templates t on t.AT_Id = v.AT_Id
            Join Alarm_Template_SPC_Rule_Data rd on rd.AT_Id = t.AT_Id
            Join Alarm_SPC_Rules r on r.Alarm_SPC_Rule_Id = rd.Alarm_SPC_Rule_Id
            Join Alarm_Template_SPC_Rule_Property_Data pd on pd.ATSRD_Id = rd.ATSRD_Id
            Join Alarm_SPC_Rule_Properties rp on rp.Alarm_SPC_Rule_Property_Id = pd.Alarm_SPC_Rule_Property_Id
            Where v.ATD_Id = @ATDId and rd.Firing_Priority = 1
          END
      END           
  END
If @UseTemp = 1 
  Select @Temp = COALESCE(AT_Desc, '') 
    From Alarm_Template_Var_Data d 
    Join Alarm_Templates t on t.AT_Id = d.AT_Id
    Where ATD_Id = @ATDId
Select @Desc = LTRIM(RTRIM(@Line))
Select @Desc = @Desc + LTRIM(RTRIM(CASE WHEN @Unit  = '' THEN '' ELSE CASE WHEN @Desc = '' THEN @Unit  ELSE '-' + @Unit  END END ))
Select @Desc = @Desc + LTRIM(RTRIM(CASE WHEN @Var   = '' THEN '' ELSE CASE WHEN @Desc = '' THEN @Var   ELSE '-' + @Var   END END ))
Select @Desc = @Desc + LTRIM(RTRIM(CASE WHEN @Limit = '' THEN '' ELSE CASE WHEN @Desc = '' THEN @Limit ELSE '-' + @Limit END END ))
Select @Desc = @Desc + LTRIM(RTRIM(CASE WHEN @Temp  = '' THEN '' ELSE CASE WHEN @Desc = '' THEN @Temp  ELSE '-' + @Temp  END END ))
Select @Desc = @Desc + LTRIM(RTRIM(CASE WHEN @Custm = '' THEN '' ELSE CASE WHEN @Desc = '' THEN @Custm ELSE '-' + @Custm END END ))
