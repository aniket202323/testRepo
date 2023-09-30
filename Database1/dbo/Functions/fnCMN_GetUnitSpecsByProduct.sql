CREATE FUNCTION dbo.fnCMN_GetUnitSpecsByProduct(@StartTime DATETIME, @EndTime DATETIME, @Unit INT, @ReferenceProduct int) 
     RETURNS @UnitSpecs Table (Ideal real, Warning real, Reject real, TargetPercent real, WarningPercent real, RejectPercent real)
AS 
Begin
--------------------------------------------------------------
-- Local Variables
--------------------------------------------------------------
Declare @ProductionSpecification int
Declare @QualitySpecification int
Declare @ProductionVariable int
Declare @TimeEngineeringUnits int
Declare @ProductionProperty int
Declare @ProductionCharacteristic int
Declare @QualityProperty int
Declare @QualityCharacteristic int
-- output in table
Declare @Ideal real
Declare @Warning real
Declare @Reject real
Declare @TargetPercent real
Declare @WarningPercent real
Declare @RejectPercent real
-----------------------------------------------
-- Look Up Unit, Specification Information
-----------------------------------------------
Select @ProductionSpecification = Production_Rate_Specification,
       @QualitySpecification = Waste_Percent_Specification,
       @ProductionVariable = Production_Variable,
       @TimeEngineeringUnits = Production_Rate_TimeUnits
       --,@BalanceVariable = Balance_Variable
  From Prod_Units 
  Where PU_Id = @Unit
-----------------------------------------------
-- Production Specification
-----------------------------------------------
If @ProductionSpecification Is Not Null
  Begin
    Select @ProductionProperty = prop_id 
      From Specifications 
      Where Spec_Id = @ProductionSpecification
    Select @ProductionCharacteristic = char_id
      From pu_characteristics 
      Where prop_id = @ProductionProperty and
            prod_id = @ReferenceProduct and
            pu_id = @Unit
     -----------------------------------------------
     -- Production Characteristic
     -----------------------------------------------
    If @ProductionCharacteristic Is Not NUll
      Begin
        Select @Ideal = convert(real,target), 
               @Warning = convert(real, l_warning),
               @Reject = convert(real, l_reject)
          From Active_Specs
          Where Spec_Id = @ProductionSpecification and
                Char_Id = @ProductionCharacteristic and
                Effective_Date <= @StartTime and 
                ((Expiration_Date > @StartTime) or (Expiration_Date Is Null))
        --Always Scale To Per Minute 
        If @TimeEngineeringUnits = 0 
          Begin
            -- Spec Is Per Hour
            Select @Ideal = @Ideal / 60.0
            Select @Warning = @Warning / 60.0
            Select @Reject = @Reject / 60.0
          End
        Else If @TimeEngineeringUnits = 2
          Begin
            -- Spec Is Per Second
            Select @Ideal = @Ideal * 60.0
            Select @Warning = @Warning * 60.0
            Select @Reject = @Reject * 60.0
          End
        Else If @TimeEngineeringUnits = 3
          Begin
            -- Spec Is Per Day
            Select @Ideal = @Ideal / 1440.0
            Select @Warning = @Warning / 1440.0
            Select @Reject = @Reject / 1440.0
          End
      End 
  End
-----------------------------------------------
-- Quality Specification
-----------------------------------------------
If @QualitySpecification Is Not Null
  Begin
    Select @QualityProperty = prop_id 
      From Specifications 
      Where Spec_Id = @QualitySpecification
    Select @QualityCharacteristic = char_id
      From pu_characteristics 
      Where prop_id = @QualityProperty and
            prod_id = @ReferenceProduct and
            pu_id = @Unit
     -----------------------------------------------
     -- Quality Characteristic
     -----------------------------------------------
    If @QualityCharacteristic Is Not NUll
      Begin
        Select @TargetPercent = convert(real,target), 
               @WarningPercent = convert(real, u_warning),
               @RejectPercent = convert(real, u_reject)
          From Active_Specs
          Where Spec_Id = @QualitySpecification and
                Char_Id = @QualityCharacteristic and
                Effective_Date <= @StartTime and 
                ((Expiration_Date > @StartTime) or (Expiration_Date Is Null))
      End 
  End
     Insert Into @UnitSpecs(Ideal, Warning, Reject, TargetPercent, WarningPercent, RejectPercent)
     Values(@Ideal, @Warning, @Reject, @TargetPercent, @WarningPercent, @RejectPercent)
     RETURN
END
