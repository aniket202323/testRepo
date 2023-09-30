CREATE PROCEDURE dbo.spServer_CmnGetPSTestData
@Var_Id int,
@Start_Time nVarChar(30),
@End_Time nVarChar(30),
@MU_Id int
 AS
Select Result,
       Year = DatePart(Year,Result_On),
       Month = DatePart(Month,Result_On),
       Day = DatePart(Day,Result_On),
       Hour = DatePart(Hour,Result_On),
       Minute = DatePart(Minute,Result_On),
       Second = 0
  From Tests 
  Where (Var_Id = @Var_Id) And 
        (Result_On > @Start_Time) And 
        (Result_On <= @End_Time) And 
        (Canceled = 0) And 
        (Result Is Not Null)
  Order By Result_On
