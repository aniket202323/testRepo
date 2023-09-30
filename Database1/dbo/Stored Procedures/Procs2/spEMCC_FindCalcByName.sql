CREATE PROCEDURE dbo.spEMCC_FindCalcByName
@CalcName          nvarchar(50),
@CalcId            int OUT
  AS
Select @CalcId = NULL
select @CalcId = Calculation_Id From Calculations Where Calculation_Name = @CalcName
