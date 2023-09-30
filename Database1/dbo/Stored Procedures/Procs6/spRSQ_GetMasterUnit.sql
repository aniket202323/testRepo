Create Procedure dbo.spRSQ_GetMasterUnit
@PU_Id int,
@MasterUnit int OUTPUT
 AS
Select @MasterUnit = Master_Unit From Prod_Units Where PU_Id = @PU_Id
