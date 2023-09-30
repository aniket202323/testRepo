
CREATE PROCEDURE dbo.spActivities_GetArrayData @ArrayId  Int
                                              
AS
BEGIN
    SELECT Array_Id, Data, Element_Size, Num_Elements, PctGood FROM Array_Data WHERE Array_Id = @ArrayId
END
