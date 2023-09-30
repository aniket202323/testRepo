CREATE Procedure dbo.spEMEC_LoadEventSubtype
@Event_Subtype_Id int,
@User_Id int
AS
    select distinct MyType = 1,event_configuration.pu_id, prod_units.pu_desc
    from event_configuration
    join prod_units on prod_units.pu_id = event_configuration.pu_id
    where event_configuration.event_subtype_id = @Event_Subtype_Id
 	 UNION
 	 Select MyType = 2,Var_Id,Var_Desc
 	 From Variables 
 	 WHERE Event_Subtype_Id = @Event_Subtype_Id
 	 
