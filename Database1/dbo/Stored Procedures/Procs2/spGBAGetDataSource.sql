Create Procedure dbo.spGBAGetDataSource @ID integer
 AS
  select ds_desc from data_source where ds_id = @ID
