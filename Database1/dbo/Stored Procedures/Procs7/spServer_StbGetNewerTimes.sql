CREATE PROCEDURE dbo.spServer_StbGetNewerTimes
@Var_Id int,
@TimeStamp datetime
 AS
Select Datepart(Year,Result_On),
       Datepart(Month,Result_On),
       Datepart(Day,Result_On),
       Datepart(Hour,Result_On),
       Datepart(Minute,Result_On),
       Datepart(Second,Result_On)
  From Tests
  Where (Var_Id = @Var_Id) And
        (Result_On > @TimeStamp)
