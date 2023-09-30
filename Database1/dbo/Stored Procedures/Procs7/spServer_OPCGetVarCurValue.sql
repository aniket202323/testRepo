CREATE PROCEDURE dbo.spServer_OPCGetVarCurValue
@Var_Type int,
@Var_Key int,
@Property int,
@OutValue nVarChar(100) OUTPUT,
@OutTimestamp datetime OUTPUT,
@OutQuality nVarChar(10) OUTPUT,
@PRMsgType int OUTPUT,
@PRMsgKey int OUTPUT,
@ValueMsgId int OUTPUT,
@TimeMsgId int OUTPUT
AS
declare
  @PU_Id int,
  @MU_Id int,
  @Prod_Id int,
  @GCTime datetime,
  @TTime datetime,
  @SA_Id int
select @OutValue = Null
select @OutTimestamp = Null
select @OutQuality = 'Bad'
select @PRMsgType = Null
select @PRMsgKey = Null
select @ValueMsgId = Null
select @TimeMsgId = Null
-- Variables
if (@Var_Type = 1)
begin
  if (@Property = 2) -- Value Property
  begin
    select     top 1 @OutValue = Result, @OutTimestamp = Result_On
      from     Tests
      where    Var_Id = @Var_Key and Canceled = 0 and Result is not null
      order by Result_On desc
    if @OutValue is not null select @OutQuality = 'Good'
    select @PRMsgType = 3
    select @PRMsgKey = @Var_Key
    select @ValueMsgId = 3
    select @TimeMsgId = 11
  end
  if ((@Property = 5000) or -- UEntry Property
      (@Property = 5001) or -- UReject Property
      (@Property = 5002) or -- UWarning Property
      (@Property = 5003) or -- UUser Property
      (@Property = 5004) or -- Target Property
      (@Property = 5005) or -- LUser Property
      (@Property = 5006) or -- LWarning Property
      (@Property = 5007) or -- LReject Property
      (@Property = 5008))   -- LEntry Property
  begin
    Select @PU_Id = PU_Id, @SA_Id = SA_Id from Variables_Base where Var_Id = @Var_Key
    Select @MU_Id = Master_Unit from Prod_Units_Base where PU_Id = @PU_Id
    if (@MU_Id is null)
      Select @MU_Id = @PU_Id
    Select @Prod_Id = Prod_Id, @GCTime = Start_Time from Production_Starts where PU_Id = @MU_Id and End_Time is null
    if (@SA_Id = 2) -- Product Change
      Select @TTime = @GCTime
    else
      Select @TTime = dbo.fnServer_CmnGetDate(GetUTCDate())
    if (@Property = 5000)
      Select @OutValue = replace(convert(nVarChar(100),U_Entry),' ',''), @OutTimestamp = Effective_Date from Var_Specs where Var_Id = @Var_Key and Prod_Id = @Prod_Id and Effective_Date <= @TTime and (Expiration_Date > @TTime or  Expiration_Date is null)
    if (@Property = 5001)
      Select @OutValue = replace(convert(nVarChar(100),U_Reject),' ',''), @OutTimestamp = Effective_Date from Var_Specs where Var_Id = @Var_Key and Prod_Id = @Prod_Id and Effective_Date <= @TTime and (Expiration_Date > @TTime or  Expiration_Date is null)
    if (@Property = 5002)
      Select @OutValue = replace(convert(nVarChar(100),U_Warning),' ',''), @OutTimestamp = Effective_Date from Var_Specs where Var_Id = @Var_Key and Prod_Id = @Prod_Id and Effective_Date <= @TTime and (Expiration_Date > @TTime or  Expiration_Date is null)
    if (@Property = 5003)
      Select @OutValue = replace(convert(nVarChar(100),U_User),' ',''), @OutTimestamp = Effective_Date from Var_Specs where Var_Id = @Var_Key and Prod_Id = @Prod_Id and Effective_Date <= @TTime and (Expiration_Date > @TTime or  Expiration_Date is null)
    if (@Property = 5004)
      Select @OutValue = replace(convert(nVarChar(100),Target),' ',''), @OutTimestamp = Effective_Date from Var_Specs where Var_Id = @Var_Key and Prod_Id = @Prod_Id and Effective_Date <= @TTime and (Expiration_Date > @TTime or  Expiration_Date is null)
    if (@Property = 5005)
      Select @OutValue = replace(convert(nVarChar(100),L_User),' ',''), @OutTimestamp = Effective_Date from Var_Specs where Var_Id = @Var_Key and Prod_Id = @Prod_Id and Effective_Date <= @TTime and (Expiration_Date > @TTime or  Expiration_Date is null)
    if (@Property = 5006)
      Select @OutValue = replace(convert(nVarChar(100),L_Warning),' ',''), @OutTimestamp = Effective_Date from Var_Specs where Var_Id = @Var_Key and Prod_Id = @Prod_Id and Effective_Date <= @TTime and (Expiration_Date > @TTime or  Expiration_Date is null)
    if (@Property = 5007)
      Select @OutValue = replace(convert(nVarChar(100),L_Reject),' ',''), @OutTimestamp = Effective_Date from Var_Specs where Var_Id = @Var_Key and Prod_Id = @Prod_Id and Effective_Date <= @TTime and (Expiration_Date > @TTime or  Expiration_Date is null)
    if (@Property = 5008)
      Select @OutValue = replace(convert(nVarChar(100),L_Entry),' ',''), @OutTimestamp = Effective_Date from Var_Specs where Var_Id = @Var_Key and Prod_Id = @Prod_Id and Effective_Date <= @TTime and (Expiration_Date > @TTime or  Expiration_Date is null)
    if (@SA_Id = 2) -- Product Change
      Select @OutTimestamp = @GCTime
    if (datediff(second,@GCTime,@OutTimestamp) < 0)
      select @OutTimestamp = @GCTime
    if @OutValue is not null select @OutQuality = 'Good'
    select @PRMsgType = 5
    select @PRMsgKey = @MU_Id
    select @ValueMsgId = Null
    select @TimeMsgId = Null
  end
