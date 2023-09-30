CREATE PROCEDURE dbo.spServer_AMgrGetVarSpecs
@VarId int,
@MasterPUId int,
@Result_On DateTime,
@ProdId int OUTPUT, -- Input/Output
@EffectiveDate DateTime OUTPUT,
@ExpirationDate DateTime OUTPUT,
@UEntry nvarchar(25) OUTPUT,
@UReject nvarchar(25) OUTPUT,
@UWarning nvarchar(25) OUTPUT,
@UUser nvarchar(25) OUTPUT,
@Target nvarchar(25) OUTPUT,
@LUser nvarchar(25) OUTPUT,
@LWarning nvarchar(25) OUTPUT,
@LReject nvarchar(25) OUTPUT,
@LEntry nvarchar(25) OUTPUT,
@LControl nvarchar(25) OUTPUT,
@TControl nvarchar(25) OUTPUT,
@UControl nvarchar(25) OUTPUT
AS
DECLARE @StartTime datetime
declare @sa_id int
 --
select @EffectiveDate = NULL
select @ExpirationDate = NULL
select @UEntry = NULL
select @UReject = NULL
select @UWarning = NULL
select @UUser = NULL
select @Target = NULL
select @LUser = NULL
select @LWarning = NULL
select @LReject = NULL
select @LEntry = NULL
select @LControl = NULL
select @TControl = NULL
select @UControl = NULL
select @sa_id = NULL
select @sa_id=sa_id from variables_base where var_id=@varid
SELECT @MasterPUId = Coalesce(Master_Unit,PU_Id) From Prod_Units_Base Where PU_Id = @MasterPUId
if @sa_Id is Null
  return (2)
if (@ProdId is Null or @ProdId = -1)
begin
  select @ProdId = Prod_Id, @StartTime=Start_Time from Production_Starts where PU_Id = @MasterPUId and 
                ((@Result_On >= Start_Time) and ((@Result_On < End_Time) or (End_Time is NULL)))
  if @ProdId is Null
    return (2)
end
if @sa_id=2 -- GRade
  select @Result_on = @StartTime
select @UEntry   = U_Entry,   @UReject  = U_Reject,  @UWarning = U_Warning, @UUser = U_User,
       @LEntry   = L_Entry,   @LReject  = L_Reject,  @LWarning = L_Warning, @LUser = L_User,
       @LControl = L_Control, @TControl = T_Control, @UControl = U_Control, @Target = Target,
       @EffectiveDate = Effective_Date, @ExpirationDate = Expiration_Date
       from var_specs where Prod_Id = @ProdId and @VarId = Var_Id and
       ((@Result_On >= Effective_Date) and ((@Result_On < Expiration_Date) or (Expiration_Date is NULL)))
if (@@RowCount = 0)
  if (not exists(select * from var_specs where Var_Id = @varid))
    return (99)
return (1)
