CREATE PROCEDURE dbo.spEM_ShowServerLogs 
 	 @StartTime  datetime,
 	 @EndTime    datetime,
 	 @Name       nvarchar(50),
 	 @Parms      nvarchar(50)
  AS
  --
  Select @Parms = replace(@Parms,'*','%')
  Select @Parms = replace(@Parms,'?','_')
  Select @Name = replace(@Name,'*','%')
  Select @Name = replace(@Name,'?','_')
  Select @Parms = '%' + @Parms + '%'
If  isdate(@StartTime) = 0
   Begin
    Select @StartTime = Dateadd(day,-1,dbo.fnServer_CmnGetDate(getUTCdate()))
    Select @EndTime =dbo.fnServer_CmnGetDate(getUTCdate())
   End
If  isdate(@EndTime) = 0
   Begin
    Select @StartTime =Dateadd(day,-1,dbo.fnServer_CmnGetDate(getUTCdate()))
    Select @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
   End
DECLARE  @TT Table(TIMECOLUMNS nvarchar(50))
Insert Into @TT  (TIMECOLUMNS) Values ('Time')
select * from @TT
If @Name = '%' and @Parms = '%'
  SELECT [Time] = Message_TimeStamp,[Message] = Message, [Service] = Service_Desc
     From Server_Log_Records
     Where Message_TimeStamp  between  @StartTime and @EndTime  -- and (Service_Desc like @Name)  and (Message Like @Parms)
   Order by Message_TimeStamp ,Record_Order
Else If @Name = '%'
  SELECT [Time] = Message_TimeStamp ,[Message] = Message, [Service] = Service_Desc
     From Server_Log_Records
     Where (Message_TimeStamp  between @StartTime and @EndTime) and (Message Like @Parms)
   Order by Message_TimeStamp ,Record_Order
Else If @Parms = '%'
  SELECT [Time] = Message_TimeStamp ,[Message] = Message, [Service] = Service_Desc
     From Server_Log_Records
     Where (Message_TimeStamp  between @StartTime and @EndTime) and (Service_Desc like @Name)
   Order by Message_TimeStamp ,Record_Order
Else
  SELECT [Time] = Message_TimeStamp ,[Message] = Message, [Service] = Service_Desc
     From Server_Log_Records
     Where (Message_TimeStamp  between @StartTime and @EndTime) and (Service_Desc like @Name)  and (Message Like @Parms)
   Order by Message_TimeStamp ,Record_Order
