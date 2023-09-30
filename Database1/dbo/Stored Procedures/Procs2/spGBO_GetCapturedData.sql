Create Procedure dbo.spGBO_GetCapturedData
  @DSet_ID int     AS
  select * from gb_dset 
    where dset_id = @DSet_Id
  select * from gb_dset_data
    where dset_id = @Dset_Id
