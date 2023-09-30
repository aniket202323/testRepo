Create Procedure dbo.spDS_ProdChangeGetAdditionData
 @PUId int,
 @EventSubTypeId int
AS
 Declare @EventSubTypeDesc nVarChar(50),
         @PUDesc nVarChar(50)
 Select @EventSubTypeDesc = NULL
 Select @PUDesc = NULL
--------------------------------------------------------
-- Get Products produced on the PUId
--------------------------------------------------------
 Select PP.Prod_Id as ProdId, PR.Prod_Code as ProdCode 
  From PU_Products PP Inner Join Products PR
   On PP.Prod_Id = PR.Prod_Id
   Where PP.PU_Id = @PUId
    Order by PR.Prod_Code
-----------------------------------------------------------------------------
-- Detail info (event subtype and PU date)
-----------------------------------------------------------------------------
 Select @PUDesc = PU_Desc
  From Prod_Units
   Where PU_Id = @PUId
 Select @EventSubTypeDesc=Event_SubType_Desc  
  From Event_SubTypes
   Where Event_SubType_Id = @EventSubTypeId
 Select @PUDesc as PUDesc ,@EventSubTypeDesc as EventSubTypeDesc
