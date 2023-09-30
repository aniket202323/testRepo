Create Procedure dbo.spGBO_InsertCapturedData
  @DSet_Id int,
  @Var_Id int, 
  @Result nvarchar(25)     AS
  insert into gb_dset_data (dset_id,var_id,value)
    values (@DSet_Id,@Var_Id,@Result)
  return(100)
