CREATE procedure [dbo].[spASP_wrEventGenealogyAlias]
@Unit int
AS
-- Inputs
Select Distinct PEI_Id [Id], Input_Name Alias
From PRDExec_Inputs
Where PU_Id = @Unit
Order By Alias
-- Output
Select Distinct pei.PEI_Id [Id], pei.Input_Name Alias
From PRDExec_Input_Sources peis
Join PRDExec_Inputs pei On pei.PEI_Id = peis.PEI_Id
Where peis.PU_Id = @Unit
