Create Procedure dbo.spDS_CheckEventAppliedProduct
@ProdCode nVarChar(50),
@ProdId int Output
AS
/*
declare @out int
exec spDS_CheckEventAppliedProduct 'BSTK50',@out output
select @out
*/
 Declare @NewTimeStamp datetime
----------------------------------------------------------------
-- Initialize variables
---------------------------------------------------------------- 
 Select @ProdId = -1
----------------------------------------------------------------
-- Check if product exists
----------------------------------------------------------------
 Select @ProdID = Prod_Id 
  From Products 
   Where Prod_Code = @ProdCode
