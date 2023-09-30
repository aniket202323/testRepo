CREATE PROCEDURE dbo.spServer_CmnGetEventStatus
@EventStatus_Id int,
@EventStatus_Code nvarchar(50) OUTPUT
 AS
Select @EventStatus_Code = ProdStatus_Desc From Production_Status Where ProdStatus_Id = @EventStatus_Id
