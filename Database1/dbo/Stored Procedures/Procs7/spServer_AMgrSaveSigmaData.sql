CREATE PROCEDURE dbo.spServer_AMgrSaveSigmaData
@TestId bigint,
@SampleSize int,
@Mean float,
@Sigma float
AS
Declare @CurTestId bigint
Declare @CurMean float
Declare @CurSigma float
Declare @LimitMean float
Declare @LimitSigma float
Declare @IsDifferent bit
Set @CurTestId = null
Set @CurMean = null
Set @CurSigma = null
Set @LimitMean = null
Set @LimitSigma = null
Set @IsDifferent = 0
Select @CurTestId = Test_Id, @CurMean = Mean, @CurSigma = Sigma from Test_Sigma_Data where Test_Id = @TestId
if (@CurTestId is null) -- The record doesn't exist, so add it and exit
begin
 	 if (@Mean is not null)
 	  	 insert into Test_Sigma_Data(Test_Id, Entry_On, Mean, Sigma) values (@TestId,dbo.fnServer_CmnGetDate(GETUTCDATE()), @Mean, @Sigma)
  return (1)
end
if (@Mean is null)
begin
 	 delete from Test_Sigma_Data where Test_Id = @TestId
  return (1)
end
if ((@CurMean is not null) and (@Mean is not null))
begin
  if ABS(@CurMean) > ABS(@Mean)
    set @LimitMean = ABS(@CurMean) * 0.000000001
  else
    set @LimitMean = ABS(@Mean) * 0.000000001
  if @LimitMean < 0.000000001
    set @LimitMean = 0.000000001
end
if ((@CurSigma is not null) and (@Sigma is not null))
begin
  if ABS(@CurSigma) > ABS(@Sigma)
    set @LimitSigma = ABS(@CurSigma) * 0.000000001
  else
    set @LimitSigma = ABS(@Sigma) * 0.000000001
  if @LimitSigma < 0.000000001
    set @LimitSigma = 0.000000001
end
if ((@CurMean is null) and (@Mean is not null)) or
   ((@CurMean is not null) and (@Mean is null)) or
   ((@CurMean is not null) and (@Mean is not null) and (ABS(@CurMean - @Mean) > @LimitMean))
  set @IsDifferent = 1
if ((@CurSigma is null) and (@Sigma is not null)) or
   ((@CurSigma is not null) and (@Sigma is null)) or
   ((@CurSigma is not null) and (@Sigma is not null) and (ABS(@CurSigma - @Sigma) > @LimitSigma))
  set @IsDifferent = 1
if (@IsDifferent = 1)
begin
  update Test_Sigma_Data set Entry_On = dbo.fnServer_CmnGetDate(GETUTCDATE()), Mean = @Mean, Sigma = @Sigma where Test_Id = @TestId
  return (1)
end
return (0);
