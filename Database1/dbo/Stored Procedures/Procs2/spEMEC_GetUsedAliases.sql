Create Procedure dbo.spEMEC_GetUsedAliases 
@EC_Id int,
@FieldType int
as
/*
ED_Field_Type_Id Field_Type_Desc 
---------------- ----------------
3                Tag             
10               Variable Id     
Get the aliases for all other field types. As we add more, add to the join below
*/
Select Alias
  from Event_Configuration_Data d
  Join ED_Fields f on f.ED_Field_Id = d.ED_Field_Id and f.ED_Field_Type_Id in (3,10) --Add them all here
  Where d.EC_Id = @EC_Id and f.ED_Field_Type_Id <> @FieldType And Alias is not null --remove the one I'm already in
