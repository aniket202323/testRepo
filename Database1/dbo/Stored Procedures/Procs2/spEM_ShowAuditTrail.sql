CREATE PROCEDURE dbo.spEM_ShowAuditTrail 
 	 @StartTime  nvarchar(25),
 	 @EndTime    nvarchar(25),
 	 @SpName     nvarchar(50),
 	 @Parms      nvarchar(50)
  AS
  --
  Select @SpName = replace(@SpName,'*','%')
  Select @SpName = replace(@SpName,'?','_')
  Select @Parms = replace(@Parms,'*','%')
  Select @Parms = replace(@Parms,'?','_')
If  isdate(@StartTime) = 0
   Begin
    Select @StartTime = convert(nvarchar(25),Dateadd(day,-2,dbo.fnServer_CmnGetDate(getUTCdate())))
    Select @EndTime = convert(nvarchar(25),dbo.fnServer_CmnGetDate(getUTCdate()))
   End
If  isdate(@EndTime) = 0
   Begin
    Select @StartTime = convert(nvarchar(25),Dateadd(day,-2,dbo.fnServer_CmnGetDate(getUTCdate())))
    Select @EndTime = convert(nvarchar(25),dbo.fnServer_CmnGetDate(getUTCdate()))
   End
 	 DECLARE  @TT Table(TIMECOLUMNS nvarchar(50))
 	 Insert Into @TT  (TIMECOLUMNS) Values ('Start Time')
 	 select * from @TT
  SELECT [Start Time] = StartTime,[User] = Username,[Stored Procedure] = Sp_Name,Parameters
 	 From audit_Trail a
 	 Left Join Users u on u.user_Id = a.User_Id
   Where Sp_Name like @SpName and (Parameters is null or Parameters Like @Parms) and StartTime between convert(datetime,@StartTime) and convert(datetime,@EndTime)
   Order by StartTime desc
  --
