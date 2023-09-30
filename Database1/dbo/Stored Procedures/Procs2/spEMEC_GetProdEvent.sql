Create Procedure dbo.spEMEC_GetProdEvent
@Event_Subtype_Id int,
@User_Id int
AS
select event_subtype_id, event_subtype_desc, event_mask,
    dimension_a_enabled, dimension_a_name, 
    A_Eng_Unit_Id = Dimension_A_Eng_Unit_Id, dimension_x_name, 
    X_Eng_Unit_Id = Dimension_X_Eng_Unit_Id, dimension_y_enabled, 
    dimension_y_name, Y_Eng_Unit_Id = Dimension_Y_Eng_Unit_Id, 
    dimension_z_enabled, dimension_z_name, 
    Z_Eng_Unit_Id = Dimension_Z_Eng_Unit_Id, comment_id
from event_subtypes
where event_subtype_id = @Event_Subtype_Id
