CREATE PROCEDURE dbo.spServer_OPCWriteCurValue
@Var_Type int,
@Var_Key int,
@Property int,
@User_Id int,
@Value nVarChar(100),
@ErrMsg nVarChar(100) output
AS
declare
  @PU_Id int,
  @MU_Id int,
  @Prod_Id int,
  @GCTime datetime,
  @TTime datetime,
  @SA_Id int,
  @Group_Id int,
  @Access_Id int
-- Variables
if (@Var_Type = 1)
begin
  if (@Property = 2) -- Value Property
  begin
     --Get Group_Id assigned to Variable, Production Group up to Production Unit if necessary
    select @Group_Id = Coalesce(Coalesce(v.Group_Id, pg.Group_Id), pu.Group_Id)
       From Variables_Base v
         Join PU_Groups pg on pg.PUG_Id = v.PUG_Id
         Join Prod_Units_Base pu on pu.PU_Id = pg.PU_Id
           Where v.Var_Id = @Var_Key
    if @Group_Id is not NULL
      Begin
        select @Access_Id = Coalesce(Access_Level, 0) from User_Security Where User_Id = @User_Id and Group_Id = 1
        if @Access_Id is NULL
          Begin
            Select @Access_Id = Coalesce(Access_Level, 0) from User_Security Where User_Id = @User_Id and Group_Id = @Group_Id
            if @Access_Id is NULL or @Access_Id < 2
              Select @ErrMsg = 'User is not Authorized to Write to Var'
              return
          End
      End
    select 2, @Var_Key, 0, @User_Id, 0, @Value, dbo.fnServer_CmnGetDate(GetUTCDate()), 0, 0
  end
end
-- Production Units
--if (@Var_Type = 2)
--begin
--  if (@Property = 5013) -- CurrentProduct Property
--  begin
--    Select @MU_Id = Master_Unit from Prod_Units where PU_Id = @Var_Key
--    if (@MU_Id is null)
--      Select @MU_Id = @Var_Key
--    Select @OutValue = replace(convert(nVarChar(100),Prod_Id),' ',''), @OutTimestamp = Start_Time from Production_Starts where PU_Id = @MU_Id and End_Time is null
--  end
--end
