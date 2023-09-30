Create Procedure dbo.spGBAGetDataType @ID integer 
 AS
  select * from data_type where data_type_id = @ID
