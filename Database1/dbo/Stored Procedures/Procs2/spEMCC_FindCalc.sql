CREATE PROCEDURE dbo.spEMCC_FindCalc
@NumberOfInputs    int,
@CalcSPName        nvarchar(50),
@CalcId            int OUT
  AS
Create Table #Calcs (
Calculation_Id int,
NumberOfInputs int
)
Select @CalcId = NULL
Insert into #Calcs
Select ci.Calculation_Id, Input_Count = Count(*) from Calculation_Inputs ci
  join Calculations c on c.Calculation_Id = ci.Calculation_Id
    Where c.Calculation_Type_Id = 2 and c.Stored_Procedure_Name = @CalcSPName
    Group By ci.Calculation_Id
select @CalcId = Calculation_Id From #Calcs Where NumberOfInputs = @NumberOfInputs
drop table #Calcs
