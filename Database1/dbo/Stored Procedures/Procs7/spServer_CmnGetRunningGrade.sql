CREATE PROCEDURE dbo.spServer_CmnGetRunningGrade
@PU_Id int,
@TimeStamp datetime,
@LookAtAppProdId int,
@Prod_Id int OUTPUT,
@Start_Id int OUTPUT
 AS
Declare
  @Master_Unit int,
  @AppProdId int
Select @Master_Unit = Master_Unit From Prod_Units_Base Where (PU_Id = @PU_Id)
If @Master_Unit Is Null
  Select @Master_Unit = @PU_Id
Select @AppProdId = NULL
If (@LookAtAppProdId = 1)
  Select @AppProdId = Applied_Product From Events Where (PU_Id = @Master_Unit) And (TimeStamp = @TimeStamp)
Select @Start_Id = 0
If (@AppProdId Is Not NULL)
  Select @Prod_Id = @AppProdId
Else
  Select @Prod_Id = Prod_Id, @Start_Id = Start_Id
    From Production_Starts
    Where (PU_Id = @Master_Unit) And
          (Start_Time < @TimeStamp) And 
          ((End_Time >= @TimeStamp) Or (End_Time Is Null))