end
-- Production Units
if (@Var_Type = 2)
begin
  if (@Property = 5013) -- CurrentProduct Property
  begin
    Select @MU_Id = Master_Unit from Prod_Units_Base where PU_Id = @Var_Key
    if (@MU_Id is null)
      Select @MU_Id = @Var_Key
    Select @OutValue = replace(convert(nVarChar(100),Prod_Id),' ',''), @OutTimestamp = Start_Time from Production_Starts where PU_Id = @MU_Id and End_Time is null
    if @OutValue is not null select @OutQuality = 'Good'
    select @PRMsgType = 5
    select @PRMsgKey = @MU_Id
    select @ValueMsgId = 23
    select @TimeMsgId = 20
  end
  if (@Property = 5014) -- CurProdName Property
  begin
    Select @MU_Id = Master_Unit from Prod_Units_Base where PU_Id = @Var_Key
    if (@MU_Id is null)
      Select @MU_Id = @Var_Key
    Select @Prod_Id = Prod_Id, @OutTimestamp = Start_Time from Production_Starts where PU_Id = @MU_Id and End_Time is null
    Select @OutValue = Prod_Desc from Products where Prod_Id = @Prod_Id
    if @OutValue is not null select @OutQuality = 'Good'
    select @PRMsgType = 5
    select @PRMsgKey = @MU_Id
    select @ValueMsgId = null
    select @TimeMsgId = null
  end
end
-- Topic 100
if (@Var_Type = 100)
begin
  select @OutQuality = 'Wait' -- Wait for First Value
  select @PRMsgType = 100
  select @PRMsgKey = @Var_Key
  select @ValueMsgId = 60
  select @TimeMsgId = null
end
