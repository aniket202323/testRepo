CREATE PROCEDURE dbo.spServer_CmnGetProdCodeByTime
@PU_Id int,
@TimeStamp datetime,
@Prod_Code nvarchar(50) OUTPUT
 AS
Declare
  @Prod_Id int,
  @Master_Unit int
Select @Master_Unit = NULL
Select @Master_Unit = Master_Unit From Prod_Units_Base Where PU_Id = @PU_Id
If (@Master_Unit Is NULL)
  Select @Master_Unit = @PU_Id
Select @Prod_Id = Prod_Id
  From Production_Starts 
  Where (PU_Id = @Master_Unit) And
        (Start_Time < @TimeStamp) And
        ((End_Time >= @TimeStamp) Or (End_Time Is Null))
Select @Prod_Code = NULL
Select @Prod_Code = Prod_Code From Products Where Prod_Id = @Prod_Id
If (@Prod_Code Is Null)
  Select @Prod_Code = ''
