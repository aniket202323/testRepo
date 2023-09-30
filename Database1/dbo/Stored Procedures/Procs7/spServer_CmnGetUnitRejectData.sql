CREATE PROCEDURE dbo.spServer_CmnGetUnitRejectData
  @PU_Id int,
  @STime nVarChar(30),
  @ETime nVarChar(30)
AS
Declare
  @Prod_Id int,
  @Prod_Start_Time DateTime,
  @Prod_End_Time DateTime,
  @Master_Unit int
select @Master_Unit = Master_Unit from Prod_Units_Base where PU_Id = @PU_Id
if (@Master_Unit is null) Select @Master_Unit = @PU_Id
Declare @UnitRejectWork Table(VarId int, Result_On DateTime, Result nVarChar(100) COLLATE DATABASE_DEFAULT, L_Reject float, U_Reject float, GoodData int)
declare Starts cursor read_only
    for select Start_Time, End_Time, Prod_Id
          from production_starts
         where PU_Id = @Master_Unit
           and ((@STime >  Start_Time and @STime <= End_Time)
             or (@ETime >  Start_Time and @ETime <= End_Time)
             or (@STime <= Start_Time and @ETime >= End_Time)
             or (@ETime >  Start_Time and End_Time is null))
open Starts
fetch next from Starts into @Prod_Start_Time, @Prod_End_Time, @Prod_Id
while @@FETCH_STATUS = 0
begin
  if (@Prod_Start_Time < @STime) select @Prod_Start_Time = @STime
  if (@Prod_End_Time   > @ETime) select @Prod_End_Time   = @ETime
  if (@Prod_End_Time is null)    select @Prod_End_Time   = @ETime
  --select @Prod_Start_Time, @Prod_End_Time, @Prod_Id
  insert into @UnitRejectWork (VarId, Result_On, Result, L_Reject, U_Reject, GoodData)
    (select v.Var_Id, t.Result_on, t.Result, s.L_Reject, s.U_Reject,
            GoodResult = case when convert(float,t.Result) < s.L_Reject then 0
                              when convert(float,t.Result) > s.U_Reject then 0
                              else 1
                         end
       from variables_Base v
       join var_specs s on s.Var_Id = v.Var_Id and s.Prod_Id = @Prod_Id and s.Effective_Date <= @Prod_End_Time and (s.Expiration_Date > @Prod_End_Time or s.Expiration_Date is null)
       join tests     t on t.Var_Id = v.Var_Id and t.Result_On > @Prod_Start_Time and t.Result_On <= @Prod_End_Time and t.Result is not null
      where v.PU_Id        =      @PU_Id
        and v.Unit_Reject  =      1
        and v.Data_Type_Id not in (3,8)
        and v.Is_Active    =      1
        and v.Data_Type_Id in     (1, 2)) -- Ints and Floats only???
  fetch next from Starts into @Prod_Start_Time, @Prod_End_Time, @Prod_Id
end
close Starts
deallocate Starts
Select * from @UnitRejectWork
 order by VarId, Result_On
