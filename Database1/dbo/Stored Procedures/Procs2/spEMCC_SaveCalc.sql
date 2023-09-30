CREATE PROCEDURE dbo.spEMCC_SaveCalc
@CalcName    nvarchar(255),
@CalcDesc    nvarchar(255),
@CalcTypeId  int,
@Equation    nvarchar(255),
@SPName      nvarchar(50),
@Version     nVarChar(10),
@Locked      bit,
@Trigger     int,
@Lagtime     int,
@MaxRunTime int,
@Optimizecalc 	 Int,
@User_Id     int,
@CalcId      int = 0 Output
  AS
DECLARE @Insert_Id integer 
  select @CalcId = isnull(@CalcId,0)
  if @CalcName is null
    select @CalcName = '(null)'
  if @CalcDesc is null
    select @CalcDesc = '(null)'
  if @CalcTypeId is null
    select @CalcTypeId = 0
  if @Equation is null
    select @Equation = '(null)'
  if @SPName is null
    select @SPName  = '(null)'
  if @Version is null
    select @Version  = '(null)'
  if @Locked is null
    select @Locked = 0
  if @Trigger is null
    select @Trigger = 0
If @Lagtime is null
    Select @Lagtime = 0
If @MaxRunTime is null
   Select @MaxRunTime = 15 -- 15 is current default value
Select @Optimizecalc = isnull(@Optimizecalc,1)
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
  VALUES (1, @User_Id, substring('spEMCC_CalcConfig_CalcSave', 1, 30),
          convert(nvarchar(55),@CalcId) + ','  + 
          substring(convert(nvarchar(255),ltrim(rtrim(@CalcName))),1,25) + ','  + 
          substring(convert(nvarchar(255),ltrim(rtrim(@CalcDesc))),1,25) + ','  + 
          convert(varchar(5),@CalcTypeId) + ','  + 
          substring(convert(nvarchar(255),ltrim(rtrim(@Equation))),1,20) + ','  + 
          substring(convert(nvarchar(255),ltrim(rtrim(@SPName))),1,20) + ','  + 
          substring(convert(nvarchar(255),ltrim(rtrim(@Version))),1,20) + ','  + 
           Convert(nVarChar(1),@Locked) + ','  + 
          convert(nVarChar(10),@LagTime) + ','  + 
          convert(nVarChar(10),@MaxRunTime) + ','  + 
 	    Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
if @Trigger = 0 
   select @Trigger = null
if @CalcID = 0 -- is new id 
  begin
    insert into calculations
      (calculation_name, calculation_desc, calculation_type_id, version, locked,trigger_type_id,Lag_Time,Max_Run_Time,Optimize_Calc_Runs)
      values(@CalcName, @CalcDesc, @CalcTypeId, @Version, @Locked,@Trigger,@Lagtime, @MaxRunTime,@Optimizecalc)
    select @CalcId = Scope_Identity()
  end
else
  begin
    update calculations
      set calculation_name      = @CalcName,
            calculation_desc    = @CalcDesc,
            calculation_type_id  = @CalcTypeId,
            version             = @Version, 
            locked              = @Locked,
            trigger_type_id     = @Trigger,
 	      	   Lag_time 	  	 = @Lagtime,
            Max_Run_Time = @MaxRunTime,
 	  	   Optimize_Calc_Runs = @Optimizecalc
        where calculation_id = @CalcId
  end
if @CalcTypeId = 1 	  	 -- equation
  update calculations
    set equation = @Equation, stored_procedure_name = '', script = ''
      where calculation_id = @CalcId
else if @CalcTypeId = 2 	  	 -- sp
  update calculations
    set stored_procedure_name = @SPName, equation = Null, script = ''
      where calculation_id = @CalcId
else if @CalcTypeId = 3 	  	 -- script
  update calculations
    set stored_procedure_name = '', equation = Null
      where calculation_id = @CalcId
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
  WHERE Audit_Trail_Id = @Insert_Id
