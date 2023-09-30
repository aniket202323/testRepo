CREATE FUNCTION dbo.fnCMN_GetSpecTargetsByProduct(@StartTime DATETIME, @EndTime DATETIME, @Unit INT, @ReferenceProduct INT) 
     RETURNS @SpecTargets Table (TargetPercent real, WarningPercent real, RejectPercent real)
AS 
Begin
--------------------------------------------------------------
-- Local Variables
--------------------------------------------------------------
Declare @TargetPercent real
Declare @WarningPercent real
Declare @RejectPercent real
If @ReferenceProduct IS NOT NULL 
  Begin
    Select @TargetPercent = convert(real,target), 
           @WarningPercent = convert(real, u_warning),
           @RejectPercent = convert(real, u_reject)
      From Active_Specs aspec
      Join Prod_Units pu on pu.Downtime_Percent_Specification = aspec.Spec_Id and pu.PU_Id = @Unit
      Join Specifications s on pu.Downtime_Percent_Specification = s.Spec_Id
      Join PU_Characteristics puc on puc.PU_Id = pu.PU_Id and puc.prop_id = s.prop_id and puc.Prod_Id = @ReferenceProduct
      Where aspec.Char_Id = puc.Char_Id and 
            aspec.Effective_Date <= @StartTime and 
            ((aspec.Expiration_Date > @StartTime) or (aspec.Expiration_Date Is Null))
  end
insert Into @SpecTargets(TargetPercent, WarningPercent, RejectPercent)
   Values(@TargetPercent, @WarningPercent, @RejectPercent)
RETURN
END
