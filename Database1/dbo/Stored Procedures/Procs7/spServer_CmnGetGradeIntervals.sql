CREATE PROCEDURE dbo.spServer_CmnGetGradeIntervals
@PU_Id int,
@Start_Time datetime,
@End_Time datetime
AS
Declare
  @Master_Unit int
Select @Master_Unit = Master_Unit From Prod_Units_Base Where (PU_Id = @PU_Id)
If @Master_Unit Is Null
  Select @Master_Unit = @PU_Id
Select SYear = DatePart(Year,Start_Time),
       SMonth = DatePart(Month,Start_Time),
       SDay = DatePart(Day,Start_Time),
       SHour = DatePart(Hour,Start_Time),
       SMin = DatePart(Minute,Start_Time),
       SSec = DatePart(Second,Start_Time),
       ProdId = Prod_Id
  From Production_Starts
  Where (PU_Id = @Master_Unit) And
        (Start_Time > @Start_Time) And 
        (Start_Time < @End_Time)
  Order By Start_Time
