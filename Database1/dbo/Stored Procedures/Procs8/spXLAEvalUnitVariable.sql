Create Procedure dbo.spXLAEvalUnitVariable @Id integer, @which integer
 AS
  If @which = 1
    select * from gb_rsum_data where rsum_id = @Id
  Else
    select * from gb_dset_data where dset_id = @Id
