
CREATE PROCEDURE [dbo].[spPS_GetUnitEngineeringUnits]
@UnitId Int 
 AS
 if @UnitId IS NULL
BEGIN
    -- Raise an error and return
    RAISERROR ('Invalid parameter: @UnitId cannot be NULL ', 16, 1)
    RETURN
END

BEGIN
		SELECT	 u.PU_Id UnitId, es.Dimension_X_Eng_Unit_Id EngUnitId
		FROM	Prod_Units_Base u
		left join Event_Configuration ec on ec.PU_Id = u.PU_Id and ec.ET_Id = 1
		left join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
		WHERE	 u.PU_Id = @UnitId
END
    
