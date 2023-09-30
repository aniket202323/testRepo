CREATE PROCEDURE dbo.spServer_CmnGetDBValues
@Var_Id int,
@Start_Time nVarChar(30),
@End_Time nVarChar(30)
 AS
Select  	 Result,
 	 DatePart(Year,Result_On),
 	 DatePart(Month,Result_On),
 	 DatePart(Day,Result_On),
 	 DatePart(Hour,Result_On),
 	 DatePart(Minute,Result_On),
 	 DatePart(Second,Result_On)
  From Tests
  Where (Var_Id = @Var_Id) And
 	 (Result_On > @Start_Time) And
        (Result_On <= @End_Time) And
        (Result Is Not Null)
  Order By Result_On Desc
