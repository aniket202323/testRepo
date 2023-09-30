Create Procedure dbo.spSPC_GetCpCpk
@StartTime DATETIME,
@EndTime DATETIME,
@Var_Id INT,
@Prod_Id INT
AS
select Cp, Cpk from fnCMN_GetVariableStatistics(@StartTime, @EndTime, @Var_Id, @Prod_Id, 0)
