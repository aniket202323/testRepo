CREATE PROCEDURE dbo.spServer_EMgrGetCurrentSpec
@PU_Id int,
@Prod_Code nvarchar(50) OUTPUT
 AS
Declare
  @MasterUnit int
Select @MasterUnit = NULL
Select @MasterUnit = Master_Unit From Prod_Units_Base Where PU_Id = @PU_Id
If (@MasterUnit Is NULL)
  Select @MasterUnit = @PU_Id
Select @Prod_Code = NULL
Select @Prod_Code = Prod_Code 
  From Products 
  Where Prod_Id = 
    (Select Prod_Id 
       From Production_Starts Where (PU_Id = @MasterUnit) And (End_Time Is Null))
If (@Prod_Code Is Null)
  Select @Prod_Code = Prod_Code From Products Where Prod_Id = 1
