create procedure [dbo].[spWA_GetErrorList]
  @Day DateTime = Null,
  @InTimeZone nvarchar(200) =NULL
AS
SELECT [Id]
      ,[AppId]
      ,[ErrorCode]
      ,[ErrorDesc]
      ,[ErrorType]
      ,[ExceptionType]
      ,[Parameters]
      ,[SourceFile]
      ,[SourceMethod]
      ,[StackTrace]
      ,'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] ([TimeStamp],@InTimeZone)  
      ,[UserId]
FROM [GBDB].[dbo].[Errors]
WHERE ([TimeStamp] Between @Day And DATEADD(dd, 1, @Day) Or @Day Is Null)
AND ErrorType = 1
