Create Procedure dbo.spGBO_InsertCapturedSet
  @PU_Id int,
  @Timestamp datetime, 
  @Prod_Id int, 
  @Operator nvarchar(10),
  @DSet_Id int OUTPUT     AS
  insert into gb_dset (pu_id,timestamp,prod_id,operator)
    values (@pu_id,@Timestamp,@Prod_Id, @operator)
  select @DSet_Id = Scope_Identity()
  if @DSet_Id is null return(1)
  return(100)
