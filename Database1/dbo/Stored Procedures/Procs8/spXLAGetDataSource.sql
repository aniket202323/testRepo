Create Procedure dbo.spXLAGetDataSource @ID integer
AS 
  select ds_desc from data_source where ds_id = @ID
