Create Procedure dbo.spDS_EventGetAdditionData
@PUId int,
@EventSubTypeId int
AS
 Declare @PUDesc nVarChar(50)
 Select @PUDesc = NULL
--------------------------------------------------------
-- PU Desc and Event Subtype info
--------------------------------------------------------
 Select @PUDesc = PU_Desc
  From Prod_Units
   Where PU_Id = @PUId
 Select @PUDesc as PU_Desc, ES.Event_SubType_Desc as EventSubTypeDesc,ES.Dimension_X_Name as DimensionXName, 
        ES.Dimension_Y_Name as DimensionYName, ES.Dimension_Z_Name as DimensionZName, ES.Dimension_A_Name as DimensionAName
  From Event_SubTypes ES
   Where Event_SubType_Id = @EventSubTypeId
