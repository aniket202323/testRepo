CREATE PROCEDURE dbo.spServer_AMgrGetVarSpecsCache
@numgrades int=3,
@AffectedUnit int=NULL
 AS
declare
  @@varid int,
  @@ATDId int,
  @result nvarchar(25),
  @result_on datetime,
  @ChangeTime datetime,
  @StartTime datetime,
  @EffectTime datetime,
  @TmpStartTime datetime,
  @EndTime datetime,
  @UserId int,
  @count int,
  @sa_id int,
  @pu_id int,
  @prod_id int,
  @Master_Unit int,
  @OneSpec int,
  @Bailout int
if (@numgrades < 1)
  return 
Declare @AGVSCTheResults Table(StartTime datetime NULL, EndTime datetime NULL, EffectiveDate datetime NULL, ProdId int, VarId int, 
 	  	  	 LowerEntry nVarChar(30) COLLATE DATABASE_DEFAULT NULL, LowerReject nVarChar(30) COLLATE DATABASE_DEFAULT NULL, LowerWarning nVarChar(30) COLLATE DATABASE_DEFAULT NULL, LowerUser nVarChar(30) COLLATE DATABASE_DEFAULT NULL, 
 	  	  	 Target nVarChar(30) COLLATE DATABASE_DEFAULT NULL, UpperUser nVarChar(30) COLLATE DATABASE_DEFAULT NULL, UpperWarning nVarChar(30) COLLATE DATABASE_DEFAULT NULL, UpperReject nVarChar(30) COLLATE DATABASE_DEFAULT NULL, UpperEntry nVarChar(30) COLLATE DATABASE_DEFAULT NULL,
 	  	  	 LowerControl nVarChar(30) COLLATE DATABASE_DEFAULT NULL, TargetControl nVarChar(30) COLLATE DATABASE_DEFAULT NULL, UpperControl nVarChar(30) COLLATE DATABASE_DEFAULT NULL)
Declare Var_Cursor INSENSITIVE CURSOR 
For Select distinct var_id from Alarm_Template_Var_Data
For Read Only
Open Var_Cursor  
VarLoop:
Fetch Next From Var_Cursor Into @@varid
If (@@Fetch_Status = 0)
Begin
  select @sa_id=sa_id, @pu_id=pu_id from variables_base where var_id=@@varid
  Select @Master_Unit = Master_Unit From Prod_Units_Base Where PU_Id = @PU_Id
  If (@Master_Unit Is Null)
    Select @Master_Unit = @PU_Id
  select @StartTime = dbo.fnServer_CmnGetDate(GetUTCDate())
  select @Count=0
GradeLoop:
 	 if (@AffectedUnit is NULL or @AffectedUnit = @Master_Unit)
 	   select @StartTime=max(start_time) from production_starts where (Start_Time < @StartTime) and (PU_Id = @Master_Unit)
 	 else
 	   select @StartTime=NULL
  if @starttime is not null
  begin
    select @prod_id=Prod_id, @EndTime=End_Time from Production_Starts where pu_id=@master_unit and Start_Time = @StartTime
    if @sa_id = 2 -- Grade
    begin
      Insert Into @AGVSCTheResults(VarId, ProdId, StartTime, EndTime, EffectiveDate, LowerEntry, LowerReject, LowerWarning, LowerUser, Target, UpperUser, UpperWarning, UpperReject, UpperEntry, LowerControl, TargetControl, UpperControl) 
      select @@varid, @Prod_id, @StartTime, @EndTime, Effective_Date, L_Entry, L_Reject, L_Warning, L_User, Target, U_User, U_Warning, U_Reject, U_Entry, L_Control, T_Control, U_Control
            from var_specs where var_id=@@varid and Prod_id=@Prod_id and @StartTime >= Effective_Date and (Expiration_Date is null or Expiration_Date > @StartTime)
    end
    else -- immediate
    begin
      select @Bailout=0
      select @TmpStartTime=@StartTime
ImmediateLoop:
      Select @ChangeTime = Null --Mike this is the line we added
      Select @EffectTime = Null
      select @ChangeTime=Expiration_Date, @EffectTime=Effective_Date from var_specs 
        where var_id=@@varid and Prod_id=@Prod_id and @TmpStartTime >= Effective_Date and (Expiration_Date is null or Expiration_Date > @TmpStartTime)
      if @ChangeTime is null and @EffectTime is null
      begin
        select @ChangeTime=min(Effective_Date) from var_specs where var_id=@@varid and Prod_id=@Prod_id and @TmpStartTime < Effective_Date 
      end
      select @Bailout=@Bailout + 1
      select @OneSpec = 1
      if (@ChangeTime > @TmpStartTime and (@EndTime is null or @ChangeTime <= @EndTime))
        select @OneSpec = 0
      if (@ChangeTime < @TmpStartTime and (@EndTime is null or @ChangeTime <= @EndTime))
        select @OneSpec = 0
      if @OneSpec = 1
      begin
        Insert Into @AGVSCTheResults(VarId, ProdId, StartTime, EndTime, EffectiveDate, LowerEntry, LowerReject, LowerWarning, LowerUser, Target, UpperUser, UpperWarning, UpperReject, UpperEntry, LowerControl, TargetControl, UpperControl) 
        select @@varid, @Prod_id, @TmpStartTime, @EndTime, Effective_Date, L_Entry, L_Reject, L_Warning, L_User, Target, U_User, U_Warning, U_Reject, U_Entry, L_Control, T_Control, U_Control
              from var_specs where var_id=@@varid and Prod_id=@Prod_id and @TmpStartTime > Effective_Date and (Expiration_Date is null or Expiration_Date > @TmpStartTime)
      end
      else
      begin
        Insert Into @AGVSCTheResults(VarId, ProdId, StartTime, EndTime, EffectiveDate, LowerEntry, LowerReject, LowerWarning, LowerUser, Target, UpperUser, UpperWarning, UpperReject, UpperEntry, LowerControl, TargetControl, UpperControl) 
        select @@varid, @Prod_id, @TmpStartTime, @ChangeTime, Effective_Date, L_Entry, L_Reject, L_Warning, L_User, Target, U_User, U_Warning, U_Reject, U_Entry, L_Control, T_Control, U_Control
              from var_specs where var_id=@@varid and Prod_id=@Prod_id and @ChangeTime = Expiration_Date
        select @TmpStartTime = DateAdd(Second,1,@ChangeTime)
        if @Bailout < 30
          goto ImmediateLoop
      end
    end
    select @Count=@Count + 1
    if @Count < @numGrades
      goto GradeLoop
  end
  goto VarLoop
end
Close Var_Cursor
Deallocate Var_Cursor
select VarId, ProdId, StartTime, EndTime, LowerEntry, LowerReject, LowerWarning, LowerUser, Target, UpperUser, UpperWarning, UpperReject, UpperEntry, LowerControl, TargetControl, UpperControl, EffectiveDate from @AGVSCTheResults order by varid, starttime
