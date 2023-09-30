Create Procedure dbo.spGBAGetActiveSpec
 @SpecID integer, @CharId integer 
 AS
  select * from active_specs where spec_id = @SpecId  and char_id = @CharId
